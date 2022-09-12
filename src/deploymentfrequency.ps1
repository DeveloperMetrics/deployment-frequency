#Parameters for the top level  deploymentfrequency.ps1 PowerShell script
Param(
    [string] $ownerRepo,
    [string] $workflows,
    [string] $branch,
    [Int32] $numberOfDays,
    [string] $ghPatToken = "",
    [string] $ghActionsToken = ""#,
    #[string] $ghAppToken 
)

#The main function
function Main ([string] $ownerRepo,
    [string] $workflows,
    [string] $branch,
    [Int32] $numberOfDays,
    [string] $ghPatToken,
    [string] $ghActionsToken#,
    #[string] $ghAppToken 
    ){

#==========================================
#Input processing
$ownerRepoArray = $ownerRepo -split '/'
$owner = $ownerRepoArray[0]
$repo = $ownerRepoArray[1]
Write-Output "Owner/Repo: $owner/$repo"
$workflowsArray = $workflows -split ','
Write-Output "Workflows: $($workflowsArray[0])"
Write-Output "Branch: $branch"
$numberOfDays = $numberOfDays        
Write-Output "Number of days: $numberOfDays"

#==========================================
# Get authorization headers
$authHeader = GetAuthHeader($ghPatToken, $ghActionsToken)

#==========================================
#Get workflow definitions from github
$uri = "https://api.github.com/repos/$owner/$repo/actions/workflows"
if (!$authHeader)
{
    #No authentication
    Write-Output "No authentication"
    $workflowsResponse = Invoke-RestMethod -Uri $uri -ContentType application/json -Method Get -ErrorAction Stop
}
else
{
    #there is authentication
    if (![string]::IsNullOrEmpty($ghPatToken))
    {
        Write-Output "Authentication detected: PAT TOKEN"  
    }      
    elseif (![string]::IsNullOrEmpty($ghActionsToken))
    {
        Write-Output "Authentication detected: GITHUB TOKEN"  
    }
    $workflowsResponse = Invoke-RestMethod -Uri $uri -ContentType application/json -Method Get -Headers @{Authorization=($authHeader["Authorization"])} -ErrorAction Stop 
    #$workflowsResponse = Invoke-RestMethod -Uri $uri -ContentType application/json -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -ErrorAction Stop
    #$workflowsResponse = Invoke-RestMethod -Uri $uri -ContentType application/json -Method Get -Headers @{Authorization=("Bearer {0}" -f $base64AuthInfo)} -ErrorAction Stop
}

#Extract workflow ids from the definitions, using the array of names. Number of Ids should == number of workflow names
$workflowIds = [System.Collections.ArrayList]@()
Foreach ($workflow in $workflowsResponse.workflows){

    Foreach ($arrayItem in $workflowsArray){
        if ($workflow.name -eq $arrayItem)
        {
            #Write-Output "'$($workflow.name)' matched with $arrayItem"
            $result = $workflowIds.Add($workflow.id)
            if ($result -lt 0)
            {
                Write-Output "unexpected result"
            }
        }
        else 
        {
            #Write-Output "'$($workflow.name)' DID NOT match with $arrayItem"
        }
    }
}

#==========================================
#Filter out workflows that were successful. Measure the number by date/day. Aggegate workflows together
$dateList = @()

#For each workflow id, get the last 100 workflows from github
Foreach ($workflowId in $workflowIds){
    #Get workflow definitions from github
    $uri2 = "https://api.github.com/repos/$owner/$repo/actions/workflows/$workflowId/runs?per_page=100"
    if (!$authHeader)
    {
        $workflowRunsResponse = Invoke-RestMethod -Uri $uri2 -ContentType application/json -Method Get -ErrorAction Stop
    }
    else
    {
        $workflowRunsResponse = Invoke-RestMethod -Uri $uri2 -ContentType application/json -Method Get -Headers @{Authorization=($authHeader["Authorization"])} -ErrorAction Stop          
    }

    $buildTotal = 0
    Foreach ($run in $workflowRunsResponse.workflow_runs){
        #Count workflows that are completed, on the target branch, and were created within the day range we are looking at
        if ($run.status -eq "completed" -and $run.head_branch -eq $branch -and $run.created_at -gt (Get-Date).AddDays(-$numberOfDays))
        {
            #Write-Output "Adding item with status $($run.status), branch $($run.head_branch), created at $($run.created_at), compared to $((Get-Date).AddDays(-$numberOfDays))"
            $buildTotal++       
            #get the workflow start and end time            
            $dateList += New-Object PSObject -Property @{start_datetime=$run.created_at;end_datetime=$run.updated_at}     
        }
    }
}

#==========================================
#Show current rate limit
$uri3 = "https://api.github.com/rate_limit"
if (!$authHeader)
{
    $rateLimitResponse = Invoke-RestMethod -Uri $uri3 -ContentType application/json -Method Get -ErrorAction Stop
}
else
{
    $rateLimitResponse = Invoke-RestMethod -Uri $uri3 -ContentType application/json -Method Get -Headers @{Authorization=($authHeader["Authorization"])}  -ErrorAction Stop
}    
Write-Output "Rate limit consumption: $($rateLimitResponse.rate.used) / $($rateLimitResponse.rate.limit)"


#==========================================
#Calculate deployments per day
$deploymentsPerDay = 0

if ($dateList.Count -gt 0 -and $numberOfDays -gt 0)
{
    $deploymentsPerDay = $dateList.Count / $numberOfDays
}


#==========================================
#output result
$dailyDeployment = 1
$weeklyDeployment = 1 / 7
$monthlyDeployment = 1 / 30
$everySixMonthsDeployment = 1 / (6 * 30) #//Every 6 months
$yearlyDeployment = 1 / 365

#Calculate rating 
$rating = ""
if ($deploymentsPerDay -le 0)
{
    $rating = "None"
}
elseif ($deploymentsPerDay -ge $dailyDeployment)
{
    $rating = "Elite"
}
elseif ($deploymentsPerDay -le $dailyDeployment -and $deploymentsPerDay -ge $monthlyDeployment)
{
    $rating = "High"
}
elseif (deploymentsPerDay -le $monthlyDeployment -and $deploymentsPerDay -ge $everySixMonthsDeployment)
{
    $rating = "Medium"
}
elseif ($deploymentsPerDay -le $everySixMonthsDeployment)
{
    $rating = "Low"
}

#Calculate metric and unit
if ($deploymentsPerDay -gt $dailyDeployment) 
{
    $displayMetric = [math]::Round($deploymentsPerDay,2)
    $displayUnit = "per day"
}
elseif ($deploymentsPerDay -le $dailyDeployment -and $deploymentsPerDay -ge $weeklyDeployment)
{
    $displayMetric = [math]::Round($deploymentsPerDay * 7,2)
    $displayUnit = "times per week"
}
elseif ($deploymentsPerDay -lt $weeklyDeployment -and $deploymentsPerDay -ge $monthlyDeployment)
{
    $displayMetric = [math]::Round($deploymentsPerDay * 30,2)
    $displayUnit = "times per month"
}
elseif ($deploymentsPerDay -lt $monthlyDeployment -and $deploymentsPerDay -gt $yearlyDeployment)
{
    $displayMetric = [math]::Round($deploymentsPerDay * 30,2)
    $displayUnit = "times per month"
}
elseif ($deploymentsPerDay -le $yearlyDeployment)
{
    $displayMetric = [math]::Round($deploymentsPerDay * 365,2)
    $displayUnit = "times per year"
}

Write-Output "Deployment frequency over last $numberOfDays days, is $displayMetric $displayUnit, with a DORA rating of '$rating'"
}

#Generate the authorization header for the PowerShell call to the GitHub API
#warning: PowerShell has really wacky return semantics - all output is captured, and returned
#reference: https://stackoverflow.com/questions/10286164/function-return-value-in-powershell
function GetAuthHeader ([string] $ghPatToken, [string] $ghActionsToken) {
    #Clean the string - without this the PAT TOKEN doesn't process
    $ghPatToken = $ghPatToken.Trim()

    if (![string]::IsNullOrEmpty($ghPatToken))
    {
        $base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$ghPatToken"))
        $authHeader = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
    }
    elseif (![string]::IsNullOrEmpty($ghActionsToken))
    {
        $authHeader = @{Authorization=("Bearer {0}" -f $base64AuthInfo)}
    }
    else
    {
        $base64AuthInfo = $null
        $authHeader = $null
    }

    return $authHeader
}

cls
main -ownerRepo $ownerRepo -workflows $workflows -branch $branch -numberOfDays $numberOfDays -ghPatToken $ghPatToken -ghActionsToken $ghActionsToken

exit $LASTEXITCODE