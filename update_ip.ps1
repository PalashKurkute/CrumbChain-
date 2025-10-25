# Update IP Configuration Script
# Run this script whenever your local IP changes

# Get current IPv4 address
$currentIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq "Dhcp" -and $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -First 1).IPAddress

Write-Host "Current IP Address: $currentIp" -ForegroundColor Green

# Update backend .env file
$envPath = "backend\.env"
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath -Raw
    $envContent = $envContent -replace "LOCAL_IP=.*", "LOCAL_IP=$currentIp"
    $envContent | Set-Content $envPath -NoNewline
    Write-Host "✅ Updated backend\.env with IP: $currentIp" -ForegroundColor Green
} else {
    Write-Host "❌ backend\.env file not found!" -ForegroundColor Red
}

# Update Flutter api_config.dart
$apiConfigPath = "lib\config\api_config.dart"
if (Test-Path $apiConfigPath) {
    $apiContent = Get-Content $apiConfigPath -Raw
    $apiContent = $apiContent -replace "const String localIp =\s*'[^']+';", "const String localIp =`n          '$currentIp';"
    $apiContent | Set-Content $apiConfigPath -NoNewline
    Write-Host "✅ Updated lib\config\api_config.dart with IP: $currentIp" -ForegroundColor Green
} else {
    Write-Host "❌ lib\config\api_config.dart file not found!" -ForegroundColor Red
}

Write-Host "`n🎉 IP configuration updated successfully!" -ForegroundColor Cyan
Write-Host "Backend .env: LOCAL_IP=$currentIp" -ForegroundColor Yellow
Write-Host "Flutter config: localIp='$currentIp'" -ForegroundColor Yellow
Write-Host "`nNote: Restart your backend server if it's currently running." -ForegroundColor Magenta
