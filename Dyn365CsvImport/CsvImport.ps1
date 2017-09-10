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
        
        $record = [hashtable]@{}
        $attributes | ForEach-Object {
            $record."$_" = $row."$_"
        }
        $pkfield = $entity + "id"
        $id = [guid]$record."$pkfield"
        $record."$pkfield" = [guid]$id

        Write-Host "Executing action `"$action`" on $entity with id `"$id`""

        try{
            if($action -eq "create") {
                $result = New-CrmRecord -conn $conn -Fields $record -EntityLogicalName $entity
            }

            if($action -eq "upsert") {
                $result = $null
                try {
                    $result = Get-CrmRecord -conn $conn -EntityLogicalName $entity -Id $id -Fields $pkfield -ErrorAction SilentlyContinue
                } catch {}
                if($result) {
                    $result = Set-CrmRecord -conn $conn -EntityLogicalName $entity -Id $id -Fields $record
                }
                else {
                    $result = New-CrmRecord -conn $conn -Fields $record -EntityLogicalName $entity
                }
            }

            if($action -eq "update") {
                $result = Set-CrmRecord -conn $conn -Fields $record -EntityLogicalName $entity -Id $id
            }

            if($action -eq "delete") {
                $result = Remove-CrmRecord -conn $conn -EntityLogicalName $entity -Id $id
            }
        }
        Catch {
            Write-Warning $_.Exception.Message
            Write-Warning $_.ScriptStackTrace
        }
        
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
