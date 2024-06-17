FROM mcr.microsoft.com/dotnet/framework/aspnet

# uncomment below if docker deployment is for KTA service only  without IIS and comment above line
#FROM mcr.microsoft.com/dotnet/framework/runtime

COPY ContainerFiles C:\\KTA

RUN powershell C:\KTA\PowershellScripts\ConfigureContainer.ps1

EXPOSE 80

EXPOSE 443

ENTRYPOINT powershell "C:\KTA\PowershellScripts\Startup.ps1"