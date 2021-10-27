<#
 
1. Gets all TA services
2. Set startup mode to auto
3. Start services
#>
Get-Service| ForEach-Object {

    if ($_.DisplayName.StartsWith("Kofax")) {
        $serviceName =  $_.Name;

        Set-Service -Name  $_.Name -StartupType Automatic;                      
        Start-Service -Name $_.Name -PassThru;

        Write-Host("start service " + $_.Name);        
   }
}