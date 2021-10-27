# install prerequisites for TA
filter timestamp {"$(Get-Date -Format G): $_"}
write-output "install prerequisites for TA" | timestamp
Invoke-Expression C:\KTA\PowershellScripts\InstallWindowsFeatures.ps1

filter timestamp {"$(Get-Date -Format G): $_"}
write-output "Add Admin user for TA" | timestamp

# Add KTA_Admin account local system 
Invoke-Expression C:\KTA\PowershellScripts\AddAdminUser.ps1
Invoke-Expression C:\KTA\PowershellScripts\UpdateAdminUser.ps1

# Install self signed cert
filter timestamp {"$(Get-Date -Format G): $_"}
write-output "Install Self signed cert" | timestamp
Invoke-Expression C:\KTA\PowershellScripts\CreateHttpsCert.ps1;

# Install TA in silent mode
filter timestamp {"$(Get-Date -Format G): $_"}
write-output "Start silent Install" | timestamp

# -passthru is used to get output from the command
if(Test-Path -path "C:\KTA\TotalAgility\TotalAgilityInstall\setup.exe") {
$proc = Start-Process C:\KTA\TotalAgility\TotalAgilityInstall\setup.exe -argumentlist '/silent' -wait -PassThru
}
if(Test-Path -path "C:\KTA\OnPremiseMultiTenancyInstall\setup.exe") {
$proc = Start-Process C:\KTA\OnPremiseMultiTenancyInstall\setup.exe -argumentlist '/silent' -wait -PassThru
}
if(Test-Path -path "C:\KTA\IntegrationServerInstall\setup.exe") {
$proc = Start-Process C:\KTA\IntegrationServerInstall\setup.exe -argumentlist '/silent' -wait -PassThru
}

filter timestamp {"$(Get-Date -Format G): $_"}

Write-output "Completed silent Install" | timestamp

if ($proc.ExitCode -eq 0) {
  write-output "Silent Install is sucessful"
  
  # Stop all TA Services. Services will be re-started when configuration settings will be passed during container run.
  Invoke-Expression C:\KTA\PowershellScripts\StopTAServices.ps1
}
elseif ($proc.ExitCode -eq 1) {
    write-output "Warnings while installing TA. To check warnings, go to powershell on the container image and run command: type C:\users\containerhost\desktop\KofaxTotalAgilityInstallErrorLog.txt"
}
else {
    write-output "Errors while installing TA. To check warnings, go to powershell on the container image and run command: type C:\users\containerhost\desktop\KofaxTotalAgilityInstallErrorLog.txt"
}
