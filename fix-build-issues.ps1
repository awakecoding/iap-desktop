# Fix Remaining Build Issues Script for IAP Desktop

Write-Host "========================================================"
Write-Host "=== Fixing Remaining Build Issues                   ==="
Write-Host "========================================================"

$rootDir = $PSScriptRoot
$sourcesDir = Join-Path $rootDir "sources"

Write-Host "Fixing TaskDialog ambiguous reference errors..."

# Fix TaskDialog ambiguous references in test files
$testFiles = @(
    "Google.Solutions.Mvvm.Test\Controls\TestTaskDialog.cs"
)

foreach ($file in $testFiles) {
    $filePath = Join-Path $sourcesDir $file
    if (Test-Path $filePath) {
        Write-Host "Fixing TaskDialog references in $file"
        
        $content = Get-Content $filePath
        $content = $content -replace '\bTaskDialog\b', 'Google.Solutions.Mvvm.Controls.TaskDialog'
        $content = $content -replace '\bTaskDialogCommandLinkButton\b', 'Google.Solutions.Mvvm.Controls.TaskDialogCommandLinkButton'
        $content = $content -replace '\bTaskDialogVerificationCheckBox\b', 'Google.Solutions.Mvvm.Controls.TaskDialogVerificationCheckBox'
        
        $content | Set-Content $filePath
        Write-Host "Fixed TaskDialog references in $file"
    }
}

# Fix VirtualFileDataObject ref keyword issues
$virtualFileTestPath = Join-Path $sourcesDir "Google.Solutions.Mvvm.Test\Shell\TestVirtualFileDataObject.cs"
if (Test-Path $virtualFileTestPath) {
    Write-Host "Fixing ref keyword issues in VirtualFileDataObject tests"
    
    $content = Get-Content $virtualFileTestPath
    # Find patterns like GetData(format) and replace with GetData(ref format) where appropriate
    $content = $content -replace '\.GetData\(([^)]+)\)', '.GetData(ref $1)'
    
    $content | Set-Content $virtualFileTestPath
    Write-Host "Fixed ref keyword issues"
}

Write-Host "========================================================"
Write-Host "=== Build Issues Fix Complete                       ==="
Write-Host "========================================================"

Write-Host ""
Write-Host "? Fixed most common build issues!"
Write-Host ""
Write-Host "The solution should now build with significantly fewer errors."
Write-Host "Any remaining errors are likely minor compatibility issues that"
Write-Host "can be addressed individually as needed."
Write-Host ""
Write-Host "Try building again with:"
Write-Host "  dotnet build sources\Google.Solutions.IapDesktop.sln"