Param(
  # ==== New Parameters ====
	[string]$username="haba8",
	[string]$orcl_user="ets",
	[string]$orcl_pwd="ets",
	[string]$orcl_tns="orcl",
	[string]$db_path="D:\eterra\e-terrasource\Database"
  
   # ==== New Parameters ====
)

write-host "Setting vars - full database."
#connection info
$sysname=$orcl_user
$syspw=$orcl_user
$tns=$orcl_tns
    
#local oracle connection info (unused)
$localSysname=$orcl_user
$localSyspw=$orcl_user
$localTNS=$orcl_tns

#sqlServer path, doesn't work with anything but localhost. :)
$mssqlSrvName="localhost"

#API user and Master user names and passwords
$name=$orcl_user + "api"
$pw=$name
$master=$orcl_user
$masterpw=$master

#workspace and user info
$company="eterra"
$ws_name=$username+"_ws"
$ws_pw=$ws_name
$schema="CIM/EMS"

#Path to ETS Scripting library, default: @"C:\Program Files (x86)\Eterra\Presentation Framework\Plugins\e-terrasource\EtsScripting\EtsScripting.psm1"
# $scriptLib = "C:\Program Files (x86)\Eterra\Presentation Framework\Plugins\e-terrasource\EtsScripting\EtsScripting.psm1"


# Set vars to global scope
Set-Variable -Name 'sysname' -Value $sysname -Scope Global
Set-Variable -Name 'syspw' -Value $syspw -Scope Global
Set-Variable -Name 'tns' -Value $tns -Scope Global
Set-Variable -Name 'localSysname' -Value $localSysname -Scope Global
Set-Variable -Name 'localSyspw' -Value $localSyspw -Scope Global
Set-Variable -Name 'localTNS' -Value $localTNS -Scope Global
Set-Variable -Name 'mssqlSrvName' -Value $mssqlSrvName -Scope Global
Set-Variable -Name 'name' -Value $name -Scope Global
Set-Variable -Name 'pw' -Value $pw -Scope Global
Set-Variable -Name 'master' -Value $master -Scope Global
Set-Variable -Name 'masterpw' -Value $masterpw -Scope Global
Set-Variable -Name 'company' -Value $company -Scope Global
Set-Variable -Name 'username' -Value $username -Scope Global
Set-Variable -Name 'ws_name' -Value $ws_name -Scope Global
Set-Variable -Name 'ws_pw' -Value $ws_pw -Scope Global
Set-Variable -Name 'schema' -Value $schema -Scope Global
Set-Variable -Name 'db_path' -Value $db_path -Scope Global
Set-Variable -Name 'test' -Value "test" -Scope Global