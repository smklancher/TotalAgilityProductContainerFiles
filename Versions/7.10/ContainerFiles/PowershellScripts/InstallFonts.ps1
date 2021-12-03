$sFontsFolder = "C:\KTA\PowershellScripts\Fonts";
$sRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts";

$objShell = New-Object -ComObject Shell.Application;

$objFolder = $objShell.namespace($sFontsFolder);

foreach ($objFile in $objFolder.items()) {
    
    $objFileType = $($objFolder.getDetailsOf($objFile, 2));
    $sFontName = $($objFolder.getDetailsOf($objFile, 21));
    $sRegKeyName = $sFontName, "(TrueType)" -join " ";
    $sRegKeyValue = $objFile.Name;
	try{
		Copy-Item $objFile.Path "c:\windows\fonts";
		$null = New-ItemProperty -Path $sRegPath -Name $sRegKeyName -Value $sRegKeyValue -PropertyType String -Force;
	}
	catch {}
}