Get-Service -CN . | 
ForEach-Object { 
write-host -ForegroundColor 9 "Service name $($_.name)" 
  if($_.DependentServices) 
    { write-host -ForegroundColor 3 "`tServices that depend on $($_.name)" 
      foreach($s in $_.DependentServices) 
       { "`t`t" + $s.name } 
    } #end if DependentServices 
  if($_.RequiredServices) 
    { Write-host -ForegroundColor 10 "`tServices required by $($_.name)" 
      foreach($r in $_.RequiredServices) 
       { "`t`t" + $r.name } 
    } #end if DependentServices 
} #end foreach-object