<#
 
1. Gets all TA services
2. stop services
3. Set startup mode to manual
#>
Get-Service| ForEach-Object {

    if ($_.DisplayName.StartsWith("Kofax")) {

            Stop-Service -Name $_.Name -PassThru;
            Set-Service -Name  $_.Name -StartupType Manual;               
            Write-Host("stop service " + $_.Name);
   }
}
