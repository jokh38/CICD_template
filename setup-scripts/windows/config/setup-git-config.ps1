#!/usr/bin/env pwsh
# Git Configuration and Initialization Setup for Windows

param(
    [string]$RunnerUser = "github-runner",
    [string]$GitUserName = "Kwanghyun Jo",
    [string]$GitUserEmail = "jokh38@gmail.com"
)

$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = $PSScriptRoot
$UtilsDir = Join-Path (Split-Path (Split-Path $ScriptDir -Parent) -Parent) "utils"

# Import utility module
$UtilsModule = Join-Path $UtilsDir "Check-Dependencies.psm1"
if (Test-Path $UtilsModule) {
    Import-Module $UtilsModule -Force
} else {
    Write-Host "ERROR: Utility module not found: $UtilsModule" -ForegroundColor Red
    exit 1
}

function Configure-GitUser {
    Write-ColorOutput "Configuring git user for $RunnerUser..." "Green"

    try {
        # Configure git user globally
        git config --global user.name $GitUserName
        git config --global user.email $GitUserEmail

        # Verify configuration
        Write-ColorOutput "Git user configuration:" "Cyan"
        git config --global user.name
        git config --global user.email

        # Configure useful git defaults
        git config --global init.defaultBranch "main"
        git config --global pull.rebase "false"
        git config --global core.autocrlf "true"  # Windows uses CRLF
        git config --global core.preloadindex "true"
        git config --global core.fscache "true"
        git config --global gc.auto "256"

        # Configure editor (use notepad++ if available, otherwise notepad)
        $editors = @("code", "notepad++", "notepad")
        $selectedEditor = $null

        foreach ($editor in $editors) {
            try {
                $null = Get-Command $editor -ErrorAction Stop
                $selectedEditor = $editor
                break
            } catch {
                continue
            }
        }

        if ($selectedEditor) {
            git config --global core.editor $selectedEditor
            Write-ColorOutput "Using editor: $selectedEditor" "Cyan"
        } else {
            git config --global core.editor "notepad"
            Write-ColorOutput "Using default editor: notepad" "Cyan"
        }

        Write-ColorOutput "Git configuration completed for $RunnerUser" "Green"

    } catch {
        Write-ColorOutput "Error configuring git user: $($_.Exception.Message)" "Red"
        throw
    }
}

function Set-GitAliases {
    Write-ColorOutput "Setting up git aliases..." "Green"

    try {
        # Set up useful git aliases
        $aliases = @{
            "st" = "status"
            "co" = "checkout"
            "br" = "branch"
            "cm" = "commit -m"
            "ca" = "commit --amend"
            "cam" = "commit --amend -m"
            "cp" = "cherry-pick"
            "fp" = "fetch --prune"
            "gr" = "graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
            "last" = "log -1 HEAD"
            "unstage" = "reset HEAD --"
            "lg" = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
            "tree" = "log --graph --pretty=oneline --abbrev-commit --all --decorate"
            "logs" = "log --show-signature --stat --graph"
            "diffstat" = "diff --stat"
            "diffstaged" = "diff --staged --stat"
        }

        foreach ($alias in $aliases.GetEnumerator()) {
            git config --global alias.$($alias.Key) $alias.Value
        }

        Write-ColorOutput "Git aliases configured" "Green"

    } catch {
        Write-ColorOutput "Error setting up git aliases: $($_.Exception.Message)" "Red"
        throw
    }
}

function Set-GitCredentialsHelper {
    Write-ColorOutput "Setting up git credentials helper..." "Green"

    try {
        # Configure credentials helper (for potential future use)
        git config --global credential.helper "manager-core"

        # Configure safe directory (important for security)
        $currentPath = Get-Location
        $userProfile = [System.Environment]::GetEnvironmentVariable("USERPROFILE", "User")

        git config --global --add safe.directory $currentPath
        git config --global --add safe.directory $userProfile

        Write-ColorOutput "Git credentials helper configured" "Green"

    } catch {
        Write-ColorOutput "Error setting up git credentials helper: $($_.Exception.Message)" "Red"
        throw
    }
}

function New-GitIgnoreGlobal {
    Write-ColorOutput "Creating global .gitignore..." "Green"

    try {
        $gitIgnorePath = Join-Path $userProfile ".gitignore_global"

        $gitIgnoreContent = @"
# Common development ignores
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE and editor files
.vscode/
.idea/
*.swp
*.swo
*~
.project
.classpath
.c9/
*.launch
.settings/
*.sublime-project
*.sublime-workspace

# Build directories
build/
cmake-build-*/
dist/
target/
bin/
out/

# Dependency directories
node_modules/
.pnp
.pnp.js

# Python
__pycache__/
*.py[cod]
*`$py.class
*.so
.Python
env/
venv/
.venv/
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
.mypy_cache/
.pytest_cache/
.coverage
htmlcov/

# Temporary files
*.tmp
*.temp
*.log
*.pid
*.seed
*.pid.lock

# Cache directories
.cache/
.sass-cache/
.parcel-cache/

# Backup files
*.bak
*.backup
*.orig
*.rej

# OS generated files
.DS_Store?
ehthumbs.db
Icon?
Thumbs.db

# Windows specific
*.lnk
*.url
desktop.ini
"@

        Set-Content -Path $gitIgnorePath -Value $gitIgnoreContent -Encoding UTF8

        # Configure git to use global gitignore
        git config --global core.excludesfile $gitIgnorePath

        Write-ColorOutput "Global .gitignore created at: $gitIgnorePath" "Green"

    } catch {
        Write-ColorOutput "Error creating global .gitignore: $($_.Exception.Message)" "Red"
        throw
    }
}

function New-GitCommitTemplate {
    Write-ColorOutput "Creating git commit message template..." "Green"

    try {
        $configDir = Join-Path $userProfile ".config\git"
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null

        $commitTemplatePath = Join-Path $configDir "commit.template"

        $commitTemplateContent = @"
# <type>(<scope>): <subject>
#
# <body>
#
# <footer>
#
# Types: feat, fix, docs, style, refactor, test, chore
# Subject: Imperative mood, short description (50 chars or less)
# Body: Detailed explanation of what and why, not how
# Footer: References to issues, breaking changes, etc.
#
# Examples:
# feat(ci): add automated testing for new pipeline
# fix(parser): handle null input gracefully
# docs(readme): update installation instructions
"@

        Set-Content -Path $commitTemplatePath -Value $commitTemplateContent -Encoding UTF8

        # Configure git to use commit template
        git config --global commit.template $commitTemplatePath

        Write-ColorOutput "Git commit template created at: $commitTemplatePath" "Green"

    } catch {
        Write-ColorOutput "Error creating git commit template: $($_.Exception.Message)" "Red"
        throw
    }
}

function Set-GitHooksDirectory {
    Write-ColorOutput "Setting up git hooks directory..." "Green"

    try {
        $hooksDir = Join-Path $userProfile ".git-hooks"
        New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null

        # Create sample pre-commit hook
        $preCommitHookPath = Join-Path $hooksDir "pre-commit.sample"
        $preCommitContent = @"
#!/bin/bash
# Sample pre-commit hook

echo "Running pre-commit checks..."

# Check for large files
echo "Checking for large files..."
if git diff --cached --name-only | xargs ls -la | awk '`$5 > 10485760 {print `$9}' | grep .; then
    echo "Error: Found files larger than 10MB. Consider using git-lfs."
    exit 1
fi

# Check for common issues
echo "Checking for common issues..."
if git diff --cached --name-only | grep -E '\.(py|js|ts|cpp|hpp|c|h)`$'; then
    echo "Source files detected. Consider running linting/formatting."
fi

echo "Pre-commit checks completed."
"@

        Set-Content -Path $preCommitHookPath -Value $preCommitContent -Encoding UTF8

        Write-ColorOutput "Git hooks directory configured at: $hooksDir" "Green"

    } catch {
        Write-ColorOutput "Error setting up git hooks directory: $($_.Exception.Message)" "Red"
        throw
    }
}

function Test-GitConfiguration {
    Write-ColorOutput "Verifying git configuration..." "Green"

    try {
        Write-ColorOutput "=== Git Configuration Summary ===" "Cyan"
        Write-ColorOutput "User: $(git config --global user.name)" "White"
        Write-ColorOutput "Email: $(git config --global user.email)" "White"
        Write-ColorOutput "Default Branch: $(git config --global init.defaultBranch)" "White"
        Write-ColorOutput "Editor: $(git config --global core.editor)" "White"
        Write-ColorOutput "Core Excludesfile: $(git config --global core.excludesfile)" "White"
        Write-ColorOutput "Commit Template: $(git config --global commit.template)" "White"

        Write-ColorOutput "" "White"
        Write-ColorOutput "=== Git Aliases ===" "Cyan"
        $aliases = git config --global --get-regexp '^alias\.' | Sort-Object
        foreach ($alias in $aliases) {
            Write-ColorOutput $alias "White"
        }

        Write-ColorOutput "" "White"
        Write-ColorOutput "=== Configuration Files ===" "Cyan"
        Write-ColorOutput "Global .gitignore: $(git config --global core.excludesfile)" "White"
        Write-ColorOutput "Commit template: $(git config --global commit.template)" "White"

        Write-ColorOutput "" "White"
        Write-ColorOutput "✅ Git configuration verified successfully" "Green"

    } catch {
        Write-ColorOutput "Error verifying git configuration: $($_.Exception.Message)" "Red"
        throw
    }
}

function Main {
    Write-Success "Starting Windows git configuration setup..."

    try {
        # Check if git is already configured
        if (Test-GitConfig) {
            Write-Success "Git is already configured - skipping"
            exit 0
        }

        Configure-GitUser
        Set-GitAliases
        Set-GitCredentialsHelper
        New-GitIgnoreGlobal
        New-GitCommitTemplate
        Set-GitHooksDirectory
        Test-GitConfiguration

        Write-Host ""
        Write-Success "================================"
        Write-Success "✅ Git configuration setup complete!"
        Write-Success "================================"
        Write-Host ""
        Write-Success "Configured for user: $RunnerUser"
        Write-Success "Git user: $GitUserName <$GitUserEmail>"
        Write-Host ""
        Write-Success "The git configuration includes:"
        Write-Host "  - User name and email"
        Write-Host "  - Useful aliases (st, co, br, cm, lg, etc.)"
        Write-Host "  - Global .gitignore"
        Write-Host "  - Commit message template"
        Write-Host "  - Credentials helper"
        Write-Host "  - Git hooks directory"
        Write-Host ""
        Write-Success "Git is now ready for use!"

    } catch {
        Write-Error-Output "Error in git configuration setup: $($_.Exception.Message)"
        exit 1
    }
}

Main