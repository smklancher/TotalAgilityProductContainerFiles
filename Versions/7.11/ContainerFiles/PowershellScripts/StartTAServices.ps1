<#
 
1. Gets all TA services
2. Start services with retries
#>

function Execute-WithRetry([ScriptBlock] $command, [int] $maxFailures = 3, [int] $sleepBetweenFailures = 1) {

	$attemptCount = 0

	$operationIncomplete = $true

	while ($operationIncomplete -and $attemptCount -lt $maxFailures) {

		$attemptCount = ($attemptCount + 1)

		if ($attemptCount -ge 2) {

			Write-Output "Waiting for $sleepBetweenFailures seconds before retrying..."
			Start-Sleep -s $sleepBetweenFailures
			Write-Output "Retrying..."
		}
		try {
			& $command

			$operationIncomplete = $false

		} catch [System.Exception] {

			if ($attemptCount -lt ($maxFailures)) {

				Write-Output ("Attempt $attemptCount of $maxFailures failed: " + $_.Exception.Message)
			}           
		}
	}
}

function StartService([string] $serviceName, [string] $status)
{
  if($status -eq "stopped")
   {
        Start-Service $serviceName -PassThru
        # Wait up to 30 seconds for the service to start
        $service.WaitForStatus('Running', '00:00:30')

	    Execute-WithRetry {
		Start-Service $serviceName -PassThru
		## Wait up to 30 seconds for the service to start
		$service.WaitForStatus('Running', '00:00:30')
    }
   }
}

# start license service before other services
$service = Get-Service "KSALicenseService" -ErrorAction Ignore;
if($service -ne $null)
{
    # do 10 retries to ensure service is started
    For ($i=0; $i -le 10; $i++) {    
        StartService -serviceName $service.Name -status $service.Status;
    }
}

Get-Service| ForEach-Object {

    if ($_.DisplayName.StartsWith("Kofax")) {
        $service = $_;        
        Write-Host($service.DisplayName);
        StartService -serviceName $_.Name -status $_.Status;
   }
}




