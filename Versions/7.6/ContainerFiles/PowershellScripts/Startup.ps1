param (
   [string]$configPath = "C:\Program Files\Kofax\TotalAgility\"   
)

# get current script path
$pos = $MyInvocation.MyCommand.Path.IndexOf($MyInvocation.MyCommand.Name);

#Remove current script name
$currentPath = $MyInvocation.MyCommand.Path.SubString(0,$pos);

# call UpdateConfigSettings.ps1 to update settings.
Invoke-Expression "$currentPath\UpdateConfigSettings.ps1 -configPath '$configPath'";

# Install self signed cert 
$scriptPath = "$currentPath\CreateHttpsCert.ps1";
Invoke-Expression "$scriptPath";

# call StartTAServices.ps1 to start services.
$scriptPath = "$currentPath\StartTAServices.ps1";
Invoke-Expression "$scriptPath";

# start poweshell
cmd powershell

