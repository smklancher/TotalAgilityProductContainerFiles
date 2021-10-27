﻿###############
#  Constants  #
###############


$opAppName_Const = "/TotalAgility"
$opmtAppName_Const = "/TenantManagementWebSite"

$section_Const = "appSettings"
$connectionStringSection_Const = "connectionStrings"
$dapapiProvider = "DPAPI"
$rsaProvider = "RSA"

# Required installation and config file location
$installationDir = "C:\Program Files\Kofax\TotalAgility\"
$transformationInstallationDir = $installationDir + "Transformation Server\"
$LicenseServerDir = "C:\Program Files (x86)\Kofax\TotalAgility\LicenseServer"

$keyFileExportLocation_Const = "c:\KTA\PowerShellScripts\"
$keyFileName_Const = "totalAgilityKeysFile.xml"
$frameworkLocation_Const = "C:\windows\Microsoft.Net\Framework\v4.0.30319\"


$agilityServerWebDir = $installationDir + "Agility.Server.Web"
$agilityServerWebBinDir = $agilityServerWebDir + "\bin"
$CoreWorkerServiceDir = $installationDir + "CoreWorkerService"
$ReportingDir = $installationDir + "Reporting"

# EXE Configuration file names
$exportConnectConfigfile = "Agility.Server.ExportConnector.exe.config"
$coreWorkerServiceConfigFile = "Agility.Server.Core.WorkerService.exe.config"
$executorConfigFile = "Agility.Server.Core.Executor.exe.config"
$exportServiceConfigFile = "Agility.Server.Core.ExportService.exe.config"
$exportWorkerConfigFile = "Agility.Server.Core.ExportWorker.Host.exe.config"
$streamingServiceConfigFile = "Agility.Server.StreamingService.exe.config"
$reportingServiceAzureConfigFile = "Kofax.CEBPM.Reporting.AzureETL.exe.config"
$reportingServiceTAServiceConfigFile = "Kofax.CEBPM.Reporting.TAService.exe.config"
$transformationServiceHostConfigFile = "Kofax.CEBPM.CPUServer.ServiceHost.exe.config"
$transformationServiceDocConvSrvConfigFile = "Kofax.CEBPM.DocumentConversionService.Host.exe.config"
$licensingServiceDocConvSrvConfigFile = "KSALicenseService.exe.config"

# RSA encryption paramters
$containerFileNameAgilitySeverWeb_Const = "keyFileAgilityServerWeb"
$containerFileNameCoreworkerService_Const = "keyFileAgilityServerWeb"

$totalAgilityserviceUser_Const = "NT Authority\system"


###########################
#  Initalization methods  #
###########################

function init([string] $targetLocation) {
    Copy-Item -Path "c:\KTA\PowerShellScripts\Kofax.CEBPM.EncryptConfig.exe" -destination $targetLocation -Force
}

###############################################
#  Encryption  methods  for web config files  #
###############################################

function EncryptWebConfigFile([string] $frameworkLocation, [string] $appName, [string] $section, [string] $provider) {
    Set-Location $frameworkLocation
    "Encrypting " + $appName + " web.config file"
    .\aspnet_regiis.exe -pe $section -app $appName -prov $provider
}

##############################
#  DPAPI encryption methods  #
##############################

function AddSecurityProvider ([string] $exeConfigFileName, [string] $exeConfigFileLocation) {
    $fileName = $exeConfigFileLocation + "\" + $exeConfigFileName
    $xmlDoc = [System.Xml.XmlDocument](Get-Content $fileName);

    if($xmlDoc -ne $null -and $xmlDoc.configuration.configProtectedData -eq $null) 
    {
        $configProtectedDataElement = $xmlDoc.configuration.AppendChild($xmlDoc.CreateElement("configProtectedData"));
        $providersElement = $configProtectedDataElement.AppendChild($xmlDoc.CreateElement("providers"));

		if ($encryptionType -eq $dapapiProvider)
		{
			$addElement = $providersElement.AppendChild($xmlDoc.CreateElement("add"));
			$addElement.SetAttribute("useMachineProtection","true");
			$addElement.SetAttribute("name","DPAPIProtection");
			$addElement.SetAttribute("type","System.Configuration.DpapiProtectedConfigurationProvider, System.Configuration, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a");
		}
		if ($encryptionType -eq $rsaProvider)
		{
			$addElement = $providersElement.AppendChild($xmlDoc.CreateElement("add"));        
			$addElement.SetAttribute("name","RSAProvider");
			$addElement.SetAttribute("type","System.Configuration.RsaProtectedConfigurationProvider, System.Configuration, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a, processorArchitecture=MSIL");
			$addElement.SetAttribute("keyContainerName","CPUServerKeys");
		}

        $xmlDoc.Save($fileName);
    }
}

function DPAPIEncryption ([string] $exeConfigFileName, [string] $exeConfigFileLocation, [string] $section) {        
    Set-Location $exeConfigFileLocation
    $filePath = $exeConfigFileLocation + "\" + $exeConfigFileName
    $fileExists = Test-Path -Path $filePath 
    if($fileExists)
    {
        "DPAPI Encrypting " + $filePath + " config file"
        AddSecurityProvider $exeConfigFileName $exeConfigFileLocation
        .\Kofax.CEBPM.EncryptConfig.exe -f $exeConfigFileName -s $section -p DPAPIProtection -enc
    }
}

############################
#  RSA encryption methods  #
############################

function PrepareRSAContainerFile ([string] $RSAContainerFile, [string] $frameworkLocation, 
                                  [string] $totalAgilityserviceUser, [string] $exeConfigFileLocation, 
                                  [string] $exeConfigFileName, [string] $section, [string] $keyFileName) { 
    Set-Location $frameworkLocation

    # Generate custom RSA container file
    .\aspnet_regiis.exe -pz $RSAContainerFile
    .\aspnet_regiis.exe -pc $RSAContainerFile -exp

    # Grant the TotalAgility Core Worker Server Service user permission to read the RSA container file
    .\aspnet_regiis -pa $RSAContainerFile $totalAgilityserviceUser

    # Encrypt the file
    Set-Location $exeConfigFileLocation
    .\Kofax.CEBPM.EncryptConfig.exe -f $exeConfigFileName -s $section -p RSAProvider -enc

    # Export the key
    $ExportedKeyFile = $keyFileExportLocation + "\" + $keyFileName 
    Set-Location $frameworkLocation
    .\aspnet_regiis -px $RSAContainerFile $ExportedKeyFile -pri
}

function ImportRSAContainerFile ([string] $RSAContainerFile, [string] $keyFileName, [string] $keyFileSourceLocation, [string] $totalAgilityServiceUser){
    $sourceKeyFileName = $keyFileSourceLocation + "\" + $keyFileName    
    
    .\aspnet_regiis -pi $RSAContainerFile $sourceKeyFileName
    Remove-Item -Path $sourceKeyFileName -Force

    .\aspnet_regiis -pa $RSAContainerFile $totalAgilityServiceUser

}

function RSAEncryption ([string] $RSAContainerFile, [string] $frameworkLocation, [string] $totalAgilityserviceUser,
                        [string] $exeConfigFileLocation, [string] $exeConfigFileName, [string] $section,
                        [string] $keyFileExportLocation, [string] $keyFileName) {
    $filePath = $exeConfigFileLocation + "\" + $exeConfigFileName
    $fileExists = Test-Path -Path $filePath 
    if($fileExists) {
        "RSA Encrypting " + $filePath + " config file"
        AddSecurityProvider $exeConfigFileName $exeConfigFileLocation
        PrepareRSAContainerFile $RSAContainerFile $frameworkLocation $totalAgilityserviceUser $exeConfigFileLocation $exeConfigFileName $section $keyFileName
        ImportRSAContainerFile $RSAContainerFile $keyFileName $keyFileExportLocation $totalAgilityServiceUser
    }
}

####################
#  Main functions  #
####################

# OP Web config - Encryption
function EncryptWebConfig ([string] $provider){
    EncryptWebConfigFile $frameworkLocation_Const $opAppName_Const $section_Const $provider

	# OPMT Web config - Encryption
	if(Test-Path ("IIS:\Sites\Default Web Site\" + $opmtAppName_Const))
	{
		EncryptWebConfigFile $frameworkLocation_Const $opmtAppName_Const $section_Const $provider
	}
}

# DPAPI Encryption - for all exe config files in Agility.Server.Web
function AgilityServerWebConfig_DPAPICrypto () {
    init $agilityServerWebBinDir
    DPAPIEncryption $exportConnectConfigfile $agilityServerWebBinDir $section_Const
    DPAPIEncryption $streamingServiceConfigFile $agilityServerWebBinDir $section_Const
}

# DPAPI Encryption - for all exe config files in CoreWorkerService
function CoreWorkerServiceConfig_DPAPICrypto () {
    init $CoreWorkerServiceDir
    DPAPIEncryption  $coreWorkerServiceConfigFile $CoreWorkerServiceDir $section_Const
    DPAPIEncryption  $executorConfigFile $CoreWorkerServiceDir $section_Const
    DPAPIEncryption  $exportServiceConfigFile $CoreWorkerServiceDir $section_Const
    DPAPIEncryption  $exportWorkerConfigFile $CoreWorkerServiceDir $section_Const    
    DPAPIEncryption  $streamingServiceConfigFile $CoreWorkerServiceDir $section_Const
}

# DPAPI Encryption - for all exe config files in Reporting
function ReportingConfig_DPAPICrypto(){   
    init $ReportingDir 
    DPAPIEncryption $reportingServiceTAServiceConfigFile $ReportingDir $section_Const
}

# DPAPI Encryption - for all exe config files in TransformationServer
function TransformationServerConfig_DPAPICrypto(){ 
    init $transformationInstallationDir   
    DPAPIEncryption $transformationServiceHostConfigFile $transformationInstallationDir $section_Const
}

# DPAPI Encryption - for all exe config files in LicenseServer
function LicenseServerConfig_DPAPICrypto(){ 
    init $LicenseServerDir   
    DPAPIEncryption $licensingServiceDocConvSrvConfigFile $LicenseServerDir $section_Const
    DPAPIEncryption $licensingServiceDocConvSrvConfigFile $LicenseServerDir $connectionStringSection_Const
}

# RSA Encryption - for all exe config files in Agility.Server.Web
function AgilityServerWebConfig_RSACrypto () {
    init $agilityServerWebBinDir
    RSAEncryption $containerFileNameCoreworkerService_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $agilityServerWebBinDir $exportConnectConfigfile $section_Const $keyFileExportLocation_Const $keyFileName_Const
    RSAEncryption $containerFileNameCoreworkerService_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $agilityServerWebBinDir $streamingServiceConfigFile $section_Const $keyFileExportLocation_Const $keyFileName_Const
}

# RSA Encryption - for all exe config files in CoreWorkerService
function CoreWorkerServiceConfig_RSACrypto () {
    init $CoreWorkerServiceDir
    RSAEncryption $containerFileNameAgilitySeverWeb_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $CoreWorkerServiceDir $coreWorkerServiceConfigFile $section_Const $keyFileExportLocation_Const $keyFileName_Const
    RSAEncryption $containerFileNameAgilitySeverWeb_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $CoreWorkerServiceDir $executorConfigFile $section_Const $keyFileExportLocation_Const $keyFileName_Const
    RSAEncryption $containerFileNameAgilitySeverWeb_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $CoreWorkerServiceDir $exportServiceConfigFile $section_Const $keyFileExportLocation_Const $keyFileName_Const
    RSAEncryption $containerFileNameAgilitySeverWeb_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $CoreWorkerServiceDir $exportWorkerConfigFile $section_Const $keyFileExportLocation_Const $keyFileName_Const
    RSAEncryption $containerFileNameAgilitySeverWeb_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $CoreWorkerServiceDir $streamingServiceConfigFile $section_Const $keyFileExportLocation_Const $keyFileName_Const
}

# RSA Encryption - for all exe config files in Reporting
function ReportingConfig_RSACrypto(){    
    init $ReportingDir
    RSAEncryption $containerFileNameAgilitySeverWeb_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $ReportingDir $reportingServiceTAServiceConfigFile $section_Const $keyFileExportLocation_Const $keyFileName_Const
}

# RSA Encryption - for all exe config files in TransformationServer
function TransformationServerConfig_RSACrypto(){    
    init $transformationInstallationDir
    RSAEncryption $containerFileNameAgilitySeverWeb_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $transformationInstallationDir $transformationServiceHostConfigFile $section_Const $keyFileExportLocation_Const $keyFileName_Const
}

# RSA Encryption - for all exe config files in LicenseServer
function LicenseServerConfig_RSACrypto(){    
    init $LicenseServerDir    
    RSAEncryption $containerFileNameAgilitySeverWeb_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $LicenseServerDir $licensingServiceDocConvSrvConfigFile $section_Const $keyFileExportLocation_Const $keyFileName_Const
    RSAEncryption $containerFileNameAgilitySeverWeb_Const $frameworkLocation_Const $totalAgilityserviceUser_Const $LicenseServerDir $licensingServiceDocConvSrvConfigFile $connectionStringSection_Const $keyFileExportLocation_Const $keyFileName_Const
}

function AllDPAPIEncryption () {
    EncryptWebConfig ("DataProtectionConfigurationProvider")
    AgilityServerWebConfig_DPAPICrypto
    CoreWorkerServiceConfig_DPAPICrypto
    ReportingConfig_DPAPICrypto
    TransformationServerConfig_DPAPICrypto
	LicenseServerConfig_DPAPICrypto
}

function AllRSAEncryption () {
    EncryptWebConfig ("RsaProtectedConfigurationProvider")
    AgilityServerWebConfig_RSACrypto
    CoreWorkerServiceConfig_RSACrypto
    ReportingConfig_RSACrypto
    TransformationServerConfig_RSACrypto
	LicenseServerConfig_RSACrypto
}

function main ([string] $encryptionType) {
    switch ($encryptionType) {
        $dapapiProvider {
            AllDPAPIEncryption
        }
        $rsaProvider {
            AllRSAEncryption
        }
    }
}

# Getting value of encryption provider type from system environment variables if present or else using default value of DPAPI
$encryptionType = "";
Get-ChildItem env:*| sort-object name|Where-Object {$_.key -eq "KTA_CONFIG_ENCRYPTION_PROVIDER_TYPE"} | ForEach-Object {
    if ($_.value -eq $dapapiProvider -or $_.value -eq $rsaProvider)
	{
		$encryptionType = $_.value;
	}
}
# Calling the function to perform the encryption
main($encryptionType);
