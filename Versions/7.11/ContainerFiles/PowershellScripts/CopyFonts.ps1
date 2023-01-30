$currentDirectory = Split-Path $MyInvocation.MyCommand.Path
$silentConfig = $null

if(Test-Path -path ($currentDirectory + "\..\TotalAgilityInstall\setup.exe")) {
$silentConfig = $currentDirectory + "\..\TotalAgilityInstall\SilentInstallConfig.xml"
}
elseif(Test-Path -path ($currentDirectory + "\..\OnPremiseMultiTenancyInstall\setup.exe")) {
$silentConfig = $currentDirectory + "\..\OnPremiseMultiTenancyInstall\SilentInstallConfig.xml"
}
if ($silentConfig -ne $null){
    $xmlDoc = [System.Xml.XmlDocument](Get-Content $silentConfig);
   if($xmlDoc.ConfigurationEntity.ServicesInstallOptions.TransformationService -eq $true)
   {
      Push-Location $currentDirectory
      $winFonts = $env:windir + "\Fonts\*"
      $FontsDir= ".\Fonts\"	
      $FontsFilter= @('times*.ttf')
      New-Item -ItemType Directory -Force -Path $FontsDir
      Get-ChildItem $winFonts -Include $FontsFilter | 
      Foreach-Object {
        Write-Host $_.FullName
        Copy-Item $_.FullName -Destination $FontsDir
      }
   }
}