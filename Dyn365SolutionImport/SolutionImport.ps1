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
    $act = Get-VstsInput -Name act -AsBool
    $pub = Get-VstsInput -Name pub -AsBool
    $mwt = Get-VstsInput -Name mwt -AsInt
    $ovw = Get-VstsInput -Name ovw -AsBool

    $connString = "AuthType=$auth;Domain=$dmn;Username=$usn;Password=$pwd;Url=$url"
    $connString

    $conn = Get-CrmConnection -ConnectionString $connString

    $exp = "Import-CrmSolution -conn `$conn -SolutionFilePath `$sln"
    if($act) {$exp = "$exp -ActivatePlugIns"}
    if($pub) {$exp = "$exp -PublishChanges"}
    if($mwt -gt 0) {$exp = "$exp -MaxWaitTimeInSeconds $mwt"}
    if($ovw) {$exp = "$exp -OverwriteUnManagedCustomizations"}

    Write-Host "Invoking `"$exp`""

    Invoke-Expression $exp

    Write-Host "Solution Imported"

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
