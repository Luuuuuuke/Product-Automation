# .".\SetVars.ps1"

pushd "$db_path\SqlServer\InstallScripts"

write-host uninstall csm
.\uninstall_csm.ps1 -ServerName $mssqlSrvName -Trusted -dbName $name -CsmLogin $name -ModelAuthority $company -SkipUserInput

popd
