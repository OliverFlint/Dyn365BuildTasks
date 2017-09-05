[CmdletBinding()]
Param(
    # Parameter help description
    [Parameter(Mandatory=$false)]
    [switch]
    $ReDeploy
)

if($ReDeploy) {
    Invoke-Expression "tfx build tasks delete --task-id 2007e0c0-8465-11e7-877a-4b139e4565f7"
    Invoke-Expression "tfx build tasks delete --task-id 19e5ecc0-8ab2-11e7-b763-79549c856ef7"
    Invoke-Expression "tfx build tasks delete --task-id bdeda48b-674f-48b9-b055-1507c9ef2484"
}

Invoke-Expression "tfx build tasks upload --task-path ./Dyn365SolutionVersion"
Invoke-Expression "tfx build tasks upload --task-path ./Dyn365SolutionExport"
Invoke-Expression "tfx build tasks upload --task-path ./Dyn365PublishAll"