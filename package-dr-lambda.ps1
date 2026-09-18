#!/usr/bin/env pwsh
# Package Lambda function for DR scale-up

Write-Host "Packaging DR Scale-Up Lambda function..." -ForegroundColor Cyan

$lambdaDir = "lambda"
$outputZip = "$lambdaDir/dr-scale-up.zip"

# Remove existing zip if present
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
    Write-Host "Removed existing zip file" -ForegroundColor Yellow
}

# Create zip file
Compress-Archive -Path "$lambdaDir/dr-scale-up.py" -DestinationPath $outputZip -Force

if (Test-Path $outputZip) {
    $size = (Get-Item $outputZip).Length / 1KB
    Write-Host "✓ Lambda function packaged successfully: $outputZip ($([math]::Round($size, 2)) KB)" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to package Lambda function" -ForegroundColor Red
    exit 1
}
