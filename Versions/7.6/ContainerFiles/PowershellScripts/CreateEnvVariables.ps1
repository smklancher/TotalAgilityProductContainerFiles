#Test script to create variables on local machine

param (
   [string]$webConfig = "E:\Docker\DockerSettings.env"    
)

foreach($line in [System.IO.File]::ReadLines($webConfig))
{
    $pos= $line.IndexOf("=");
    $key = $line.Substring(0,$pos);
    $value = $line.Substring($pos + 1);  

    Write-Host($key,$value);

   [Environment]::SetEnvironmentVariable($key, $value, "Machine");
}



