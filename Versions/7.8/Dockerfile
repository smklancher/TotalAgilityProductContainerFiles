FROM microsoft/aspnet

COPY ContainerFiles C:\\KTA

RUN powershell C:\KTA\PowershellScripts\ConfigureContainer.ps1

EXPOSE 80

EXPOSE 443

ENTRYPOINT powershell "C:\KTA\PowershellScripts\Startup.ps1"