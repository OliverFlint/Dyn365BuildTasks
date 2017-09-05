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
    $cwd = Get-VstsInput -Name cwd -Require
    $fln = Get-VstsInput -Name fln -Require
    $mng = Get-VstsInput -Name mng -AsBool
    $tvr = Get-VstsInput -Name tvr
    $ans = Get-VstsInput -Name ans -AsBool
    $cal = Get-VstsInput -Name cal -AsBool
    $cms = Get-VstsInput -Name cms -AsBool
    $ets = Get-VstsInput -Name ets -AsBool
    $gen = Get-VstsInput -Name gen -AsBool
    $mks = Get-VstsInput -Name mks -AsBool
    $oss = Get-VstsInput -Name oss -AsBool
    $rol = Get-VstsInput -Name rol -AsBool
    $isv = Get-VstsInput -Name isv -AsBool
    $sal = Get-VstsInput -Name sal -AsBool

    $connString = "AuthType=$auth;Domain=$dmn;Username=$usn;Password=$pwd;Url=$url"
    $connString

    $conn = Get-CrmConnection -ConnectionString $connString

    $exp = "Export-CrmSolution -Verbose -conn `$conn -SolutionName `$sln -SolutionFilePath `$cwd -SolutionZipFileName `$fln"
    
    if($mng) { $exp = "$exp -Managed" }
    if($tvr -ne "null") { $exp = "$exp -TargetVersion $tvr" }
    if($ans) { $exp = "$exp -ExportAutoNumberingSettings" }
    if($cal) { $exp = "$exp -ExportCalendarSettings" }
    if($cms) { $exp = "$exp -ExportCustomizationSettings" }
    if($ets) { $exp = "$exp -ExportEmailTrackingSettings" }
    if($gen) { $exp = "$exp -ExportGeneralSettings" }
    if($mks) { $exp = "$exp -ExportMarketingSettings" }
    if($oss) { $exp = "$exp -ExportOutlookSynchronizationSettings" }
    if($rol) { $exp = "$exp -ExportRelationshipRoles" }
    if($isv) { $exp = "$exp -ExportIsvConfig" }
    if($sal) { $exp = "$exp -ExportSales" }

    "Export Expression = $exp"

    Invoke-Expression $exp

    Write-Host "Solution `"$sln`" exported to `"$cwd\$fln`""

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
