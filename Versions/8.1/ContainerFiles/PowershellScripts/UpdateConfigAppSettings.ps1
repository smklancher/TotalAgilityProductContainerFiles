<# 
1. Reads KTA system environment variable created per setting.
2. Format of env variable name is KTA_ScriptPath_SettingName (KTA_Agility.Server.Web\web.config_InstallDatabases)
4. Env variables are searched using key KTA_filepath_.
5. Configuration file's full path is constructed using $configPath script argument and script path in env variable's name.
6. Setting name is constructed by removing KTA_ScriptPath_ from the variable name.
7. Setting value is the value of env variable.
8. Function Update-ConfigFile will update app settings in a config file with env variable value. 
#>

param (
   [string]$configPath = "C:\Program Files\Tungsten\TotalAgility\"    
)

# all kta env variable will start with KTA_ prefix
$appSettingPrefix = "KTA_";

# Updates app settings in a config file with env variable value.
Function Update-ConfigFile {

Param ([string]$searchKey) 

   $modified = $FALSE;
   $currentFileName  ="";
   $doc = $null;   
   $continue =$TRUE;

   # Gets env variables where name starts with KTA_. 
   # This will return all env variables that were created for a config file.
   # Excluding the CCMServerURL since it should not be updated without being part of the KCMProxy configuration
    Get-ChildItem env:*| sort-object name|Where-Object {$_.key.StartsWith($searchKey) -and -not ($_.key.contains("CCMServerURL"))} | ForEach-Object {
        
     # break\continue\return works differently than C# . When we return from if,  ending 
     # if statement but not returning back from function so added additional if statement
      if($continue -eq $FALSE)
      {
        return;
      }
     
        # Remove prefix KTA_    
        $key = $_.Key.Substring($appSettingPrefix.Length);

        # get position _ to separate out script path from setting name
        $pos= $key.IndexOf("_");              

        # construct config file's full path

        $currentFileName =$key.Substring(0,$pos);

        $currentFileName = $currentFileName.Replace("--","\");
		
		# Fixing whitespace issue with Transformation Server install location
		
		if($currentFileName.Contains("TransformationServer"))
        {
          $currentFileName = $currentFileName -replace "TransformationServer", "Transformation Server"
        }

		# for Tenant management web.config path needs to be appended bug 1884081.
		if($currentFileName.Contains("Agility.Server.Web.TenantManagement"))
        {
			$currentFileName = "C:\Program Files\Tungsten\TotalAgility Tenant Management\"  + $currentFileName;
        }

        # for regasc path will be appended
        if(-not $currentFileName.Contains("C:\"))
        {
          $currentFileName = $configPath  + $currentFileName;
        }               

        # set setting name as key
        $key =  $key.Substring($pos+1);           
        
        # index is unique for every config file. We should open and save file once.
        if($doc -eq $null)
        {  
            # check if file exists before opening file.
            if(Test-Path $currentFileName) {            
				
				$doc = (Get-Content $currentFileName) -as [Xml];                
            }
            else
            {                
				# break loop and get next index          
                $continue =$FALSE;                
            }
        }         

        if($doc -ne $null)
        {
			# look for app setting name in a config file.
            $appSetting = $doc.configuration.appSettings.add | Where-Object {$_.key -eq $key};

            if($currentFileName.Contains("Transformation Server"))
            {
            # New config required for TS OPMT deployment
			if (($appSetting.key -eq "IsMultitenantDeployment" -and $appSetting.value -eq "true") -or ($appSetting.key -eq "IsRttsMultitenantDeployment" -and $appSetting.value -eq "true")) {
				$newEl=$doc.CreateElement("add");
				$nameAtt1=$doc.CreateAttribute("key");
				$nameAtt1.psbase.value="TenantConfiguration";
				$newEl.SetAttributeNode($nameAtt1);
				$nameAtt2=$doc.CreateAttribute("value");
				$nameAtt2.psbase.value="MultiTenant";
				$newEl.SetAttributeNode($nameAtt2);
				$doc.configuration["appSettings"].AppendChild($newEl);
				$modified = $TRUE;
            }            
            }
            if ($appSetting) {

                # update app setting with env var value.
                $appSetting.value = $_.Value;                   
                $modified = $TRUE;
            }
			
        }
    }

    if ($modified) {
			$fileName = [System.IO.Path]::GetFileName($currentFileName);
            # save config file after making changes.                           
            Write-Host "Updated config settings in file: $fileName";
            $doc.Save($currentFileName);               
     }         
}

$keys = New-Object 'System.Collections.Generic.HashSet[string]';

Get-ChildItem env:*| sort-object name|Where-Object {$_.key.StartsWith($appSettingPrefix)} | ForEach-Object {
    
     # construct search key to search env variables
    $pos= $_.Key.IndexOf(".config_");
    $key = $_.Key.Substring(0, $pos + ".config_".Length-1);

    if (-not $keys.Contains($key))
    {
        $keys.Add($key) | Out-Null;
       
        # update config settings for the config file
        Update-ConfigFile -searchKey $key;
    }     
}    

# Updates server id and DB connection string in a licensing config file with env variable value.
function Update-License-Config {

	param ([string] $licenseServerId, [string] $licenseDBConnStr)

	if($licenseServerId -ne 1 -and $licenseServerId -ne 2)
	{
		"Invalid license server ID."
		return
	}

	$fileName = "C:\Program Files (x86)\Tungsten\TotalAgility\LicenseServer\KSALicenseService.exe.config"
	if(Test-Path -Path $fileName)
	{
		$xmlDoc = [System.Xml.XmlDocument](Get-Content $fileName);

		if($xmlDoc -ne $null) 
		{
			# Updating licensing server id
			if($xmlDoc.configuration.appSettings.add -ne $null)
			{
				$xmlDoc.configuration.appSettings.add.SetAttribute("value",$licenseServerId)
			}

			# Updating licensing database connection string
			if($xmlDoc.configuration.connectionStrings.add -ne $null)
			{
				$xmlDoc.configuration.connectionStrings.add.SetAttribute("connectionString",$licenseDBConnStr)
			}

			$xmlDoc.Save($fileName);
			Write-Host "Updated config settings in file: $fileName"			
		}
	}
}

# Verifying if the License server is installed making use of the registry key.
# If present then only update the license server configuration file.
if(Test-Path -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{AF1D8F88-1CF4-4B6A-A5B5-E94CB2E9C7AB}")
{
	$licenseServerId = "1";
	$licenseDBConnStr = "";

	# Read the licensing server id from the env variable
	Get-ChildItem env:*| sort-object name|Where-Object {$_.key -eq "ServerId"} | ForEach-Object {
			$licenseServerId = $_.value;
	}

	# Read the licensing database connections string from the env variable
	Get-ChildItem env:*| sort-object name|Where-Object {$_.key -eq "LicensingDatabase"} | ForEach-Object {
			$licenseDBConnStr = $_.value;
	}

	# Update licensing information.
	Update-License-Config $licenseServerId $licenseDBConnStr
}