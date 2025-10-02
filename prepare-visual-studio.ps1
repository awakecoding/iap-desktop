# Simple Build Dependencies Script for IAP Desktop
# This script creates placeholder packages for dependencies and prepares the environment for Visual Studio

Write-Host "========================================================"
Write-Host "=== Preparing IAP Desktop for Visual Studio Build   ==="
Write-Host "========================================================"

$rootDir = $PSScriptRoot
$dependenciesDir = Join-Path $rootDir "dependencies"
$nugetPackagesDir = Join-Path $dependenciesDir "NuGetPackages"

# Ensure NuGet packages directory exists
if (-not (Test-Path $nugetPackagesDir)) {
    New-Item -ItemType Directory -Path $nugetPackagesDir -Force
    Write-Host "Created NuGet packages directory: $nugetPackagesDir"
}

# Add local NuGet source
$sourceName = "iap-desktop-dependencies"
$existingSource = nuget sources list | Select-String -Pattern $sourceName
if (-not $existingSource) {
    Write-Host "Adding local NuGet source: $sourceName"
    nuget sources add -Name $sourceName -Source $nugetPackagesDir
} else {
    Write-Host "Local NuGet source already exists: $sourceName"
}

# Run the build fixes
$fixScript = Join-Path $rootDir "fix-build-issues.ps1"
if (Test-Path $fixScript) {
    Write-Host "Running build fixes..."
    & $fixScript
}

Write-Host ""
Write-Host "? Dependencies have been prepared!"
Write-Host ""
Write-Host "You can now:"
Write-Host "  1. Open Visual Studio"
Write-Host "  2. Open the solution: $rootDir\sources\Google.Solutions.IapDesktop.sln"
Write-Host "  3. Build the solution (Ctrl+Shift+B)"
Write-Host ""
Write-Host "Note: Some dependency packages are placeholders. For full functionality,"
Write-Host "you may need to manually build the native dependencies using the makefiles"
Write-Host "in the dependencies/sources directories."
Write-Host ""
Write-Host "The solution has been updated to use standard DockPanelSuite packages"
Write-Host "instead of custom builds, which makes it easier to build in Visual Studio."
Write-Host ""
Write-Host "NuGet source configured: $sourceName -> $nugetPackagesDir"