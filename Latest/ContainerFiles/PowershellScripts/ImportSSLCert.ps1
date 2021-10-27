#Import SSL Cert

param (
   [string]$certPath = "C:\ContainerStore\cert.pfx",   
   [string]$certPassword = ""    
)

if (Test-Path $certPath)
{    
    # Import certificate to container      
    $pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2  
    $pfx.Import($certPath,$certPassword,"Exportable,PersistKeySet")   
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("WebHosting","LocalMachine")   
    $store.Open("ReadWrite")  
    $store.Add($pfx)   
    $store.Close()   
    $certThumbprint = $pfx.Thumbprint  

    $thumbprints = Get-ChildItem -path cert:\LocalMachine\WebHosting;
         
    # assign cert to default web site
    $iisWebsiteName="Default Web Site"
      
    Import-Module WebAdministration 

    $binding1 = Get-WebBinding -Name $iisWebsiteName -Port 443 -Protocol "https";
        
    if($binding1 -eq $null)
    {            
        Write-Output (" Add new binding");
          
        New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https;
        $binding1 = Get-WebBinding -Name $iisWebsiteName -Port 443 -Protocol "https";
    }

    Write-Host ("add cert");
    $binding1.AddSslCertificate($thumbprints[0].Thumbprint, "WebHosting");       
        
}
else
{
    Write-Output("Error: SSL Certificate not found @ '$certPath'");
}
