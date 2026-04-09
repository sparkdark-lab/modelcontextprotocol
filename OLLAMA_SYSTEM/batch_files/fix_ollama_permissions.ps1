#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix Ollama File Permission Issues
.DESCRIPTION
    Fixes access denied errors for Ollama model manifest files
#>

Write-Host ""
Write-Host "================================================================"
Write-Host "        FIXING OLLAMA FILE PERMISSIONS"
Write-Host "================================================================"
Write-Host ""

# Stop all Ollama processes first
Write-Host "PHASE 1: Stopping Ollama processes..."
Get-Process | Where-Object { $_.Name -like "*ollama*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
Write-Host "[OK] Ollama processes stopped"
Write-Host ""

# Problematic file path
$problematicPath = "C:\Users\$env:USERNAME\.ollama\models\manifests\registry.ollama.ai\library\qwen2.5-coder"

Write-Host "PHASE 2: Fixing permissions on problematic file..."
Write-Host "Path: $problematicPath"
Write-Host ""

if (Test-Path $problematicPath) {
    Write-Host "Found problematic file/directory"
    
    try {
        # Try to take ownership and grant full control
        Write-Host "Attempting to fix permissions..."
        
        # Remove read-only attribute
        if (Test-Path $problematicPath -PathType Container) {
            Get-ChildItem -Path $problematicPath -Recurse | ForEach-Object {
                $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
            }
            (Get-Item $problematicPath).Attributes = (Get-Item $problematicPath).Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
        }
        else {
            (Get-Item $problematicPath).Attributes = (Get-Item $problematicPath).Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
        }
        
        Write-Host "[OK] Read-only attributes removed"
        
        # Try to remove the file/directory
        Write-Host "Attempting to remove problematic file/directory..."
        Remove-Item -Path $problematicPath -Recurse -Force -ErrorAction Stop
        Write-Host "[OK] Problematic file/directory removed successfully"
        
    }
    catch {
        Write-Host "[WARNING] Could not remove file automatically: $_"
        Write-Host ""
        Write-Host "MANUAL FIX REQUIRED:"
        Write-Host "1. Open File Explorer"
        Write-Host "2. Navigate to: $problematicPath"
        Write-Host "3. Right-click → Properties → Security → Advanced"
        Write-Host "4. Change owner to your user account"
        Write-Host "5. Grant Full Control permissions"
        Write-Host "6. Delete the file/directory"
        Write-Host ""
        Write-Host "Or run this script as Administrator"
        exit 1
    }
}
else {
    Write-Host "[INFO] Problematic file not found (may have been removed already)"
}

Write-Host ""
Write-Host "PHASE 3: Starting Ollama..."
Write-Host ""

# Start Ollama using the OLLAMA_SYSTEM script
$ollamaStartScript = "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\batch_files\start_ollama_gpu.ps1"

if (Test-Path $ollamaStartScript) {
    Write-Host "Using OLLAMA_SYSTEM startup script..."
    & powershell -ExecutionPolicy Bypass -File $ollamaStartScript
}
else {
    Write-Host "Using default Ollama startup..."
    $ollamaPath = "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe"
    if (Test-Path $ollamaPath) {
        Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Hidden
        Write-Host "[OK] Ollama started"
    }
    else {
        Write-Host "[ERROR] Ollama executable not found"
        exit 1
    }
}

Write-Host ""
Write-Host "PHASE 4: Verifying Ollama..."
Write-Host ""

Start-Sleep -Seconds 5

$maxRetries = 10
$retry = 0
$apiOk = $false

while ($retry -lt $maxRetries -and -not $apiOk) {
    try {
        $response = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 3 -ErrorAction Stop
        $apiOk = $true
        Write-Host "[OK] Ollama API responding"
        Write-Host ""
        Write-Host "Available models:"
        $response.models | ForEach-Object {
            Write-Host "   - $($_.name)"
        }
    }
    catch {
        $retry++
        if ($retry -lt $maxRetries) {
            Write-Host "Waiting for API... (attempt $retry/$maxRetries)"
            Start-Sleep -Seconds 2
        }
    }
}

if (-not $apiOk) {
    Write-Host ""
    Write-Host "[ERROR] Ollama API not responding after $maxRetries attempts"
    Write-Host ""
    Write-Host "RECOMMENDATION: Run nuclear reset script:"
    Write-Host "   .\nuclear_reset_ollama.ps1"
    exit 1
}

Write-Host ""
Write-Host "================================================================"
Write-Host "         [OK] OLLAMA FIXED AND RUNNING"
Write-Host "================================================================"
Write-Host ""

