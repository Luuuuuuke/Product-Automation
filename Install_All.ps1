Param(
  [switch]$ResetUser,
  [switch]$Islocal=$false,
  [switch]$ForSql=$false,
  [switch]$SkipPrepWs=$false,
  # ==== New Parameters ====
  [string]$install_kits_dir=".\Latest",
  # Available ETS Versions are: {"31","DEV"}, mapping the file name on server
  [string]$ETSVersion,
  # Available ETS Version Release.  1: Patch Release             2: SPR Release           3: Official Release
  [int]$Release,
  [string]$Install_dir,
  # [string]$Install_dir="D:\eterra\e-terrasource",
  [string]$server_instance_name,
  [string]$export_dir=$Install_dir + "\Server\DefaultInstance\export",
  [string]$import_dir=$Install_dir + "\Server\DefaultInstance\import",
  [string]$logs_dir=$Install_dir + "\Server\DefaultInstance\logs",
  [string]$FirstUser,
  [string]$orcl_user,
  [string]$orcl_pwd,
  [string]$orcl_tns,
  [string]$sql_user,
  [string]$sql_pwd
   # ==== New Parameters ====
)

########## Parameter Check ########### Start

$UserDir = "C:\Users\" + $FirstUser
while([string]::IsNullOrEmpty($FirstUser) -or !(Test-Path $UserDir)){
	$FirstUser = $(Read-Host "Enter first ETS user")
	$UserDir = "C:\Users\" + $FirstUser
}
if(!$Islocal){
	#install_kits_dir
	if([string]::IsNullOrEmpty($install_kits_dir)) {
		$install_kits_dir = $(Read-Host "Input the directory to store the kits")
	}
	while(!(Test-Path $install_kits_dir)){
		Write-Host "The kits directory is not found."
		$install_kits_dir = $(Read-Host "Input the directory to store the kits")
	}
	# ETS Version
	while([String]::IsNullOrEmpty($ETSVersion) -or ($ETSVersion -ne "3.1" -and 
		$ETSVersion -ne "31_EP1" -and $ETSVersion -ne "31_SPR" -and 
		$ETSVersion -ne "31" -and $ETSVersion -ne "DEV")){
		$ETSVersion = $(Read-Host "Enter the ETS Version (3.1 or DEV)")
	}
	if($ETSVersion -eq "3.1"){
		$Release = 0
		while($Release -ne 1 -and $Release -ne 2 -and $Release -ne 3){
			$Release = $(Read-Host "Enter the release type (1:Patch or 2:SPR or 3:Official) ")
		}
		if($Release -eq 1) {
			$ETSVersion = "31_EP1"
		}
		if($Release -eq 2) {
			$ETSVersion = "31_SPR"
		}
		if($Release -eq 3) {
			$ETSVersion = "31"
		}
	}
} else {
	#install_kits_dir
	if([string]::IsNullOrEmpty($install_kits_dir)) {
		$Install_kits_dir = $(Read-Host "Input the local kits directory")
	}
	if(!(Test-Path ($Install_kits_dir + "\*Server*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Client*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Transformation*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Database*.msi"))){
		Write-Host "One or more kits are missing under the directory."
		$Install_kits_dir = $(Read-Host "Input the local kits directory")
		while(!(Test-Path ($Install_kits_dir + "\*Server*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Client*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Transformation*.msi")) -or !(Test-Path ($Install_kits_dir + "\*Database*.msi"))){
			Write-Host "One or more kits are missing under the directory."
			$Install_kits_dir = $(Read-Host "Input local the kits directory")
		}
	}
}

#Install_dir
if([string]::IsNullOrEmpty($Install_dir) -or !(Test-Path $Install_dir)) {
	if([string]::IsNullOrEmpty($Install_dir)){
		$Install_dir = $(Read-Host "Input the ETS installation directory")
	}
	while(!(Test-Path $Install_dir)){
		Write-Host "The ETS installation directory is not found."
		$Install_dir = $(Read-Host "Input the ETS installation directory")
	}
	$export_dir=$Install_dir + "\export"
	$import_dir=$Install_dir + "\import"
	$logs_dir=$Install_dir + "\logs"
	Write-Host "The export, import and logs file is set under $Install_dir"
}
if([string]::IsNullOrEmpty($export_dir)) {
	$export_dir=$Install_dir + "\Server\DefaultInstance\export"
}
if([string]::IsNullOrEmpty($import_dir)) {
	$import_dir=$Install_dir + "\Server\DefaultInstance\import"
}
if([string]::IsNullOrEmpty($logs_dir)) {
	$logs_dir=$Install_dir + "\Server\DefaultInstance\logs"
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
			$orcl_user = $(Read-Host "Input Oracle User")
		}
		if([string]::IsNullOrEmpty($orcl_pwd)) {
			$orcl_pwd_secured = $(Read-Host "Input Oracle password" -AsSecureString)
			$orcl_pwd = $orcl_pwd_secured | ConvertFrom-SecureString
		}
		if([string]::IsNullOrEmpty($orcl_tns)) {
			$orcl_tns = $(Read-Host "Input Oracle TNS name")
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
			$sql_user = $(Read-Host "Input SQL User")
		}
		if([string]::IsNullOrEmpty($sql_pwd)) {
			$sql_pwd_secured = $(Read-Host "Input SQL password" -AsSecureString)
			$sql_pwd = $sql_pwd_secured | ConvertFrom-SecureString
		}
	}
}
# Server Instance name
if([string]::IsNullOrEmpty($server_instance_name)) {
	$server_instance_name="DefaultInstance"
}

########## Parameter Check ############ End

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
 # Set important variables into global scope
$db_path = $Install_dir + "\Database"
.".\SetVars.ps1" -username "$FirstUser" -orcl_user "$orcl_user" -orcl_pwd "$orcl_pwd" -orcl_tns "$orcl_tns" -db_path "$db_path"

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
    return $true
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
  return $false
}

function install([string]$kit, [string]$extraArgs="")
{
  $kitsDir = $install_kits_dir + "\*$kit*.msi"
  $tMsi = (gci $kitsDir).FullName
  write-host "Installing $kit kit: $tMsi" -foregroundcolor cyan
  $kitArgs = "/i ""$tMsi"" /passive $extraArgs"
  $code = (Start-Process -FilePath "msiexec.exe" -ArgumentList $kitArgs -Wait -Passthru).ExitCode
  return write-result $code
}
   
# .".\SetVars.ps1"
# $scriptLib = "C:\Program Files (x86)\Eterra\Presentation Framework\Plugins\e-terrasource\EtsScripting\EtsScripting.psm1"

if(!$Islocal)
{
  if(!(Test-Path $install_kits_dir))
  {
    New-Item -ItemType directory -Path $install_kits_dir
  }
  else
  {
	$oldKitsDir = $install_kits_dir + "\*"
    remove-item $oldKitsDir -Force
  }
  #\\share.empgrid.esca.com\tfsdropbuilds\kits\e-terrasource\CSM_DEV_DAILY
  if($ETSVersion -ne "31" -and $ETSVersion -ne "31_EP1" -and $ETSVersion -ne "31_SPR" -and $ETSVersion -ne "DEV"){
	write-host failed: Could not find ETS Version $ETSVersion
	return $false
  }
  if (!(Test-Path ("\\share.empgrid.esca.com\tfsdropbuilds\kits\buildDrop\source\" + $ETSVersion)))
  {
	throw "Cannot connect to the R&D Share drive for $ETSVersion"
  }
  $latestDir = (gci \\share.empgrid.esca.com\tfsdropbuilds\kits\buildDrop\source\$ETSVersion | ? { $_.PSIsContainer } | sort CreationTime -desc | select -f 1)
  write-host "Copying kit: $latestDir" -foregroundcolor cyan
  $ETSVersion = $latestDir.toString().ToUpper()

  copy-item -R -Force -Filter *.msi ($latestDir.FullName+"\*") -Destination $install_kits_dir
}

$ApfExeDir = "C:\Program Files (x86)\Eterra\Presentation Framework\Eterra.apf.exe"
if (Test-Path Env:ApfInstallDir) {
	$ApfExeDir = ((Get-ChildItem Env:ApfInstallDir).Value + 'Eterra.apf.exe')
}
if(!(Test-Path $ApfExeDir))
{
	write-host "Please install APF and then press the 'Enter' key to continue" -foregroundcolor Yellow
	read-host
}
$db_install_dir = $Install_dir + "\"
$result = install "Database" "INSTALLDIR=$db_install_dir"
if (!$result)
{
	throw "Error during installation of the Database MSI"
	exit
}

if($ResetUser)
{
	& ".\ResetUser.ps1"
}

write-host "Running Install scripts..." -foregroundcolor cyan
if(!$ForSql){
	$oracleJob = start-job -scriptblock {param($path,$db_path,$master,$masterpw,$tns,$name,$pw,$company,$username) Set-Variable -Name 'db_path' -Value $db_path -Scope Global; Set-Variable -Name 'master' -Value $master -Scope Global; Set-Variable -Name 'masterpw' -Value $masterpw -Scope Global; Set-Variable -Name 'tns' -Value $tns -Scope Global; Set-Variable -Name 'name' -Value $name -Scope Global; Set-Variable -Name 'pw' -Value $pw -Scope Global;Set-Variable -Name 'company' -Value $company -Scope Global;Set-Variable -Name 'username' -Value $username -Scope Global; set-location $path; & ".\InstallORA.ps1"} -Name "Install_Oracle" -ArgumentList (get-location),$db_path,$master,$masterpw,$tns,$name,$pw,$company,$username
} else {
	$sqlJob = start-job -scriptblock {param($path,$db_path,$name,$pw,$company,$username) Set-Variable -Name 'db_path' -Value $db_path -Scope Global; Set-Variable -Name 'name' -Value $name -Scope Global; Set-Variable -Name 'pw' -Value $pw -Scope Global; Set-Variable -Name 'username' -Value $username -Scope Global; Set-Variable -Name 'company' -Value $company -Scope Global; set-location $path; & ".\InstallSQL.ps1"} -Name "Install_SQL" -ArgumentList (get-location),$db_path,$name,$pw,$company,$username
}

$result = install "Client"
if (!$result)
{
	throw "Error during installation of the Client MSI"
	exit
}

# Set ets scripting lib
$scriptLib = "C:\Program Files (x86)\Eterra\Presentation Framework\"
if (Test-Path Env:ApfInstallDir) {
	$scriptLib = ((Get-ChildItem Env:ApfInstallDir).Value + 'Plugins\e-terrasource\EtsScripting')
}
if (-not(Test-Path ($scriptLib + '\EtsScripting.psm1'))) {
	$scriptLib = $( Read-Host "Enter the local APF ETS scripts plugin directory" )
}
$scriptLib = $scriptLib + '\EtsScripting.psm1'
Set-Variable -Name 'scriptLib' -Value $scriptLib -Scope Global;

$server_install_dir = $Install_dir + "\Server\" + $server_instance_name + "\"
 if(!(Test-Path $server_install_dir))
{
New-Item -ItemType directory -Path $server_install_dir
}
$server_app_dir = $server_install_dir
$result = install "Server" "MSINEWINSTANCE=1 TRANSFORMS=:i4 INSTANCENAME=$server_instance_name INSTALLDIR=$server_install_dir APPDIR=$server_app_dir ETS_APPDATA_EXPORT=$export_dir ETS_APPDATA_IMPORT=$import_dir ETS_APPDATA_LOGS=$logs_dir"
if (!$result)
{
	throw "Error during installation of the Server MSI"
	exit
}
else
{
  write-host "Configure server..." -foregroundcolor cyan
  pushd $server_install_dir
  if(!$ForSql){
	.\srvconfig.exe /db-type:oracle /tns-name:$tns /login:$name /password:$pw
  }
  popd
}

$transform_install_dir = $Install_dir + "\"
$result = install "Transformation" "INSTALLDIR=$transform_install_dir"
if (!$result)
{
	throw "Error during installation of the Transformation MSI"
	exit
}

Write-Host -NoNewLine "Waiting to finish DB install."
get-job | wait-job

if(!$ForSql)
{
  write-host "Oracle output:"
  receive-job -job $oracleJob
  remove-job $oracleJob
}
else
{
  write-host "SQL output:"
  receive-job -job $sqlJob
  remove-job $sqlJob
}

write-host "Starting Server services..." -foregroundcolor cyan
& ".\StartServer.ps1"

if(!$SkipPrepWs)
{
	$question = 'Do you want to prep the workspace?'
	$choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
	$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
	$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

	$decision = $Host.UI.PromptForChoice($message, $question, $choices, 0)
}
else
{
	$decision = 1
}
if ($decision -eq 0) 
{
	if(!(test-path $scriptLib)) {
		write-host "Cannot find ETS Scripting Module. skipping." -foregroundcolor yellow
    $decision = 1
	}
  else{
    Import-Module $scriptLib -DisableNameChecking 
    & ".\prepWS.ps1"
  }
} else {
  Write-Host 'skipped.' -foregroundcolor cyan
}

# Set the ETS Version
[Environment]::SetEnvironmentVariable("ETS_VERSION", $ETSVersion, "Machine")

#SWEG special
if(test-path "..\Sequence")
{
    remove-item "..\Sequence\*" -Force
	if(test-path "..\log")
	{
		remove-item "..\log\*" -Force
	}
}
