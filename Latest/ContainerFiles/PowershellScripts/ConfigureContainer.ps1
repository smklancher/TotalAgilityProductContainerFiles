# install prerequisites for TA
filter timestamp {"$(Get-Date -Format G): $_"}
write-output "Install prerequisites for KTA" | timestamp
Invoke-Expression C:\KTA\PowershellScripts\InstallWindowsFeatures.ps1

filter timestamp {"$(Get-Date -Format G): $_"}
write-output "Add Admin user for KTA" | timestamp

# Add KTA_Admin account local system 
Invoke-Expression C:\KTA\PowershellScripts\AddAdminUser.ps1
Invoke-Expression C:\KTA\PowershellScripts\UpdateAdminUser.ps1

# Install self signed cert
filter timestamp {"$(Get-Date -Format G): $_"}
write-output "Install Self signed cert" | timestamp
Invoke-Expression C:\KTA\PowershellScripts\CreateHttpsCert.ps1;

# Deleting Transformation Designer folder
$strings=@("TransformationDesigner*")
get-childitem -path "C:\KTA\" -Include ($strings) -Recurse -force | ForEach-Object {
    try {
		#  -ErrorAction Ignore is being used to suppress known issue in Docker on Windows Server 2016 with deletion
        Remove-Item $_ -Force –Recurse -ErrorAction Ignore
		}
    catch { }
	}

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

# Install TA in silent mode
filter timestamp {"$(Get-Date -Format G): $_"}
write-output "Start silent Install" | timestamp

# -passthru is used to get output from the command
if(Test-Path -path "C:\KTA\TotalAgility\TotalAgilityInstall\setup.exe") {
$proc = Start-Process C:\KTA\TotalAgility\TotalAgilityInstall\setup.exe -argumentlist '/silent' -wait -PassThru

# Copying Encrypt utility to powershellscripts folder
Copy-Item "C:\KTA\TotalAgility\Utilities\Kofax.CEBPM.EncryptConfig.exe" "C:\KTA\PowershellScripts\Kofax.CEBPM.EncryptConfig.exe"
}
elseif(Test-Path -path "C:\KTA\OnPremiseMultiTenancyInstall\setup.exe") {
$proc = Start-Process C:\KTA\OnPremiseMultiTenancyInstall\setup.exe -argumentlist '/silent' -wait -PassThru

# Copying Encrypt utility to powershellscripts folder
Copy-Item "C:\KTA\Utilities\Kofax.CEBPM.EncryptConfig.exe" "C:\KTA\PowershellScripts\Kofax.CEBPM.EncryptConfig.exe"
}
elseif(Test-Path -path "C:\KTA\IntegrationServerInstall\setup.exe") {
$proc = Start-Process C:\KTA\IntegrationServerInstall\setup.exe -argumentlist '/silent' -wait -PassThru

# Copying Encrypt utility to powershellscripts folder
Copy-Item "C:\KTA\Utilities\Kofax.CEBPM.EncryptConfig.exe" "C:\KTA\PowershellScripts\Kofax.CEBPM.EncryptConfig.exe"
}

# Setting the KTA service startup type to manual to prevent automatic startup of services during container creation
	Get-Service| ForEach-Object {	
    if ($_.DisplayName.StartsWith("Kofax")) {
        Set-Service -Name  $_.Name -StartupType Manual -Status "Stopped" -PassThru;        
	}
}
if ($proc.ExitCode -ne 0) {
	filter timestamp {"$(Get-Date -Format G): $_"}
	Write-output "Install failed with errors" | timestamp
    Get-ChildItem -Path "C:\Users\ContainerAdministrator\Desktop" | Where-Object {$_.Name.StartsWith("KofaxTotalAgility")} | ForEach-Object {get-content $_.FullName}
}
elseif ($proc.ExitCode -eq 0) {	
	filter timestamp {"$(Get-Date -Format G): $_"}
	Write-output "Completed silent Install" | timestamp
	filter timestamp {"$(Get-Date -Format G): $_"}
	Write-output "Delete installation media" | timestamp
	# Deleting Installation media since installation was successful	
	Get-ChildItem -Path  "C:\KTA\" -Recurse -exclude loktarogar.txt | 
	Select -ExpandProperty FullName | 
	Where {$_ -notlike "C:\KTA\PowershellScripts*"} | 
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