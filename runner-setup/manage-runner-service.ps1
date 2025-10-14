# GitHub Actions Runner Service Management Script
# Part of CICD Template System - Phase 6.2

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "status", "install", "uninstall", "logs", "test", "config")]
    [string]$Action = "status",

    [Parameter(Mandatory=$false)]
    [string]$RunnerName,

    [Parameter(Mandatory=$false)]
    [switch]$Help,

    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Configuration
$RUNNER_VERSION = "2.319.1"
$INSTALL_DIR = "C:\actions-runner"
$LOG_DIR = "$INSTALL_DIR\_diag"
$CONFIG_DIR = "$INSTALL_DIR\config"

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "Green",
        [switch]$NoNewline
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = "[$timestamp]"

    if ($NoNewline) {
        Write-Host "$prefix $Message" -ForegroundColor $Color -NoNewline
    } else {
        Write-Host "$prefix $Message" -ForegroundColor $Color
    }
}

function Write-Success { param([string]$Message) Write-ColorOutput "✅ $Message" "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput "⚠️  $Message" "Yellow" }
function Write-Error { param([string]$Message) Write-ColorOutput "❌ $Message" "Red" }
function Write-Info { param([string]$Message) Write-ColorOutput "ℹ️  $Message" "White" }

function Show-Help {
    Write-Host @"
GitHub Actions Runner Service Management Script

USAGE:
    .\manage-runner-service.ps1 -Action <action> [-RunnerName <name>] [-Verbose]

ACTIONS:
    start      Start the runner service
    stop       Stop the runner service
    restart    Restart the runner service
    status     Show service status (default)
    install    Install the runner as Windows service
    uninstall  Uninstall the runner Windows service
    logs       Show recent log files
    test       Test runner connectivity
    config     Show runner configuration

PARAMETERS:
    -Action       Action to perform (default: status)
    -RunnerName   Specific runner name (optional)
    -Help         Show this help message
    -Verbose      Enable verbose output

EXAMPLES:
    .\manage-runner-service.ps1
    .\manage-runner-service.ps1 -Action start
    .\manage-runner-service.ps1 -Action restart -Verbose
    .\manage-runner-service.ps1 -Action logs
    .\manage-runner-service.ps1 -Action test

SHORTCUTS:
    .\manage-runner-service.ps1 start
    .\manage-runner-service.ps1 stop
    .\manage-runner-service.ps1 restart
    .\manage-runner-service.ps1 status
"@
    exit 0
}

function Test-AdminPrivileges {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if (-not $isAdmin) {
            Write-Error "This script requires administrator privileges for most actions"
            Write-Info "Right-click PowerShell and select 'Run as Administrator'"
            return $false
        }
        return $true
    }
    catch {
        Write-Error "Failed to check administrator privileges: $_"
        return $false
    }
}

function Get-RunnerService {
    try {
        $serviceName = if ($RunnerName) {
            "actions.runner.$RunnerName.*"
        } else {
            "actions.runner.*"
        }

        $services = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        return $services
    }
    catch {
        return $null
    }
}

function Show-ServiceStatus {
    Write-Info "Checking GitHub Actions runner service status..."

    $services = Get-RunnerService

    if (-not $services) {
        Write-Warning "No runner services found"
        return
    }

    Write-Host ""
    Write-Host "Runner Service Status:" -ForegroundColor Cyan
    Write-Host ("-" * 80)

    foreach ($service in $services) {
        Write-Host "Service Name: $($service.Name)" -ForegroundColor White
        Write-Host "Display Name: $($service.DisplayName)" -ForegroundColor Gray
        Write-Host "Status: $($service.Status)" -ForegroundColor $(
            switch ($service.Status) {
                "Running" { "Green" }
                "Stopped" { "Red" }
                "Paused" { "Yellow" }
                default { "Gray" }
            }
        )
        Write-Host "Start Type: $($service.StartType)" -ForegroundColor Gray
        Write-Host "Can Stop: $($service.CanStop)" -ForegroundColor Gray
        Write-Host "Can Pause: $($service.CanPauseAndContinue)" -ForegroundColor Gray
        Write-Host ""

        if ($Verbose) {
            Write-Info "Additional Details:"
            Write-Info "  Service Type: $($service.ServiceType)"
            Write-Info "  Dependent Services: $($service.DependentServices.Count)"
            Write-Info "  Services Depended On: $($service.ServicesDependedOn.Count)"
            Write-Info "  Machine Name: $($service.MachineName)"
            Write-Host ""
        }
    }

    # Show installation directory status
    if (Test-Path $INSTALL_DIR) {
        Write-Info "Installation Directory: $INSTALL_DIR"
        Write-Info "Runner Version: $RUNNER_VERSION"
    } else {
        Write-Warning "Installation directory not found: $INSTALL_DIR"
    }
}

function Start-RunnerService {
    Write-Info "Starting GitHub Actions runner service..."

    if (-not (Test-AdminPrivileges)) {
        return
    }

    $services = Get-RunnerService

    if (-not $services) {
        Write-Error "No runner services found to start"
        return
    }

    foreach ($service in $services) {
        Write-Info "Starting service: $($service.Name)"
        try {
            $service.Start()
            Start-Sleep -Seconds 5

            $service.Refresh()
            if ($service.Status -eq "Running") {
                Write-Success "Service started successfully: $($service.Name)"
            } else {
                Write-Warning "Service may not have started properly. Current status: $($service.Status)"
            }
        }
        catch {
            Write-Error "Failed to start service $($service.Name): $_"
        }
    }
}

function Stop-RunnerService {
    Write-Info "Stopping GitHub Actions runner service..."

    if (-not (Test-AdminPrivileges)) {
        return
    }

    $services = Get-RunnerService

    if (-not $services) {
        Write-Error "No runner services found to stop"
        return
    }

    foreach ($service in $services) {
        Write-Info "Stopping service: $($service.Name)"
        try {
            $service.Stop()
            Start-Sleep -Seconds 5

            $service.Refresh()
            if ($service.Status -eq "Stopped") {
                Write-Success "Service stopped successfully: $($service.Name)"
            } else {
                Write-Warning "Service may not have stopped properly. Current status: $($service.Status)"
            }
        }
        catch {
            Write-Error "Failed to stop service $($service.Name): $_"
        }
    }
}

function Restart-RunnerService {
    Write-Info "Restarting GitHub Actions runner service..."
    Stop-RunnerService
    Start-Sleep -Seconds 2
    Start-RunnerService
}

function Install-RunnerService {
    Write-Info "Installing GitHub Actions runner as Windows service..."

    if (-not (Test-AdminPrivileges)) {
        return
    }

    if (-not (Test-Path $INSTALL_DIR)) {
        Write-Error "Runner installation not found at $INSTALL_DIR"
        Write-Info "Please run the installation script first"
        return
    }

    Set-Location $INSTALL_DIR

    try {
        Write-Info "Running service installation..."
        $process = Start-Process -FilePath ".\svc.cmd" -ArgumentList "install" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Success "Service installed successfully"
            Write-Info "Starting service..."
            $startProcess = Start-Process -FilePath ".\svc.cmd" -ArgumentList "start" -Wait -PassThru -NoNewWindow

            if ($startProcess.ExitCode -eq 0) {
                Write-Success "Service started successfully"
            } else {
                Write-Warning "Service installed but failed to start (exit code: $($startProcess.ExitCode))"
            }
        } else {
            Write-Error "Service installation failed (exit code: $($process.ExitCode))"
        }
    }
    catch {
        Write-Error "Failed to install service: $_"
    }
}

function Uninstall-RunnerService {
    Write-Info "Uninstalling GitHub Actions runner Windows service..."

    if (-not (Test-AdminPrivileges)) {
        return
    }

    if (-not (Test-Path $INSTALL_DIR)) {
        Write-Error "Runner installation not found at $INSTALL_DIR"
        return
    }

    Set-Location $INSTALL_DIR

    try {
        Write-Info "Stopping service first..."
        Stop-RunnerService

        Write-Info "Running service uninstallation..."
        $process = Start-Process -FilePath ".\svc.cmd" -ArgumentList "uninstall" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Success "Service uninstalled successfully"
        } else {
            Write-Error "Service uninstallation failed (exit code: $($process.ExitCode))"
        }
    }
    catch {
        Write-Error "Failed to uninstall service: $_"
    }
}

function Show-Logs {
    Write-Info "Showing recent runner logs..."

    if (-not (Test-Path $LOG_DIR)) {
        Write-Warning "Log directory not found: $LOG_DIR"
        return
    }

    try {
        $logFiles = Get-ChildItem $LOG_DIR -File | Sort-Object LastWriteTime -Descending | Select-Object -First 10

        if (-not $logFiles) {
            Write-Warning "No log files found"
            return
        }

        Write-Host ""
        Write-Host "Recent Log Files:" -ForegroundColor Cyan
        Write-Host ("-" * 80)

        foreach ($logFile in $logFiles) {
            $size = [math]::Round($logFile.Length / 1KB, 2)
            Write-Host "$($logFile.Name) ($size KB) - $($logFile.LastWriteTime)" -ForegroundColor White
        }

        Write-Host ""
        Write-Info "Showing content of most recent log file..."
        $latestLog = $logFiles | Select-Object -First 1

        Write-Host "Content of $($latestLog.Name):" -ForegroundColor Cyan
        Write-Host ("-" * 40)

        # Show last 50 lines of the log
        $content = Get-Content $latestLog.FullName -Tail 50
        foreach ($line in $content) {
            Write-Host $line -ForegroundColor Gray
        }

        Write-Host ""
        Write-Info "To view full logs, open: $($latestLog.FullName)"
    }
    catch {
        Write-Error "Failed to read log files: $_"
    }
}

function Test-RunnerConnectivity {
    Write-Info "Testing runner connectivity..."

    if (-not (Test-Path $INSTALL_DIR)) {
        Write-Error "Runner installation not found at $INSTALL_DIR"
        return
    }

    Set-Location $INSTALL_DIR

    try {
        Write-Info "Running connectivity test..."
        $process = Start-Process -FilePath ".\run.cmd" -ArgumentList "--once" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Success "Runner connectivity test passed"
        } else {
            Write-Warning "Runner connectivity test failed with exit code $($process.ExitCode)"
            Write-Info "This may indicate network issues or configuration problems"
        }
    }
    catch {
        Write-Error "Failed to run connectivity test: $_"
    }
}

function Show-Configuration {
    Write-Info "Showing runner configuration..."

    # Check runner configuration
    $runnerConfig = Join-Path $INSTALL_DIR ".runner"
    if (Test-Path $runnerConfig) {
        Write-Host "Runner Configuration File: $runnerConfig" -ForegroundColor Green
        try {
            $config = Get-Content $runnerConfig | ConvertFrom-Json
            Write-Host "Runner Name: $($config.agentName)" -ForegroundColor White
            Write-Host "Pool ID: $($config.poolId)" -ForegroundColor White
            Write-Host "Agent ID: $($config.agentId)" -ForegroundColor White
        }
        catch {
            Write-Warning "Could not parse runner configuration file"
        }
    } else {
        Write-Warning "Runner configuration file not found"
    }

    # Check our saved configuration
    $savedConfig = Join-Path $CONFIG_DIR "runner-config.json"
    if (Test-Path $savedConfig) {
        Write-Host ""
        Write-Host "Saved Configuration: $savedConfig" -ForegroundColor Green
        try {
            $config = Get-Content $savedConfig | ConvertFrom-Json
            Write-Host "Name: $($config.Name)" -ForegroundColor White
            Write-Host "URL: $($config.Url)" -ForegroundColor White
            Write-Host "Labels: $($config.Labels -join ', ')" -ForegroundColor White
            Write-Host "Configured: $($config.ConfiguredAt)" -ForegroundColor White
        }
        catch {
            Write-Warning "Could not parse saved configuration file"
        }
    }

    # Show environment variables
    Write-Host ""
    Write-Host "Environment Variables:" -ForegroundColor Cyan
    $envVars = @("SCCACHE_DIR", "SCCACHE_CACHE_SIZE", "CMAKE_C_COMPILER_LAUNCHER", "CMAKE_CXX_COMPILER_LAUNCHER")
    foreach ($var in $envVars) {
        $value = [System.Environment]::GetEnvironmentVariable($var, "User")
        if ($value) {
            Write-Host "$var = $value" -ForegroundColor White
        }
    }
}

# Main execution
try {
    if ($Help) {
        Show-Help
    }

    Write-Host "GitHub Actions Runner Service Management" -ForegroundColor Magenta
    Write-Host "CICD Template System - Phase 6.2" -ForegroundColor Magenta
    Write-Host ""

    switch ($Action.ToLower()) {
        "status" {
            Show-ServiceStatus
        }
        "start" {
            Start-RunnerService
        }
        "stop" {
            Stop-RunnerService
        }
        "restart" {
            Restart-RunnerService
        }
        "install" {
            Install-RunnerService
        }
        "uninstall" {
            Uninstall-RunnerService
        }
        "logs" {
            Show-Logs
        }
        "test" {
            Test-RunnerConnectivity
        }
        "config" {
            Show-Configuration
        }
        default {
            Write-Error "Unknown action: $Action"
            Write-Info "Use -Help to see available actions"
            exit 1
        }
    }
}
catch {
    Write-Error "Script execution failed: $_"
    Write-Info "Error details:"
    Write-Info "  $($_.Exception.GetType().FullName)"
    Write-Info "  $($_.Exception.Message)"
    Write-Info "  Line: $($_.InvocationInfo.ScriptLineNumber)"
    exit 1
}