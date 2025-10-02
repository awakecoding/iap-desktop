# Final Build Fix Script - Address Remaining Issues
# This script fixes the last remaining build errors for IAP Desktop

Write-Host "========================================================"
Write-Host "=== Final Build Fix - Remaining Issues              ==="
Write-Host "========================================================"

$rootDir = $PSScriptRoot
$sourcesDir = Join-Path $rootDir "sources"

# Fix 1: Add WFO1000 suppression to test projects that need it
Write-Host "Adding WFO1000 suppression to test projects..."

$testProjectsToFix = @(
    "Google.Solutions.IapDesktop.Application.Test\Google.Solutions.IapDesktop.Application.Test.csproj"
)

foreach ($projectFile in $testProjectsToFix) {
    $projectPath = Join-Path $sourcesDir $projectFile
    if (Test-Path $projectPath) {
        Write-Host "Adding WFO1000 suppression to: $projectFile"
        
        $content = Get-Content $projectPath -Raw
        
        # Add NoWarn for WFO1000 if not already present
        if ($content -notmatch 'NoWarn.*WFO1000') {
            $content = $content -replace '(<PropertyGroup[^>]*>)', "`$1`n    <NoWarn>`$(NoWarn);WFO1000</NoWarn>"
        }
        
        Set-Content $projectPath $content -NoNewline
        Write-Host "Added WFO1000 suppression to: $projectFile"
    }
}

# Fix 2: Fix TaskDialog ambiguous references in remaining files
Write-Host "Fixing TaskDialog ambiguous references..."

$filesToFixTaskDialog = @(
    "Google.Solutions.IapDesktop.Application.Test\ToolWindows\Update\TestCheckForUpdateCommand.cs",
    "Google.Solutions.IapDesktop.Extensions.Diagnostics\Dialog\DialogCommands.cs"
)

foreach ($file in $filesToFixTaskDialog) {
    $filePath = Join-Path $sourcesDir $file
    if (Test-Path $filePath) {
        Write-Host "Fixing TaskDialog references in: $file"
        
        $content = Get-Content $filePath -Raw
        
        # Fix TaskDialog ambiguous references by using fully qualified names
        $content = $content -replace '\bTaskDialog(?![A-Za-z])', 'Google.Solutions.Mvvm.Controls.TaskDialog'
        $content = $content -replace '\bTaskDialogIcon(?![A-Za-z])', 'Google.Solutions.Mvvm.Controls.TaskDialogIcon'
        $content = $content -replace '\bTaskDialogCommandLinkButton(?![A-Za-z])', 'Google.Solutions.Mvvm.Controls.TaskDialogCommandLinkButton'
        $content = $content -replace '\bTaskDialogVerificationCheckBox(?![A-Za-z])', 'Google.Solutions.Mvvm.Controls.TaskDialogVerificationCheckBox'
        
        # Fix over-aggressive replacements
        $content = $content -replace 'Google\.Solutions\.Mvvm\.Controls\.Google\.Solutions\.Mvvm\.Controls\.TaskDialog', 'Google.Solutions.Mvvm.Controls.TaskDialog'
        
        Set-Content $filePath $content -NoNewline
        Write-Host "Fixed TaskDialog references in: $file"
    }
}

# Fix 3: Fix TabAccentColorIndex missing references
Write-Host "Fixing TabAccentColorIndex references..."

$sessionFactoryPath = Join-Path $sourcesDir "Google.Solutions.IapDesktop.Extensions.Session\ToolWindows\Session\SessionFactory.cs"
if (Test-Path $sessionFactoryPath) {
    Write-Host "Fixing TabAccentColorIndex references in SessionFactory.cs..."
    
    $content = Get-Content $sessionFactoryPath -Raw
    
    # Replace TabAccentColorIndex with simple integers (this was a custom DockPanelSuite enum)
    $content = $content -replace 'TabAccentColorIndex\.Accent1', '1'
    $content = $content -replace 'TabAccentColorIndex\.Accent2', '2'
    $content = $content -replace 'TabAccentColorIndex\.Accent3', '3'
    $content = $content -replace 'TabAccentColorIndex\.Accent4', '4'
    $content = $content -replace 'TabAccentColorIndex\.None', '0'
    $content = $content -replace 'TabAccentColorIndex\s+', 'int '
    
    Set-Content $sessionFactoryPath $content -NoNewline
    Write-Host "Fixed TabAccentColorIndex references in SessionFactory.cs"
}

Write-Host "========================================================"
Write-Host "=== Final Build Fix Complete                        ==="
Write-Host "========================================================"

Write-Host ""
Write-Host "? Applied final build fixes!"
Write-Host ""
Write-Host "Changes made:"
Write-Host "  • Added WFO1000 suppression to test projects"
Write-Host "  • Fixed remaining TaskDialog ambiguous references"  
Write-Host "  • Fixed TabAccentColorIndex missing enum (replaced with integers)"
Write-Host ""
Write-Host "Try building again with:"
Write-Host "  dotnet build sources\Google.Solutions.IapDesktop.sln"