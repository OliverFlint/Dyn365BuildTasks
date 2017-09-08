[CmdletBinding()]
param()
# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
Trace-VstsEnteringInvocation $MyInvocation
try {

    Import-Module $PSScriptRoot\ps_modules\Microsoft.Xrm.Data.PowerShell

    $url = Get-VstsInput -Name url -Require
    $usn = Get-VstsInput -Name usn -Require
    $pwd = Get-VstsInput -Name pwd -Require
    $dmn = Get-VstsInput -Name dmn
    $auth = Get-VstsInput -Name auth -Require
    $csv = Get-VstsInput -Name csv -Require

    $connString = "AuthType=$auth;Domain=$dmn;Username=$usn;Password=$pwd;Url=$url"
    $connString

    $conn = Get-CrmConnection -ConnectionString $connString

    $csvData = Import-Csv -Path $csv
    $csvHeader = ($csvData | Get-Member -MemberType Properties)

    $attributes = New-Object System.Collections.Generic.List[System.String]
    $csvHeader | ForEach-Object {
        if($_.Name.ToLower() -ne "action" -and $_.Name.ToLower() -ne "entity") {
            $attributes.Add($_.Name.ToLower())
        }
    }

    $csvData | ForEach-Object {
        $row = $_
        $action = $row.action.ToLower()
        $entity = $row.entity.ToLower()
        
        $record = @{}
        $attributes | ForEach-Object {
            $record."$_" = $row."$_"
        }
        $pkfield = $entity + "id"
        [guid]$id = [guid]$record."$pkfield"
        $record."$pkfield" = [guid]$id

        Write-Host "Executing action `"$action`" on $entity with id `"$id`""

        try{
            if($action -eq "create") {
                New-CrmRecord -conn $conn -Fields $record -EntityLogicalName $entity
            }

            if($action -eq "upsert") {
                $record.Remove($record[$pkfield])
                Set-CrmRecord -conn $conn -EntityLogicalName $entity -Id $id -Fields $record -Upsert -Verbose
            }

            if($action -eq "update") {
                $record.Remove($record[$pkfield])
                Set-CrmRecord -conn $conn -Fields $record -EntityLogicalName $entity -Id $id
            }

            if($action -eq "delete") {
                Remove-CrmRecord -conn $conn -EntityLogicalName $entity -Id $id
            }
        }
        Catch {
            Write-Warning $_.Exception.Message
        }
        
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
