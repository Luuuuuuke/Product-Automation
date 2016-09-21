# .".\SetVars.ps1"

if(test-path "$db_path\Oracle\InstallScripts\install_csm.sql")
{
    pushd "$db_path\Oracle\InstallScripts"
}
elseif(test-path "$db_path\Oracle\Install Scripts\install_csm.sql")
{
    pushd "$db_path\Oracle\Install Scripts"
}
else
{
    pushd "C:\ETERRA\e-terrasource\DatabaseScripts\Oracle\InstallScripts"
}

write-host "create $name APIuser"

$sqlFile = "create_csm_api_user.sql"
"$master`n$masterpw`n$tns`n$name`n$pw`nusers`ntemp" | sqlplus $master/$masterpw`@$tns `@$sqlFile 

popd
