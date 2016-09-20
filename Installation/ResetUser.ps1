# .".\SetVars.ps1"

#Drop API User
write-host "Drop API & Master Users"

"drop user $name cascade;`ndrop user $ws_name cascade;`ndrop user $master cascade;`ncommit;`nexit;" | sqlplus $sysname/$syspw`@$tns as sysdba

write-host "create $master Master user"

if(test-path $db_path + "\Oracle\InstallScripts\install_csm.sql")
{
    pushd $db_path + "\Oracle\InstallScripts"
}
elseif(test-path $db_path + "\Oracle\Install Scripts\install_csm.sql")
{
    pushd $db_path + "\Database\Oracle\Install Scripts"
}
else
{
    pushd "C:\ETERRA\e-terrasource\DatabaseScripts\Oracle\InstallScripts"
}


$sqlFile = "create_csm_master_user.sql"
"$master`n$masterpw`nusers`ntemp" | sqlplus $sysname/$syspw`@$tns as sysdba `@$sqlFile 

popd
write-host `a