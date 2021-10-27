
#Agustín Mántaras December 2014.
#This code was downloaded from MSDN Code Gallery
#You can visit my blog post http://blogs.msdn.com/b/amantaras/archive/2014/12/10/powershell-script-to-change-windows-service-credentials.aspx

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)] [string]$UserName,
  [Parameter(Mandatory=$True,Position=2)][string]$Password,
  [Parameter(Mandatory=$True,Position=3)][string]$Service,
  [Parameter(Mandatory=$True,Position=4)][string]$ServerN,
  [Parameter(Mandatory=$True,Position=5)][int]$SecondsToWait
)


function PowerShell-PrintErrorCodes ($strReturnCode)
{
#This function will print the right value. The error code list was extracted using the MSDN documentation for the change method as December 2014
Switch ($strReturnCode) 
    {
    0{ write-host  "    0 The request was accepted." -foregroundcolor "white" -BackgroundColor "Red" } 
    1{ write-host  "    1 The request is not supported." -foregroundcolor "white" -BackgroundColor "Red" } 
    2{ write-host  "    2 The user did not have the necessary access."-foregroundcolor "white" -BackgroundColor "Red"} 
    3{ write-host  "    3 The service cannot be stopped because other services that are running are dependent on it." -foregroundcolor "white" -BackgroundColor "Red"} 
    4{ write-host  "    4 he requested control code is not valid, or it is unacceptable to the service." -foregroundcolor "white" -BackgroundColor "Red"} 
    5{ write-host  "    5 The requested control code cannot be sent to the service because the state of the service (Win32_BaseService State property) is equal to 0, 1, or 2." -foregroundcolor "white" -BackgroundColor "Red"} 
    6{ write-host  "    6 The service has not been started." -foregroundcolor "white" -BackgroundColor "Red"} 
    7{ write-host  "    7 The service did not respond to the start request in a timely fashion." -foregroundcolor "white" -BackgroundColor "Red"} 
    8{ write-host  "    8 Unknown failure when starting the service."-foregroundcolor "white" -BackgroundColor "Red" } 
    9{ write-host  "    9 The directory path to the service executable file was not found." -foregroundcolor "white" -BackgroundColor "Red"} 
    10{ write-host  "    10 The service is already running."-foregroundcolor "white" -BackgroundColor "Red" } 
    11{ write-host  "    11 The database to add a new service is locked."-foregroundcolor "white" -BackgroundColor "Red" } 
    12{ write-host  "    12 A dependency this service relies on has been removed from the system."-foregroundcolor "white" -BackgroundColor "Red" } 
    13{ write-host  "    13 The service failed to find the service needed from a dependent service."-foregroundcolor "white" -BackgroundColor "Red" } 
    14{ write-host  "    14 The service has been disabled from the system."-foregroundcolor "white" -BackgroundColor "Red" } 
    15{ write-host  "    15 The service does not have the correct authentication to run on the system."-foregroundcolor "white" -BackgroundColor "Red" } 
    16{ write-host  "    16 This service is being removed from the system."-foregroundcolor "white" -BackgroundColor "Red" }
    17{ write-host  "    17 The service has no execution thread." -foregroundcolor "white" -BackgroundColor "Red"} 
    18{ write-host  "    18 The service has circular dependencies when it starts."-foregroundcolor "white" -BackgroundColor "Red" } 
    19{ write-host  "    19 A service is running under the same name."-foregroundcolor "white" -BackgroundColor "Red" } 
    20{ write-host  "    20 The service name has invalid characters."-foregroundcolor "white" -BackgroundColor "Red" } 
    21{ write-host  "    21 Invalid parameters have been passed to the service."-foregroundcolor "white" -BackgroundColor "Red" } 
    22{ write-host  "    22 The account under which this service runs is either invalid or lacks the permissions to run the service."-foregroundcolor "white" -BackgroundColor "Red" } 
    23{ write-host  "    23 The service exists in the database of services available from the system."-foregroundcolor "white" -BackgroundColor "Red" } 
    24{ write-host  "    24 The service is currently paused in the system."-foregroundcolor "white" -BackgroundColor "Red" } 
    }
}



function PowerShell-Wait($seconds)
{
#This function will cause the script to wait n seconds
   [System.Threading.Thread]::Sleep($seconds*1000)
}


function main()
{

#The main code. This function is called at the end of the script, in line 138
$svcD=gwmi win32_service -computername $ServerN -filter "name like '%$Service%'" 
write-host "----------------------------------------------------------------"  
write-host "REMEMBER TO RUN THE SCRIPT AS ADMINISTRATOR"  -foregroundcolor "RED" -backgroundcolor "yellow"


write-host "Services found:"  $svcD.Count -foregroundcolor "green"
$svcD | ForEach-Object {

write-host "Service to change user and pasword: "   $_.name -foregroundcolor "green"

write-host "----------------------------------------------------------------"  


       if ($_.state -eq 'Running')
       {
          
           write-host "    Attempting to Stop de service..."
           $Value = $_.StopService()
            if ($Value.ReturnValue -eq '0') 

               {
                $Change = 1       
                $Starts = 1      
                write-host "    Service stopped" -foregroundcolor "white" -BackgroundColor "darkgreen"
                }
               Else 
               {
                    write-host "    The stop action returned the following error: " -foregroundcolor "white" -BackgroundColor "Red"
                    PowerShell-PrintErrorCodes ($Value.ReturnValue)
                     $Change = 0
                     $Starts = 0
                }
       }
       Else
       {
         write-host "    As the service is not running before, is not going to be started after the change." -foregroundcolor "RED" -backgroundcolor "yellow"
         $Starts = 0
         $Change = 1
        
       }
       
           if ($Change -eq 1 ) 
           {
             write-host "    Attemtping to change the service..."
               #this is the method that will do the user and pasword change
               $Value = $_.change($null,$null,$null,$null,$null,$null,$UserName,$Password,$null,$null,$null) 
               if ($Value.ReturnValue -eq '0') 
                {
                   write-host "    Pasword and user changed" -foregroundcolor "white" -BackgroundColor "darkgreen"
                   if ($Starts -eq 1) 
                        {
                            write-host "    Attemtping to start the service, waiting $SecondsToWait seconds..."
                            PowerShell-Wait ($SecondsToWait)
                            $Value =  $_.StartService()
                            if ($Value.ReturnValue -eq '0') 
                                {
                                    write-host "    Service started sucsesfully" -foregroundcolor "white" -BackgroundColor "darkgreen"
                                }
                             Else
                                {
                                write-host "    Error while starting the service: " -foregroundcolor "white" -BackgroundColor "red"
                                 PowerShell-PrintErrorCodes ($Value.ReturnValue)
                                }
                        }                                                           
                    }
                Else 
                 {
                 write-host "    The change action returned the following error: "  -foregroundcolor "white" -BackgroundColor "red"
                  PowerShell-PrintErrorCodes ($Value.ReturnValue)
                 }
                }                      

   write-host "----------------------------------------------------------------"    
}

write-host "PROCESS COMPLETED"  -foregroundcolor "RED" -backgroundcolor "yellow"

}

clear  #clearing  the screen

main   #Calling the main function that will do the job.