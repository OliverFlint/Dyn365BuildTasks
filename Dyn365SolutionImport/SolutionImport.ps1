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
    $skp = Get-VstsInput -Name skp -AsBool

    $connString = "AuthType=$auth;Domain=$dmn;Username=$usn;Password=$pwd;Url=$url"
    $connString

    $conn = Get-CrmConnection -ConnectionString $connString

    $slnFile = Get-Item $sln
    $root = $slnFile.Directory.FullName

    #get solution version from zip
    Expand-Archive -Path $sln -DestinationPath "$root\temp" -Force
    [xml]$slnXml = Get-Content "$root\temp\solution.xml"
    $slnZipVersion = $slnXml.ImportExportXml.SolutionManifest.Version
    Write-Host "Solution version from zip file is $slnZipVersion"
    $slnZipUniqueName = $slnXml.ImportExportXml.SolutionManifest.UniqueName
    Write-Host "Solution name from zip file is $slnZipUniqueName"

    #get solution version from Dynamics 365
    $solutions = Get-CrmRecords -conn $conn -EntityLogicalName solution -FilterAttribute uniquename -FilterOperator eq -FilterValue $slnZipUniqueName -Fields "version"
    if($solutions.CrmRecords.Count -gt 0)
    {
        $solution = $solutions.CrmRecords[0]
        $solutionVersion = $solution.version
        Write-Host "Solution version already installed is $solutionVersion"
    
        if($skp -and $slnZipVersion -eq $solutionVersion)
        {
            Write-Warning "Skipping! Solution versions match ($solutionVersion)"
            return;
        }
    }

    #import solution
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
