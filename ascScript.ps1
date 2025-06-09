# Self-elevate if not already running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Attempting to elevate..." -ForegroundColor Yellow
    $ScriptPath = $MyInvocation.MyCommand.Path
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" -Verb RunAs
    exit
}

$logFile = "C:\DevelopmentToolsInstallation.log"
"Installation started at $(Get-Date)" | Out-File -FilePath $logFile -Append

# Create a temporary directory for the installers
$tempDir = "$env:TEMP\devtools_install"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ProgressPreference = 'SilentlyContinue'
$webClient = New-Object System.Net.WebClient

# Install PowerShell Core
Write-Host "`nStarting PowerShell Core installation process..." -ForegroundColor Cyan
"Starting PowerShell Core installation at $(Get-Date)" | Out-File -FilePath $logFile -Append

$psInstallerPath = "$tempDir\PowerShell-7.5.1-win-x64.msi"
$psDownloadUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/PowerShell-7.5.1-win-x64.msi"
Write-Host "Downloading PowerShell Core installer..." -ForegroundColor Cyan

try {
    $webClient.DownloadFile($psDownloadUrl, $psInstallerPath)
    "PowerShell Core installer downloaded successfully at $(Get-Date)" | Out-File -FilePath $logFile -Append
}
catch {
    $errorMessage = "Failed to download PowerShell Core installer: $_"
    Write-Host $errorMessage -ForegroundColor Red
    $errorMessage | Out-File -FilePath $logFile -Append
}

Write-Host "Installing PowerShell Core..." -ForegroundColor Yellow
try {
    $psInstallArgs = "/i `"$psInstallerPath`" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $psInstallArgs -Wait -NoNewWindow

    $psCoreExists = Test-Path -Path "${env:ProgramFiles}\PowerShell\7\pwsh.exe"
    if ($psCoreExists) {
        Write-Host "PowerShell Core installation completed successfully!" -ForegroundColor Green
        "PowerShell Core installation completed successfully at $(Get-Date)" | Out-File -FilePath $logFile -Append
    } else {
        Write-Host "PowerShell Core installation may have encountered issues." -ForegroundColor Red
        "PowerShell Core installation encountered issues at $(Get-Date)" | Out-File -FilePath $logFile -Append
    }
}
catch {
    $errorMessage = "Error during PowerShell Core installation: $_"
    Write-Host $errorMessage -ForegroundColor Red
    $errorMessage | Out-File -FilePath $logFile -Append
}

# Install Az PowerShell Modules
Write-Host "`nStarting Az PowerShell Modules installation process..." -ForegroundColor Cyan
"Starting Az PowerShell modules installation at $(Get-Date)" | Out-File -FilePath $logFile -Append

try {
    Write-Host "Installing NuGet provider..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    
    Write-Host "Setting up PowerShell Gallery as a trusted repository..." -ForegroundColor Yellow
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    
    Write-Host "Installing Az PowerShell modules globally (this may take some time)..." -ForegroundColor Yellow
    Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -SkipPublisherCheck -Confirm:$false
    
    $windowsPSModulePath = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules"
    
    Write-Host "Installing Az PowerShell modules to Windows PowerShell directory..." -ForegroundColor Yellow
    Save-Module -Name Az -Path $windowsPSModulePath -Force -Confirm:$false
    
    if (Test-Path -Path "$windowsPSModulePath\Az") {
        Write-Host "Az PowerShell modules successfully installed to Windows PowerShell modules directory!" -ForegroundColor Green
        "Az PowerShell modules installation completed successfully at $(Get-Date)" | Out-File -FilePath $logFile -Append
    } else {
        Write-Host "Failed to install Az modules to Windows PowerShell modules directory." -ForegroundColor Red
        "Failed to install Az modules to Windows PowerShell modules directory at $(Get-Date)" | Out-File -FilePath $logFile -Append
    }
}
catch {
    $errorMessage = "Error during Az PowerShell modules installation: $_"
    Write-Host $errorMessage -ForegroundColor Red
    $errorMessage | Out-File -FilePath $logFile -Append
}

# Install Visual Studio 2022 Community
Write-Host "Starting Visual Studio 2022 Community installation process..." -ForegroundColor Cyan
"Starting Visual Studio 2022 Community installation at $(Get-Date)" | Out-File -FilePath $logFile -Append

$vsInstallerPath = "$tempDir\vs_community.exe"
$vsDownloadUrl = "https://aka.ms/vs/17/release/vs_community.exe"
Write-Host "Downloading Visual Studio 2022 Community installer..." -ForegroundColor Cyan

try {
    $webClient.DownloadFile($vsDownloadUrl, $vsInstallerPath)
    "Visual Studio installer downloaded successfully at $(Get-Date)" | Out-File -FilePath $logFile -Append
} 
catch {
    $errorMessage = "Failed to download Visual Studio installer: $_"
    Write-Host $errorMessage -ForegroundColor Red
    $errorMessage | Out-File -FilePath $logFile -Append
    exit 1
}

Write-Host "Installing Visual Studio 2022 Community with requested workloads..." -ForegroundColor Yellow
Write-Host "This may take some time. Please wait..." -ForegroundColor Yellow

try {
    Start-Process -FilePath $vsInstallerPath -ArgumentList "--quiet", "--norestart", "--wait", `
                                                        "--add Microsoft.VisualStudio.Workload.NetWeb", `
                                                        "--add Microsoft.VisualStudio.Workload.Node", `
                                                        "--add Microsoft.VisualStudio.Workload.ManagedDesktop", `
                                                        "--add Microsoft.VisualStudio.Workload.NativeDesktop" -Wait -NoNewWindow
    
    $vsExitCode = $LASTEXITCODE
    
    if ($vsExitCode -eq 0 -or $vsExitCode -eq 3010) {
        Write-Host "Visual Studio 2022 Community installation completed successfully! (Exit code: $vsExitCode)" -ForegroundColor Green
        "Visual Studio 2022 Community installation completed successfully with exit code: $vsExitCode at $(Get-Date)" | Out-File -FilePath $logFile -Append
    } else {
        Write-Host "Visual Studio installation may have encountered issues. Exit code: $vsExitCode" -ForegroundColor Red
        "Visual Studio installation encountered issues. Exit code: $vsExitCode at $(Get-Date)" | Out-File -FilePath $logFile -Append
    }
}
catch {
    $errorMessage = "Error during Visual Studio installation: $_"
    Write-Host $errorMessage -ForegroundColor Red
    $errorMessage | Out-File -FilePath $logFile -Append
}

# Cleanup
Write-Host "`nCleaning up temporary files..." -ForegroundColor Cyan
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nInstallation process completed!" -ForegroundColor Green
"Installation process completed at $(Get-Date)" | Out-File -FilePath $logFile -Append
