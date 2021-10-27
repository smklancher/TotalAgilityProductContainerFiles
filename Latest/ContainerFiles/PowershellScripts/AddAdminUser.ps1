$Password = ConvertTo-SecureString "W0rkstation" –AsPlainText –Force
New-LocalUser -Name KTA_Admin -Password $Password -AccountNeverExpires -FullName KTA_Admin -PasswordNeverExpires -UserMayNotChangePassword
Add-LocalGroupMember -Group "Administrators" -Member "KTA_Admin"
