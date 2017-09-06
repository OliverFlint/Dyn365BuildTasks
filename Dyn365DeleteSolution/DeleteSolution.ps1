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
    $sln = Get-VstsInput -Name sln -Require

    $connString = "AuthType=$auth;Domain=$dmn;Username=$usn;Password=$pwd;Url=$url"
    $connString

    $conn = Get-CrmConnection -ConnectionString $connString

    $solutions = Get-CrmRecords -conn $conn -EntityLogicalName solution -FilterAttribute uniquename -FilterOperator eq -FilterValue $sln

    if($solutions.CrmRecords.Count -ne 1)
    {
        throw "Solution with name `"$SolutionName`" not found!"
    }

    $solution = $solutions.CrmRecords[0]

    Remove-CrmRecord -conn $conn -EntityLogicalName solution -Id $solution.solutionid

    Write-Host "Solution `"$sln`" deleted"

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
