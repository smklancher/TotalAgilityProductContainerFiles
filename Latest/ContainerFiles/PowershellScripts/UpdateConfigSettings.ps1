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
   [string]$configPath = "C:\Program Files\Kofax\TotalAgility\"    
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
    Get-ChildItem env:*| sort-object name|Where-Object {$_.key.StartsWith($searchKey)} | ForEach-Object {
        
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

                Write-Host "Opening File: $currentFileName";
                $doc = (Get-Content $currentFileName) -as [Xml];                
            }
            else
            {
                # show error if config file doesn't exists.
                Write-Host "File Not Found: $currentFileName";      
                
                 # break loop and get next index          
                $continue =$FALSE;                
            }
        }         

        if($doc -ne $null)
        {
			# New config required for TS OPMT deployment
			if ($appSetting -eq "IsMultitenantDeployment" -and $appSetting.value -eq "true") {
				$newEl=$doc.configuration.appSetting.CreateElement("add");
				$nameAtt1=$doc.CreateAttribute("key");
				$nameAtt1.psbase.value="TenantConfiguration";
				$newEl.SetAttributeNode($nameAtt1);
				$nameAtt2=$doc.CreateAttribute("value");
				$nameAtt2.psbase.value="MultiTenant";
				$newEl.SetAttributeNode($nameAtt2);
				$doc.configuration["appSettings"].AppendChild($newEl);
				$modified = $TRUE;
            }
            # look for app setting name in a config file.
            $appSetting = $doc.configuration.appSettings.add | Where-Object {$_.key -eq $key};

            if ($appSetting) {

                # update app setting with env var value.
                $appSetting.value = $_.Value;                   
                $modified = $TRUE;
            }
			
        }
    }

    if ($modified) {

            # save config file after making changes.                           
            Write-Host "Saving File: $currentFileName";
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
        $keys.Add($key);
       
        # update config settings for the config file
        Update-ConfigFile -searchKey $key;
    }     
}    