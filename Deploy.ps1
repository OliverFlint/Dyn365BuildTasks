[CmdletBinding()]
Param(
    # Parameter help description
    [Parameter(Mandatory=$false)]
    [switch]
    $ReDeploy,
    # Parameter help description
    [Parameter(Mandatory=$false)]
    [string]
    $TaskName
)

function DeployTask ($taskName) {
    $jsonObj = (Get-Content ".\$taskName\task.json") -join "`n" | ConvertFrom-Json
    $taskId = $jsonObj.Id
    $taskfriendlyName = $jsonObj.friendlyName
    if($ReDeploy){
        Write-Host "Deleteing task $taskfriendlyName"
        Invoke-Expression "tfx build tasks delete --task-id $taskId"
    }
    
    Write-Host "Uploading task $taskfriendlyName"
    Invoke-Expression "tfx build tasks upload --task-path ./$taskName"
}

Get-ChildItem -Directory | ForEach-Object -Process {
    if($TaskName){
        if($_.Name -eq $TaskName){
            DeployTask($TaskName)
        }
    }else{
        DeployTask($_.Name)
    }
}

