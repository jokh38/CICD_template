#!/usr/bin/env pwsh
# Final Comprehensive Validation Script for Windows
# Tests all installed development tools and provides clean success/failure output

param(
    [switch]$SystemOnly,
    [switch]$CppOnly,
    [switch]$PythonOnly,
    [switch]$ConfigOnly,
    [switch]$Quick
)

$ErrorActionPreference = "Stop"

# Validation tracking
$ValidationPassed = $true
$FailedTests = @()

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to run validation test with expected result
function Test-Tool {
    param(
        [string]$TestName,
        [string]$TestCommand,
        [string]$ExpectedPattern = $null
    )

    Write-Host -NoNewline "Testing $TestName... "

    try {
        # Run test and capture output
        $output = Invoke-Expression $TestCommand 2>&1

        if ($LASTEXITCODE -eq 0) {
            if ($ExpectedPattern) {
                if ($output -match $ExpectedPattern) {
                    Write-ColorOutput "✓ PASS" "Green"
                    return $true
                } else {
                    Write-ColorOutput "✗ FAIL" "Red"
                    Write-Host "  Expected pattern: $ExpectedPattern"
                    Write-Host "  Got: $output"
                    $script:FailedTests += $TestName
                    $script:ValidationPassed = $false
                    return $false
                }
            } else {
                Write-ColorOutput "✓ PASS" "Green"
                return $true
            }
        } else {
            Write-ColorOutput "✗ FAIL" "Red"
            Write-Host "  Command failed: $TestCommand"
            $script:FailedTests += $TestName
            $script:ValidationPassed = $false
            return $false
        }
    } catch {
        Write-ColorOutput "✗ FAIL" "Red"
        Write-Host "  Command failed: $TestCommand"
        $script:FailedTests += $TestName
        $script:ValidationPassed = $false
        return $false
    }
}

function Test-SystemTools {
    Write-ColorOutput "=== System Tools Validation ===" "Cyan"

    # Test compilers
    Test-Tool "GCC compiler" "gcc --version | Select-Object -First 1" "gcc"
    Test-Tool "G++ compiler" "g++ --version | Select-Object -First 1" "g\+\+"
    Test-Tool "Clang compiler" "clang --version | Select-Object -First 1" "clang"
    Test-Tool "Clang++ compiler" "clang++ --version | Select-Object -First 1" "clang\+\+"

    # Test build tools
    Test-Tool "CMake" "cmake --version | Select-Object -First 1" "cmake"
    Test-Tool "Ninja" "ninja --version" "\d+"

    # Test git
    Test-Tool "Git" "git --version | Select-Object -First 1" "git"

    Write-Host ""
}

function Test-CppTools {
    Write-ColorOutput "=== C++ Development Tools Validation ===" "Cyan"

    # Test sccache
    Test-Tool "sccache" "sccache --version | Select-Object -First 1" "sccache"

    # Test clang-format
    Test-Tool "clang-format" "clang-format --version | Select-Object -First 1" "clang-format"

    # Test clang-tidy
    Test-Tool "clang-tidy" "clang-tidy --version" "LLVM"

    # Test C++ test project if it exists
    $testProjectPath = "$env:TEMP\cpp-test-project"
    if (Test-Path $testProjectPath) {
        Write-Host -NoNewline "Testing C++ project build... "
        try {
            Push-Location $testProjectPath
            $buildResult = cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release 2>&1
            if ($LASTEXITCODE -eq 0) {
                $buildResult2 = cmake --build build 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "✓ PASS" "Green"
                } else {
                    Write-ColorOutput "✗ FAIL" "Red"
                    $script:FailedTests += "C++ project build"
                    $script:ValidationPassed = $false
                }
            } else {
                Write-ColorOutput "✗ FAIL" "Red"
                $script:FailedTests += "C++ project build"
                $script:ValidationPassed = $false
            }
            Pop-Location
        } catch {
            Write-ColorOutput "✗ FAIL" "Red"
            $script:FailedTests += "C++ project build"
            $script:ValidationPassed = $false
        }

        Write-Host -NoNewline "Testing C++ project tests... "
        try {
            Push-Location $testProjectPath
            $testResult = ctest --test-dir build --output-on-failure 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✓ PASS" "Green"
            } else {
                Write-ColorOutput "✗ FAIL" "Red"
                $script:FailedTests += "C++ project tests"
                $script:ValidationPassed = $false
            }
            Pop-Location
        } catch {
            Write-ColorOutput "✗ FAIL" "Red"
            $script:FailedTests += "C++ project tests"
            $script:ValidationPassed = $false
        }
    } else {
        Write-ColorOutput "⚠ C++ test project not found - skipping build tests" "Yellow"
    }

    Write-Host ""
}

function Test-PythonTools {
    Write-ColorOutput "=== Python Development Tools Validation ===" "Cyan"

    # Test Python
    Test-Tool "Python interpreter" "python --version | Select-Object -First 1" "Python"

    # Test ruff
    Test-Tool "ruff linter" "python -m ruff --version | Select-Object -First 1" "ruff"
    Test-Tool "ruff formatter" "python -m ruff format --version | Select-Object -First 1" "ruff"

    # Test pytest
    Test-Tool "pytest" "python -m pytest --version | Select-Object -First 1" "pytest"

    # Test mypy
    Test-Tool "mypy" "python -m mypy --version | Select-Object -First 1" "mypy"

    # Test Python test project if it exists
    $testProjectPath = "$env:TEMP\python-test-project"
    if (Test-Path $testProjectPath) {
        Write-Host -NoNewline "Testing Python project linting... "
        try {
            Push-Location $testProjectPath
            $lintResult1 = python -m ruff check . 2>&1
            $lintResult2 = python -m ruff format --check . 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✓ PASS" "Green"
            } else {
                Write-ColorOutput "✗ FAIL" "Red"
                $script:FailedTests += "Python project linting"
                $script:ValidationPassed = $false
            }
            Pop-Location
        } catch {
            Write-ColorOutput "✗ FAIL" "Red"
            $script:FailedTests += "Python project linting"
            $script:ValidationPassed = $false
        }

        Write-Host -NoNewline "Testing Python project tests... "
        try {
            Push-Location $testProjectPath
            $testResult = python -m pytest tests/ -v 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✓ PASS" "Green"
            } else {
                Write-ColorOutput "✗ FAIL" "Red"
                $script:FailedTests += "Python project tests"
                $script:ValidationPassed = $false
            }
            Pop-Location
        } catch {
            Write-ColorOutput "✗ FAIL" "Red"
            $script:FailedTests += "Python project tests"
            $script:ValidationPassed = $false
        }

        Write-Host -NoNewline "Testing Python project type checking... "
        try {
            Push-Location $testProjectPath
            $typeCheckResult = python -m mypy . 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✓ PASS" "Green"
            } else {
                Write-ColorOutput "✗ FAIL" "Red"
                $script:FailedTests += "Python project type checking"
                $script:ValidationPassed = $false
            }
            Pop-Location
        } catch {
            Write-ColorOutput "✗ FAIL" "Red"
            $script:FailedTests += "Python project type checking"
            $script:ValidationPassed = $false
        }
    } else {
        Write-ColorOutput "⚠ Python test project not found - skipping build tests" "Yellow"
    }

    Write-Host ""
}

function Test-ConfigurationFiles {
    Write-ColorOutput "=== Configuration Files Validation ===" "Cyan"

    # Test git config (check if configured, not specific value)
    Write-Host -NoNewline "Testing Git configuration... "
    try {
        $gitConfig = git config --global user.name 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ PASS" "Green"
        } else {
            Write-ColorOutput "⚠ WARNING" "Yellow" -NoNewline
            Write-Host " - Git user name not configured"
        }
    } catch {
        Write-ColorOutput "⚠ WARNING" "Yellow" -NoNewline
        Write-Host " - Git user name not configured"
    }

    # Test config files existence (as warnings since they may not exist in all environments)
    Write-Host -NoNewline "Testing Git config file... "
    if (Test-Path "$env:USERPROFILE\.gitconfig") {
        Write-ColorOutput "✓ PASS" "Green"
    } else {
        Write-ColorOutput "⚠ WARNING" "Yellow" -NoNewline
        Write-Host " - ~/.gitconfig not found"
    }

    Write-Host -NoNewline "Testing Clang format config... "
    if (Test-Path "$env:USERPROFILE\.clang-format") {
        Write-ColorOutput "✓ PASS" "Green"
    } else {
        Write-ColorOutput "⚠ WARNING" "Yellow" -NoNewline
        Write-Host " - ~/.clang-format not found"
    }

    Write-Host -NoNewline "Testing Ruff config... "
    if (Test-Path "$env:USERPROFILE\.config\ruff\ruff.toml") {
        Write-ColorOutput "✓ PASS" "Green"
    } else {
        Write-ColorOutput "⚠ WARNING" "Yellow" -NoNewline
        Write-Host " - ~/.config/ruff/ruff.toml not found"
    }

    Write-Host ""
}

function Show-FinalSummary {
    Write-ColorOutput "================================" "Cyan"
    if ($script:ValidationPassed) {
        Write-ColorOutput "✅ ALL VALIDATIONS PASSED!" "Green"
        Write-ColorOutput "   Development environment is ready for use." "Green"
    } else {
        Write-ColorOutput "❌ VALIDATION FAILED!" "Red"
        Write-ColorOutput "   The following tests failed:" "Red"
        foreach ($test in $script:FailedTests) {
            Write-ColorOutput "   - $test" "Red"
        }
        Write-Host ""
        Write-ColorOutput "   Please check the installation and re-run validation." "Yellow"
    }
    Write-ColorOutput "================================" "Cyan"
    Write-Host ""
}

# Main execution
switch ($true) {
    $SystemOnly { Test-SystemTools }
    $CppOnly { Test-CppTools }
    $PythonOnly { Test-PythonTools }
    $ConfigOnly { Test-ConfigurationFiles }
    $Quick {
        Test-SystemTools
        Test-ConfigurationFiles
    }
    default {
        Test-SystemTools
        Test-CppTools
        Test-PythonTools
        Test-ConfigurationFiles
    }
}

Show-FinalSummary

# Exit with appropriate code
if ($script:ValidationPassed) {
    exit 0
} else {
    exit 1
}