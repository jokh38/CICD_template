#!/usr/bin/env pwsh
# Final Comprehensive Validation for Windows

$ErrorActionPreference = "Stop"

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Status {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Error-Output {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "================================" "Cyan"
    Write-ColorOutput $Title "Cyan"
    Write-ColorOutput "================================" "Cyan"
}

# Validation counters
$TotalCategories = 0
$PassedCategories = 0

# Function to run a category of tests
function Test-Category {
    param(
        [string]$CategoryName,
        [scriptblock]$TestScript
    )

    $TotalCategories++
    Write-Header $CategoryName

    try {
        $categoryPassed = $true
        $testResults = & $TestScript

        if ($testResults.Passed -eq $testResults.Total) {
            Write-Success "✅ $CategoryName - PASSED ($($testResults.Passed)/$($testResults.Total) tests)"
            $PassedCategories++
        } else {
            Write-Error-Output "❌ $CategoryName - FAILED ($($testResults.Passed)/$($testResults.Total) tests passed)"
            $categoryPassed = $false
        }

        return @{
            Passed = $categoryPassed
            Results = $testResults
        }
    } catch {
        Write-Error-Output "❌ $CategoryName - ERROR: $($_.Exception.Message)"
        return @{
            Passed = $false
            Results = @{
                Total = 0
                Passed = 0
                Failed = 1
                Errors = @($_.Exception.Message)
            }
        }
    }
}

# Function to test a single command
function Test-Command {
    param(
        [string]$Command,
        [string]$Description,
        [string]$ExpectedPattern = $null
    )

    try {
        $result = Invoke-Expression $Command 2>&1
        if ($LASTEXITCODE -eq 0) {
            if ($ExpectedPattern -and $result -notmatch $ExpectedPattern) {
                return @{
                    Command = $Command
                    Description = $Description
                    Passed = $false
                    Error = "Output doesn't match expected pattern: $ExpectedPattern"
                    Output = $result
                }
            }
            return @{
                Command = $Command
                Description = $Description
                Passed = $true
                Output = $result
            }
        } else {
            return @{
                Command = $Command
                Description = $Description
                Passed = $false
                Error = "Exit code: $LASTEXITCODE"
                Output = $result
            }
        }
    } catch {
        return @{
            Command = $Command
            Description = $Description
            Passed = $false
            Error = $_.Exception.Message
        }
    }
}

# System Tools Tests
function Test-SystemTools {
    $tests = @(
        @{ Command = "git --version"; Description = "Git" },
        @{ Command = "cmake --version"; Description = "CMake" },
        @{ Command = "ninja --version"; Description = "Ninja" },
        @{ Command = "python --version"; Description = "Python" },
        @{ Command = "pip --version"; Description = "Pip" },
        @{ Command = "choco --version"; Description = "Chocolatey" }
    )

    $passed = 0
    $total = $tests.Count
    $errors = @()

    foreach ($test in $tests) {
        $result = Test-Command -Command $test.Command -Description $test.Description
        if ($result.Passed) {
            Write-Success "✓ $($test.Description) is available"
            $passed++
        } else {
            Write-Error-Output "✗ $($test.Description) not working: $($result.Error)"
            $errors += "$($test.Description): $($result.Error)"
        }
    }

    return @{ Total = $total; Passed = $passed; Errors = $errors }
}

# Compiler Tools Tests
function Test-CompilerTools {
    $tests = @(
        @{ Command = "gcc --version"; Description = "GCC" },
        @{ Command = "clang --version"; Description = "Clang" },
        @{ Command = "clang-format --version"; Description = "Clang-format" },
        @{ Command = "clang-tidy --version"; Description = "Clang-tidy" },
        @{ Command = "sccache --version"; Description = "sccache" }
    )

    $passed = 0
    $total = $tests.Count
    $errors = @()

    foreach ($test in $tests) {
        $result = Test-Command -Command $test.Command -Description $test.Description
        if ($result.Passed) {
            Write-Success "✓ $($test.Description) is available"
            $passed++
        } else {
            Write-Warning "✗ $($test.Description) not working: $($result.Error)"
            $errors += "$($test.Description): $($result.Error)"
        }
    }

    # Test MSVC (Visual Studio Compiler)
    try {
        $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (Test-Path $vsWhere) {
            $vsPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
            if ($vsPath) {
                Write-Success "✓ Visual Studio C++ tools found at: $vsPath"
                $passed++
            } else {
                Write-Warning "✗ Visual Studio C++ tools not found"
                $errors += "Visual Studio C++ tools not found"
            }
        } else {
            Write-Warning "✗ Visual Studio Installer not found"
            $errors += "Visual Studio Installer not found"
        }
        $total++
    } catch {
        Write-Warning "✗ Could not check Visual Studio installation: $($_.Exception.Message)"
        $errors += "Visual Studio check failed: $($_.Exception.Message)"
        $total++
    }

    return @{ Total = $total; Passed = $passed; Errors = $errors }
}

# Build Tools Tests
function Test-BuildTools {
    $tests = @(
        @{ Command = "conan --version"; Description = "Conan" },
        @{ Command = "vcpkg version"; Description = "vcpkg" }
    )

    $passed = 0
    $total = $tests.Count
    $errors = @()

    foreach ($test in $tests) {
        $result = Test-Command -Command $test.Command -Description $test.Description
        if ($result.Passed) {
            Write-Success "✓ $($test.Description) is available"
            $passed++
        } else {
            Write-Warning "✗ $($test.Description) not working: $($result.Error)"
            $errors += "$($test.Description): $($result.Error)"
        }
    }

    # Check make availability
    try {
        $makeResult = make --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "✓ GNU Make is available"
            $passed++
        } else {
            Write-Warning "✗ GNU Make not available"
            $errors += "GNU Make not available"
        }
    } catch {
        Write-Warning "✗ GNU Make not found"
        $errors += "GNU Make not found"
    }
    $total++

    return @{ Total = $total; Passed = $passed; Errors = $errors }
}

# Python Tools Tests
function Test-PythonTools {
    $tests = @(
        @{ Command = "ruff --version"; Description = "Ruff" },
        @{ Command = "black --version"; Description = "Black" },
        @{ Command = "pytest --version"; Description = "Pytest" },
        @{ Command = "mypy --version"; Description = "MyPy" },
        @{ Command = "bandit --version"; Description = "Bandit" },
        @{ Command = "pre-commit --version"; Description = "Pre-commit" }
    )

    $passed = 0
    $total = $tests.Count
    $errors = @()

    foreach ($test in $tests) {
        $result = Test-Command -Command $test.Command -Description $test.Description
        if ($result.Passed) {
            Write-Success "✓ $($test.Description) is available"
            $passed++
        } else {
            Write-Warning "✗ $($test.Description) not working: $($result.Error)"
            $errors += "$($test.Description): $($result.Error)"
        }
    }

    return @{ Total = $total; Passed = $passed; Errors = $errors }
}

# Configuration Files Tests
function Test-ConfigurationFiles {
    $configFiles = @(
        @{ Path = "$env:USERPROFILE\.gitignore_global"; Description = "Global gitignore" },
        @{ Path = "$env:USERPROFILE\.clang-format"; Description = "Clang-format config" },
        @{ Path = "$env:USERPROFILE\.clang-tidy"; Description = "Clang-tidy config" },
        @{ Path = "$env:USERPROFILE\.config\ruff\ruff.toml"; Description = "Ruff config" },
        @{ Path = "$env:USERPROFILE\pyproject.toml"; Description = "Python project config" },
        @{ Path = "$env:USERPROFILE\.config\cmake\CMakePresets.json"; Description = "CMake presets" },
        @{ Path = "$env:USERPROFILE\.config\sccache\config"; Description = "sccache config" },
        @{ Path = "$env:USERPROFILE\.config\ai-workflows"; Description = "AI workflow templates" }
    )

    $passed = 0
    $total = $configFiles.Count
    $errors = @()

    foreach ($config in $configFiles) {
        if (Test-Path $config.Path) {
            Write-Success "✓ $($config.Description) exists"
            $passed++
        } else {
            Write-Warning "✗ $($config.Description) not found at: $($config.Path)"
            $errors += "$($config.Description): Not found"
        }
    }

    return @{ Total = $total; Passed = $passed; Errors = $errors }
}

# Git Configuration Tests
function Test-GitConfiguration {
    $gitConfigs = @(
        @{ Setting = "user.name"; Description = "Git user name" },
        @{ Setting = "user.email"; Description = "Git user email" },
        @{ Setting = "init.defaultBranch"; Description = "Default branch" },
        @{ Setting = "core.autocrlf"; Description = "Core autocrlf" },
        @{ Setting = "core.excludesfile"; Description = "Global excludes file" }
    )

    $passed = 0
    $total = $gitConfigs.Count
    $errors = @()

    foreach ($config in $gitConfigs) {
        try {
            $value = git config --global $config.Setting 2>$null
            if ($LASTEXITCODE -eq 0 -and $value) {
                Write-Success "✓ $($config.Description) configured: $value"
                $passed++
            } else {
                Write-Warning "✗ $($config.Description) not configured"
                $errors += "$($config.Description): Not configured"
            }
        } catch {
            Write-Warning "✗ $($config.Description) check failed: $($_.Exception.Message)"
            $errors += "$($config.Description): $($_.Exception.Message)"
        }
    }

    return @{ Total = $total; Passed = $passed; Errors = $errors }
}

# C++ Compilation Tests
function Test-CppCompilation {
    Write-Status "Testing C++ compilation..."

    $passed = 0
    $total = 0
    $errors = @()

    # Create test C++ file
    $testCppFile = Join-Path $env:TEMP "test_validation.cpp"
    $testCppContent = @"
#include <iostream>
#include <vector>
#include <string>

int main() {
    std::vector<int> numbers = {1, 2, 3, 4, 5};
    int sum = 0;
    for (int num : numbers) {
        sum += num;
    }
    std::cout << "Sum: " << sum << std::endl;
    std::cout << "Windows C++ validation test successful!" << std::endl;
    return 0;
}
"@

    $testCppContent | Out-File -FilePath $testCppFile -Encoding UTF8 -Force

    # Test with MSVC (if available)
    $total++
    try {
        $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (Test-Path $vsWhere) {
            $vsPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
            if ($vsPath) {
                $vcVarsPath = Join-Path $vsPath "VC\Auxiliary\Build\vcvars64.bat"
                if (Test-Path $vcVarsPath) {
                    $outputFile = Join-Path $env:TEMP "msvc_output.txt"
                    $cmd = "cmd /c `"`"$vcVarsPath`" && cl /EHsc /Fe:`"$env:TEMP\msvc_test.exe`" `"$testCppFile`" && `"$env:TEMP\msvc_test.exe`" > `"$outputFile`"`""
                    Invoke-Expression $cmd | Out-Null

                    if ($LASTEXITCODE -eq 0 -and (Test-Path $outputFile)) {
                        $output = Get-Content $outputFile -Raw
                        if ($output -match "Sum: 15" -and $output -match "successful") {
                            Write-Success "✓ MSVC compilation and execution successful"
                            $passed++
                        } else {
                            Write-Warning "✗ MSVC program output incorrect"
                            $errors += "MSVC: Incorrect program output"
                        }
                        Remove-Item $outputFile -ErrorAction SilentlyContinue
                        Remove-Item "$env:TEMP\msvc_test.exe" -ErrorAction SilentlyContinue
                    } else {
                        Write-Warning "✗ MSVC compilation failed"
                        $errors += "MSVC: Compilation failed"
                    }
                } else {
                    Write-Warning "✗ MSVC vcvars64.bat not found"
                    $errors += "MSVC: vcvars64.bat not found"
                }
            } else {
                Write-Warning "✗ Visual Studio installation not found"
                $errors += "MSVC: Visual Studio not found"
            }
        } else {
            Write-Warning "✗ Visual Studio Installer not found"
            $errors += "MSVC: VS Installer not found"
        }
    } catch {
        Write-Warning "✗ MSVC test failed: $($_.Exception.Message)"
        $errors += "MSVC: $($_.Exception.Message)"
    }

    # Test with Clang (if available)
    $total++
    try {
        $outputFile = Join-Path $env:TEMP "clang_output.txt"
        $result = clang++ -std=c++17 -o "$env:TEMP\clang_test.exe" $testCppFile 2>&1
        if ($LASTEXITCODE -eq 0) {
            & "$env:TEMP\clang_test.exe" > $outputFile 2>&1
            if ($LASTEXITCODE -eq 0) {
                $output = Get-Content $outputFile -Raw
                if ($output -match "Sum: 15" -and $output -match "successful") {
                    Write-Success "✓ Clang compilation and execution successful"
                    $passed++
                } else {
                    Write-Warning "✗ Clang program output incorrect"
                    $errors += "Clang: Incorrect program output"
                }
            } else {
                Write-Warning "✗ Clang program execution failed"
                $errors += "Clang: Program execution failed"
            }
            Remove-Item "$env:TEMP\clang_test.exe" -ErrorAction SilentlyContinue
        } else {
            Write-Warning "✗ Clang compilation failed"
            $errors += "Clang: Compilation failed"
        }
        Remove-Item $outputFile -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "✗ Clang test failed: $($_.Exception.Message)"
        $errors += "Clang: $($_.Exception.Message)"
    }

    # Cleanup
    Remove-Item $testCppFile -ErrorAction SilentlyContinue

    return @{ Total = $total; Passed = $passed; Errors = $errors }
}

# Python Environment Tests
function Test-PythonEnvironment {
    Write-Status "Testing Python environment..."

    $passed = 0
    $total = 0
    $errors = @()

    # Test Python code execution
    $total++
    try {
        $testPyFile = Join-Path $env:TEMP "test_validation.py"
        $testPyContent = @"
#!/usr/bin/env python3
"""Test Python script for validation."""

from typing import List

def calculate_sum(numbers: List[int]) -> int:
    """Calculate sum of numbers."""
    return sum(numbers)

def main() -> None:
    """Main function."""
    numbers = [1, 2, 3, 4, 5]
    result = calculate_sum(numbers)
    print(f"Sum: {result}")
    print("Windows Python validation test successful!")

if __name__ == "__main__":
    main()
"@

        $testPyContent | Out-File -FilePath $testPyFile -Encoding UTF8 -Force

        $outputFile = Join-Path $env:TEMP "python_output.txt"
        $result = python $testPyFile > $outputFile 2>&1
        if ($LASTEXITCODE -eq 0) {
            $output = Get-Content $outputFile -Raw
            if ($output -match "Sum: 15" -and $output -match "successful") {
                Write-Success "✓ Python script execution successful"
                $passed++
            } else {
                Write-Warning "✗ Python script output incorrect"
                $errors += "Python: Incorrect script output"
            }
        } else {
            Write-Warning "✗ Python script execution failed"
            $errors += "Python: Script execution failed"
        }

        Remove-Item $testPyFile -ErrorAction SilentlyContinue
        Remove-Item $outputFile -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "✗ Python test failed: $($_.Exception.Message)"
        $errors += "Python: $($_.Exception.Message)"
    }

    # Test Python tools on current project
    $total++
    try {
        # Check if we're in a Python project directory
        if ((Test-Path "src") -or (Test-Path "tests") -or (Test-Path "pyproject.toml")) {
            Write-Status "Found Python project structure, testing on project files"

            # Test Black formatting
            if (Test-Path "src") {
                $blackResult = black --check src 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "✓ Black formatting check passed"
                } else {
                    Write-Warning "✗ Black formatting check failed"
                    $errors += "Python: Black formatting failed"
                }

                # Test Ruff linting
                $ruffResult = ruff check src 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "✓ Ruff linting passed"
                    $passed++
                } else {
                    Write-Warning "✗ Ruff linting failed"
                    $errors += "Python: Ruff linting failed"
                }

                # Test MyPy type checking
                $mypyResult = mypy src 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "✓ MyPy type checking passed"
                } else {
                    Write-Warning "✗ MyPy type checking failed"
                    $errors += "Python: MyPy type checking failed"
                }

                # Test Bandit security analysis
                $banditResult = bandit -r src 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "✓ Bandit security analysis passed"
                } else {
                    Write-Warning "✗ Bandit security analysis failed"
                    $errors += "Python: Bandit security analysis failed"
                }
            } else {
                Write-Warning "⊘ No src/ directory found, skipping code quality checks"
            }
        } else {
            # Fallback to test file approach if not in a project directory
            Write-Warning "Not in a Python project directory, using test file approach"

            $testDir = Join-Path $env:TEMP "python_test_validation"
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
            $testSrcDir = Join-Path $testDir "src"
            New-Item -Path $testSrcDir -ItemType Directory -Force | Out-Null

            $sampleCode = @"
def calculate_sum(numbers):
    ""\"Calculate sum of numbers.""\"
    return sum(numbers)

def main():
    ""\"Main function.""\"
    numbers = [1, 2, 3, 4, 5]
    result = calculate_sum(numbers)
    print(f"Sum: {result}")
    return result

if __name__ == "__main__":
    main()
"@

            $sampleCode | Out-File -FilePath (Join-Path $testSrcDir "validation.py") -Encoding UTF8 -Force

            # Test Black formatting
            $blackResult = black --check $testSrcDir 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✓ Black formatting check passed"
            } else {
                Write-Warning "✗ Black formatting check failed"
                $errors += "Python: Black formatting failed"
            }

            # Test Ruff linting
            $ruffResult = ruff check $testSrcDir 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✓ Ruff linting passed"
                $passed++
            } else {
                Write-Warning "✗ Ruff linting failed"
                $errors += "Python: Ruff linting failed"
            }

            Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "✗ Python tools test failed: $($_.Exception.Message)"
        $errors += "Python tools: $($_.Exception.Message)"
    }

    return @{ Total = $total; Passed = $passed; Errors = $errors }
}

# Performance Tests
function Test-PerformanceTools {
    Write-Status "Testing performance tools..."

    $passed = 0
    $total = 0
    $errors = @()

    # Test sccache functionality
    $total++
    try {
        $sccacheStats = sccache --show-stats 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "✓ sccache is functional"
            $passed++
        } else {
            Write-Warning "✗ sccache is not working properly"
            $errors += "sccache: Not functional"
        }
    } catch {
        Write-Warning "✗ sccache test failed: $($_.Exception.Message)"
        $errors += "sccache: $($_.Exception.Message)"
    }

    return @{ Total = $total; Passed = $passed; Errors = $errors }
}

# Integration Tests
function Test-Integration {
    Write-Status "Testing integration capabilities..."

    $passed = 0
    $total = 0
    $errors = @()

    # Test project creation and git workflow
    $total++
    try {
        $testProjectDir = Join-Path $env:TEMP "integration_test_$(Get-Date -Format 'yyyyMMddHHmmss')"
        New-Item -Path $testProjectDir -ItemType Directory -Force | Out-Null

        Set-Location $testProjectDir

        # Initialize git repo
        $gitInit = git init 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Configure git user for this repo
            git config user.name "Test User"
            git config user.email "test@example.com"

            # Create README
            "# Test Project`nFor integration testing purposes." | Out-File -FilePath "README.md" -Encoding UTF8

            # Add and commit
            $gitAdd = git add README.md 2>&1
            $gitCommit = git commit -m "Initial commit" 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "✓ Git workflow integration successful"
                $passed++
            } else {
                Write-Warning "✗ Git commit failed"
                $errors += "Git: Commit failed"
            }
        } else {
            Write-Warning "✗ Git initialization failed"
            $errors += "Git: Initialization failed"
        }

        # Cleanup
        Set-Location $env:TEMP
        Remove-Item $testProjectDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "✗ Integration test failed: $($_.Exception.Message)"
        $errors += "Integration: $($_.Exception.Message)"
    }

    return @{ Total = $total; Passed = $passed; Errors = $errors }
}

# Main validation execution
try {
    Write-Status "Starting Windows final comprehensive validation..."

    # Run all test categories
    $results = @(
        (Test-Category "System Tools Validation" { Test-SystemTools }),
        (Test-Category "Compiler Tools Validation" { Test-CompilerTools }),
        (Test-Category "Build Tools Validation" { Test-BuildTools }),
        (Test-Category "Python Development Tools Validation" { Test-PythonTools }),
        (Test-Category "Configuration Files Validation" { Test-ConfigurationFiles }),
        (Test-Category "Git Configuration Validation" { Test-GitConfiguration }),
        (Test-Category "C++ Compilation Validation" { Test-CppCompilation }),
        (Test-Category "Python Environment Validation" { Test-PythonEnvironment }),
        (Test-Category "Performance Tools Validation" { Test-PerformanceTools }),
        (Test-Category "Integration Tests Validation" { Test-Integration })
    )

    # Final Summary
    Write-Header "Final Validation Summary"

    Write-Host "Total Categories: $TotalCategories"
    Write-Host "Passed Categories: $PassedCategories"
    Write-Host "Failed Categories: $($TotalCategories - $PassedCategories)"

    Write-Host ""
    Write-Host "Environment Information:"
    Write-Host "- OS: $((Get-WmiObject -Class Win32OperatingSystem).Caption)"
    Write-Host "- Version: $((Get-WmiObject -Class Win32OperatingSystem).Version)"
    Write-Host "- Architecture: $((Get-WmiObject -Class Win32OperatingSystem).OSArchitecture)"
    Write-Host "- PowerShell: $($PSVersionTable.PSVersion)"
    Write-Host "- User: $env:USERNAME"
    Write-Host "- Home Directory: $env:USERPROFILE"
    Write-Host "- Current Directory: $((Get-Location).Path)"

    Write-Host ""
    Write-Host "Key Tool Versions:"
    try {
        $gitVersion = git --version 2>$null
        Write-Host "- Git: $gitVersion"
    } catch {
        Write-Host "- Git: Not available"
    }

    try {
        $cmakeVersion = cmake --version 2>$null
        Write-Host "- CMake: $cmakeVersion"
    } catch {
        Write-Host "- CMake: Not available"
    }

    try {
        $pythonVersion = python --version 2>$null
        Write-Host "- Python: $pythonVersion"
    } catch {
        Write-Host "- Python: Not available"
    }

    try {
        $gccVersion = gcc --version 2>$null
        Write-Host "- GCC: $($gccVersion[0])"
    } catch {
        Write-Host "- GCC: Not available"
    }

    try {
        $clangVersion = clang --version 2>$null
        Write-Host "- Clang: $($clangVersion[0])"
    } catch {
        Write-Host "- Clang: Not available"
    }

    # Show detailed errors if any
    $allErrors = @()
    foreach ($result in $results) {
        if ($result.Results.Errors) {
            $allErrors += $result.Results.Errors
        }
    }

    if ($allErrors.Count -gt 0) {
        Write-Host ""
        Write-Warning "Errors encountered:"
        foreach ($error in $allErrors) {
            Write-Warning "  - $error"
        }
    }

    Write-Host ""

    if ($PassedCategories -eq $TotalCategories) {
        Write-Success "🎉 ALL VALIDATION TESTS PASSED! 🎉"
        Write-Host ""
        Write-Host "Your Windows development environment is fully configured and ready for use!"
        Write-Host ""
        Write-Host "Next Steps:"
        Write-Host "1. Start developing your projects"
        Write-Host "2. Use the provided AI workflow templates in: $env:USERPROFILE\.config\ai-workflows"
        Write-Host "3. Test your tools with real projects"
        Write-Host "4. Customize configurations as needed"
        Write-Host ""
        Write-Host "Helpful Resources:"
        Write-Host "- Git configuration: git config --global --list"
        Write-Host "- Code formatting: Check .clang-format and .config/ruff/ruff.toml"
        Write-Host "- Build presets: Check .config/cmake/CMakePresets.json"
        Write-Host "- AI workflows: $env:USERPROFILE\.config\ai-workflows\"
        Write-Host ""
        Write-Host "PowerShell Aliases Available:"
        Write-Host "- Import with: . `$env:USERPROFILE\.config\ai-workflows\scripts\dev-aliases.ps1"
        Write-Host "- Use py-test, cpp-build, gs, gp, and many more!"
        exit 0
    } else {
        Write-Error-Output "❌ SOME VALIDATION TESTS FAILED"
        Write-Host ""
        Write-Host "Please review the failed tests above and resolve the issues."
        Write-Host "You may need to reinstall or reconfigure certain tools."
        Write-Host ""
        Write-Host "Troubleshooting Tips:"
        Write-Host "1. Check that all packages were installed correctly"
        Write-Host "2. Verify environment variables are set correctly"
        Write-Host "3. Ensure you have the necessary permissions"
        Write-Host "4. Try running the setup script again"
        Write-Host "5. Restart PowerShell to refresh environment variables"
        exit 1
    }

} catch {
    Write-Error-Output "Validation process failed: $($_.Exception.Message)"
    exit 1
}