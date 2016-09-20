# .".\SetVars.ps1"

#C:\Program Files (x86)\Eterra\Presentation Framework\Plugins\e-terrasource\EtsScripting\EtsScripting.psm1

if(!(test-path $scriptLib))
{
	throw "Cannot find ETS Scripting Module. Closing."
	exit
}

Import-Module $scriptLib -DisableNameChecking 

write-host "Initializing connection to ETS Server..."
Initialize-EtsConnection -username $username -servername 'localhost' -port 8092

if(test-etsworkspace $ws_name)
{
	write-host "$ws_name exists, resetting..."
	Set-EtsWorkspaceOwner -Workspace $ws_name -owner $username
	Reset-EtsWorkspace $ws_name
}
else
{
	write-host "Creating $ws_name..."
	create-etsworkspace -Workspace $ws_name -Password $ws_pw -SchemaId $schema -SchemaVersion 1 -owner $username
}
Set-EtsWorkspace -Workspace $ws_name -user $username

write-host "Importing EMP60..."
if(!(test-path EMSImport.txt)){
	Create-EtsIEParameterFile -Sequence 'Import Model Authority Set' -UseDefaults -Filename EMSImport.txt
}

Import-EtsData -Sequence 'Import Model Authority Set' -filename EMSImport.txt -workspace $ws_name -waitfortriggers

write-host "Creating new MAS..."

$MASCreated = $false;
while ($MASCreated -eq $false)
{
    try
    {
        start-sleep 10 
        $MASCreated = Create-EtsModelAuthoritySet EMP60 -workspace $ws_name
    }
    Catch
    {
        $errorMsg = $_.Exception.Message

        if($errorMsg -like "*Triggers are currently running*")
        {
            Write-Host "Triggers are running, retrying."
        }
        else
        {
            Write-Error "MAS Creation failed, continuing..." 
            $MASCreated = 2
        }
    }
}

write-host "Creating new project..."
if(Test-EtsProject $name)
{
	remove-EtsProject $name
}
Create-EtsProject $name $name (get-date -format s) $schema

Load-EtsProject $name -workspace $ws_name

######################################################################################

write-host "Creating workspace for metadata..."
$meta_ws_name = 'meta_' + $ws_name
if(test-etsworkspace $meta_ws_name)
{
	write-host "$meta_ws_name exists, resetting..."
	Set-EtsWorkspaceOwner -Workspace $meta_ws_name -owner $username
	Reset-EtsWorkspace $meta_ws_name
}
else
{
	write-host "Creating $meta_ws_name..."
	create-etsworkspace -Workspace $meta_ws_name -Password $meta_ws_name -SchemaId 'MetaModel' -SchemaVersion 1 -owner $username
}
Set-EtsWorkspace -Workspace $meta_ws_name -user $username
write-host "Importing MetaModel..."
if(!(test-path MetaModelImport.txt)){
	Create-EtsIEParameterFile -Sequence 'Import MetaModel' -UseDefaults -Filename MetaModelImport.txt
}

Import-EtsData -Sequence 'Import MetaModel' -filename MetaModelImport.txt -workspace $meta_ws_name -waitfortriggers
