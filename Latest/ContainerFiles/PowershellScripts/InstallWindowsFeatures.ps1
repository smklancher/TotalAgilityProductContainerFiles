$IIS = Get-WindowsOptionalFeature -Online -FeatureName “IIS-WebServer”
    if($IIS.State -eq "Enabled")
	{
		write-output "Installing Windows Feature IIS-NetFxExtensibility45" 
		Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45 -All

		write-output "Installing Windows Feature IIS-Security" 
		Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security -All

		write-output "Installing Windows Feature IIS-IPSecurity" 
		Enable-WindowsOptionalFeature -Online -FeatureName IIS-IPSecurity -All

		write-output "Installing Windows Feature IIS-Performance" 
		Enable-WindowsOptionalFeature -Online -FeatureName IIS-Performance -All

		write-output "Installing Windows Feature IIS-WindowsActivationService" 
		Enable-WindowsOptionalFeature -Online -FeatureName WAS-WindowsActivationService -All

		write-output "Installing Windows Feature IIS-ProcessModel" 
		Enable-WindowsOptionalFeature -Online -FeatureName WAS-ProcessModel -All

		write-output "Installing Windows Feature IIS-ConfigurationAPI" 
		Enable-WindowsOptionalFeature -Online -FeatureName WAS-ConfigurationAPI -All

		write-output "Installing Windows Feature IIS-ISAPIExtensions" 
		Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions -All

		write-output "Installing Windows Feature IIS-ISAPIFilter" 
		Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter -All

		write-output "Installing Windows Feature IIS-WindowsAuthentication" 
		Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication -All

		write-output "Installing Windows Feature WCF-HTTP-Activation45" 
		Enable-WindowsOptionalFeature -Online -FeatureName WCF-HTTP-Activation45 -All
	}
	