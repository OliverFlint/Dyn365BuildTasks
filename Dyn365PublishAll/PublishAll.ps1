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

    $connString = "AuthType=$auth;Domain=$dmn;Username=$usn;Password=$pwd;Url=$url"
    $connString

    $conn = Get-CrmConnection -ConnectionString $connString

    Publish-CrmAllCustomization -conn $conn -Verbose

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
