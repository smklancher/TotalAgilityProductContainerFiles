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
   $SslEnabled = $null; 
   $AuthenticationMode = $null;
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

        $currentFileName = $currentFileName.Replace("--","\");
		
		# Fixing whitespace issue with Transformation Server install location
		
		if($currentFileName.Contains("TransformationServer"))
        {
          $currentFileName = $currentFileName -replace "TransformationServer", "Transformation Server"
        }

		# for Tenant management web.config path needs to be appended bug 1884081.
		if($currentFileName.Contains("Agility.Server.Web.TenantManagement"))
        {
			$currentFileName = "C:\Program Files\Kofax\TotalAgility Tenant Management\"  + $currentFileName;
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
            $appSetting=@{"key"=$key;"value"=$_.value};
			# Setting variables for SSL enablement
			if ($appSetting.key -eq "SslEnabled") {
				$SslEnabled = $appSetting.value;
            }
            # Setting variables for streaming service baseAddress
			if ($appSetting.key -eq "baseAddress") {
				$StreamingBaseAddress = $appSetting.value;
            }
			# Setting variable for authentication type
			if ($appSetting.key -eq "AuthenticationMode") {
				$AuthenticationMode = $appSetting.value;
            }
			# Setting variables for security mode
			if($SslEnabled -eq "false"){
				$mode="TransportCredentialOnly"
			}
			elseif($SslEnabled -eq "true") {
				$mode="Transport"
			}
			# Setting variables for transport clientCredentialType
			if($AuthenticationMode -eq "Windows"){
				$clientCredentialType="Windows";
				$authenticationScheme="Negotiate";
			}
			elseif($AuthenticationMode -eq "Anonymous") {
				$clientCredentialType="None";
				$authenticationScheme="Anonymous";
			}
			# List of bindings that should not be modified
			[string[]]$excludedBindings= @("BasicHttpBinding_ExchangeNotificationService","BasicHttpBinding_DeviceManagerService","BasicHttpBinding_SharepointCommunicatorService","BasicHttpBinding_TrimCommunicatorService","BasicHttpBinding_DynamicsAxCommunicatorService","BasicHttpBinding_DynamicsAxIntegrationService","BasicHttpBinding_InsightDataService","WebHttpBinding_DeviceManagerService","TransformationServerExternalService_Binding");
			# List of Integration Service bindings
			[string[]]$integraionServiceBindings= @("BasicHttpBinding_ExchangeNotificationService","BasicHttpBinding_SharepointCommunicatorService","BasicHttpBinding_TrimCommunicatorService","BasicHttpBinding_DynamicsAxCommunicatorService","BasicHttpBinding_DynamicsAxIntegrationService","BasicHttpBinding_InsightDataService");			
            $integrationsModified= $FALSE;
            if($integraionServiceBindings.Contains($appSetting.key))
            {
               $integrationsModified = $TRUE; 
            }
			$exists1 = $doc.configuration.'system.web'.httpCookies;
			if ($exists1 -and -not ([System.Convert]::ToBoolean([string]::IsNullOrEmpty($SslEnabled))))
			{
				# Updating httpCookies depending on SSL enablement
				$doc.configuration.'system.web'.httpCookies.SetAttribute("requireSSL",$SslEnabled)
			}
			$exists2 = $doc.configuration.'system.serviceModel'.bindings.basicHttpBinding;
			if (($exists2 -and -not ([System.Convert]::ToBoolean([string]::IsNullOrEmpty($SslEnabled))) -and -not ([System.Convert]::ToBoolean([string]::IsNullOrEmpty($AuthenticationMode)))) -or $integrationsModified)
			{
			# Array of basicHttpBindings and webHttpBindings
			$bindingsList=@($doc.configuration.'system.serviceModel'.bindings.basicHttpBinding.binding,$doc.configuration.'system.serviceModel'.bindings.webHttpBinding.binding);
			# Array of customBindings
			$customBindings=@($doc.configuration.'system.serviceModel'.bindings.customBinding.binding);
			# Updating basicHttpBindings and webHttpBindings
			foreach($bindings in $bindingsList)
			{
				foreach($node in $bindings)
				{   
					if($integraionServiceBindings.Contains($node.name))
					{
						if($appSetting.key -eq $node.name)
						{
							if([System.Convert]::ToBoolean($appSetting.value))
							{
								$node.security.SetAttribute("mode","Transport");
							}
							else
							{
								$node.security.SetAttribute("mode","TransportCredentialOnly");
							}
							$modified = $TRUE;
						}
					}
					# Exclduing the bindings which are not to be modified
					if(-not $excludedBindings.Contains($node.name)-and -not ([System.Convert]::ToBoolean([string]::IsNullOrEmpty($mode))) -and -not ([System.Convert]::ToBoolean([string]::IsNullOrEmpty($clientCredentialType))))
					{
                        $exists3 = $node.security;
						if ($exists3)
						{
						    $node.security.SetAttribute("mode",$mode);
							$node.security.transport.SetAttribute("clientCredentialType",$clientCredentialType);
							$modified = $TRUE;
						}
					}										
				}
			}
			# Updating customBinding
			foreach($node in $customBindings)
			{   				
				if(-not $excludedBindings.Contains($node.name))
				{
					if($SslEnabled -eq "false")
					{
						$exists4 = $node.httpTransport;
						if ($exists4)
						{
							if($AuthenticationMode -eq "Windows")
							{
								$node.httpTransport.SetAttribute("authenticationScheme",$authenticationScheme);
								$modified = $TRUE;
							}
							elseif($AuthenticationMode -eq "Anonymous")
							{
								$node.httpTransport.SetAttribute("authenticationScheme",$authenticationScheme);  
								$modified = $TRUE;
							}
						}   
					}
					elseif($SslEnabled -eq "true")
					{
						if ($node.httpTransport.Attributes.Count -gt 1)
						{
							# Creating new httpsTransport child in case of SSL being enabled
							$newEl=$node.ParentNode.ParentNode.ParentNode.ParentNode.ParentNode.CreateElement("httpsTransport");
							$nameAtt1=$doc.CreateAttribute("authenticationScheme");
							$nameAtt2=$doc.CreateAttribute("allowCookies");
							$nameAtt3=$doc.CreateAttribute("maxBufferSize");
							$nameAtt4=$doc.CreateAttribute("maxReceivedMessageSize");
							$nameAtt5=$doc.CreateAttribute("maxBufferPoolSize");
							$nameAtt1.psbase.value=$authenticationScheme;
							$nameAtt2.psbase.value="true";
							$nameAtt3.psbase.value="2147483647";
							$nameAtt4.psbase.value="2147483647";
							$nameAtt5.psbase.value="524288";
							$newEl.SetAttributeNode($nameAtt1);
							$newEl.SetAttributeNode($nameAtt2);
							$newEl.SetAttributeNode($nameAtt3);
							$newEl.SetAttributeNode($nameAtt4);
							$newEl.SetAttributeNode($nameAtt5);
							$node.AppendChild($newEl);
							# Removing the httpTransport child in case of SSL being enabled
							$node.RemoveChild($node.httpTransport);
							$modified = $TRUE;
						}  
					}
					}        
			}
			}

			# Updating serviceBehaviors
			$exists5 = $doc.configuration.'system.serviceModel'.behaviors.serviceBehaviors;
			if ($exists5 -and -not ([System.Convert]::ToBoolean([string]::IsNullOrEmpty($SslEnabled))))
			{
				# Updating serviceBehaviors depending on SSL enablement
				$behaviors = $doc.SelectNodes("//configuration/system.serviceModel/behaviors/serviceBehaviors/behavior/serviceMetadata")
				foreach($behavior in $behaviors)
				{
					if($SslEnabled -eq "false"){
						$behavior.SetAttribute("httpGetEnabled",($TRUE).ToString().ToLower());
						$behavior.SetAttribute("httpsGetEnabled",($FALSE).ToString().ToLower());
					}
					elseif($SslEnabled -eq "true"){
						$behavior.SetAttribute("httpGetEnabled",($FALSE).ToString().ToLower());
						$behavior.SetAttribute("httpsGetEnabled",($TRUE).ToString().ToLower());
					}
				}
			}
			
            # Array of sdk.StreamingService , PackageStreamingService and core.StreamingService
			$servicesList=@($doc.configuration.'system.serviceModel'.services.service);
            
            # Updating the base address
			foreach($services in $servicesList)
			{
				foreach($node in $services)
				{   
                    if($node.name -eq "Agility.Sdk.Services.StreamingService" -or 
                        $node.name -eq "Agility.Sdk.Services.PackageStreamingService" -or 
                        $node.name -eq "Agility.Server.Core.Services.StreamingService" -or
						$node.name -eq "Agility.Sdk.Services.CaptureStreamingService")
                    {

					    $baseAddressesExists = $node.host.baseAddresses;
					    if ($baseAddressesExists -and $StreamingBaseAddress)
                        {       $baseAddress = $node.host.baseAddresses.add.GetAttribute("baseAddress");

                            # base address will be as "http://localhost:port/TotalAgility/Services/Sdk/StreamingService.svc"
                            $index = $node.host.baseAddresses.add.GetAttribute("baseAddress").indexOf("/TotalAgility/");
                            $baseAddress = $baseAddress.Substring($index);

                            # $StreamingBaseAddress will be as http://systemName:port/
                            # Remove the last "/" from the streaming address
                            $AddressString = $StreamingBaseAddress.Substring(0, $StreamingBaseAddress.Length - 1);

                            # Now concanate both $baseAddress and #StreamingBaseAddress
                            $baseAddress = $AddressString + $baseAddress;

                            # Update the attribute
							$node.host.baseAddresses.add.SetAttribute("baseAddress",$baseAddress);
							$modified = $TRUE;
					    }
                    }
				}
		}
        }
    }

    if ($modified) {
			$fileName = [System.IO.Path]::GetFileName($currentFileName);
            # save config file after making changes.                           
            Write-Host "Updated config bindings in file: $fileName";
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