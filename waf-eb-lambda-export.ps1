# Root export directory
$exportDir = ".\aws-export"
New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

########################################
# WAF EXPORT (WAFv2)
########################################
$wafDir = "$exportDir\waf"
New-Item -ItemType Directory -Path $wafDir -Force | Out-Null
Write-Host "`nExporting WAFv2 resources..."

$wafScope = "REGIONAL"  # or CLOUDFRONT

$webAcls = aws wafv2 list-web-acls --scope $wafScope | ConvertFrom-Json
$webAcls.WebACLs | ConvertTo-Json -Depth 5 | Out-File "$wafDir\webacls.json"

$webAclDetails = @()
foreach ($acl in $webAcls.WebACLs) {
    $details = aws wafv2 get-web-acl --scope $wafScope --name $acl.Name --id $acl.Id | ConvertFrom-Json
    $webAclDetails += $details
}
$webAclDetails | ConvertTo-Json -Depth 10 | Out-File "$wafDir\webacls-detailed.json"

$ipSets = aws wafv2 list-ip-sets --scope $wafScope | ConvertFrom-Json
$ipSets.IPSets | ConvertTo-Json -Depth 5 | Out-File "$wafDir\ipsets.json"

$ipSetDetails = @()
foreach ($ipset in $ipSets.IPSets) {
    $details = aws wafv2 get-ip-set --scope $wafScope --name $ipset.Name --id $ipset.Id | ConvertFrom-Json
    $ipSetDetails += $details
}
$ipSetDetails | ConvertTo-Json -Depth 10 | Out-File "$wafDir\ipsets-detailed.json"

$ruleGroups = aws wafv2 list-rule-groups --scope $wafScope | ConvertFrom-Json
$ruleGroups.RuleGroups | ConvertTo-Json -Depth 5 | Out-File "$wafDir\rule-groups.json"

$ruleGroupDetails = @()
foreach ($group in $ruleGroups.RuleGroups) {
    $details = aws wafv2 get-rule-group --scope $wafScope --name $group.Name --id $group.Id | ConvertFrom-Json
    $ruleGroupDetails += $details
}
$ruleGroupDetails | ConvertTo-Json -Depth 10 | Out-File "$wafDir\rule-groups-detailed.json"

########################################
# EVENTBRIDGE SCHEDULER EXPORT
########################################
$eventBridgeDir = "$exportDir\eventbridge"
New-Item -ItemType Directory -Path $eventBridgeDir -Force | Out-Null
Write-Host "`nExporting EventBridge Scheduler..."

$scheduleGroups = aws scheduler list-schedule-groups | ConvertFrom-Json
$scheduleGroups.ScheduleGroups | ConvertTo-Json -Depth 3 | Out-File "$eventBridgeDir\schedule-groups.json"

$schedules = aws scheduler list-schedules | ConvertFrom-Json
$schedules.Schedules | ConvertTo-Json -Depth 5 | Out-File "$eventBridgeDir\schedules.json"

$detailedScheduleData = @()
foreach ($schedule in $schedules.Schedules) {
    $details = aws scheduler get-schedule --name $schedule.Name --group-name $schedule.GroupName | ConvertFrom-Json
    $detailedScheduleData += $details
}
$detailedScheduleData | ConvertTo-Json -Depth 10 | Out-File "$eventBridgeDir\schedules-detailed.json"

########################################
# LAMBDA EXPORT
########################################
$lambdaDir = "$exportDir\lambda"
New-Item -ItemType Directory -Path $lambdaDir -Force | Out-Null
New-Item -ItemType Directory -Path "$lambdaDir\code" -Force | Out-Null
Write-Host "`nExporting Lambda functions and downloading code..."

$functions = aws lambda list-functions | ConvertFrom-Json
$functions.Functions | ConvertTo-Json -Depth 5 | Out-File "$lambdaDir\lambda-functions.json"

$lambdaDetails = @()
foreach ($function in $functions.Functions) {
    $functionName = $function.FunctionName
    Write-Host "Downloading code for Lambda: $functionName"

    $config = aws lambda get-function --function-name $functionName | ConvertFrom-Json
    $lambdaDetails += $config

    $codeLocation = $config.Code.Location
    $zipPath = "$lambdaDir\code\$functionName.zip"
    Invoke-WebRequest -Uri $codeLocation -OutFile $zipPath
}

$lambdaDetails | ConvertTo-Json -Depth 10 | Out-File "$lambdaDir\lambda-functions-detailed.json"

Write-Host "`n Export complete. Files saved in: $exportDir"
