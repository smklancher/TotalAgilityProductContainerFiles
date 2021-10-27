Import-Module 'C:\KTA\PowershellScripts\LHSNTrights.psm1' -verbose
Set-LHSNTRights -PrivilegeName 'SeServiceLogonRight' -Identity 'KTA_Admin'
Set-LHSTokenPrivilege -Privilege 'SeIncreaseQuotaPrivilege'
Set-LHSTokenPrivilege -Privilege 'SeCreateTokenPrivilege'
Set-LHSTokenPrivilege -Privilege 'SeAssignPrimaryTokenPrivilege'
