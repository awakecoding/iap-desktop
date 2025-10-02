# Building IAP Desktop in Visual Studio

This repository has been configured to work with Visual Studio without requiring makefiles.

## Quick Start

1. **Prepare Dependencies**: Run the PowerShell script to set up the local NuGet packages:
   ```powershell
   .\prepare-visual-studio.ps1
   ```

2. **Open in Visual Studio**: Open the solution file:
   ```
   sources\Google.Solutions.IapDesktop.sln
   ```

3. **Build**: Use Visual Studio's standard build commands (Ctrl+Shift+B)

## What was fixed

The original project relied on makefiles to build custom NuGet packages for dependencies. These have been replaced with:

- **TSC Package**: Built from the .NET 9 project with COM references properly configured
- **Placeholder Packages**: Created for other native dependencies to satisfy build requirements

## Package Sources

The setup script automatically configures a local NuGet source pointing to:
```
dependencies\NuGetPackages\
```

You can verify this in Visual Studio under:
**Tools ? NuGet Package Manager ? Package Manager Settings ? Package Sources**

## Native Dependencies

Some dependencies are native C/C++ projects. The current setup uses placeholder packages to allow the solution to build. For full functionality, you may need to:

1. Install the required development tools (Visual Studio C++ components)
2. Build the native dependencies manually using their makefiles
3. Replace the placeholder packages with the actual builds

## Target Framework

This solution targets **.NET 9** with Windows-specific features enabled where required.

## Troubleshooting

- **Missing Package Errors**: Ensure the local NuGet source is configured correctly
- **COM Reference Errors**: Make sure you're using the full .NET Framework version of MSBuild (comes with Visual Studio)
- **Build Errors**: Some warnings are expected and don't prevent the application from running

## Original Makefile System

The original makefile-based build system is still available in the `dependencies` directory if you need to build the full native dependencies.