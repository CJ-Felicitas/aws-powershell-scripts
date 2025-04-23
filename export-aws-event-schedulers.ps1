# export-schedulers.ps1

$confirmation = Read-Host "Ready? [y/n]"

if ($confirmation -ne "y" -and $confirmation -ne "Y") {
    Write-Host "Cancelled."
    exit
}

# Set region
$region = "ap-southeast-1"

# Set output directory
$outputDir = "schedulers"
if (-Not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Get list of schedulers
Write-Host "`nFetching list of schedulers from region: $region..."
$schedulesJson = aws scheduler list-schedules --region $region | ConvertFrom-Json
$scheduleList = $schedulesJson.Schedules

if (-Not $scheduleList) {
    Write-Host "No schedulers found in region $region."
    exit
}

# Counter for total schedules exported
$scheduleCount = 0

# Loop through each schedule and export details
foreach ($schedule in $scheduleList) {
    $name = $schedule.Name
    Write-Host "Exporting: $name"

    $scheduleDetail = aws scheduler get-schedule --name $name --region $region | ConvertFrom-Json
    $scheduleDetail | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\$name.json"

    $scheduleCount++
}

# Summary
Write-Host "TOTAL NUMBER OF SCHEDULERS FOUND: $scheduleCount"
Write-Host "EXPORT COMPLETE"
