function startService([string]$srvName)
{
    $serviceBefore = Get-Service | Where-Object {$_.name -eq $srvName}
    if(!$serviceBefore)
    {
        write-host "Service $srvName doesn't exist."
    }
    else
    {
        Start-Service $srvName
        $serviceAfter = Get-Service $srvName
        "$srvName is now " + $serviceAfter.status
    }
}

# .".\SetVars.ps1"

write-host Start SQL Server agent
startService "SQLSERVERAGENT"

write-host installing ets

pushd "$db_path\SqlServer\InstallScripts"

.\install_csm.ps1 -ServerName $mssqlSrvName -Trusted -dbName $name -CsmLogin $name -csmPassword $pw -ModelAuthority $company -FirstUser $username -SkipUserInput

popd

write-host install CIM/EMS schema
pushd "$db_path\SqlServer\CIMEMS\InstallScripts"

.\install_cim_EMS.ps1 -ServerName $mssqlSrvName -Trusted -dbName $name -SkipUserInput

popd