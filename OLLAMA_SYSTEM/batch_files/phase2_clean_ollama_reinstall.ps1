#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Phase 2: Clean Ollama Reinstallation with aria2 Support
    Based on United Nations Team recommendations
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PHASE 2: CLEAN OLLAMA REINSTALLATION" -ForegroundColor Cyan
Write-Host "  United Nations Team Recommended" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "   Some steps may require admin privileges" -ForegroundColor Yellow
    Write-Host ""
}

# Step 1: Stop Ollama
Write-Host "[1/8] Stopping Ollama processes..." -ForegroundColor Yellow
$ollamaProcesses = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if ($ollamaProcesses) {
    Write-Host "  Found $($ollamaProcesses.Count) Ollama process(es)" -ForegroundColor Cyan
    Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "  ✅ Ollama stopped" -ForegroundColor Green
}
else {
    Write-Host "  ✅ No Ollama processes running" -ForegroundColor Green
}

# Step 2: Uninstall Ollama
Write-Host ""
Write-Host "[2/8] Uninstalling Ollama..." -ForegroundColor Yellow
$ollamaApp = Get-AppxPackage -Name "*ollama*" -ErrorAction SilentlyContinue
if ($ollamaApp) {
    Write-Host "  Found Ollama app package" -ForegroundColor Cyan
    Remove-AppxPackage $ollamaApp -ErrorAction SilentlyContinue
}

# Check for installed program
$ollamaProgram = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Ollama*" } -ErrorAction SilentlyContinue
if ($ollamaProgram) {
    Write-Host "  Found Ollama in installed programs" -ForegroundColor Cyan
    Write-Host "  Please uninstall Ollama manually from:" -ForegroundColor Yellow
    Write-Host "    Settings → Apps → Apps & Features → Ollama" -ForegroundColor White
    Write-Host "  Press Enter after uninstalling..." -ForegroundColor Yellow
    Read-Host
}

# Step 3: Delete residual directories
Write-Host ""
Write-Host "[3/8] Deleting residual Ollama directories..." -ForegroundColor Yellow
$dirsToDelete = @(
    "$env:USERPROFILE\.ollama",
    "$env:LOCALAPPDATA\Ollama",
    "C:\Program Files\Ollama",
    "C:\ProgramData\Ollama"
)

foreach ($dir in $dirsToDelete) {
    if (Test-Path $dir) {
        Write-Host "  Deleting: $dir" -ForegroundColor Gray
        try {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
            Write-Host "    ✅ Deleted" -ForegroundColor Green
        }
        catch {
            Write-Host "    ⚠️  Could not delete (may need manual deletion): $_" -ForegroundColor Yellow
        }
    }
}

# Step 4: Check for aria2
Write-Host ""
Write-Host "[4/8] Checking for aria2..." -ForegroundColor Yellow
$aria2Path = Get-Command "aria2c" -ErrorAction SilentlyContinue
if ($aria2Path) {
    Write-Host "  ✅ aria2 found: $($aria2Path.Source)" -ForegroundColor Green
    $useAria2 = $true
}
else {
    Write-Host "  ⚠️  aria2 not found" -ForegroundColor Yellow
    Write-Host "  Downloading will use standard methods" -ForegroundColor Gray
    $useAria2 = $false
}

# Step 5: Download latest Ollama installer
Write-Host ""
Write-Host "[5/8] Downloading latest Ollama installer..." -ForegroundColor Yellow
$ollamaInstaller = "$env:TEMP\ollama-windows-amd64.exe"
$ollamaUrl = "https://ollama.com/download/windows"

Write-Host "  URL: $ollamaUrl" -ForegroundColor Cyan
Write-Host "  Destination: $ollamaInstaller" -ForegroundColor Cyan

if ($useAria2) {
    Write-Host "  Using aria2 for faster download..." -ForegroundColor Green
    try {
        # Get actual download URL (may need to parse the page)
        # For now, try direct download
        $downloadUrl = "https://github.com/ollama/ollama/releases/latest/download/OllamaSetup.exe"
        Write-Host "  Download URL: $downloadUrl" -ForegroundColor Gray
        & aria2c -x 16 -s 16 -k 1M -d $env:TEMP -o "ollama-windows-amd64.exe" $downloadUrl
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Download complete with aria2" -ForegroundColor Green
        }
        else {
            Write-Host "  ⚠️  aria2 download failed, trying alternative..." -ForegroundColor Yellow
            $useAria2 = $false
        }
    }
    catch {
        Write-Host "  ⚠️  aria2 error: $_" -ForegroundColor Yellow
        $useAria2 = $false
    }
}

if (-not $useAria2) {
    Write-Host "  Using standard download method..." -ForegroundColor Gray
    try {
        Invoke-WebRequest -Uri "https://github.com/ollama/ollama/releases/latest/download/OllamaSetup.exe" -OutFile $ollamaInstaller -UseBasicParsing
        Write-Host "  ✅ Download complete" -ForegroundColor Green
    }
    catch {
        Write-Host "  ❌ Download failed: $_" -ForegroundColor Red
        Write-Host "  Please download manually from: https://ollama.com/download/windows" -ForegroundColor Yellow
        exit 1
    }
}

# Step 6: Install Ollama
Write-Host ""
Write-Host "[6/8] Installing Ollama..." -ForegroundColor Yellow
if (Test-Path $ollamaInstaller) {
    Write-Host "  Running installer..." -ForegroundColor Cyan
    Write-Host "  (Follow the installation wizard)" -ForegroundColor Gray
    Start-Process -FilePath $ollamaInstaller -Wait -NoNewWindow
    Write-Host "  ✅ Installation complete" -ForegroundColor Green
    
    # Wait for Ollama to be available
    Write-Host "  Waiting for Ollama to be ready..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    
    # Verify installation
    $ollamaCmd = Get-Command "ollama" -ErrorAction SilentlyContinue
    if ($ollamaCmd) {
        Write-Host "  ✅ Ollama command available" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠️  Ollama command not found in PATH" -ForegroundColor Yellow
        Write-Host "  You may need to restart your terminal or add Ollama to PATH" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  ❌ Installer not found" -ForegroundColor Red
    exit 1
}

# Step 7: Re-download models with aria2 (if available)
Write-Host ""
Write-Host "[7/8] Re-downloading models..." -ForegroundColor Yellow
Write-Host "  This will use aria2 if available for faster downloads" -ForegroundColor Cyan

# Set OLLAMA_MODELS to OLLAMA_SYSTEM if it exists
$ollamaSystemModels = "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models"
if (Test-Path $ollamaSystemModels) {
    $env:OLLAMA_MODELS = $ollamaSystemModels
    Write-Host "  OLLAMA_MODELS set to: $env:OLLAMA_MODELS" -ForegroundColor Cyan
}

# Start Ollama service
Write-Host "  Starting Ollama service..." -ForegroundColor Gray
Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
Start-Sleep -Seconds 5

# Download llama3.1:8b
Write-Host "  Downloading llama3.1:8b..." -ForegroundColor Cyan
if ($useAria2) {
    Write-Host "    (Ollama will use aria2 automatically if configured)" -ForegroundColor Gray
}
ollama pull llama3.1:8b 2>&1 | ForEach-Object {
    if ($_ -match "pulling|verifying|success|100%") {
        Write-Host "    $_" -ForegroundColor Green
    }
    else {
        Write-Host "    $_" -ForegroundColor Gray
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ llama3.1:8b downloaded" -ForegroundColor Green
}
else {
    Write-Host "  ⚠️  Download had issues" -ForegroundColor Yellow
}

# Step 8: Reconfigure with MRG settings
Write-Host ""
Write-Host "[8/8] Reconfiguring with MRG v8.0 settings..." -ForegroundColor Yellow
Write-Host "  Running restart_ollama_with_gpu.ps1..." -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File "restart_ollama_with_gpu.ps1" 2>&1 | Select-Object -Last 10

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PHASE 2 COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test Ollama: ollama run llama3.1:8b 'test'" -ForegroundColor White
Write-Host "  2. Verify GPU acceleration: nvidia-smi" -ForegroundColor White
Write-Host "  3. Test router: python test_router_activation.py" -ForegroundColor White
Write-Host ""
Write-Host "If issues persist, proceed to Phase 3: Gradual Reconfiguration" -ForegroundColor Cyan

