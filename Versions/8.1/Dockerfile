FROM mcr.microsoft.com/dotnet/framework/aspnet

# uncomment below if docker deployment is for TA service only  without IIS and comment above line
#FROM mcr.microsoft.com/dotnet/framework/runtime

COPY ContainerFiles C:\\TA

RUN powershell C:\TA\PowershellScripts\ConfigureContainer.ps1

EXPOSE 80

EXPOSE 443

ENTRYPOINT powershell "C:\TA\PowershellScripts\Startup.ps1"