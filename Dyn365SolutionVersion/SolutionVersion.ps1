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
    $ver = Get-VstsInput -Name ver
    $calc = Get-VstsInput -Name calc -Require -AsBool
    $typ = Get-VstsInput -Name typ -Require
    $max = Get-VstsInput -Name max -Require
    $desc = Get-VstsInput -Name desc -Require -AsBool

    $connString = "AuthType=$auth;Domain=$dmn;Username=$usn;Password=$pwd;Url=$url"
    $connString

    $conn = Get-CrmConnection -ConnectionString $connString

    $solutions = Get-CrmRecords -conn $conn -EntityLogicalName solution -FilterAttribute uniquename -FilterOperator eq -FilterValue $sln -Fields uniquename,version,description

    if($solutions.CrmRecords.Count -ne 1)
    {
        throw "Solution with name `"$SolutionName`" not found!"
    }

    $solution = $solutions.CrmRecords[0]
    $oldVersion = $solution.version
    $newVersion = $oldVersion
    
    if($calc -eq $false)
    {
        $newVersion = $ver
    }
    else
    {
        $oldVersionParts = $oldVersion.Split(".")
        $oldVersionMajor = $oldVersionParts[0]
        $oldVersionMinor = $oldVersionParts[1]
        $oldVersionBuild = $oldVersionParts[2]
        $oldVersionRevision = $oldVersionParts[3]
        $padLength = $max.Length
        if($typ -eq "Date")
        {
            $newVersionDate = Get-Date -Format "yyyy.MM.dd"
            $oldVersionDate = "$oldVersionMajor.$oldVersionMinor.$oldVersionBuild"
            if($newVersionDate -eq $oldVersionDate)
            {
                $newVersionRevision = ([string](([int]$oldVersionRevision) + 1)).PadLeft($padLength,"0")
                $newVersion = "$oldVersionMajor.$oldVersionMinor.$oldVersionBuild.$newVersionRevision"
            }
            else 
            {
                $newVersion = "$newVersionDate.00"
            }
        }

        if($typ -eq "DotNet")
        {
            $startDate = [datetime]"2000-01-01"
            $endDate = Get-Date
            $timeSpan = New-TimeSpan -Start $startDate -End $endDate
            $newVersionBuild = [Math]::Round($timeSpan.TotalDays)

            $startDate = Get-Date -Format "yyyy-MM-dd"
            $endDate = Get-Date
            $timeSpan = New-TimeSpan -Start $startDate -End $endDate
            $newVersionRevision = [Math]::Round($timeSpan.TotalSeconds)

            $newVersion = "$oldVersionMajor.$oldVersionMinor.$newVersionBuild.$newVersionRevision"
        }

        if($typ -eq "Default")
        {
            $incrementNext = $false
            if($oldVersionRevision -eq $max)
            {
                $newVersionRevision = "00"
                $incrementNext = $true
            }
            else
            {
                $incrementNext = $false
                $newVersionRevision = ([string](([int]$oldVersionRevision) + 1)).PadLeft($padLength,"0")
            }

            if($incrementNext)
            {
                if($oldVersionBuild -eq $max)
                {
                    $newVersionBuild = "00"
                    $incrementNext = $true
                }
                else
                {
                    $newVersionBuild = ([string](([int]$oldVersionBuild) + 1)).PadLeft($padLength,"0")
                    $incrementNext = $false
                }
            }
            else
            {
                $newVersionBuild = $oldVersionBuild
            }

            if($incrementNext)
            {
                if($oldVersionMinor -eq $max)
                {
                    $newVersionMinor = "00"
                    $incrementNext = $true
                }
                else
                {
                    $newVersionMinor = ([string](([int]$oldVersionMinor) + 1)).PadLeft($padLength,"0")
                    $incrementNext = $false
                }
            }
            else
            {
                $newVersionMinor = $oldVersionMinor
            }

            if($incrementNext)
            {
                $newVersionMajor = ([string](([int]$oldVersionMajor) + 1)).PadLeft($padLength,"0")
                $incrementNext = $false
            }
            else
            {
                $newVersionMajor = $oldVersionMajor
            }

            $newVersion = "$newVersionMajor.$newVersionMinor.$newVersionBuild.$newVersionRevision"
        }
    }
    
    $solution.version = $newVersion

    Set-VstsTaskVariable -Name "Dyn365NewSolutionVersion" -Value $newVersion
    
    if($desc)
    {
        $descDate = Get-Date -Format "yyyy/MM/dd"
        $newDesc = "Version $newVersion - $descDate"
        $oldDesc = $solution.description
        $solution.description = "$newDesc`r`n$oldDesc"
    }

    Set-CrmRecord -conn $conn -CrmRecord $solution

    Write-Host "Solution version changed from `"$oldVersion`" to `"$newVersion`""

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
