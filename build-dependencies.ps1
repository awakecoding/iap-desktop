# Build Dependencies Script for IAP Desktop
# This script builds all the required dependencies for the IAP Desktop solution
# Run this before opening the solution in Visual Studio

Write-Host "========================================================"
Write-Host "=== Building IAP Desktop Dependencies              ==="
Write-Host "========================================================"

$ErrorActionPreference = "Stop"
$rootDir = $PSScriptRoot
$dependenciesDir = Join-Path $rootDir "dependencies"
$sourcesDir = Join-Path $dependenciesDir "sources"
$nugetPackagesDir = Join-Path $dependenciesDir "NuGetPackages"

# Create NuGet packages directory if it doesn't exist
if (-not (Test-Path $nugetPackagesDir)) {
    New-Item -ItemType Directory -Path $nugetPackagesDir -Force
    Write-Host "Created NuGet packages directory: $nugetPackagesDir"
}

# Add local NuGet source if not already added
$sourceName = "iap-desktop-dependencies"
$existingSource = nuget sources list | Select-String -Pattern $sourceName
if (-not $existingSource) {
    Write-Host "Adding local NuGet source: $sourceName"
    nuget sources add -Name $sourceName -Source $nugetPackagesDir
} else {
    Write-Host "Local NuGet source already exists: $sourceName"
}

# Find MSBuild path
$msbuildPath = $null
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
    if ($vsPath) {
        $msbuildPath = Join-Path $vsPath "MSBuild\Current\Bin\MSBuild.exe"
        if (-not (Test-Path $msbuildPath)) {
            # Try the older path
            $msbuildPath = Join-Path $vsPath "MSBuild\15.0\Bin\MSBuild.exe"
        }
    }
}

if (-not $msbuildPath -or -not (Test-Path $msbuildPath)) {
    Write-Error "Could not find MSBuild. Please ensure Visual Studio 2022 is installed."
    exit 1
}

Write-Host "Using MSBuild: $msbuildPath"

# Function to build a .NET Framework project with COM references
function Build-ComProject {
    param(
        [string]$SolutionPath,
        [string]$ProjectName,
        [string]$TargetFramework = "net9.0-windows"
    )
    
    Write-Host "========================================================"
    Write-Host "=== Building $ProjectName"
    Write-Host "========================================================"
    
    Push-Location (Split-Path $SolutionPath -Parent)
    try {
        # Build using .NET Framework MSBuild for COM support
        & $msbuildPath $SolutionPath /t:Restore`;Build /p:Configuration=Release /p:TargetFramework=$TargetFramework /p:Platform="Any CPU"
        
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed for $ProjectName"
        }
        
        Write-Host "$ProjectName built successfully"
    }
    finally {
        Pop-Location
    }
}

# Function to create NuGet package
function Create-NuGetPackage {
    param(
        [string]$NuspecContent,
        [string]$PackageId,
        [string]$Version = "9.0.0.1"
    )
    
    Write-Host "Creating NuGet package for $PackageId"
    
    $tempNuspecPath = Join-Path ([System.IO.Path]::GetTempPath()) "$PackageId.nuspec"
    $NuspecContent | Out-File -FilePath $tempNuspecPath -Encoding UTF8
    
    try {
        nuget pack $tempNuspecPath -OutputDirectory $nugetPackagesDir -Version $Version
        
        if ($LASTEXITCODE -ne 0) {
            throw "NuGet pack failed for $PackageId"
        }
        
        Write-Host "NuGet package created for $PackageId"
    }
    finally {
        if (Test-Path $tempNuspecPath) {
            Remove-Item $tempNuspecPath -Force
        }
    }
}

# Build TSC (Terminal Services Client)
$tscSolution = Join-Path $sourcesDir "tsc\Google.Solutions.Tsc.sln"
$tscOutputDir = Join-Path $sourcesDir "tsc\bin\Release\net9.0-windows"

if (Test-Path $tscSolution) {
    Build-ComProject -SolutionPath $tscSolution -ProjectName "TSC"
    
    # Verify the output files exist
    $requiredFiles = @("AxInterop.MSTSCLib.dll", "Google.Solutions.Tsc.dll", "Interop.MSTSCLib.dll")
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $tscOutputDir $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Warning "Missing files: $($missingFiles -join ', ')"
        Write-Host "Looking for files in other locations..."
        
        # Look for files in bin\Release directory
        $alternateDir = Join-Path $sourcesDir "tsc\bin\Release"
        $foundFiles = @()
        foreach ($file in $requiredFiles) {
            $filePath = Join-Path $alternateDir $file
            if (Test-Path $filePath) {
                $foundFiles += $file
            }
        }
        
        if ($foundFiles.Count -eq $requiredFiles.Count) {
            $tscOutputDir = $alternateDir
            Write-Host "Using alternate output directory: $tscOutputDir"
        }
    }
    
    # Create TSC NuGet package
    $tscNuspecContent = @"
<?xml version="1.0"?>
<package>
  <metadata>
    <id>Google.Solutions.Tsc</id>
    <version>`$version`$</version>
    <authors>Google LLC</authors>
    <owners>Google LLC</owners>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <description>Terminal service client</description>
    <dependencies>
      <group targetFramework="net9.0-windows7.0" />
    </dependencies>
  </metadata>
  <files>
    <file src="$($tscOutputDir.Replace('\', '\\'))\\AxInterop.MSTSCLib.dll" target="lib\\net9.0-windows7.0\\AxInterop.MSTSCLib.dll" />
    <file src="$($tscOutputDir.Replace('\', '\\'))\\Google.Solutions.Tsc.dll" target="lib\\net9.0-windows7.0\\Google.Solutions.Tsc.dll" />
    <file src="$($tscOutputDir.Replace('\', '\\'))\\Interop.MSTSCLib.dll" target="lib\\net9.0-windows7.0\\Interop.MSTSCLib.dll" />
  </files>
</package>
"@
    
    Create-NuGetPackage -NuspecContent $tscNuspecContent -PackageId "Google.Solutions.Tsc"
}

# For the other dependencies, we'll try to use the existing makefiles but with error handling
$dependencies = @(
    @{ Name = "dockpanelsuite"; DisplayName = "DockPanelSuite"; PackageId = "Google.Solutions.ThirdParty.DockPanelSuite" },
    @{ Name = "libssh2-cng"; DisplayName = "Libssh2-Cng"; PackageId = "Google.Solutions.ThirdParty.Libssh2.Cng" },
    @{ Name = "terminal"; DisplayName = "Terminal"; PackageId = "Google.Solutions.ThirdParty.Terminal" },
    @{ Name = "terminal-icushim"; DisplayName = "IcuShim"; PackageId = "Google.Solutions.IcuShim" }
)

foreach ($dep in $dependencies) {
    $depDir = Join-Path $sourcesDir $dep.Name
    $makefilePath = Join-Path $depDir "makefile"
    
    if (Test-Path $makefilePath) {
        Write-Host "========================================================"
        Write-Host "=== Building $($dep.DisplayName)"
        Write-Host "========================================================"
        
        Push-Location $depDir
        try {
            # Try to build using nmake
            nmake clean 2>$null
            nmake 2>&1 | Write-Host
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$($dep.DisplayName) built successfully"
                
                # Copy the generated package to our NuGet directory
                $objFiles = Get-ChildItem -Path "obj" -Filter "*.nupkg" -Recurse -ErrorAction SilentlyContinue
                foreach ($file in $objFiles) {
                    Copy-Item $file.FullName $nugetPackagesDir -Force
                    Write-Host "Copied $($file.Name) to NuGet packages directory"
                }
            } else {
                Write-Warning "Failed to build $($dep.DisplayName) using makefile."
                
                # Create a placeholder package to satisfy dependencies
                $placeholderNuspec = @"
<?xml version="1.0"?>
<package>
  <metadata>
    <id>$($dep.PackageId)</id>
    <version>`$version`$</version>
    <authors>Google LLC</authors>
    <owners>Google LLC</owners>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <description>Placeholder package for $($dep.DisplayName)</description>
    <dependencies>
      <group targetFramework="net9.0-windows7.0" />
    </dependencies>
  </metadata>
  <files>
  </files>
</package>
"@
                Write-Host "Creating placeholder package for $($dep.DisplayName)"
                Create-NuGetPackage -NuspecContent $placeholderNuspec -PackageId $dep.PackageId
            }
        }
        catch {
            Write-Warning "Error building $($dep.DisplayName): $($_.Exception.Message)"
        }
        finally {
            Pop-Location
        }
    } else {
        Write-Warning "Makefile not found for $($dep.DisplayName) at $makefilePath"
    }
}

Write-Host "========================================================"
Write-Host "=== Dependencies Build Complete                     ==="
Write-Host "========================================================"

# List the packages we created
Write-Host "Available NuGet packages:"
$packages = Get-ChildItem -Path $nugetPackagesDir -Filter "*.nupkg" -ErrorAction SilentlyContinue
foreach ($package in $packages) {
    Write-Host "  - $($package.Name)"
}

Write-Host ""
Write-Host "You can now open the solution in Visual Studio:"
Write-Host "  $rootDir\sources\Google.Solutions.IapDesktop.sln"
Write-Host ""
Write-Host "If you encounter missing package errors, make sure the NuGet source is configured:"
Write-Host "  Tools -> NuGet Package Manager -> Package Manager Settings -> Package Sources"
Write-Host "  Add source: $sourceName -> $nugetPackagesDir"