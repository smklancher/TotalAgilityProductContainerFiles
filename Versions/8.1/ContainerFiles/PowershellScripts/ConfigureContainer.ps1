# install prerequisites for TA
$IIS = Get-WindowsOptionalFeature -Online -FeatureName “IIS-WebServer”
filter timestamp {"$(Get-Date -Format G): $_"}
write-output "Install prerequisites for TA" | timestamp
Invoke-Expression C:\TA\PowershellScripts\InstallWindowsFeatures.ps1

filter timestamp {"$(Get-Date -Format G): $_"}
write-output "Add Admin user for TA" | timestamp

# Add TA_Admin account local system 
Invoke-Expression C:\TA\PowershellScripts\AddAdminUser.ps1
Invoke-Expression C:\TA\PowershellScripts\UpdateAdminUser.ps1

if($IIS.State -eq "Enabled")
{
	# Install self signed cert
	filter timestamp {"$(Get-Date -Format G): $_"}
	write-output "Install Self signed cert" | timestamp
	Invoke-Expression C:\TA\PowershellScripts\CreateHttpsCert.ps1;
}
	
# Deleting Transformation Designer folder
$strings=@("TransformationDesigner*")
get-childitem -path "C:\TA\" -Include ($strings) -Recurse -force | ForEach-Object {
    try {
		#  -ErrorAction Ignore is being used to suppress known issue in Docker on Windows Server 2016 with deletion
        Remove-Item $_ -Force –Recurse -ErrorAction Ignore
		}
    catch { }
	}

if($IIS.State -eq "Enabled")
{
	# Download and install prerequisites for KCMProxy in silent mode

	# Download URL Rewrite
	wget https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi -OutFile "C:\rewrite_amd64_en-US.msi"
	# Download Application Request Routing
	wget http://download.microsoft.com/download/E/9/8/E9849D6A-020E-47E4-9FD0-A023E99B54EB/requestRouter_amd64.msi -OutFile "C:\requestRouter_amd64.msi"
	# Install URL Rewrite
	$url = Start-Process msiexec.exe -ArgumentList '/i','C:\rewrite_amd64_en-US.msi','/qn','/log C:\URLRewrite.log' -Wait -PassThru
	if ($url.ExitCode -ne 0)
	{
		Write-Host("Error occured while installing URL Rewrite, please refer to C:\URLRewrite.log inside the container for more details")
	}
	# Install Application Request Routing
	$arr = Start-Process msiexec.exe -ArgumentList '/i','C:\requestRouter_amd64.msi','/qn','/log C:\ApplicationRequestRouting.log' -Wait -PassThru
	if ($arr.ExitCode -ne 0)
	{
		Write-Host("Error occured while installing URL Rewrite, please refer to C:\ApplicationRequestRouting.log inside the container for more details")
	}
}
	
# Configuring MS-DTC for cross DB transactions
filter timestamp {"$(Get-Date -Format G): $_"}
try {   
   write-output "Enable MS DTC" | timestamp
   Set-DtcNetworkSetting -DtcName "Local" -AuthenticationLevel "NoAuth" -InboundTransactionsEnabled $true -OutboundTransactionsEnabled $true -RemoteClientAccessEnabled $true -RemoteAdministrationAccessEnabled $true  -XATransactionsEnabled $true -LUTransactionsEnabled $true -Confirm:$false
   
   # Display network settings
   $dtcSettings = Get-DtcNetworkSetting
   write-output $dtcSettings
}
catch {
  write-output "Error Setting MSDTC Settings" | timestamp
}

$silentConfig = $null
# Install TA in silent mode
filter timestamp {"$(Get-Date -Format G): $_"}
write-output "Start silent Install" | timestamp

# -passthru is used to get output from the command
if(Test-Path -path "C:\TA\TotalAgilityInstall\setup.exe") {
$proc = Start-Process C:\TA\TotalAgilityInstall\setup.exe -argumentlist '/silent' -wait -PassThru

# Copying Encrypt utility to powershellscripts folder
Copy-Item "C:\TA\Utilities\TotalAgility.EncryptConfig.exe" "C:\TA\PowershellScripts\TotalAgility.EncryptConfig.exe"
$silentConfig = "C:\TA\TotalAgilityInstall\SilentInstallConfig.xml"
}
elseif(Test-Path -path "C:\TA\OnPremiseMultiTenancyInstall\setup.exe") {
$proc = Start-Process C:\TA\OnPremiseMultiTenancyInstall\setup.exe -argumentlist '/silent' -wait -PassThru

# Copying Encrypt utility to powershellscripts folder
Copy-Item "C:\TA\Utilities\TotalAgility.EncryptConfig.exe" "C:\TA\PowershellScripts\TotalAgility.EncryptConfig.exe"
$silentConfig = "C:\TA\OnPremiseMultiTenancyInstall\SilentInstallConfig.xml"
}
elseif(Test-Path -path "C:\TA\IntegrationServerInstall\setup.exe") {
$proc = Start-Process C:\TA\IntegrationServerInstall\setup.exe -argumentlist '/silent' -wait -PassThru

# Copying Encrypt utility to powershellscripts folder
Copy-Item "C:\TA\Utilities\TotalAgility.EncryptConfig.exe" "C:\TA\PowershellScripts\TotalAgility.EncryptConfig.exe"
}

# CopyFonts for OP and OPMT if install transformation service is true
if ($silentConfig -ne $null) {
    $xmlDoc = [System.Xml.XmlDocument](Get-Content $silentConfig);
    if (($xmlDoc.ConfigurationEntity.ServicesInstallOptions.TransformationService -eq $true) -And (Test-Path -path "C:\TA\PowershellScripts\Fonts")) {
	     Invoke-Expression C:\TA\PowershellScripts\InstallFonts.ps1
		 write-output "Windows fonts copied successfully." | timestamp
	}
}

# Setting the TA service startup type to manual to prevent automatic startup of services during container creation
	Get-Service| ForEach-Object {	
    if ($_.DisplayName.StartsWith("Kofax") -or $_.DisplayName.StartsWith("Tungsten")) {
        Set-Service -Name  $_.Name -StartupType Manual -Status "Stopped" -PassThru;        
	}
}
if ($proc.ExitCode -ne 0) {
	filter timestamp {"$(Get-Date -Format G): $_"}
	Write-output "Install failed with errors" | timestamp
    Get-ChildItem -Path "C:\Users\ContainerAdministrator\Desktop" | Where-Object {$_.Name.StartsWith("TungstenTotalAgility")} | ForEach-Object {get-content $_.FullName}
}
elseif ($proc.ExitCode -eq 0) {	
	filter timestamp {"$(Get-Date -Format G): $_"}
	Write-output "Completed silent Install" | timestamp
	filter timestamp {"$(Get-Date -Format G): $_"}
	Write-output "Delete installation media" | timestamp
	# Deleting Installation media since installation was successful	
	Get-ChildItem -Path  "C:\TA\" -Recurse -exclude SilentInstallConfig.xml | 
	Select -ExpandProperty FullName | 
	Where {$_ -notlike "C:\TA\PowershellScripts*"} | 
	sort length -Descending | 
	ForEach-Object {
	try {
		#  -ErrorAction Ignore is being used to suppress known issue in Docker on Windows Server 2016 with deletion
		Remove-Item -path $_ -force -ErrorAction Ignore;
		}
	catch { }
	}
	filter timestamp {"$(Get-Date -Format G): $_"}
	Write-output "Installation media deletion completed" | timestamp	
}