# .".\SetVars.ps1"
# Param(
	# [string]$db_path =  "C:\ETERRA\e-terrasource\DatabaseScripts"
# )

if(test-path "$db_path\Oracle\InstallScripts\install_csm.sql")
{
    $path = "$db_path\Oracle\InstallScripts"
}
elseif(test-path "$db_path\Oracle\Install Scripts\install_csm.sql")
{
    $path = "$db_path\Oracle\Install Scripts"
}
else
{
    $path = "C:\ETERRA\e-terrasource\DatabaseScripts\Oracle\InstallScripts"
}

pushd $path
write-host installing ets

$sqlFile = "install_csm.sql"
"$company`n$username" | sqlplus $master/$masterpw`@$tns `@$sqlFile 

popd

& ".\CreateAPIUser.ps1"

pushd (join-path $path "..\CIMEMS\InstallScripts")

write-host install CIM/EMS schema

$sqlFile = "install_CIM_EMS.sql"
sqlplus $master/$masterpw`@$tns `@$sqlFile 

popd

#SWEG special
if(test-path (".\InstallSQL\install_csm" + $username + ".sql"))
{
    pushd ".\InstallSQL"

	write-host Install SWEG users

	$sqlFile = "install_csm" + $username + ".sql"
	sqlplus $master/$masterpw`@$tns `@$sqlFile 

	popd
}