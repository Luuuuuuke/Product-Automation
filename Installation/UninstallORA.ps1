# .".\SetVars.ps1"
& ".\DropAPIUser.ps1"

#uninstall
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

write-host uninstalling ets

$sqlFile = "uninstall_csm.sql"
"`n" |sqlplus $master/$masterpw`@$tns `@$sqlFile 

popd
