call cls
@echo off
setlocal EnableDelayedExpansion
rem ###########################################################
rem This script will perform the following:
rem     1.  User input (Versions, HDB, Others)
rem		2.	Create/Update the Import clones
rem		3.	Load the savecases to the Import clones
rem		4.	Standard upgrade
rem		5.	Customer upgrade (Skip if customer files are not found)
rem     6.  Validate Database
rem		7.	Update the model to correct model errors (Skip if update files are not found)
rem		8.	Validate Database
rem		9.	Create a new set of savecases, for reference
rem ###########################################################

rem Available Habitat/EMP/Scada/Comm Versions, modify if needded, 
rem Please sort manually from low to high when modifying
set _HabitatVersions=5.7 5.8 5.9 5.10
set _EMPVersions=2.5 2.6 3.0 3.1
set _ScadaVersions=2.5 2.6 3.0 3.1
set _CommVersions=2.5 2.6 3.0

rem set versions data into Arrays: HabitatVersions, EMPVersions, ScadaVersions, CommVersions
call :SetIntoArray

rem ########################  Interacitve Setting Part ################

echo ==Version Setting Start==
:SetHabitat
set /p DoHabitat="Upgrade Habitat Version? [y/n]:"
if "%DoHabitat%" neq "y" (
	if "%DoHabitat%" neq "n" (
		echo Invalid input.
		goto :SetHabitat
	)
)
if "%DoHabitat%" equ "n" goto :SetEMP
call :GetVersionsString "Habitat" OrigHabitatStr -1
:SetHabitatVersion
set /p OrigVersion_Habitat="Orignal Habitat Version? [%OrigHabitatStr%]:"
call :ValidateVersionChoice %OrigVersion_Habitat% %OrigHabitatStr%
if %ERRORLEVEL% neq 0 (
	echo Invalid input.
	goto :SetHabitatVersion
)

call :GetVersionsString "Habitat" NewHabitatStr %OrigVersion_Habitat%
set /p NewVersion_Habitat="New Habitat Version? [%NewHabitatStr%]:"
call :ValidateVersionChoice %NewVersion_Habitat% %NewHabitatStr%
if %ERRORLEVEL% neq 0 (
	echo Invalid input.
	goto :SetHabitatVersion
)

:SetEMP
set /p DoEMP="Upgrade EMP Version? [y/n]:"
if "%DoEMP%" neq "y" (
	if "%DoEMP%" neq "n" (
		echo Invalid input.
		goto :SetEMP
	)
)
if "%DoEMP%" equ "n" goto :SetScada
call :GetVersionsString "EMP" OrigEMPStr -1
:SetEMPVersion
set /p OrigVersion_EMP="Orignal EMP Version? [%OrigEMPStr%]:"
call :ValidateVersionChoice %OrigVersion_EMP% %OrigEMPStr%
if %ERRORLEVEL% neq 0 (
	echo Invalid input.
	goto :SetEMPVersion
)

call :GetVersionsString "EMP" NewEMPStr %OrigVersion_EMP%
set /p NewVersion_EMP="New EMP Version? [%NewEMPStr%]:"
call :ValidateVersionChoice %NewVersion_EMP% %NewEMPStr%
if %ERRORLEVEL% neq 0 (
	echo Invalid input.
	goto :SetEMPVersion
)

:SetScada
set /p DoScada="Upgrade Scada Version? [y/n]:"
if "%DoScada%" neq "y" (
	if "%DoScada%" neq "n" (
		echo Invalid input.
		goto :SetScada
	)
)
if "%DoScada%" equ "n" goto :SetComm
call :GetVersionsString "Scada" OrigScadaStr -1
:SetScadaVersion
set /p OrigVersion_Scada="Orignal Scada Version? [%OrigScadaStr%]:"
call :ValidateVersionChoice %OrigVersion_Scada% %OrigScadaStr%
if %ERRORLEVEL% neq 0 (
	echo Invalid input.
	goto :SetScadaVersion
)

call :GetVersionsString "Scada" NewScadaStr %OrigVersion_Scada%
set /p NewVersion_Scada="New Scada Version? [%NewScadaStr%]:"
call :ValidateVersionChoice %NewVersion_Scada% %NewScadaStr%
if %ERRORLEVEL% neq 0 (
	echo Invalid input.
	goto :SetScadaVersion
)

:SetComm
set /p DoComm="Upgrade Comm Version? [y/n]:"
if "%DoComm%" neq "y" (
	if "%DoComm%" neq "n" (
		echo Invalid input.
		goto :SetComm
	)
)
if "%DoComm%" equ "n" goto :SetDatabase
call :GetVersionsString "Comm" OrigCommStr -1
:SetCommVersion
set /p OrigVersion_Comm="Orignal Comm Version? [%OrigCommStr%]:"
call :ValidateVersionChoice %OrigVersion_Comm% %OrigCommStr%
if %ERRORLEVEL% neq 0 (
	echo Invalid input.
	goto :SetCommVersion
)

call :GetVersionsString "Comm" NewCommStr %OrigVersion_Comm%
set /p NewVersion_Comm="New Comm Version? [%NewCommStr%]:"
call :ValidateVersionChoice %NewVersion_Comm% %NewCommStr%
if %ERRORLEVEL% neq 0 (
	echo Invalid input.
	goto :SetCommVersion
)
echo ==Version Setting End==

:SetDatabase
REM Initialize Database setting
set DoAlarm=n
set DoAlarmDef=n
set DoCtgs=n
set DoDtsmom=n
set DoDydef=n
set DoDynrtg=n
set DoGenmom=n
set DoHymom=n
set DoNetmom=n
set DoRasmom=n
set DoResmom=n
set DoRgalm=n
set DoScadamom=n
set DoTagging=n
set DoOagmom=n
if "%DoHabitat%%DoEMP%%DoScada%%DoComm%" equ "nnnn" goto :SetOtherInfo
echo ==Database Setting Start==
:SetAlarm
if "%DoHabitat%" equ "n" goto :SetCtgs
if "%OrigVersion_Habitat%" equ "%NewVersion_Habitat%" goto :SetCtgs
if "%NewVersion_Habitat%" neq "5.8" (
	if "%NewVersion_Habitat%" neq "5.9" (
		echo Alarm migration not available with new Habitat version %NewVersion_Habitat%.
		goto :SetAlarmDef
	)
)
set /p DoAlarm="Upgrade Alarm? [y/n]:"
if "%DoAlarm%" neq "y" (
	if "%DoAlarm%" neq "n" (
		echo Invalid input.
		goto :SetAlarm
	)
)

:SetAlarmDef
if "%NewVersion_Habitat%" neq "5.9" (
	echo Alarmdef migration not available with new Habitat version %NewVersion_Habitat%.
	goto :SetCtgs
)
set /p DoAlarmDef="Upgrade AlarmDef? [y/n]:"
if "%DoAlarmDef%" neq "y" (
	if "%DoAlarmDef%" neq "n" (
		echo Invalid input.
		goto :SetAlarmDef
	)
)

REM :SetCIM
REM set /p DoCIM="Upgrade CIM? [y/n]:"
REM if "%DoCIM%" neq "y" (
	REM if "%DoCIM%" neq "n" (
		REM echo Invalid input.
		REM goto :SetCIM
	REM )
REM )

:SetCtgs
if "%DoEMP%" equ "n" goto :SetScadamom
if "%OrigVersion_EMP%" equ "%NewVersion_EMP%" goto :SetScadamom
if "%NewVersion_EMP%" equ "2.5" (
	echo Ctgs migration not available with new EMP version %NewVersion_EMP%.
	goto :SetDtsmom
)
set /p DoCtgs="Upgrade Ctgs? [y/n]:"
if "%DoCtgs%" neq "y" (
	if "%DoCtgs%" neq "n" (
		echo Invalid input.
		goto :SetCtgs
	)
)

:SetDtsmom
if "%NewVersion_EMP%" equ "2.5" (
	echo Dtsmom migration not available with new EMP version %NewVersion_EMP%.
	goto :SetDydef
)
set /p DoDtsmom="Upgrade Dtsmom? [y/n]:"
if "%DoDtsmom%" neq "y" (
	if "%DoDtsmom%" neq "n" (
		echo Invalid input.
		goto :SetDtsmom
	)
)

:SetDydef
if "%NewVersion_EMP%" equ "2.5" (
	echo Dydef migration not available with new EMP version %NewVersion_EMP%.
	goto :SetDynrtg
)
set /p DoDydef="Upgrade Dydef? [y/n]:"
if "%DoDydef%" neq "y" (
	if "%DoDydef%" neq "n" (
		echo Invalid input.
		goto :SetDydef
	)
)

:SetDynrtg
if "%NewVersion_EMP%" neq "3.0" (
	if "%NewVersion_EMP%" neq "3.1" (
		echo Dynrtg migration not available with new EMP version %NewVersion_EMP%.
		goto :SetGenmom
	)
)
set /p DoDynrtg="Upgrade Dynrtg? [y/n]:"
if "%DoDynrtg%" neq "y" (
	if "%DoDynrtg%" neq "n" (
		echo Invalid input.
		goto :SetDynrtg
	)
)

:SetGenmom
if "%NewVersion_EMP%" equ "2.5" (
	echo Genmom migration not available with new EMP version %NewVersion_EMP%.
	goto :SetHymom
)
set /p DoGenmom="Upgrade Genmom? [y/n]:"
if "%DoGenmom%" neq "y" (
	if "%DoGenmom%" neq "n" (
		echo Invalid input.
		goto :SetGenmom
	)
)

:SetHymom
if "%NewVersion_EMP%" equ "2.5" (
	echo Hymom migration not available with new EMP version %NewVersion_EMP%.
	goto :SetNetmom
)
set /p DoHymom="Upgrade Hymom? [y/n]:"
if "%DoHymom%" neq "y" (
	if "%DoHymom%" neq "n" (
		echo Invalid input.
		goto :SetHymom
	)
)

REM :SetLoadshed
REM set /p DoLoadshed="Upgrade Loadshed? [y/n]:"
REM if "%DoLoadshed%" neq "y" (
	REM if "%DoLoadshed%" neq "n" (
		REM echo Invalid input.
		REM goto :SetLoadshed
	REM )
REM )

:SetNetmom
if "%NewVersion_EMP%" equ "2.5" (
	echo Netmom migration not available with new EMP version %NewVersion_EMP%.
	goto :SetRasmom
)
set /p DoNetmom="Upgrade Netmom? [y/n]:"
if "%DoNetmom%" neq "y" (
	if "%DoNetmom%" neq "n" (
		echo Invalid input.
		goto :SetNetmom
	)
)

:SetRasmom
if "%NewVersion_EMP%" equ "2.5" (
	echo Rasmom migration not available with new EMP version %NewVersion_EMP%.
	goto :SetResmom
)
set /p DoRasmom="Upgrade Rasmom? [y/n]:"
if "%DoRasmom%" neq "y" (
	if "%DoRasmom%" neq "n" (
		echo Invalid input.
		goto :SetRasmom
	)
)

:SetResmom
if "%NewVersion_EMP%" equ "2.5" (
	echo Resmom migration not available with new EMP version %NewVersion_EMP%.
	goto :SetRgalm
)
set /p DoResmom="Upgrade Resmom? [y/n]:"
if "%DoResmom%" neq "y" (
	if "%DoResmom%" neq "n" (
		echo Invalid input.
		goto :SetResmom
	)
)
:SetRgalm
if "%NewVersion_EMP%" equ "2.5" (
	echo Rgalm migration not available with new EMP version %NewVersion_EMP%.
	goto :SetScadamom
)
set /p DoRgalm="Upgrade Rgalm? [y/n]:"
if "%DoRgalm%" neq "y" (
	if "%DoRgalm%" neq "n" (
		echo Invalid input.
		goto :SetRgalm
	)
)

:SetScadamom
if "%DoScada%" equ "n" goto :SetOagmom
if "%OrigVersion_Scada%" equ "%NewVersion_Scada%" goto :SetOagmom
if "%NewVersion_Scada%" equ "2.5" (
	echo Scadamom migration not available with new Scada version %NewVersion_Scada%.
	goto :SetTagging
)
set /p DoScadamom="Upgrade Scadamom? [y/n]:"
if "%DoScadamom%" neq "y" (
	if "%DoScadamom%" neq "n" (
		echo Invalid input.
		goto :SetScadamom
	)
)
:SetTagging
if "%NewVersion_Scada%" neq "3.0" (
	if "%NewVersion_Scada%" neq "3.1" (
		echo Tagging migration not available with new Scada version %NewVersion_Scada%.
		goto :SetOagmom
	)
)
set /p DoTagging="Upgrade Tagging? [y/n]:"
if "%DoTagging%" neq "y" (
	if "%DoTagging%" neq "n" (
		echo Invalid input.
		goto :SetTagging
	)
)

:SetOagmom
if "%DoComm%" equ "n" goto :SetOtherInfo
if "%OrigVersion_Comm%" equ "%NewVersion_Comm%" goto :SetOtherInfo
if "%NewVersion_Comm%" equ "2.5" (
	echo Oagmom migration not available with new Comm version %NewVersion_Comm%.
	goto :SetOtherInfo
)
set /p DoOagmom="Upgrade Oagmom? [y/n]:"
if "%DoOagmom%" neq "y" (
	if "%DoOagmom%" neq "n" (
		echo Invalid input.
		goto :SetOagmom
	)
)
echo ==Database Setting End==

:SetOtherInfo
echo ==Other Information Setting Start==
REM ****temporary setting for test****
REM set CustomerName=standard
REM set ImportCloneFamily=cjl
REM set ETSServer=D:\Eterra\e-terrasource\Server
REM set RioDirectory=D:\users\cjl\Migration
REM set InputSavecaseDirectory=D:\users\cjl\old_Savecases
REM set OutputSavecaseDirectory=D:\users\cjl\new_Savecases
REM cls
REM goto :Confirm
REM ****temporary setting for test**** End
:SetCustomerName
set /p CustomerName="Input customer name(put 'standard' if not for customer): "
REM Import Clone family
set /p ImportCloneFamily="Input import clone family name:"
REM ETS Server location
:SetETSServer
set /p ETSServer="Input ETS Server location:"
if not exist %ETSServer% (
	echo File not exist.
	goto :SetETSServer
)
:SetRioDirectory
REM RioDirectory
set /p RioDirectory="Input Rio file directory:"
if not exist %RioDirectory% (
	echo File not exist.
	goto :SetRioDirectory
)
REM InputSavecaseDirectory
:SetInputSavecaseDirectory
set /p InputSavecaseDirectory="Input Import savecase directory:"
if not exist %InputSavecaseDirectory% (
	echo File not exist.
	goto :SetInputSavecaseDirectory
)
REM OutputSavecaseDirectory
set /p OutputSavecaseDirectory="Input Export savecase directory:"
echo ==Other Information Setting End==
cls
:Confirm
echo == Please confirm the upgrade information ==
echo =========================================================================
echo +++++ Version Setting +++++
if "%DoHabitat%" equ "y" echo Habitat:   %OrigVersion_Habitat%  -  %NewVersion_Habitat% 
if "%DoHabitat%" equ "n" echo Habitat:     No Change 
if "%DoEMP%" equ "y" echo EMP:       %OrigVersion_EMP%  -  %NewVersion_EMP% 
if "%DoEMP%" equ "n" echo EMP:         No Change 
if "%DoScada%" equ "y" echo Scada:     %OrigVersion_Scada%  -  %NewVersion_Scada% 
if "%DoScada%" equ "n" echo Scada:       No Change 
if "%DoComm%" equ "y" echo Comm:      %OrigVersion_Comm%  -  %NewVersion_Comm% 
if "%DoComm%" equ "n" echo Comm:        No Change 
echo +++++ Database Setting +++++
echo    Alarm   %DoAlarm%   ^|   AlarmDef   %DoAlarmDef%   ^|
echo    Ctgs    %DoCtgs%   ^|     Dtsmom   %DoDtsmom%   ^|    Dydef   %DoDydef%   ^|
echo   Dynrtg   %DoDynrtg%   ^|     Genmom   %DoGenmom%   ^|    Hymom   %DoHymom%   ^|
echo   Netmom   %DoNetmom%   ^|     Rasmom   %DoRasmom%   ^|   Resmom   %DoResmom%   ^|   Rgalm    %DoRgalm%   ^|
echo  Scadamom  %DoScadamom%   ^|    Tagging   %DoTagging%   ^|    
echo   Oagmom   %DoOagmom%   ^|
echo +++++ Other Infomation Setting +++++
echo Customer Name :     %CustomerName%
echo Import Clone Family:   %ImportCloneFamily%
echo ETSServer Location:   %ETSServer%
echo Rio File Directory:   %RioDirectory%
echo Import Savecase Directory: %InputSavecaseDirectory%
echo Export Savecase Directory: %OutputSavecaseDirectory%
echo =========================================================================
:EnsureConfirm
set /p Confirmed="Information confirmed. Continue? [y/n]:"
if "%Confirmed%" neq "y" (
	if "%Confirmed%" neq "n" (
		echo Invalid input.
		goto :EnsureConfirm
	)
)
if "%Confirmed%" equ "n" exit

rem ########################  Interacitve Setting Part End ############
REM ########################  Upgrading Part Start ###################
cls
echo Start upgrading...
REM According to the chosen information, determine required clones
REM This function will provide value to variables: Upgrade*CloneName* e.g. UpgradeNetmom=0, UpgradeAlarm=1
call :SetRequiredClones

REM Script parameters, to modify if needed
set SavecaseType=%CustomerName%
set UpdatedSavecaseType=%CustomerName%

REM Launch the HABITAT manager batch file
call %HABITAT_MANAGER%\habitat_define_user_env.bat

REM --- Create/Update Import Modeling Clones ---
echo -- Create or update the Import modelling clones -- Begin
@echo off
call :CreateModellingClones %ImportCloneFamily%
if %errorlevel%==1 goto :ErrorExit
echo -- Create or update the Import modelling clones -- End
@echo off

REM --- Copy the savecases to the import clones ---
echo -- Copy the savecases to the import clones -- Begin
@echo off
if %UpgradeAlarm% equ 1 (
	call hdbcopydata -sf %InputSavecaseDirectory%\case_alarm_ade.%SavecaseType% -d alarm.%ImportCloneFamily%
	call :VerifyHabitatCommand
	if %errorlevel%==1 goto :ErrorExit
)
if %UpgradeScadamdl% equ 1 (
	call hdbcopydata -sf %InputSavecaseDirectory%\case_scadamdl_ade.%SavecaseType% -d scadamdl.%ImportCloneFamily%
	call :VerifyHabitatCommand
	if %errorlevel%==1 goto :ErrorExit
)
if %UpgradeNetmodel% equ 1 (
	call hdbcopydata -sf %InputSavecaseDirectory%\case_netmodel_ade.%SavecaseType% -d netmodel.%ImportCloneFamily%
	call :VerifyHabitatCommand
	if %errorlevel%==1 goto :ErrorExit
)
if %UpgradeGenmodel% equ 1 (
	call hdbcopydata -sf %InputSavecaseDirectory%\case_genmodel_ade.%SavecaseType% -d genmodel.%ImportCloneFamily%
	call :VerifyHabitatCommand
	if %errorlevel%==1 goto :ErrorExit
)
if %UpgradeDtsmodel% equ 1 (
	call hdbcopydata -sf %InputSavecaseDirectory%\case_dtsmodel_ade.%SavecaseType% -d dtsmodel.%ImportCloneFamily%
	call :VerifyHabitatCommand
	if %errorlevel%==1 goto :ErrorExit	
)
if %UpgradeTagging% equ 1 (
	call hdbcopydata -sf %InputSavecaseDirectory%\case_tagging_ade.%SavecaseType% -d tagging.%ImportCloneFamily%
	call :VerifyHabitatCommand
	if %errorlevel%==1 goto :ErrorExit
)
if %UpgradeOagmodel% equ 1 (
	call hdbcopydata -sf %InputSavecaseDirectory%\case_oagmodel_ade.%SavecaseType% -d oagmodel.%ImportCloneFamily%
	call :VerifyHabitatCommand
	if %errorlevel%==1 goto :ErrorExit
)
echo -- Copy the savecases to the import clones -- End
@echo off

rem --- Run EMP/HABITAT/Scada/Comm upgrade ---
echo -- Run EMP/HABITAT/Scada/Comm upgrade -- Begin
@echo off
if "%DoAlarm%" equ "y" call :UpgradeDatabase alarm
if %errorlevel%==1 goto :ErrorExit
if "%DoAlarmDef%" equ "y" call :UpgradeDatabase alarmdef
if %errorlevel%==1 goto :ErrorExit
if "%DoCtgs%" equ "y" call :UpgradeDatabase ctgs
if %errorlevel%==1 goto :ErrorExit
if "%DoDtsmom%" equ "y" call :UpgradeDatabase dtsmom
if %errorlevel%==1 goto :ErrorExit
if "%DoDydef%" equ "y" call :UpgradeDatabase dydef
if %errorlevel%==1 goto :ErrorExit
if "%DoDynrtg%" equ "y" call :UpgradeDatabase dynrtg
if %errorlevel%==1 goto :ErrorExit
if "%DoGenmom%" equ "y" call :UpgradeDatabase genmom
if %errorlevel%==1 goto :ErrorExit
if "%DoHymom%" equ "y" call :UpgradeDatabase hymom
if %errorlevel%==1 goto :ErrorExit
if "%DoNetmom%" equ "y" call :UpgradeDatabase netmom
if %errorlevel%==1 goto :ErrorExit
if "%DoRasmom%" equ "y" call :UpgradeDatabase rasmom
if %errorlevel%==1 goto :ErrorExit
if "%DoResmom%" equ "y" call :UpgradeDatabase resmom
if %errorlevel%==1 goto :ErrorExit
if "%DoRgalm%" equ "y" call :UpgradeDatabase rgalm
if %errorlevel%==1 goto :ErrorExit
if "%DoScadamom%" equ "y" call :UpgradeDatabase scadamom
if %errorlevel%==1 goto :ErrorExit
if "%DoTagging%" equ "y" call :UpgradeDatabase tagging
if %errorlevel%==1 goto :ErrorExit
if "%DoOagmom%" equ "y" call :UpgradeDatabase oagmom
if %errorlevel%==1 goto :ErrorExit
rem For GENMIGRATE
REM echo ---GENMIGRATE--- >> .\log\%SavecaseType%_UpgradeRIO.log 
REM @echo off
REM call context genmodel %ImportCloneFamily%
REM call genmigrate >> .\log\%SavecaseType%_UpgradeRIO.log 2>&1
REM @echo off
echo -- Run EMP/HABITAT/Scada/Comm upgrade -- End
@echo off

rem ---  customer upgrade ---
echo -- Run customer upgrade -- Start
@echo off
if "%DoAlarm%" equ "y" call :CustomerUpgrade alarm %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoAlarmDef%" equ "y" call :CustomerUpgrade alarmdef %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoCtgs%" equ "y" call :CustomerUpgrade ctgs %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoDtsmom%" equ "y" call :CustomerUpgrade dtsmom %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoDydef%" equ "y" call :CustomerUpgrade dydef %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoDynrtg%" equ "y" call :CustomerUpgrade dynrtg %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoGenmom%" equ "y" call :CustomerUpgrade genmom %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoHymom%" equ "y" call :CustomerUpgrade hymom %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoNetmom%" equ "y" call :CustomerUpgrade netmom %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoRasmom%" equ "y" call :CustomerUpgrade rasmom %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoResmom%" equ "y" call :CustomerUpgrade resmom %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoRgalm%" equ "y" call :CustomerUpgrade rgalm %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoScadamom%" equ "y" call :CustomerUpgrade scadamom %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoTagging%" equ "y" call :CustomerUpgrade tagging %CustomerName%
if %errorlevel%==1 goto :ErrorExit
if "%DoOagmom%" equ "y" call :CustomerUpgrade oagmom %CustomerName%
if %errorlevel%==1 goto :ErrorExit
echo -- Run customer upgrade -- End
@echo off

rem --- Verify that there is no duplicate OIDs ---
call :CheckDuplicateOIDs
if %errorlevel%==1 goto :ErrorExit

rem --- Verify that all the validators are still successful ---
call :ValidateDatabases BeforeModelUpdate
if %errorlevel%==1 goto :ErrorExit

rem --- Update initial models with HDBRIO scripts ---
echo -- Update the initial model with the HDBRIO scripts -- Begin
@echo off
if "%DoAlarm%" equ "y" call :UpdateDatabase alarm
if %errorlevel%==1 goto :ErrorExit
if "%DoAlarmDef%" equ "y" call :UpdateDatabase alarmdef 
if %errorlevel%==1 goto :ErrorExit
if "%DoCtgs%" equ "y" call :UpdateDatabase ctgs 
if %errorlevel%==1 goto :ErrorExit
if "%DoDtsmom%" equ "y" call :UpdateDatabase dtsmom 
if %errorlevel%==1 goto :ErrorExit
if "%DoDydef%" equ "y" call :UpdateDatabase dydef 
if %errorlevel%==1 goto :ErrorExit
if "%DoDynrtg%" equ "y" call :UpdateDatabase dynrtg 
if %errorlevel%==1 goto :ErrorExit
if "%DoGenmom%" equ "y" call :UpdateDatabase genmom 
if %errorlevel%==1 goto :ErrorExit
if "%DoHymom%" equ "y" call :UpdateDatabase hymom 
if %errorlevel%==1 goto :ErrorExit
if "%DoNetmom%" equ "y" call :UpdateDatabase netmom 
if %errorlevel%==1 goto :ErrorExit
if "%DoRasmom%" equ "y" call :UpdateDatabase rasmom 
if %errorlevel%==1 goto :ErrorExit
if "%DoResmom%" equ "y" call :UpdateDatabase resmom 
if %errorlevel%==1 goto :ErrorExit
if "%DoRgalm%" equ "y" call :UpdateDatabase rgalm 
if %errorlevel%==1 goto :ErrorExit
if "%DoScadamom%" equ "y" call :UpdateDatabase scadamom 
if %errorlevel%==1 goto :ErrorExit
if "%DoTagging%" equ "y" call :UpdateDatabase tagging 
if %errorlevel%==1 goto :ErrorExit
if "%DoOagmom%" equ "y" call :UpdateDatabase oagmom 
if %errorlevel%==1 goto :ErrorExit
echo -- Update the initial model with the HDBRIO scripts -- End
@echo off

rem --- Verify that there is no duplicate OIDs ---
call :CheckDuplicateOIDs
if %errorlevel%==1 goto :ErrorExit

rem --- Verify that all the validators are still successful ---
call :ValidateDatabases AfterModelUpdate
if %errorlevel%==1 goto :ErrorExit

rem --- Create a new set of savecases for ETS to Import
echo -- Create a new set of savecases (%UpdatedSavecaseType%) for ETS to Import -- Begin
@echo off
call :CreateSavecases %UpdatedSavecaseType%
if %errorlevel%==1 goto :ErrorExit
echo -- Create a new set of savecases (%UpdatedSavecaseType%) for ETS to Import -- End
@echo off
echo Migration is completed.
pause
goto :SafeExit
REM ########################  Upgrading Part End ###################

REM ####################################### Internal function start ###########################################
:ValidateDatabases
echo -- Verify that all the validators are successful -- Begin
@echo off
set MLF_HABLOGS_TO_STDOUT=1
rem ALARMVAL
call context alarm %ImportCloneFamily%
@echo off
echo ---ALARMVAL--- > .\log\%SavecaseType%_%1.log
@echo off
call alarmval >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
rem SMVERIFY
call context scadamdl %ImportCloneFamily%
@echo off
echo ---SMVERIFY--- >> .\log\%SavecaseType%_%1.log
@echo off
call smverify >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
rem NETVALID/CAVALID
call context netmodel %ImportCloneFamily%
@echo off
echo ---NETVALID--- >> .\log\%SavecaseType%_%1.log
@echo off
call netvalid >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
echo ---CAVALID--- >> .\log\%SavecaseType%_%1.log
@echo off
call cavalid >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
rem GMDRIVER/RESMONVERIFY
call context genmodel %ImportCloneFamily%
@echo off
echo ---GMDRIVER--- >> .\log\%SavecaseType%_%1.log
@echo off
call gmdriver >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
echo ---RESMONVERIFY--- >> .\log\%SavecaseType%_%1.log
@echo off
call resmonverify >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
rem SCADAMAP/GENMAP
call context netmodel %ImportCloneFamily%
@echo off
echo ---SCADAMAP--- >> .\log\%SavecaseType%_%1.log
@echo off
call scadamap >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
echo ---GENMAP--- >> .\log\%SavecaseType%_%1.log
@echo off
call genmap >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
rem NETUP/GENUP/DYMODVAL/RYMODVAL/DTSMAP
call context dtsmodel %ImportCloneFamily%
@echo off
echo ---NETUP--- >> .\log\%SavecaseType%_%1.log
@echo off
call netup >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
echo ---GENUP--- >> .\log\%SavecaseType%_%1.log
@echo off
call genup >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
echo ---DYMODVAL--- >> .\log\%SavecaseType%_%1.log
@echo off
call dymodval >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
echo ---RYMODVAL--- >> .\log\%SavecaseType%_%1.log
@echo off
call rymodval >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
echo ---DTSMAP--- >> .\log\%SavecaseType%_%1.log
@echo off
call dtsmap >> .\log\%SavecaseType%_%1.log 2>&1
call :VerifyLog .\log\%SavecaseType%_%1.log
if %errorlevel%==1 goto :ErrorExit
echo -- Verify that all the validators are successful -- End
@echo off
set MLF_HABLOGS_TO_STDOUT=
goto :SafeExit

:CreateSavecases
REM for alarm
if %UpgradeAlarm% equ 1 (
	call hdbcopydata -case ade.%1 -location %OutputSavecaseDirectory% -s alarm.%ImportCloneFamily% > .\log\%SavecaseType%_CreateSavecases_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateSavecases_%1.log
	if %errorlevel%==1 goto :ErrorExit
)
REM for scadamdl
if %UpgradeScadamdl% equ 1 (
	call hdbcopydata -case ade.%1 -location %OutputSavecaseDirectory% -s scadamdl.%ImportCloneFamily% >> .\log\%SavecaseType%_CreateSavecases_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateSavecases_%1.log
	if %errorlevel%==1 goto :ErrorExit
)
REM for netmodel
if %UpgradeNetmodel% equ 1 (
	call hdbcopydata -case ade.%1 -location %OutputSavecaseDirectory% -s netmodel.%ImportCloneFamily% >> .\log\%SavecaseType%_CreateSavecases_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateSavecases_%1.log
	if %errorlevel%==1 goto :ErrorExit
)
REM for genmodel
if %UpgradeGenmodel% equ 1 (
	call hdbcopydata -case ade.%1 -location %OutputSavecaseDirectory% -s genmodel.%ImportCloneFamily% >> .\log\%SavecaseType%_CreateSavecases_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateSavecases_%1.log
	if %errorlevel%==1 goto :ErrorExit
)
REM for dtsmodel
if %UpgradeDtsmodel% equ 1 (
	call hdbcopydata -case ade.%1 -location %OutputSavecaseDirectory% -s dtsmodel.%ImportCloneFamily% >> .\log\%SavecaseType%_CreateSavecases_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateSavecases_%1.log
	if %errorlevel%==1 goto :ErrorExit
)
REM for tagging
if %UpgradeTagging% equ 1 (
	call hdbcopydata -case ade.%1 -location %OutputSavecaseDirectory% -s tagging.%ImportCloneFamily% >> .\log\%SavecaseType%_CreateSavecases_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateSavecases_%1.log
	if %errorlevel%==1 goto :ErrorExit
)
REM for oagmodel
if %UpgradeOagmodel% equ 1 (
	call hdbcopydata -case ade.%1 -location %OutputSavecaseDirectory% -s oagmodel.%ImportCloneFamily% >> .\log\%SavecaseType%_CreateSavecases_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateSavecases_%1.log
	if %errorlevel%==1 goto :ErrorExit
)
goto :SafeExit

:CheckDuplicateOIDs
echo -- Verify that there is no duplicate OIDs in the %ImportCloneFamily% set of modeling clones -- Begin
@echo off
perl %ETSServer%\find_duplicate_oids.pl -f %ImportCloneFamily% 2>NUL
findstr /M /C:" = 0" zero_duplicate_oids.bat
if %errorlevel%==0 (
    echo Reset the duplicate OIDS for the %ImportCloneFamily% modeling clones
    @echo off
    call zero_duplicate_oids.bat
)
del /F zero_duplicate_oids.bat
rem Reset the OIDs which were duplicates
if "%DoAlarm%" equ "y" call :ResetOIDs alarm 
if %errorlevel%==1 goto :ErrorExit
if "%DoAlarmDef%" equ "y" call :ResetOIDs alarmdef 
if %errorlevel%==1 goto :ErrorExit
if "%DoCtgs%" equ "y" call :ResetOIDs ctgs 
if %errorlevel%==1 goto :ErrorExit
if "%DoDtsmom%" equ "y" call :ResetOIDs dtsmom 
if %errorlevel%==1 goto :ErrorExit
if "%DoDydef%" equ "y" call :ResetOIDs dydef 
if %errorlevel%==1 goto :ErrorExit
if "%DoDynrtg%" equ "y" call :ResetOIDs dynrtg 
if %errorlevel%==1 goto :ErrorExit
if "%DoGenmom%" equ "y" call :ResetOIDs genmom 
if %errorlevel%==1 goto :ErrorExit
if "%DoHymom%" equ "y" call :ResetOIDs hymom 
if %errorlevel%==1 goto :ErrorExit
if "%DoNetmom%" equ "y" call :ResetOIDs netmom 
if %errorlevel%==1 goto :ErrorExit
if "%DoRasmom%" equ "y" call :ResetOIDs rasmom 
if %errorlevel%==1 goto :ErrorExit
if "%DoResmom%" equ "y" call :ResetOIDs resmom 
if %errorlevel%==1 goto :ErrorExit
if "%DoRgalm%" equ "y" call :ResetOIDs rgalm 
if %errorlevel%==1 goto :ErrorExit
if "%DoScadamom%" equ "y" call :ResetOIDs scadamom 
if %errorlevel%==1 goto :ErrorExit
if "%DoTagging%" equ "y" call :ResetOIDs tagging 
if %errorlevel%==1 goto :ErrorExit
if "%DoOagmom%" equ "y" call :ResetOIDs oagmom
if %errorlevel%==1 goto :ErrorExit
echo -- Verify that there is no duplicate OIDs in the %ImportCloneFamily% set of modeling clones -- End
@echo off
goto :SafeExit

:CreateModellingClones
if %UpgradeAlarm% equ 1 (
	echo ---ALARM--- > .\log\%SavecaseType%_CreateModelingClones_%1.log
	@echo off
	hdbcloner -c create_clone -a alarm -f %1 -replace >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateModelingClones_%1.log
	if %errorlevel%==1 goto:ErrorExit
)
if %UpgradeScadamdl% equ 1 (
	echo ---SCADAMDL--- >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	@echo off
	hdbcloner -c create_clone -a scadamdl -f %1 -replace >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateModelingClones_%1.log
	if %errorlevel%==1 goto:ErrorExit
)
if %UpgradeNetmodel% equ 1 (
	echo ---NETMODEL--- >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	@echo off
	hdbcloner -c create_clone -a netmodel -f %1 -replace >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateModelingClones_%1.log
	if %errorlevel%==1 goto:ErrorExit
)
if %UpgradeGenmodel% equ 1 (
	echo ---GENMODEL--- >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	@echo off
	hdbcloner -c create_clone -a genmodel -f %1 -replace >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateModelingClones_%1.log
	if %errorlevel%==1 goto:ErrorExit
)
if %UpgradeDtsmodel% equ 1 (
	echo ---DTSMODEL--- >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	@echo off
	hdbcloner -c create_clone -a dtsmodel -f %1 -replace >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateModelingClones_%1.log
	if %errorlevel%==1 goto:ErrorExit
)
if %UpgradeTagging% equ 1 (
	echo ---Tagging--- >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	@echo off
	hdbcloner -c create_clone -a tagging -f %1 -replace >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateModelingClones_%1.log
	if %errorlevel%==1 goto:ErrorExit
) 
if %UpgradeOagmodel% equ 1 (
	echo ---Oagmodel--- >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	@echo off
	hdbcloner -c create_clone -a oagmodel -f %1 -replace >> .\log\%SavecaseType%_CreateModelingClones_%1.log
	call :VerifyHabitatCommand .\log\%SavecaseType%_CreateModelingClones_%1.log
	if %errorlevel%==1 goto:ErrorExit
) 
goto :SafeExit

:VerifyLog
rem Verify that the validator is successful
echo -- Verify that the validator is successful -- Begin
@echo off
REM *** verify method issue***
REM findstr /M /C:" successfully " %1
REM if %errorlevel%==0 (
	REM echo The Validator is successful
	REM echo -- Verify that the validator is successful -- End
	REM echo -- Verify that all the validators are successful -- End
	REM @echo off
	REM goto :SafeExit
REM )
REM *** verify method issue***
findstr /M /C:" F: " %1
if %errorlevel%==0 (
    echo ERROR: The Validator is not successful
	echo -- Verify that the validator is successful -- End
	echo -- Verify that all the validators are successful -- End
    @echo off
    start notepad ".\%1"
    goto :ErrorExit
)
findstr /M /C:" E: " %1
if %errorlevel%==0 (
    echo ERROR: The Validator is not successful
	echo -- Verify that the validator is successful -- End
	echo -- Verify that all the validators are successful -- End
    @echo off
    start notepad ".\%1"
    goto :ErrorExit
)
echo -- Verify that the validator is successful -- End
@echo off
goto :SafeExit

:VerifyHabitatCommand
rem Verify that the HABITAT command was successful
echo -- Verify that the HABITAT command was successful -- Begin
@echo off
if %errorlevel% neq 0 (
    echo ERROR: The previous HABITAT command was not successful
	echo -- Verify that the HABITAT command was successful -- End
    @echo off
    goto :ErrorExit
)
IF [%1]==[] goto :SkipFileCheck
findstr /M /C:"Error executing" %1
if %errorlevel%==0 (
    echo ERROR: The previous HABITAT command was not successful
	echo -- Verify that the HABITAT command was successful -- End
    @echo off
    start notepad ".\%1"
    goto :ErrorExit
)
findstr /M /C:"completed with errors" %1
if %errorlevel%==0 (
    echo ERROR: The previous HABITAT command was not successful
	echo -- Verify that the HABITAT command was successful -- End
    @echo off
    start notepad ".\%1"
    goto :ErrorExit
)
findstr /M /C:"cannot find another record" %1
if %errorlevel%==0 (
    echo ERROR: The previous HABITAT command was not successful
	echo -- Verify that the HABITAT command was successful -- End
    @echo off
    start notepad ".\%1"
    goto :ErrorExit
)
findstr /M /C:"Syntax error cmd not found" %1
if %errorlevel%==0 (
    echo ERROR: The previous HABITAT command was not successful
	echo -- Verify that the HABITAT command was successful -- End
    @echo off
    start notepad ".\%1"
    goto :ErrorExit
)

:SkipFileCheck
echo -- Verify that the HABITAT command was successful -- End
@echo off
goto :SafeExit



REM ######################################## Added functions ##########################################
REM This function set all the versions data into arrays so that we can call as HabitatVersions[0]
:SetIntoArray
set idx1=0
for %%a in (%_HabitatVersions%) do (
	set HabitatVersions[!idx1!]=%%a
	set /A idx1+=1
)
set idx2=0
for %%a in (%_EMPVersions%) do (
	set EMPVersions[!idx2!]=%%a
	set /A idx2+=1
)
set idx3=0
for %%a in (%_ScadaVersions%) do (
	set ScadaVersions[!idx3!]=%%a
	set /A idx3+=1
)
set idx4=0
for %%a in (%_CommVersions%) do (
	set CommVersions[!idx4!]=%%a
	set /A idx4+=1
)
goto :eof

REM This function encode version string that serves for both display and validation
REM based on the information that user input
REM Params: %1 Version Type
REM Params: %2 Version string that need to be returned
REM Params: %3 Chosen original version, -1 if not chosen
:GetVersionsString
setlocal EnableDelayedExpansion
set VersionStr=
set VersionsArray=
if %1 equ "Habitat" set VersionsArray=%_HabitatVersions%
if %1 equ "EMP" set VersionsArray=%_EMPVersions%
if %1 equ "Scada" set VersionsArray=%_ScadaVersions%
if %1 equ "Comm" set VersionsArray=%_CommVersions%
set /A flag=0
for %%a in (%VersionsArray%) do (
	REM if original version has not been chosen, concat all versions
	if %3 equ -1 (
		if !flag! equ 0 (
			set VersionStr=%%a
			set /A flag=1
		) else (
			set VersionStr=!VersionStr!^/%%a
		)
	) else (
	REM if original version has been chosen, concat versions that are behind chosen original version
		if !flag! equ 0 (
			if %3 equ %%a (
				set /A flag=1
				set VersionStr=%%a
			)
		) else (
			set VersionStr=!VersionStr!^/%%a
		)
	)
)
( endlocal
	set %2=%VersionStr%
)
goto :eof

REM this function determines whether the clone need to be upgrade
REM based on the information that user input
:SetRequiredClones
set /A UpgradeAlarm=0
set /A UpgradeScadamdl=0
set /A UpgradeNetmodel=0
set /A UpgradeGenmodel=0
set /A UpgradeDtsmodel=0
set /A UpgradeTagging=0
set /A UpgradeOagmodel=0
if "%DoAlarm%%DoAlarmDef%" neq "nn" (
	set /A UpgradeAlarm=1
)
if "%DoDtsmom%%DoDydef%" neq "nn" (
	set /A UpgradeDtsmodel=1
) 
if "%DoGenmom%%DoRgalm%%DoResmom%%DoHymom%" neq "nnnn" (
	set /A UpgradeGenmodel=1
)
if "%DoNetmom%%DoRasmom%%DoCtgs%%DoDynrtg%" neq "nnnn" (
	set /A UpgradeNetmodel=1
)
if "%DoScadamom%" neq "n" set /A UpgradeScadamdl=1
if "%DoTagging%" neq "n" set /A UpgradeTagging=1
if "%DoOagmom%" neq "n" set /A UpgradeOagmodel=1
goto :eof

REM This function do standard version upgrade on specified database
REM Params: %1 database name 
:UpgradeDatabase
setlocal EnableDelayedExpansion
REM set parameters for each database upgrade
if "%1" equ "alarm" (
	set app=alarm
	set startVersion=%OrigVersion_Habitat%
	set endVersion=%NewVersion_Habitat%
	set versionSequence=%_HabitatVersions%
)
if "%1" equ "alarmdef" (
	set app=alarm
	set startVersion=%OrigVersion_Habitat%
	set endVersion=%NewVersion_Habitat%
	set versionSequence=%_HabitatVersions%
)
if "%1" equ "ctgs" (
	set app=netmodel
	set startVersion=%OrigVersion_EMP%
	set endVersion=%NewVersion_EMP%
	set versionSequence=%_EMPVersions%
)
if "%1" equ "dtsmom" (
	set app=dtsmodel
	set startVersion=%OrigVersion_EMP%
	set endVersion=%NewVersion_EMP%
	set versionSequence=%_EMPVersions%
)
if "%1" equ "dydef" (
	set app=dtsmodel
	set startVersion=%OrigVersion_EMP%
	set endVersion=%NewVersion_EMP%
	set versionSequence=%_EMPVersions%
)
if "%1" equ "dynrtg" (
	set app=netmodel
	set startVersion=%OrigVersion_EMP%
	set endVersion=%NewVersion_EMP%
	set versionSequence=%_EMPVersions%
)
if "%1" equ "genmom" (
	set app=genmodel
	set startVersion=%OrigVersion_EMP%
	set endVersion=%NewVersion_EMP%
	set versionSequence=%_EMPVersions%
)
if "%1" equ "hymom" (
	set app=genmodel
	set startVersion=%OrigVersion_EMP%
	set endVersion=%NewVersion_EMP%
	set versionSequence=%_EMPVersions%
)
if "%1" equ "netmom" (
	set app=netmodel
	set startVersion=%OrigVersion_EMP%
	set endVersion=%NewVersion_EMP%
	set versionSequence=%_EMPVersions%
)
if "%1" equ "rasmom" (
	set app=netmodel
	set startVersion=%OrigVersion_EMP%
	set endVersion=%NewVersion_EMP%
	set versionSequence=%_EMPVersions%
)
if "%1" equ "resmom" (
	set app=genmodel
	set startVersion=%OrigVersion_EMP%
	set endVersion=%NewVersion_EMP%
	set versionSequence=%_EMPVersions%
)
if "%1" equ "rgalm" (
	set app=genmodel
	set startVersion=%OrigVersion_EMP%
	set endVersion=%NewVersion_EMP%
	set versionSequence=%_EMPVersions%
)
if "%1" equ "scadamom" (
	set app=scadamdl
	set startVersion=%OrigVersion_Scada%
	set endVersion=%NewVersion_Scada%
	set versionSequence=%_ScadaVersions%
)
if "%1" equ "tagging" (
	set app=tagging
	set startVersion=%OrigVersion_Scada%
	set endVersion=%NewVersion_Scada%
	set versionSequence=%_ScadaVersions%
)
if "%1" equ "oagmom" (
	set app=oagmodel
	set startVersion=%OrigVersion_Comm%
	set endVersion=%NewVersion_Comm%
	set versionSequence=%_CommVersions%
)
REM database upgrade
echo --- %1 --- >> .\log\%SavecaseType%_UpgradeRIO.log
@echo off
set RioFile=%RioDirectory%\%startVersion%_%endVersion%_upgrade_%1.rio
REM If upgrade file can be found directly, use that file; 
REM Otherwise, find sub-file based on upgrade sequence. 
if not exist %RioFile% (
	REM try to find sub-file with unit version gap based on upgrade sequence
	set flag=0
	for %%a in (%versionSequence%) do (
		if !flag! equ 1 (
			set RioFile=%RioDirectory%\!prev!_%%a_upgrade_%1.rio
			if not exist !RioFile! (
				echo Error: Can't find file !prev!_%%a_upgrade_%1.rio >> .\log\%SavecaseType%_UpgradeRIO.log
				goto :ErrorExit
			)
			call hdbrio -f %ImportCloneFamily% -a %app% -i !RioFile! %1 >> .\log\%SavecaseType%_UpgradeRIO.log 2>&1
			call :VerifyHabitatCommand .\log\%SavecaseType%_UpgradeRIO.log
			if %errorlevel%==1 goto :ErrorExit
		)
		set prev=%%a
		if %%a equ %startVersion% set flag=1
		if %%a equ %endVersion% set flag=0
	)
) else (
	REM Use that file directly
	call hdbrio -f %ImportCloneFamily% -a %app% -i %RioFile% %1 >>.\log\%SavecaseType%_UpgradeRIO.log 2>&1
	call :VerifyHabitatCommand .\log\%SavecaseType%_UpgradeRIO.log
	if %errorlevel%==1 goto :ErrorExit
)
endlocal
goto :SafeExit

REM This function do customer upgrade on specified database
REM Params: %1 database name 
REM Params: %2 customer name 
:CustomerUpgrade
echo --- %1 --- >> .\log\%SavecaseType%_UpgradeRIO.log
@echo off
setlocal EnableDelayedExpansion
REM set parameters for each customer upgrade
if "%1" equ "alarm" set app=alarm
if "%1" equ "alarmdef" set app=alarm
if "%1" equ "ctgs" set app=netmodel
if "%1" equ "dtsmom" set app=dtsmodel
if "%1" equ "dydef" set app=dtsmodel
if "%1" equ "dynrtg" set app=netmodel
if "%1" equ "genmom" set app=genmodel
if "%1" equ "hymom" set app=genmodel
if "%1" equ "netmom" set app=netmodel
if "%1" equ "rasmom" set app=netmodel
if "%1" equ "resmom" set app=genmodel
if "%1" equ "rgalm" set app=genmodel
if "%1" equ "scadamom" set app=scadamdl
if "%1" equ "tagging" set app=tagging
if "%1" equ "oagmom" set app=oagmodel
set custName=%2
REM if the customer file exists, do database upgrade
set RioFile=%RioDirectory%\%custName%_upgrade_%1.rio 
if exist %RioFile% (
	call hdbrio -f %ImportCloneFamily% -a %app% -i %RioFile% %1 >> .\log\%SavecaseType%_UpgradeRIO.log 2>&1
	call :VerifyHabitatCommand .\log\%SavecaseType%_UpgradeRIO.log
	if %errorlevel%==1 goto :ErrorExit
) else (
	echo Warning: %RioFile% not found. Customer upgrade canceled for %1. >> .\log\%SavecaseType%_UpgradeRIO.log
)
endlocal
goto :SafeExit

REM This function will update database
REM Params: %1 database name 
:UpdateDatabase
echo --- %1 --- >> .\log\%SavecaseType%_UpdateRIO.log
@echo off
setlocal EnableDelayedExpansion
if "%1" equ "alarm" set app=alarm
if "%1" equ "alarmdef" set app=alarm
if "%1" equ "ctgs" set app=netmodel
if "%1" equ "dtsmom" set app=dtsmodel
if "%1" equ "dydef" set app=dtsmodel
if "%1" equ "dynrtg" set app=netmodel
if "%1" equ "genmom" set app=genmodel
if "%1" equ "hymom" set app=genmodel
if "%1" equ "netmom" set app=netmodel
if "%1" equ "rasmom" set app=netmodel
if "%1" equ "resmom" set app=genmodel
if "%1" equ "rgalm" set app=genmodel
if "%1" equ "scadamom" set app=scadamdl
if "%1" equ "tagging" set app=tagging
if "%1" equ "oagmom" set app=oagmodel
set RioFile=%RioDirectory%\update_%1.rio
if exist %RioFile% (
	call hdbrio -f %ImportCloneFamily% -a %app% -i %RioDirectory%\update_%1.rio %1 >> .\log\%SavecaseType%_UpdateRIO.log 2>&1
	call :VerifyHabitatCommand .\log\%SavecaseType%_UpdateRIO.log
	if %errorlevel%==1 goto :ErrorExit
) else (
	echo Warning: %RioFile% not found. %1 update canceled. >> .\log\%SavecaseType%_UpdateRIO.log
)
endlocal
goto :SafeExit


REM This function will reset the duplicate OIDs in specified database
REM Params: %1 database name 
:ResetOIDs
setlocal EnableDelayedExpansion
rem set application
if "%1" equ "alarm" set app=alarm
if "%1" equ "alarmdef" set app=alarm
if "%1" equ "ctgs" set app=netmodel
if "%1" equ "dtsmom" set app=dtsmodel
if "%1" equ "dydef" set app=dtsmodel
if "%1" equ "dynrtg" set app=netmodel
if "%1" equ "genmom" set app=genmodel
if "%1" equ "hymom" set app=genmodel
if "%1" equ "netmom" set app=netmodel
if "%1" equ "rasmom" set app=netmodel
if "%1" equ "resmom" set app=genmodel
if "%1" equ "rgalm" set app=genmodel
if "%1" equ "scadamom" set app=scadamdl
if "%1" equ "tagging" set app=tagging
if "%1" equ "oagmom" set app=oagmodel
rem Reset the OIDs which were duplicates
call hdbrio -f %ImportCloneFamily% -a %app% -c "reset -o" %1 > .\log\%SavecaseType%_ResetOIDs.log
call :VerifyHabitatCommand .\log\%SavecaseType%_ResetOIDs.log
if %errorlevel%==1 goto :ErrorExit

endlocal
goto :SafeExit

REM This function validate the input orginal version and new version
REM Params: %1 Chosen version
REM Params: %2 Remaining version string
:ValidateVersionChoice
set wholeStr=%2
REM not for external use
:SubValidateVersionChoice
for /F "tokens=1* delims=/" %%a in ("%wholeStr%") do (
	set wholeStr=%%b
	if %1 equ %%a exit /B 0
)
if defined wholeStr goto :SubValidateVersionChoice
exit /B 1

:SafeExit
EXIT /B 0

:ErrorExit
echo something is wrong...
pause
EXIT /B 1