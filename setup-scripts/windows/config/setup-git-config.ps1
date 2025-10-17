#!/usr/bin/env pwsh
# Setup Git Configuration for Windows

param(
    [string]$RunnerUser = "github-runner"
)

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

# Function to configure git user
function Set-GitUser {
    Write-Status "Configuring Git user..."

    try {
        git config --global user.name "Kwanghyun Jo"
        git config --global user.email "jokh38@gmail.com"
        Write-Success "Git user configured successfully"
    } catch {
        Write-Error-Output "Failed to configure Git user: $($_.Exception.Message)"
        throw
    }
}

# Function to configure git core settings
function Set-GitCoreSettings {
    Write-Status "Configuring Git core settings..."

    try {
        # Set default branch name
        git config --global init.defaultBranch main

        # Configure core settings for Windows
        git config --global core.autocrlf true
        git config --global core.eol crlf
        git config --global core.precomposeunicode true
        git config --global core.protectNTFS true
        git config --global core.pager "less -FRX"

        # Configure editor
        $editorPath = where.exe code 2>$null
        if ($editorPath) {
            git config --global core.editor "code --wait"
            Write-Status "Set VS Code as default Git editor"
        } else {
            git config --global core.editor "nano"
            Write-Status "Set nano as default Git editor"
        }

        # Configure file mode (important for Windows)
        git config --global core.filemode false

        Write-Success "Git core settings configured successfully"

    } catch {
        Write-Error-Output "Failed to configure Git core settings: $($_.Exception.Message)"
        throw
    }
}

# Function to configure useful git aliases
function Set-GitAliases {
    Write-Status "Configuring Git aliases..."

    try {
        $aliases = @{
            "st" = "status"
            "co" = "checkout"
            "br" = "branch"
            "ci" = "commit"
            "unstage" = "reset HEAD --"
            "last" = "log -1 HEAD"
            "visual" = "!gitk"
            "graph" = "log --oneline --graph --decorate --all"
            "Amend" = "commit --amend --no-edit"
            "fixup" = "commit --fixup"
            "squash" = "!git rebase -i --autosquash"
            "tree" = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
            "branches" = "branch -a"
            "tags" = "tag"
            "remotes" = "remote -v"
        }

        foreach ($alias in $aliases.GetEnumerator()) {
            git config --global alias.$($alias.Key) $($alias.Value)
        }

        Write-Success "Git aliases configured successfully"

    } catch {
        Write-Error-Output "Failed to configure Git aliases: $($_.Exception.Message)"
        throw
    }
}

# Function to configure git pull and push behavior
function Set-GitPushPullBehavior {
    Write-Status "Configuring Git pull and push behavior..."

    try {
        # Configure pull behavior
        git config --global pull.rebase true

        # Configure push behavior
        git config --global push.default simple

        # Configure rebase behavior
        git config --global rebase.autosquash true
        git config --global rebase.autostash true

        Write-Success "Git push/pull behavior configured successfully"

    } catch {
        Write-Error-Output "Failed to configure Git push/pull behavior: $($_.Exception.Message)"
        throw
    }
}

# Function to create global gitignore
function New-GlobalGitignore {
    Write-Status "Creating global gitignore..."

    try {
        $globalGitignorePath = Join-Path $env:USERPROFILE ".gitignore_global"

        $gitignoreContent = @"
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Windows specific
Desktop.ini
$RECYCLE.BIN/
*.cab
*.msi
*.msix
*.msm
*.msp
*.lnk

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~
.project
.pydevproject
.settings/
*.sublime-*

# Visual Studio files
.vs/
*.user
*.suo
*.userosscache
*.sln.docstates

# Build results
[Dd]ebug/
[Dd]ebugPublic/
[Rr]elease/
[Rr]eleases/
x64/
x86/
build/
bld/
[Bb]in/
[Oo]bj/
[Ll]og/

# MSTest test Results
[Tt]est[Rr]esult*/
[Bb]uild[Ll]og.*

# NUnit
*.VisualState.xml
TestResult.xml

# Build Results of an ATL Project
[Dd]ebugPS/
[Rr]eleasePS/
dlldata.c

# Benchmark Results
BenchmarkDotNet.Artifacts/

# .NET Core
project.lock.json
project.fragment.lock.json
artifacts/

# StyleCop
StyleCopReport.xml

# Files built by Visual Studio
*_i.c
*_p.c
*_h.h
*.ilk
*.meta
*.obj
*.iobj
*.pch
*.pdb
*.ipdb
*.pgc
*.pgd
*.rsp
*.sbr
*.tlb
*.tli
*.tlh
*.tmp_proj
*.vspscc
*.vssscc
.builds
*.pidb
*.svclog
*.scc

# Chutzpah Test files
_Chutzpah*

# Visual C++ cache files
ipch/
*.aps
*.ncb
*.opensdf
*.sdf
*.cachefile
*.VC.db
*.VC.VC.opendb

# Visual Studio profiler
*.psess
*.vsp
*.vspx
*.sap

# Visual Studio Trace Files
*.e2e

# TFS 2012 Local Workspace
$tf/

# Guidance Automation Toolkit
*.gpState

# ReSharper is a .NET coding add-in
_ReSharper*/
*.[Rr]e[Ss]harper
*.DotSettings.user

# TeamCity is a build add-in
_TeamCity*

# DotCover is a Code Coverage Tool
*.dotCover

# AxoCover is a Code Coverage Tool
.axoCover/*
!.axoCover/settings.json

# Coverlet is a free, cross platform Code Coverage Tool
coverage*.json
coverage*.xml
coverage*.info

# Visual Studio code coverage results
*.coverage
*.coveragexml

# NCrunch
_NCrunch_*
.*crunch*.local.xml
nCrunchTemp_*

# MightyMoose
*.mm.*
AutoTest.Net/

# Web workbench (sass)
.sass-cache/

# Installshield output folder
[Ee]xpress/

# DocProject is a documentation generator add-in
DocProject/buildhelp/
DocProject/Help/*.HxT
DocProject/Help/*.HxC
DocProject/Help/*.hhc
DocProject/Help/*.hhk
DocProject/Help/*.hhp
DocProject/Help/Html2
DocProject/Help/html

# Click-Once directory
publish/

# Publish Web Output
*.[Pp]ublish.xml
*.azurePubxml
# Note: Comment the next line if you want to checkin your web deploy settings,
# but database connection strings (with potential passwords) will be unencrypted
*.pubxml
*.publishproj

# Microsoft Azure Web App publish settings. Comment the next line if you want to
# checkin your Azure Web App publish settings, but sensitive information contained
# in these files may be disclosed
*.azurePubxml

# NuGet Packages
*.nupkg
# NuGet Symbol Packages
*.snupkg
# The packages folder can be ignored because of Package Restore
**/[Pp]ackages/*
# except build/, which is used as an MSBuild target.
!**/[Pp]ackages/build/
# Uncomment if necessary however generally it will be regenerated when needed
#!**/[Pp]ackages/repositories.config
# NuGet v3's project.json files produces more ignorable files
*.nuget.props
*.nuget.targets

# Microsoft Azure Build Output
csx/
*.build.csdef

# Microsoft Azure Emulator
ecf/
rcf/

# Windows Store app package directories and files
AppPackages/
BundleArtifacts/
Package.StoreAssociation.xml
_pkginfo.txt
*.appx
*.appxbundle
*.appxupload

# Visual Studio cache files
# files ending in .cache can be ignored
*.[Cc]ache
# but keep track of directories ending in .cache
!?*.[Cc]ache/

# Others
ClientBin/
~$*
*~
*.dbmdl
*.dbproj.schemaview
*.jfm
*.pfx
*.publishsettings
orleans.codegen.cs

# Including strong name files can present a security risk
# (https://github.com/github/gitignore/pull/2483#issue-259490424)
#*.snk

# Since there are multiple workflows, uncomment next line to ignore bower_components
# (https://github.com/github/gitignore/pull/1529#issuecomment-104372622)
#bower_components/

# RIA/Silverlight projects
Generated_Code/

# Backup & report files from converting an old project file
# to a newer Visual Studio version. Backup files are not needed,
# because we have git ;-)
_UpgradeReport_Files/
Backup*/
UpgradeLog*.XML
UpgradeLog*.htm
CDF-*.xml

# SQL Server files
*.mdf
*.ldf
*.ndf

# Business Intelligence projects
*.rdl.data
*.bim.layout
*.bim_*.settings
*.rptproj.rsuser
*- [Bb]ackup.rdl
*- [Bb]ackup ([0-9]).rdl
*- [Bb]ackup ([0-9][0-9]).rdl

# Microsoft Fakes
FakesAssemblies/

# GhostDoc plugin setting file
*.GhostDoc.xml

# Node.js Tools for Visual Studio
.ntvs_analysis.dat
node_modules/

# Visual Studio 6 build log
*.plg

# Visual Studio 6 workspace options file
*.opt

# Visual Studio 6 auto-generated workspace file (contains which files were open etc.)
*.vbw

# Visual Studio LightSwitch build output
**/*.HTMLClient/GeneratedArtifacts
**/*.DesktopClient/GeneratedArtifacts
**/*.DesktopClient/ModelManifest.xml
**/*.Server/GeneratedArtifacts
**/*.Server/ModelManifest.xml
_Pvt_Extensions

# Paket dependency manager
.paket/paket.exe
paket-files/

# FAKE - F# Make
.fake/

# CodeRush personal settings
.cr/personal

# Python Tools for Visual Studio (PTVS)
__pycache__/
*.pyc

# Cake - Uncomment if you are using it
# tools/**
# !tools/packages.config

# Tabs Studio
*.tss

# Telerik's JustMock configuration file
*.jmconfig

# BizTalk build output
*.btp.cs
*.btm.cs
*.odx.cs
*.xsd.cs

# OpenCover UI analysis results
OpenCover/

# Azure Stream Analytics local run output
ASALocalRun/

# MSBuild Binary and Structured Log
*.binlog

# NVidia Nsight GPU debugger configuration file
*.nvuser

# MFractors (Xamarin productivity tool) working folder
.mfractor/

# Local History for Visual Studio Code
.history/

# BeatPulse healthcheck temp database
healthchecksdb

# Backup folder for Package Reference Convert tool in Visual Studio 2017
MigrationBackup/

# Ionide (cross platform F# VS Code tools) working folder
.ionide/

# Fody - auto-generated XML schema
FodyWeavers.xsd

# VS Code folders for extensions
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
!.vscode/*.code-snippets

# Local History for Visual Studio Code
.history/

# Built Visual Studio Code Extensions
*.vsix

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv/
pip-log.txt
pip-delete-this-directory.txt
.tox/
.coverage
.pytest_cache/
htmlcov/
.mypy_cache/
.dmypy.json
dmypy.json

# C++
*.o
*.obj
*.exe
*.dll
*.so
*.dylib
*.a
*.lib
*.pdb
*.ilk
*.exp
*.map
*.dSYM/
*.su
*.idb
*.pdb
*.pgc
*.pgd
*.rsp
*.sbr
*.tlb
*.tli
*.tlh
*.tmp_proj
*.vspscc
*.vssscc
.builds
*.pidb
*.svclog
*.scc

# CMake
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
Makefile
*.cmake
CMake/

# Build directories
build/
Build/
dist/
build-*/

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Temporary files
*.tmp
*.temp
"@

        $gitignoreContent | Out-File -FilePath $globalGitignorePath -Encoding UTF8 -Force

        # Configure git to use the global gitignore
        git config --global core.excludesfile $globalGitignorePath

        Write-Success "Global gitignore created at: $globalGitignorePath"

    } catch {
        Write-Error-Output "Failed to create global gitignore: $($_.Exception.Message)"
        throw
    }
}

# Function to create commit template
function New-CommitTemplate {
    Write-Status "Creating commit template..."

    try {
        $gitConfigDir = Join-Path $env:USERPROFILE ".config\git"
        if (-not (Test-Path $gitConfigDir)) {
            New-Item -Path $gitConfigDir -ItemType Directory -Force | Out-Null
        }

        $commitTemplatePath = Join-Path $gitConfigDir "commit.template"

        $commitTemplate = @"
# Type(scope): subject

# Body: Explain what and why, not how.
#
# Footer:
#   - Breaking changes: BREAKING CHANGE: description
#   - Closes issues: Closes #issue-number
#   - References: References #issue-number

# Types: feat, fix, docs, style, refactor, test, chore
# Scopes: app, lib, docs, build, ci, style, refactor, test, chore

# Examples:
# feat(ui): add new button component
# fix(api): resolve null reference in user service
# docs(readme): update installation instructions
# test(calculator): add tests for division method
# refactor(parser): simplify expression parsing logic
"@

        $commitTemplate | Out-File -FilePath $commitTemplatePath -Encoding UTF8 -Force

        # Configure git to use the commit template
        git config --global commit.template $commitTemplatePath

        Write-Success "Commit template created at: $commitTemplatePath"

    } catch {
        Write-Error-Output "Failed to create commit template: $($_.Exception.Message)"
        throw
    }
}

# Function to configure Git credentials helper (optional)
function Set-GitCredentialsHelper {
    Write-Status "Configuring Git credentials helper..."

    try {
        # Configure Git Credential Manager (usually installed with Git for Windows)
        git config --global credential.helper manager-core

        Write-Success "Git credentials helper configured"

    } catch {
        Write-Warning "Failed to configure Git credentials helper: $($_.Exception.Message)"
    }
}

# Function to configure git for large files (Git LFS)
function Set-GitLFS {
    Write-Status "Configuring Git LFS..."

    try {
        # Check if Git LFS is installed
        $lfsVersion = git lfs version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Git LFS is already installed: $lfsVersion"
        } else {
            Write-Status "Git LFS not found. Install it later if needed with: choco install git-lfs"
        }

    } catch {
        Write-Warning "Could not check Git LFS status: $($_.Exception.Message)"
    }
}

# Function to verify Git configuration
function Test-GitConfiguration {
    Write-Status "Verifying Git configuration..."

    try {
        # Check user configuration
        $userName = git config --global user.name
        $userEmail = git config --global user.email
        Write-Success "Git user configured: $userName <$userEmail>"

        # Check key configurations
        $defaultBranch = git config --global init.defaultBranch
        Write-Success "Default branch: $defaultBranch"

        $coreAutocrlf = git config --global core.autocrlf
        Write-Success "Core autocrlf: $coreAutocrlf"

        $globalIgnore = git config --global core.excludesfile
        if ($globalIgnore -and (Test-Path $globalIgnore)) {
            Write-Success "Global gitignore configured: $globalIgnore"
        }

        $commitTemplate = git config --global commit.template
        if ($commitTemplate -and (Test-Path $commitTemplate)) {
            Write-Success "Commit template configured: $commitTemplate"
        }

        Write-Success "Git configuration verification completed"

    } catch {
        Write-Warning "Could not verify some Git configurations: $($_.Exception.Message)"
    }
}

# Main configuration
try {
    Write-Status "Starting Windows Git configuration..."

    # Configure Git
    Set-GitUser
    Set-GitCoreSettings
    Set-GitAliases
    Set-GitPushPullBehavior

    # Create configuration files
    New-GlobalGitignore
    New-CommitTemplate

    # Optional configurations
    Set-GitCredentialsHelper
    Set-GitLFS

    # Verify configuration
    Test-GitConfiguration

    Write-Success "Git configuration completed successfully"
    Write-Status "Git is now ready for use on Windows!"

} catch {
    Write-Error-Output "Git configuration failed: $($_.Exception.Message)"
    exit 1
}