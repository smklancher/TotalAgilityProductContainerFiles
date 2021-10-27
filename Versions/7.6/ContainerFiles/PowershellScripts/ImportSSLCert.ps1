#Import SSL Cert

param (
   [string]$certPath = "C:\KTA\PowershellScripts\SSL_cert.pfx",
   [string]$certPass = ""    
)

Write-Host("Warning!!! Before running this script copy cert from host machine to the image container ");
Write-Host("Run command - docker CP  'path at host machine' 'container id:/ path at conainer'");
Write-Host(" ");

if (Test-Path $certPath)
{    
    # Import certificate to local machine  
    $pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2  
    $pfx.Import($certPath,$certPass,"Exportable,PersistKeySet")   
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("WebHosting","LocalMachine")   
    $store.Open("ReadWrite")  
    $store.Add($pfx)   
    $store.Close()   
    $certThumbprint = $pfx.Thumbprint  

    $thumbprints = Get-ChildItem -path cert:\LocalMachine\WebHosting;
         
    # assign cert to default web site
    $iisWebsiteName="Default Web Site"

    if (Test-Path IIS:\Sites\$iisWebsiteName -pathType container)
    {   
        Import-Module WebAdministration 

        $binding1 = Get-WebBinding -Name $iisWebsiteName -Port 443 -Protocol "https";
        
        if($binding1 -eq $null)
        {            
          Write-Host (" Add new binding");
          
          New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https;
          $binding1 = Get-WebBinding -Name $iisWebsiteName -Port 443 -Protocol "https";
        }

       Write-Host ("add cert");
       $binding1.AddSslCertificate($thumbprints[0].Thumbprint, "WebHosting");       
    }    
}
else
{
    Write-Host("Error: SSL Certificate not found @ '$certPath'");
}
