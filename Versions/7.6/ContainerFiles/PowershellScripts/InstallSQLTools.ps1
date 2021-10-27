Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\KTA\SQLClientTools\sqlncli.msi /qn IACCEPTSQLNCLILICENSETERMS=YES" -Wait 
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\KTA\SQLClientTools\msodbcsql.msi /qn IACCEPTMSODBCSQLLICENSETERMS=YES" -Wait 
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\KTA\SQLClientTools\MsSqlCmdLnUtils.msi /qn IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES" -Wait 
$env:path +=';C:\Program Files\Microsoft SQL Server\client sdk\odbc\130\tools\binn'
