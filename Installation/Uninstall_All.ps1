Param(
	[switch]$ForSql=$false,
	[string]$Install_dir,
	[string]$Install_kits_dir,
	[string]$orcl_user,
	[string]$orcl_pwd,
	[string]$orcl_tns,
	[string]$sql_user,
	[string]$sql_pwd
)

#Install_dir
# if install_dir is input, test the path, keeping asking if the dir is not correct
if(![string]::IsNullOrEmpty($Install_dir)) {
	while(!(Test-Path ($Install_dir + "\Database")) -or !(Test-Path ($Install_dir + "\Server"))){
		Write-Host "The installation dir is not correct, files are missing."
		$Install_dir = $(Read-Host "Input the ETS installation directory ")
	}
}

# if the install dir is not set, detect it
if([string]::IsNullOrEmpty($Install_dir)){
	#detect if its under Habitat_DIRROOT
	if(Test-Path Env:HABITAT_DIRROOT) {
		$Hab_dir = $(Get-ChildItem Env:HABITAT_DIRROOT).Value
		if((Test-Path ($Hab_dir + "\Database")) -and (Test-Path ($Hab_dir + "\Server"))){
			$Install_dir = $Hab_dir
		} else {
			#detect \eterra\e-terrasource under each drive
			for($i = 90; $i -gt 66; $i--) {
				$drive = [char]$i
				$targetFile = $drive + ":\eterra\e-terrasource"
				if((Test-Path ($Hab_dir + "\Database")) -and (Test-Path ($Hab_dir + "\Server"))) {
					$Install_dir = $targetFile
					write-host "The Installation directory detected: $install_dir"
					break
				}
			}
			if($i -eq 66){
				throw "No ETS installation directory detected."
				exit
			}
		}
	} else {
		#detect \eterra\e-terrasource under each drive
		for($i = 90; $i -gt 66; $i--) {
			$drive = [char]$i
			$targetFile = $drive + ":\eterra\e-terrasource"
			if((Test-Path ($targetFile + "\Database")) -and (Test-Path ($targetFile + "\Server"))) {
				$Install_dir = $targetFile
				write-host "The Installation directory detected: $install_dir"
				break
			}
		}
		if($i -eq 66){
			throw "No ETS installation directory detected."
			exit
		}
	}
}

# install_kits_dir
if([string]::IsNullOrEmpty($Install_kits_dir)){
	$Install_kits_dir = ".\Latest"
	if(!(Test-Path ($Install_kits_dir + "\*Server*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Client*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Transformation*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Database*.msi"))){
		$Install_kits_dir = $(Read-Host "Input the kits directory")
		while(!(Test-Path ($Install_kits_dir + "\*Server*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Client*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Transformation*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Database*.msi"))){
			Write-Host "One or more kits are missing under the directory."
			$Install_kits_dir = $(Read-Host "Input the kits directory")
		}
	}
} else {
	if(!(Test-Path ($Install_kits_dir + "\*Server*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Client*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Transformation*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Database*.msi"))){
		Write-Host "One or more kits are missing under the directory."
		exit
	}
}

# oracle connection info
if(!$ForSql){
	if (![string]::IsNullOrEmpty($orcl_user) -and ![string]::IsNullOrEmpty($orcl_pwd) -and ![string]::IsNullOrEmpty($orcl_tns))
	{
		#check user entered information
		echo exit | sqlplus $orcl_user/$orcl_pwd@$orcl_tns | out-file '.\connectionLog.txt'
		$log_content = get-content '.\connectionLog.txt' | select-string 'ERROR'
		if(![string]::IsNullOrEmpty($log_content)){
			$orcl_user = $null
			$orcl_pwd = $null
			$orcl_tns = $null
		}
	}
	while([string]::IsNullOrEmpty($orcl_user) -or [string]::IsNullOrEmpty($orcl_pwd) -or [string]::IsNullOrEmpty($orcl_tns)){
		if([string]::IsNullOrEmpty($orcl_user)) {
			$orcl_user = $(Read-Host "Input Oracle User: ")
		}
		if([string]::IsNullOrEmpty($orcl_pwd)) {
			$orcl_pwd_secured = $(Read-Host "Input Oracle password: " -AsSecureString)
			$orcl_pwd = $orcl_pwd_secured | ConvertFrom-SecureString
		}
		if([string]::IsNullOrEmpty($orcl_tns)) {
			$orcl_tns = $(Read-Host "Input Oracle TNS name: ")
		}
		#check connection
		echo exit | sqlplus $orcl_user/$orcl_pwd@$orcl_tns | out-file '.\connectionLog.txt'
		$log_content = get-content '.\connectionLog.txt' | select-string 'ERROR'
		if(![string]::IsNullOrEmpty($log_content)){
			$orcl_user = $null
			$orcl_pwd = $null
			$orcl_tns = $null
		}
	}
} else {
	while([string]::IsNullOrEmpty($sql_user) -or [string]::IsNullOrEmpty($sql_pwd)){
		if([string]::IsNullOrEmpty($sql_user)) {
			$sql_user = $(Read-Host "Input SQL User: ")
		}
		if([string]::IsNullOrEmpty($sql_pwd)) {
			$sql_pwd_secured = $(Read-Host "Input SQL password: " -AsSecureString)
			$sql_pwd = $sql_pwd_secured | ConvertFrom-SecureString
		}
	}
}

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

# Set ets scripting lib
if (Test-Path Env:ApfInstallDir) {
	$scriptLib = ((Get-ChildItem Env:ApfInstallDir).Value + 'Plugins\e-terrasource\EtsScripting')
}
if (-not(Test-Path ($scriptLib + '\EtsScripting.psm1'))) {
	$scriptLib = $( Read-Host "Enter the local APF ETS scripts plugin directory" )
}
$scriptLib = $scriptLib + '\EtsScripting.psm1'

# Set important variables into global scope
$db_path = $Install_dir + "\Database"
.".\SetVars.ps1" -orcl_user "$orcl_user" -orcl_pwd "$orcl_pwd" -orcl_tns "$orcl_tns" -scriptLib "$scriptLib" -db_path "$db_path"
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" 
   }
else
   {
   throw "You are not running as Administrator, Please elevate and re-run."
   
   # Exit from the current, unelevated, process
   exit
   }

function write-result($ExitCode)
{
  if($ExitCode -eq "0")
  {
    write-host success. -foregroundcolor green
    return $True
  }
  elseif ($ExitCode -eq "1619")
  {
    # write-host "failed - Couldn't find msi." -foregroundcolor red
	throw "failed - Couldn't find msi."
  }
  else
  {
    # write-host failed: $ExitCode -foregroundcolor red
	throw ("Failed:" + $ExitCode)
  }
  return $False
}

function uninstall($kit, $extraArgs="")
{
  $tMsi = (gci $Install_kits_dir\*$kit*.msi).FullName
  write-host "Uninstalling $kit kit: $tMsi" -foregroundcolor cyan
  $kitArgs = "/x ""$tMsi"" /passive $extraArgs"
  $code = (Start-Process -FilePath "msiexec.exe" -ArgumentList $kitArgs -Wait -Passthru).ExitCode
  Return write-result $code
}
   
write-host "Stoping Server services..." -foregroundcolor cyan
& ".\StopServer.ps1"

write-host "Running Uninstall script..." -foregroundcolor cyan
if(!$ForSql){
	$oracleJob = start-job -scriptblock {param($path,$db_path,$master,$masterpw,$tns,$name,$pw) Set-Variable -Name 'db_path' -Value $db_path -Scope Global; Set-Variable -Name 'master' -Value $master -Scope Global; Set-Variable -Name 'masterpw' -Value $masterpw -Scope Global; Set-Variable -Name 'tns' -Value $tns -Scope Global; Set-Variable -Name 'name' -Value $name -Scope Global; Set-Variable -Name 'pw' -Value $pw -Scope Global; set-location $path; & ".\UninstallORA.ps1"} -Name "Install_Oracle" -ArgumentList (get-location),$db_path,$master,$masterpw,$tns,$name,$pw
} else {
	$sqlJob = start-job -scriptblock {param($path,$db_path,$name,$pw,$company,$username) Set-Variable -Name 'db_path' -Value $db_path -Scope Global; Set-Variable -Name 'name' -Value $name -Scope Global; Set-Variable -Name 'pw' -Value $pw -Scope Global; Set-Variable -Name 'username' -Value $username -Scope Global; Set-Variable -Name 'company' -Value $company -Scope Global; set-location $path; & ".\UninstallSQL.ps1"} -Name "Install_SQL" -ArgumentList (get-location),$db_path,$name,$pw,$company,$username
}
$result = uninstall "Transformation"

$result = uninstall "Server" "TRANSFORMS=:i4 INSTANCENAME=DefaultInstance"

$result = uninstall "Client" 

Write-Host -NoNewLine "Waiting to finish DB Uninstall."
get-job | wait-job

if(!$ForSql){
	write-host "Oracle output:"
	receive-job -job $oracleJob
	remove-job $oracleJob
} else {
	write-host "SQL output:"
	receive-job -job $sqlJob
	remove-job $sqlJob
}
$result = Uninstall "Database"

if(Test-Path Env:ApfInstallDir)
{
	if (test-path ((Get-ChildItem Env:ApfInstallDir).Value + 'Plugins\e-terrasource'))
	{
	  #remove client install dir, Development dlls can be left there that prevent me from running a normal kit. 
	  remove-item -recurse -force ((Get-ChildItem Env:ApfInstallDir).Value + 'Plugins\e-terrasource')
	}
}

# Cleanup the Install and ETS directories
$oldKitsDir = $install_kits_dir + "\*"
remove-item $oldKitsDir -Force
$oldKitsDir = $Install_dir + "\*"
remove-item $oldKitsDir -Force -Recurse
write-host "Finished." -foregroundcolor cyan