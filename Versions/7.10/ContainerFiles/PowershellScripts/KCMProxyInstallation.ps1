Get-ChildItem env:* | Where-Object {$_.key -eq "KTA_Agility.Server.Web\web.config_CCMServerURL" } | ForEach-Object {
	# Checking for non-default value of CCMServerURL app setting
	if ($_.value -ne "{http://ccmserver:port}")
	{	
		if(Test-Path -path "C:\Program Files\Kofax\TotalAgility\KCMProxyInstallation\Setup.exe")
		{
			$kcmserverurl = $_.value
			Write-Host ("Configuring KCMProxy with the URL $kcmserverurl")
			$proc = Start-Process "C:\Program Files\Kofax\TotalAgility\KCMProxyInstallation\Setup.exe" -ArgumentList '/silent',$kcmserverurl -Wait -PassThru
			if ($proc.ExitCode -ne 0)
			{
				# Check for KCM proxy install failure and show log to user
				Write-Host("Error occured while configuring the KCM Proxy please refer to the log file below for more details")
				get-content "C:\users\ContainerAdministrator\desktop\KofaxTotalAgilityCCMServerInstallErrorLog.txt"
			}
		}
	}
}