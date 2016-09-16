$PassedTestArray = @()
$FailedTestArray = @()
$SkippedTestArray = New-Object System.Collections.Generic.HashSet[string]
###############################################################################
# Miscellaneous helper functions
#
# Externally callable
# SVPP-Testing
###############################################################################
function SVPP-Testing {
	 Param 
    ( 
        # The input file to be updated
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [string]$Workspace,
		
		# User
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=1)] 
        [ValidateNotNullOrEmpty()] 
        [string]$User,
		
		# The MAS Name
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=2)] 
        [ValidateNotNullOrEmpty()] 
        [string]$MASName,
		
		# The path to the log file. 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=3)] 
        [ValidateNotNullOrEmpty()] 
        [string]$LogFile,
		
		# The path of The ETS Import Directory
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=4)] 
        [ValidateNotNullOrEmpty()] 
        [string]$ETSImportDir
    )
	
	# Set the test procedure
	$TestArray = @(
	    # 'auto_alarm_1',
		'auto_network_1',
		'auto_network_2', 
		'auto_network_3',
		'auto_network_4',	
		'auto_network_5',  #depend on network_4
		'auto_network_6',	#depend on network_5
		'auto_network_7',	##depend on network_6
		'auto_network_8',
		'auto_network_9',
		'auto_network_10',
		'auto_network_11',
		'auto_network_12',
		'auto_network_14',
		'auto_network_15',   #depend on 6
		'auto_network_16',    #depend on 15  
		'auto_network_17',
		'auto_network_18',
		'auto_network_19',		
		'auto_scada_1',			
		'auto_scada_2',       #depend on network_4,network_7 
		'auto_scada_3',
		'auto_scada_4',	#depend on network_6, scada_2
		'auto_scada_5',	#depend on network_6, scada_4
		'auto_scada_6',  
		'auto_scada_7',  	#depend on network_4,network_6,scada_1,scada_6
		'auto_scada_8',		
		'auto_scada_9',
		'auto_scada_10',		
		'auto_scada_11',		
		'auto_gen_1',
		'auto_gen_2',
		'auto_gen_3',
		'auto_gen_4',
		'auto_gen_5',
		'auto_resmom_1',
		'auto_resmom_2',
		'auto_dts_1',		
		'auto_dts_2',	         
		'auto_dts_3'	
		# 'auto_dts_4'		
	)
	
	# Default the output status
	$Success = $false
	
	# Reset Workspace
	Write-Log -Path $LogFile -Level 'Debug' -Message "Take ownership of the workspace $Workspace"
	$output=Set-EtsWorkspaceOwner -Workspace $Workspace -Owner $User
	if ($output -eq $Workspace) {
		Write-Log -Path $LogFile -Level 'Info' -Message "Reset workspace $Workspace"
		$output=Reset-EtsWorkspace -Workspace $Workspace
	}
	# Import the Server MAS
	$Success = MASWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile
	if (-not($Success)) {
		$errmsg = 'Problem found during the MAS Import on ' + $Workspace
		Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
		throw $errmsg
		return $false
	}
	
	$Count = 0
	# Create empty projects for tests, and load them into workspace
	$TestArray | Foreach-Object {
		$_ = $_.ToLower()
		$ProjectName = "proj_" + $_
		# If the project already exists, remove it first
		if (Test-EtsProject -Project $ProjectName) {
			Write-Log -Path $LogFile -Level 'Info' -Message "Remove the previous project $ProjectName"
			Remove-EtsProject -Project $ProjectName
		}
		# Create the project
		Write-Log -Path $LogFile -Level 'Info' -Message "Create project $ProjectName"
		
		Create-EtsProject -ProjectId $ProjectName -ProjectName $ProjectName -Description '$_ testing' -EffectiveDate $(Get-Date -Format 'MM/dd/yyyy') -State ProjectEditing -SchemaId CIM/EMS
		Start-Sleep 1
		
		# Load the project into workspace
		Get-EtsProject -ProjectId $ProjectName | Load-EtsProject -Workspace $Workspace
		$Count = $Count + 1
	}
	#Set Global file name 
	$FileNameStart = '_' + $MASName.ToLower() + $(Get-FileName)

	# Start individual test for each test key in TestArray
	$TestArray | Foreach-Object {
		# Obtain the test pattern
		$Pattern = Define-Pattern -TestKey $_
		# Starting test based on pattern and testkey
		Write-Log -Path $LogFile -Level 'Info' -Message "============================================= $_   Start==================================================="
		# Skipped the testkey in skipped list
		if($Script:SkippedTestArray.Contains($_)){
			Write-Log -Path $LogFile -Level 'Info' -Message "Test: $_ is skipped due to previous test result."
			Write-Log -Path $LogFile -Level 'Info' -Message "============================================= $_    End==================================================="
			return
		}
		Write-Log -Path $LogFile -Level 'Info' -Message "Start testing : $_ . Test pattern : $Pattern"
		$Success = DomainTesting -Workspace $Workspace -User $User -MASName $MASName -LogFile $LogFile -ETSImportDir $ETSImportDir -Pattern $Pattern -TestKey $_
		Write-Log -Path $LogFile -Level 'Info' -Message "============================================= $_    End==================================================="
		# If test fails, unload the project, add it to the failed list and add its related test keys to skipped list
		if (-not $Success) {
			$FailedProj = "proj_" + $_
			# Unload the failed test project
			Unload-Project -Workspace $Workspace -MasName $MASName -LogFile $LogFile -ProjectId $FailedProj -TestArray $TestArray
			# Add to failed list
			$Script:FailedTestArray += $_
			# Add related test to skiping list
			Expand-SkippingList -TestKey $_
		}
		else {
			# only add test keys that has dependency with later test keys
			if($_ -eq "auto_network_4" -or $_ -eq "auto_network_5" -or $_ -eq "auto_network_6" -or $_ -eq "auto_network_7" -or $_ -eq "auto_network_15" -or $_ -eq "auto_scada_1" -or $_ -eq "auto_scada_2" -or $_ -eq "auto_scada_4" -or $_ -eq "auto_scada_6"){
				$Script:PassedTestArray += $_
			}
			
		}
	}
	
	
	# Reset the workspace
	Write-Log -Path $LogFile -Level 'Debug' -Message "Clean up : Take ownership of the workspace $Workspace"
	$output=Set-EtsWorkspaceOwner -Workspace $Workspace -Owner $User
	if ($output -eq $Workspace) {
		Write-Log -Path $LogFile -Level 'Info' -Message "Clean up : Reset workspace $Workspace"
		$output=Reset-EtsWorkspace -Workspace $Workspace
	}
	
	# Remove all the project created
	$TestArray | Foreach-Object {
		$ProjectName = "proj_" + $_
		# If the project exists, remove it 
		if (Test-EtsProject -Project $ProjectName) {
			Write-Log -Path $LogFile -Level 'Info' -Message "Clean up : Remove the project $ProjectName"
			Remove-EtsProject -Project $ProjectName
		}
	}
	
	# Return the result of the test
	if ($Script:FailedTestArray.length -eq 0){
		$Success = $true
	}
	else{
		$Success = $false
	}
	$Script:FailedTestArray | Foreach-Object {
		Write-Log -Path $LogFile -Level 'Info' -Message "Failed test: $_"
	}
	
	return $Success
}

###############################################################################
function DomainTesting
{
	Param 
    ( 
        # The input file to be updated
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [string]$Workspace,
		
		# User
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=1)] 
        [ValidateNotNullOrEmpty()] 
        [string]$User,
		
		# The MAS Name
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=2)] 
        [ValidateNotNullOrEmpty()] 
        [string]$MASName,
		
		# The path to the log file. 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=3)] 
        [ValidateNotNullOrEmpty()] 
        [string]$LogFile,
		
		# The path of The ETS Import Directory
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=4)] 
        [ValidateNotNullOrEmpty()] 
        [string]$ETSImportDir,
		
		# The test pattern   Option1: standard.  Option2: standard plus cleanup.
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=5)] 
        [ValidateNotNullOrEmpty()] 
        [string]$Pattern,
		
		# The test key
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=6)] 
        [ValidateNotNullOrEmpty()] 
        [string]$TestKey
    )

	# Default the output status
	$Success = $false
	
	# call different test function based on the chosen pattern
	switch ($Pattern) {
		'Standard' {
			$Success = DomainTesting_Standard -Workspace $Workspace -User $User -MASName $MASName -LogFile $LogFile -ETSImportDir $ETSImportDir -TestKey $TestKey
		}
		'SingleValidation' {
			$DomainName = Get-Domain -TestKey $TestKey
			$Success = DomainTesting_SingleValidation -Workspace $Workspace -User $User -MASName $MASName -LogFile $LogFile -ETSImportDir $ETSImportDir -TestKey $TestKey -Domain $DomainName
		}
		'Special' {
			$Success = DomainTesting_Special -Workspace $Workspace -User $User -MASName $MASName -LogFile $LogFile -ETSImportDir $ETSImportDir -TestKey $TestKey
		}
		default {
			$Success = $false
			Write-Log -Path $LogFile -Level 'Error' -Message "Undefined Pattern $Pattern"
		}
	}
	
	return $Success
}


###############################################################################
function DomainTesting_Standard
{ 
	Param 
    ( 
        # The input file to be updated
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [string]$Workspace,
		
		# User
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=1)] 
        [ValidateNotNullOrEmpty()] 
        [string]$User,
		
		# The MAS Name
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=2)] 
        [ValidateNotNullOrEmpty()] 
        [string]$MASName,
		
		# The path to the log file. 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=3)] 
        [ValidateNotNullOrEmpty()] 
        [string]$LogFile,
		
		# The ETS Import directory 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=4)] 
        [ValidateNotNullOrEmpty()] 
        [string]$ETSImportDir,
		
		# The test key. 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=5)] 
        [ValidateNotNullOrEmpty()] 
        [string]$TestKey
    )
	
	$TestKey = $TestKey.ToLower()
	$ProjectName = 'proj_' + $TestKey
	
	# Set the project activate
	Set-EtsActiveProject -Project $ProjectName
	
	# Run the CSV Import
	$FormatFileName = 'CIM_EMS_Format_Testing.csv'
	$DataFileName =  $TestKey + $FileNameStart + '_data.csv' 
	# Verify if that both files exist
	if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
		$Success = $false
		$errmsg = 'The Input CSV files are missing (' + 
			($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
			($ETSImportDir + '\' + $DataFileName) + ')'
		Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
		return $false
	} else {
		# Launch a CSV Import
		$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
		if (-not($Success)) {
			$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
				Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
				return $false
		}
	}
	
	# Verify if it validates
	if ($Success) {
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Full Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the full Workspace Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
	}
	
	#
	# Run a full EMS Export
	#
	try {
		$Success = EMSWorkspaceExport -Workspace $Workspace -MASName $MASName -LogFile $LogFile -FullExp -NoArchive
	}
	catch{
		$Success = $false
	}
	if (-not($Success)) {
		$errmsg = 'Problem found during the Full EMS Export on ' + $Workspace
		Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
		Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
		return $false
	}
	if($Success){
		Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
	} else {
		Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
	}
	
	return $Success
}

###############################################################################
function DomainTesting_SingleValidation
{
	Param 
    ( 
        # The input file to be updated
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [string]$Workspace,
		
		# User
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=1)] 
        [ValidateNotNullOrEmpty()] 
        [string]$User,
		
		# The MAS Name
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=2)] 
        [ValidateNotNullOrEmpty()] 
        [string]$MASName,
		
		# The path to the log file. 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=3)] 
        [ValidateNotNullOrEmpty()] 
        [string]$LogFile,
		
		# The ETS Import directory 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=4)] 
        [ValidateNotNullOrEmpty()] 
        [string]$ETSImportDir,
		
		# The test key. 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=5)] 
        [ValidateNotNullOrEmpty()] 
        [string]$TestKey,
		
		# The domain for validation
		[Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=6)] 
        [ValidateNotNullOrEmpty()] 
        [string]$Domain
    )
	
	$TestKey = $TestKey.ToLower()
	$ProjectName = 'proj_' + $TestKey
	
	# Set the project activate
	Set-EtsActiveProject -Project $ProjectName
	
	# Run the CSV Import
	$FormatFileName = 'CIM_EMS_Format_Testing.csv'
	$DataFileName = $TestKey + $FileNameStart + '_data.csv' 
	# Verify if that both files exist
	if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
		$Success = $false
		$errmsg = 'The Input CSV files are missing (' + 
			($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
			($ETSImportDir + '\' + $DataFileName) + ')'
		Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
		Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
		return $false
	} else {
		# Launch a CSV Import
		$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
		if (-not($Success)) {
			$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
				Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
				Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
				return $false
		}
	}
	
	# Verify if it validates
	$SequenceName = ''
	switch($Domain) {
		'Network' {$SequenceName = 'Network Validation'}
		'Contingency' {$SequenceName = 'Contingency Validation'}
		'Scada' {$SequenceName = 'Scada Validation'}
		'OAG' {$SequenceName = 'OAG Validation'} #ETS3.0 does not support
		'Comm' {$SequenceName = 'Comm Validation'}
		'Generation' {$SequenceName = 'Generation Validation'}
		'Resmom' {$SequenceName = 'Reserve Monitor Model Validation'}
		'Simulation' {$SequenceName = 'Simulation Validation'}
		'Simulation Generation' {$SequenceName = 'Simulation Model Auto-Generation'}
		default {$SequenceName = 'Full Validation'}
	}
	if ($Success) {
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the $SequenceName on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence $SequenceName
		if (-not($Success)) {
			$errmsg = "Problem found during the $SequenceName on " + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
	}
	
	if($Success){
		Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
	} else {
		Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
	}
	
	return $Success
	
}

function DomainTesting_Special
{
	Param 
    ( 
        # The input file to be updated
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [string]$Workspace,
		
		# User
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=1)] 
        [ValidateNotNullOrEmpty()] 
        [string]$User,
		
		# The MAS Name
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=2)] 
        [ValidateNotNullOrEmpty()] 
        [string]$MASName,
		
		# The path to the log file. 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=3)] 
        [ValidateNotNullOrEmpty()] 
        [string]$LogFile,
		
		# The ETS Import directory 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=4)] 
        [ValidateNotNullOrEmpty()] 
        [string]$ETSImportDir,
		
		# The test key. 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=5)] 
        [ValidateNotNullOrEmpty()] 
        [string]$TestKey
    )
	$TestKey = $TestKey.ToLower()
	$ProjectName = 'proj_' + $TestKey
	
	# Set the project activate
	Set-EtsActiveProject -Project $ProjectName
	
	# for auto_alarm_2
	if($TestKey -eq 'auto_alarm_2')
	{
		# Run the CSV Import
		$FormatFileName = 'CIM_EMS_Format_Testing.csv'
		$DataFileName = $TestKey + $FileNameStart + '_data.csv' 
		# Lanch a CSV Import
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The Input CSV files are missing (' + 
				($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
				($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		
		# First time Full Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the First time Full Validation on the $Workspace workspace"
		Write-Log -Path $LogFile -Level 'Info' -Message "Fail expected."
		$Success = Validate-EtsData -Sequence 'Full Validation'
		if ($Success) {
			$Success = $false
			$errmsg = 'Validation is expected to fail. Test not passed'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		else{
			$Success = $true
		}
		
		# Recover the data
		$DataFileName = $TestKey + $FileNameStart + '_data_recover.csv' 
		# Verify if recover data file exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The recover CSV file is missing (' +($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Second time Full Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Second time Full Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Full Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the second Full Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		if($Success){
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
		} else {
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
		}
		return $Success
		
	}
	
	# for auto_network_16
	if($TestKey -eq 'auto_network_16')
	{
		# Run the CSV Import
		$FormatFileName = 'CIM_EMS_Format_Testing.csv'
		$DataFileName = $TestKey + $FileNameStart + '_data.csv' 
		# Lanch a CSV Import
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The Input CSV files are missing (' + 
				($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
				($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		
		# First time Contingency Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the First time Full Validation on the $Workspace workspace"
		Write-Log -Path $LogFile -Level 'Info' -Message "Fail expected."
		$Success = Validate-EtsData -Sequence 'Contingency Validation'
		if ($Success) {
			$Success = $false
			$errmsg = 'Validation is expected to fail. Test not passed'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		else{
			$Success = $true
		}
		
		# Recover the data
		$DataFileName = $TestKey + $FileNameStart + '_data_recover.csv' 
		# Verify if recover data file exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The recover CSV file is missing (' +($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Second time Contingency Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Second time Contingency Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Contingency Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the second Contingency Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		if($Success){
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
		} else {
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
		}
		return $Success
	}
	
	# for auto_network_17
	if($TestKey -eq 'auto_network_17') 
	{
		# First time Remedial Action Scheme Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the First time Remedial Action Scheme Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Remedial Action Scheme Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the first Remedial Action Scheme Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		# Run the CSV Import
		$FormatFileName = 'CIM_EMS_Format_Testing.csv'
		$DataFileName = $TestKey + $FileNameStart + '_data.csv' 
		# Verify if that both files exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The Input CSV files are missing (' + 
				($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
				($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Second Time Remedial Action Scheme Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Second Remedial Action Scheme Validation on the $Workspace workspace"
		Write-Log -Path $LogFile -Level 'Info' -Message "Fail expected."
		$Success = Validate-EtsData -Sequence 'Remedial Action Scheme Validation'
		if ($Success) {
			$Success = $false
			$errmsg = 'The validation is expected to fail. Test not passed'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		else {
			$Success = $true
		}
		
		# Recover the data
		$DataFileName = $TestKey + $FileNameStart + '_data_recover.csv' 
		# Verify if recover data file exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The recover CSV file is missing (' +($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Third time Remedial Action Scheme Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Third time Remedial Action Scheme Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Remedial Action Scheme Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the third Remedial Action Scheme Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		if($Success){
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
		} else {
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
		}
		return $Success
	}
	
	# for auto_network_18
	if($TestKey -eq 'auto_network_18')
	{	
		# Run the CSV Import
		$FormatFileName = 'CIM_EMS_Format_Testing.csv'
		$DataFileName = $TestKey + $FileNameStart + '_data.csv' 
		# Lanch a CSV Import
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The Input CSV files are missing (' + 
				($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
				($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		
		# First time Dynamic Rating Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the First time Dynamic Rating Validation on the $Workspace workspace"
		Write-Log -Path $LogFile -Level 'Info' -Message "Fail expected."
		$Success = Validate-EtsData -Sequence 'Dynamic Rating Validation'
		if ($Success) {
			$Success = $false
			$errmsg = 'Validation is expected to fail. Test not passed'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		else{
			$Success = $true
		}
		
		# Recover the data
		$DataFileName = $TestKey + $FileNameStart + '_data_recover.csv' 
		# Verify if recover data file exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The recover CSV file is missing (' +($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Second time Dynamic Rating Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Second time Dynamic Rating Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Dynamic Rating Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the second Dynamic Rating Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		if($Success){
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
		} else {
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
		}
		return $Success
		
		
	}
	
	# for auto_scada_9
	if($TestKey -eq 'auto_scada_9')
	{
		# Run the CSV Import
		$FormatFileName = 'CIM_EMS_Format_Testing.csv'
		$DataFileName = $TestKey + $FileNameStart + '_data.csv' 
		# Lanch a CSV Import
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The Input CSV files are missing (' + 
				($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
				($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# First time Scada Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the First time Scada Validation on the $Workspace workspace"
		Write-Log -Path $LogFile -Level 'Info' -Message "Fail expected."
		$Success = Validate-EtsData -Sequence 'Scada Validation'
		if ($Success) {
			$Success = $false
			$errmsg = 'Validation is expected to fail. Test not passed'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		else{
			$Success = $true
		}
		
		# Recover the data
		$DataFileName = $TestKey + $FileNameStart + '_data_recover.csv' 
		# Verify if recover data file exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The recover CSV file is missing (' +($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Second time Scada Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Second time Scada Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Scada Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the second Scada Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		if($Success){
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
		} else {
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
		}
		return $Success
	}
	
	# for auto_gen_1
	if($TestKey -eq 'auto_gen_1')
	{
		# First time Generation Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the First time Generation Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Generation Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the first Generation Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		# Run the CSV Import
		$FormatFileName = 'CIM_EMS_Format_Testing.csv'
		$DataFileName = $TestKey + $FileNameStart + '_data.csv' 
		# Verify if that both files exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The Input CSV files are missing (' + 
				($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
				($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Second Time Generation Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Second Generation Validation on the $Workspace workspace"
		Write-Log -Path $LogFile -Level 'Info' -Message "Fail expected."
		$Success = Validate-EtsData -Sequence 'Generation Validation'
		if ($Success) {
			$Success = $false
			$errmsg = 'The validation is expected to fail. Test not passed'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		else {
			$Success = $true
		}
		
		# Recover the data
		$DataFileName = $TestKey + $FileNameStart + '_data_recover.csv' 
		# Verify if recover data file exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The recover CSV file is missing (' +($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Third time Generation Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Third time Generation Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Generation Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the third Generation Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		if($Success){
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
		} else {
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
		}
		return $Success
	
	}
	
	# for auto_gen_3 and auto_gen_4
	if($TestKey -eq 'auto_gen_3' -or $TestKey -eq 'auto_gen_4')
	{
		# Run the CSV Import
		$FormatFileName = 'CIM_EMS_Format_Testing.csv'
		$DataFileName = $TestKey + $FileNameStart + '_data.csv' 
		# Lanch a CSV Import
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The Input CSV files are missing (' + 
				($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
				($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# First time Generation Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the First time Generation Validation on the $Workspace workspace"
		Write-Log -Path $LogFile -Level 'Info' -Message "Fail expected."
		$Success = Validate-EtsData -Sequence 'Generation Validation'
		if ($Success) {
			$Success = $false
			$errmsg = 'Validation is expected to fail. Test not passed'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		else{
			$Success = $true
		}
		
		# Recover the data
		$DataFileName = $TestKey + $FileNameStart + '_data_recover.csv' 
		# Verify if recover data file exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The recover CSV file is missing (' +($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Second time Generation Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Second time Generation Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Generation Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the second Generation Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		if($Success){
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
		} else {
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
		}
		return $Success
	}
	
	# for auto_resmom_2
	if($TestKey -eq 'auto_resmom_2')
	{
		# Run the CSV Import
		$FormatFileName = 'CIM_EMS_Format_Testing.csv'
		$DataFileName = $TestKey + $FileNameStart + '_data.csv' 
		# Lanch a CSV Import
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The Input CSV files are missing (' + 
				($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
				($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# First time Reserve Monitor Model Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the First time Reserve Monitor Model Validation on the $Workspace workspace"
		Write-Log -Path $LogFile -Level 'Info' -Message "Fail expected."
		$Success = Validate-EtsData -Sequence 'Reserve Monitor Model Validation'
		if ($Success) {
			$Success = $false
			$errmsg = 'Validation is expected to fail. Test not passed'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		else{
			$Success = $true
		}
		
		# Recover the data
		$DataFileName = $TestKey + $FileNameStart + '_data_recover.csv' 
		# Verify if recover data file exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The recover CSV file is missing (' +($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Second time Reserve Monitor Model Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Second time Reserve Monitor Model Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Reserve Monitor Model Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the second Reserve Monitor Model Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		if($Success){
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
		} else {
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
		}
		return $Success
	}
	
	# for auto_dts_2 and auto_dts_3
	if($TestKey -eq 'auto_dts_2' -or $TestKey -eq 'auto_dts_3')
	{
		# Run the CSV Import
		$FormatFileName = 'CIM_EMS_Format_Testing.csv'
		$DataFileName = $TestKey + $FileNameStart + '_data.csv' 
		# Lanch a CSV Import
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $FormatFileName)) -or -not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The Input CSV files are missing (' + 
				($ETSImportDir + '\' + $FormatFileName) + ' and/or ' + 
				($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# First time Simulation Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the First time Simulation Validation on the $Workspace workspace"
		Write-Log -Path $LogFile -Level 'Info' -Message "Fail expected."
		$Success = Validate-EtsData -Sequence 'Simulation Validation'
		if ($Success) {
			$Success = $false
			$errmsg = 'Validation is expected to fail. Test not passed'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		else{
			$Success = $true
		}
		
		# Recover the data
		$DataFileName = $TestKey + $FileNameStart + '_data_recover.csv' 
		# Verify if recover data file exist
		if(-not(Test-Path -Path ($ETSImportDir + '\' + $DataFileName))) {
			$Success = $false
			$errmsg = 'The recover CSV file is missing (' +($ETSImportDir + '\' + $DataFileName) + ')'
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		} else {
			# Launch a CSV Import
			$Success = CSVWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile -Target 'Server' -SourceFile $DataFileName -FormatFile $FormatFileName
			if (-not($Success)) {
				$errmsg = 'Problem found during the CSV Import on ' + $Workspace + ' in Test : ' + $TestKey
					Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
					Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
					return $false
			}
		}
		# Second time Simulation Validation
		Write-Log -Path $LogFile -Level 'Info' -Message "Run the Second time Simulation Validation on the $Workspace workspace"
		$Success = Validate-EtsData -Sequence 'Simulation Validation'
		if (-not($Success)) {
			$errmsg = 'Problem found during the second Simulation Validation on ' + $Workspace
			Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
			Write-Log -Path $LogFile -Level 'Info' -Message "Test failed."
			return $false
		}
		if($Success){
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test passed."
		} else {
			Write-Log -Path $LogFile -Level 'Info' -Message "$TestKey test is done. Test failed."
		}
		return $Success
	}
	return $false
	
	
}

###############################################################################
function Define-Pattern 
{
	Param 
    ( 
        # The test key
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [string]$TestKey
	)
	$Pattern = ''
	$TestKey = $TestKey.ToLower()
	switch ($TestKey) {
		'auto_alarm_1' {$Pattern = 'Standard'}
		'auto_alarm_2' {$Pattern = 'Special'}
		'auto_network_1' {$Pattern = 'SingleValidation'}
		'auto_network_2' {$Pattern = 'SingleValidation'}
		'auto_network_3' {$Pattern = 'SingleValidation'}
		'auto_network_4' {$Pattern = 'SingleValidation'}
		'auto_network_5' {$Pattern = 'SingleValidation'}
		'auto_network_6' {$Pattern = 'SingleValidation'}
		'auto_network_7' {$Pattern = 'SingleValidation'}
		'auto_network_8' {$Pattern = 'SingleValidation'}
		'auto_network_9' {$Pattern = 'SingleValidation'}
		'auto_network_10' {$Pattern = 'SingleValidation'}
		'auto_network_11' {$Pattern = 'SingleValidation'}
		'auto_network_12' {$Pattern = 'SingleValidation'}
		'auto_network_13' {$Pattern = 'SingleValidation'}
		'auto_network_14' {$Pattern = 'SingleValidation'}
		'auto_network_15' {$Pattern = 'SingleValidation'}
		'auto_network_16' {$Pattern = 'Special'}
		'auto_network_17' {$Pattern = 'Special'}
		'auto_network_18' {$Pattern = 'Special'}
		'auto_network_19' {$Pattern = 'SingleValidation'}
		'auto_scada_1' {$Pattern = 'SingleValidation'}
		'auto_scada_2' {$Pattern = 'SingleValidation'}
		'auto_scada_3' {$Pattern = 'SingleValidation'}
		'auto_scada_4' {$Pattern = 'SingleValidation'}
		'auto_scada_5' {$Pattern = 'SingleValidation'}
		'auto_scada_6' {$Pattern = 'SingleValidation'}
		'auto_scada_7' {$Pattern = 'SingleValidation'}
		'auto_scada_8' {$Pattern = 'SingleValidation'}
		'auto_scada_9' {$Pattern = 'Special'}
		'auto_scada_10' {$Pattern = 'SingleValidation'}
		'auto_scada_11' {$Pattern = 'SingleValidation'}
		'auto_scada_12' {$Pattern = 'SingleValidation'}
		'auto_gen_1' {$Pattern = 'Special'}
		'auto_gen_2' {$Pattern = 'SingleValidation'}
		'auto_gen_3' {$Pattern = 'Special'}
		'auto_gen_4' {$Pattern = 'Special'}
		'auto_gen_5' {$Pattern = 'SingleValidation'}
		'auto_resmom_1' {$Pattern = 'SingleValidation'}
		'auto_resmom_2' {$Pattern = 'Special'}
		'auto_dts_1' {$Pattern = 'SingleValidation'}
		'auto_dts_2' {$Pattern = 'Special'}
		'auto_dts_3' {$Pattern = 'Special'}
		'auto_dts_4' {$Pattern = 'SingleValidation'}
		default {$Pattern = 'Standard'}
	}
	
	return $Pattern	
}

# Define the validation domain
function Get-Domain
{
	Param 
    ( 
        # The test key
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [string]$TestKey
	)
	
	$Domain = ''
	$TestKey = $TestKey.ToLower()
	switch ($TestKey) {
		'auto_alarm_1' {$Domain = 'Full'}
		'auto_alarm_2' {$Domain = 'Full'}
		'auto_network_1' {$Domain = 'Network'}
		'auto_network_2' {$Domain = 'Network'}
		'auto_network_3' {$Domain = 'Network'}
		'auto_network_4' {$Domain = 'Network'}
		'auto_network_5' {$Domain = 'Network'}
		'auto_network_6' {$Domain = 'Network'}
		'auto_network_7' {$Domain = 'Network'}
		'auto_network_8' {$Domain = 'Network'}
		'auto_network_9' {$Domain = 'Network'}
		'auto_network_10' {$Domain = 'Network'}
		'auto_network_11' {$Domain = 'Network'}
		'auto_network_12' {$Domain = 'Network'}
		'auto_network_13' {$Domain = 'Network'}
		'auto_network_14' {$Domain = 'Network'}
		'auto_network_15' {$Domain = 'Contingency'}
		'auto_network_16' {$Domain = 'Contingency'}
		'auto_network_17' {$Domain = 'Remedial Action Scheme'}
		'auto_network_18' {$Domain = 'Dynamic Rating'}
		'auto_network_19' {$Domain = 'Network'}
		'auto_scada_1' {$Domain = 'Scada'}
		'auto_scada_2' {$Domain = 'Scada'}
		'auto_scada_3' {$Domain = 'Scada'}
		'auto_scada_4' {$Domain = 'Scada'}
		'auto_scada_5' {$Domain = 'Scada'}
		'auto_scada_6' {$Domain = 'Scada'}
		'auto_scada_7' {$Domain = 'Scada'}
		'auto_scada_8' {$Domain = 'Scada'}
		'auto_scada_9' {$Domain = 'Scada'}
		'auto_scada_10' {$Domain = 'Comm'}
		'auto_scada_11' {$Domain = 'Comm'}
		'auto_scada_12' {$Domain = 'Comm'}
		'auto_gen_1' {$Domain = 'Generation'}
		'auto_gen_2' {$Domain = 'Generation'}
		'auto_gen_3' {$Domain = 'Generation'}
		'auto_gen_4' {$Domain = 'Generation'}
		'auto_gen_5' {$Domain = 'Generation'}
		'auto_resmom_1' {$Domain = 'Resmom'}
		'auto_resmom_2' {$Domain = 'Resmom'}
		'auto_dts_1' {$Domain = 'Simulation'}
		'auto_dts_2' {$Domain = 'Simulation'}
		'auto_dts_3' {$Domain = 'Simulation'}
		'auto_dts_4' {$Domain = 'Simulation Generation'}
		
		default {$Domain = 'Network'}
	}
	
	return $Domain	
}

# Get file name based on Habitat, Scada, EMP, Comm versions
function Get-FileName {
	$_FileName = '_'
	if ($HABITATVersion -eq 5.8) {
		$_FileName += 'hab58_'
	} elseif ($HABITATVersion -eq 5.9) {
		$_FileName += 'hab59_'
	} else {
		$_FileName += 'hab510_'
	}
	if ($EMPVersion -eq 2.6) {
		$_FileName += 'emp26_'
	} elseif ($EMPVersion -eq 3.0) {
		$_FileName += 'emp30_'
	} else {
		$_FileName += 'emp31_'
	}
	if ($SCADAVersion -eq 2.6) {
		$_FileName += 'scada26_'
	} elseif ($SCADAVersion -eq 3.0) {
		$_FileName += 'scada30_'
	} else {
		$_FileName += 'scada31_'
	}
	if ($CommVersion -eq 2.6) {
		$_FileName += 'comm26'
	} else {
		$_FileName += 'comm30'
	}
	return $_FileName
}

# expand the skipping list based on the dependency
function Expand-SkippingList
{
	Param 
    ( 	
        # The test key
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [string]$TestKey
	)
	
	if($TestKey -eq 'auto_network_4'){
		$Script:SkippedTestArray.Add('auto_network_5')
		$Script:SkippedTestArray.Add('auto_network_6')
		$Script:SkippedTestArray.Add('auto_network_7')
		$Script:SkippedTestArray.Add('auto_network_13')
		$Script:SkippedTestArray.Add('auto_network_15')
		$Script:SkippedTestArray.Add('auto_network_16')
		$Script:SkippedTestArray.Add('auto_scada_2')
		$Script:SkippedTestArray.Add('auto_scada_4')
		$Script:SkippedTestArray.Add('auto_scada_5')
		$Script:SkippedTestArray.Add('auto_scada_7')
	}
	if($TestKey -eq 'auto_network_5'){
		$Script:SkippedTestArray.Add('auto_network_6')
		$Script:SkippedTestArray.Add('auto_network_7')
		$Script:SkippedTestArray.Add('auto_network_13')
		$Script:SkippedTestArray.Add('auto_network_15')
		$Script:SkippedTestArray.Add('auto_network_16')
		$Script:SkippedTestArray.Add('auto_scada_2')
		$Script:SkippedTestArray.Add('auto_scada_4')
		$Script:SkippedTestArray.Add('auto_scada_5')
		$Script:SkippedTestArray.Add('auto_scada_7')
	}
	if($TestKey -eq 'auto_network_6'){
		$Script:SkippedTestArray.Add('auto_network_7')
		$Script:SkippedTestArray.Add('auto_network_15')
		$Script:SkippedTestArray.Add('auto_network_16')
		$Script:SkippedTestArray.Add('auto_scada_2')
		$Script:SkippedTestArray.Add('auto_scada_4')
		$Script:SkippedTestArray.Add('auto_scada_5')
		$Script:SkippedTestArray.Add('auto_scada_7')
	}
	if($TestKey -eq 'auto_network_7'){
		$Script:SkippedTestArray.Add('auto_scada_2')
		$Script:SkippedTestArray.Add('auto_scada_4')
		$Script:SkippedTestArray.Add('auto_scada_5')
		$Script:SkippedTestArray.Add('auto_scada_7')
	}
	if($TestKey -eq 'auto_scada_2'){
		$Script:SkippedTestArray.Add('auto_scada_4')
		$Script:SkippedTestArray.Add('auto_scada_5')
		$Script:SkippedTestArray.Add('auto_scada_7')
	}
	if($TestKey -eq 'auto_scada_4'){
		$Script:SkippedTestArray.Add('auto_scada_5')
	}
	if($TestKey -eq 'auto_scada_6'){
		$Script:SkippedTestArray.Add('auto_scada_7')
	}
	if($TestKey -eq 'auto_network_15'){
		$Script:SkippedTestArray.Add('auto_network_16')
	}
	
}

# Unload a project 
# Unload-Project -Workspace $Workspace -MasName $MASName -LogFile $LogFile -ProjectId $FailedProj -TestArray $TestArray
function Unload-Project
{
	Param 
    ( 
		# The workspace
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [string]$Workspace,
		
        # The MAS Name
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=1)] 
        [ValidateNotNullOrEmpty()] 
        [string]$MASName,
		
		 # The Log File
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=2)] 
        [ValidateNotNullOrEmpty()] 
        [string]$LogFile,
		
		 # The project need to be unloaded
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=3)] 
        [ValidateNotNullOrEmpty()] 
        [string]$ProjectId,
		
		# The test array
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=4)] 
        [ValidateNotNullOrEmpty()] 
        [string[]]$TestArray

	)
	Write-Log -Path $LogFile -Level 'Info' -Message "== Start unloading project $ProjectId =="
	# Reset Workspace
	Write-Log -Path $LogFile -Level 'Info' -Message "Unloading $ProjectId : Take ownership of the workspace $Workspace"
	$output=Set-EtsWorkspaceOwner -Workspace $Workspace -Owner $User
	if ($output -eq $Workspace) {
		# fix the trigger problem !!!Temperary
		Start-Sleep 20
		Write-Log -Path $LogFile -Level 'Info' -Message "Unloading $ProjectId : Reset workspace $Workspace"
		$output=Reset-EtsWorkspace -Workspace $Workspace
	}
	# Import the Server MAS
	$Success = MASWorkspaceImport -Workspace $Workspace -MasName $MASName -LogFile $LogFile
	if (-not($Success)) {
		$errmsg = 'Unloading $ProjectId : Problem found during the MAS Import on ' + $Workspace
		Write-Log -Path $LogFile -Level 'Error' -Message $errmsg
		throw $errmsg
		return $false
	}
	
	# Reload previous successful test projects
	$PassedTestArray | Foreach-Object {
		$Proj = "proj_" + $_
		Write-Log -Path $LogFile -Level 'Info' -Message "Unloading $ProjectId : Reloading $Proj to $Workspace"
		# Load the project into workspace
		Get-EtsProject -ProjectId $Proj | Load-EtsProject -Workspace $Workspace
		# Issues!!! : There is no Trigger waiting for load project  !!!Temperary
		Start-Sleep 40
	}
	# Reload empty test project for later tests
	Write-Log -Path $LogFile -Level 'Info' -Message "Unloading $ProjectId : Reloading later empty projects to $Workspace"
	$flag = 0
	$TestArray | Foreach-Object {
		$Proj = "proj_" + $_
		if($Proj -eq $ProjectId){
			$flag = 1
			return
		}
		if($flag -eq 1){
			Get-EtsProject -ProjectId $Proj | Load-EtsProject -Workspace $Workspace
		}	
	}
	Write-Log -Path $LogFile -Level 'Info' -Message "== Finish unloading project $ProjectId =="
	return $true
}

#
# USER FUNCTIONS
Export-ModuleMember SVPP-Testing