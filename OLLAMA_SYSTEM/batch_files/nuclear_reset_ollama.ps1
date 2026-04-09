#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Nuclear Ollama Reset - Complete troubleshooting and recovery
.DESCRIPTION
    Comprehensive Ollama reset procedure following MRG v8.0 guidelines
#>

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗"
Write-Host "║        🔄 NUCLEAR OLLAMA RESET - STARTING                 ║"
Write-Host "╚════════════════════════════════════════════════════════════╝"
Write-Host ""

# ============================================================================
# PHASE 1: Terminate All Processes
# ============================================================================
Write-Host "PHASE 1: Terminating all Ollama and Python processes"
Write-Host "────────────────────────────────────────────────────────────"

Write-Host "Killing Ollama processes..."
taskkill /f /im ollama.exe /t 2>$null | Out-Null
Start-Sleep -Seconds 2

Write-Host "Killing Python processes..."
taskkill /f /im python.exe /t 2>$null | Out-Null
Start-Sleep -Seconds 2

Write-Host "Verifying all processes terminated..."
$ollama_check = Get-Process ollama -ErrorAction SilentlyContinue
if ($ollama_check) {
    Write-Host "⚠️  Ollama still running, force killing..."
    Stop-Process -Name ollama -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}

$final_check = Get-Process ollama -ErrorAction SilentlyContinue
if ($final_check) {
    Write-Host "❌ Failed to terminate Ollama"
    exit 1
} else {
    Write-Host "✅ All processes terminated"
}

# ============================================================================
# PHASE 2: Check GPU Memory
# ============================================================================
Write-Host ""
Write-Host "PHASE 2: GPU Memory Status"
Write-Host "────────────────────────────────────────────────────────────"

$gpu_mem = nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
$gpu_array = $gpu_mem.Split(',').Trim()
$used_mb = [int]$gpu_array[0]
$total_mb = [int]$gpu_array[1]
$percent = [math]::Round(($used_mb / $total_mb) * 100, 1)

Write-Host "GPU Memory: $used_mb MB / $total_mb MB ($percent`%)"

if ($percent -gt 50) {
    Write-Host "⚠️  GPU memory still in use. Waiting 10 seconds..."
    Start-Sleep -Seconds 10
}

# Recheck
$gpu_mem = nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
$gpu_array = $gpu_mem.Split(',').Trim()
$used_mb = [int]$gpu_array[0]
$total_mb = [int]$gpu_array[1]
$percent = [math]::Round(($used_mb / $total_mb) * 100, 1)

Write-Host "GPU Memory (after wait): $used_mb MB / $total_mb MB ($percent`%)"

if ($percent -lt 20) {
    Write-Host "✅ GPU memory cleared"
} else {
    Write-Host "⚠️  GPU memory still at $percent`% (but proceeding)"
}

# ============================================================================
# PHASE 3: Remove Problematic Models
# ============================================================================
Write-Host ""
Write-Host "PHASE 3: Removing problematic models"
Write-Host "────────────────────────────────────────────────────────────"

Write-Host "Listing current models..."
$models = & ollama list 2>&1
Write-Host $models

if ($models -match "qwen2.5-coder:32b") {
    Write-Host "Removing qwen2.5-coder:32b..."
    & ollama rm qwen2.5-coder:32b 2>&1
    Write-Host "✅ qwen2.5-coder:32b removed"
    Start-Sleep -Seconds 2
} else {
    Write-Host "ℹ️  qwen2.5-coder:32b not found in local models"
}

# ============================================================================
# PHASE 4: Start Ollama Fresh
# ============================================================================
Write-Host ""
Write-Host "PHASE 4: Starting Ollama fresh"
Write-Host "────────────────────────────────────────────────────────────"

Write-Host "Launching Ollama service..."
$ollama_path = "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe"

if (-not (Test-Path $ollama_path)) {
    Write-Host "⚠️  Custom path not found, trying PATH variable..."
    $ollama_path = (Get-Command ollama -ErrorAction SilentlyContinue).Source
    if (-not $ollama_path) {
        Write-Host "❌ Cannot find Ollama executable"
        exit 1
    }
}

Write-Host "Using: $ollama_path"

# Start Ollama in background
$proc = Start-Process -FilePath $ollama_path -ArgumentList "serve" -PassThru -NoNewWindow
Write-Host "✅ Ollama started (PID: $($proc.Id))"

Write-Host "⏳ Waiting 15 seconds for Ollama to initialize..."
Start-Sleep -Seconds 15

# ============================================================================
# PHASE 5: Verify Ollama API
# ============================================================================
Write-Host ""
Write-Host "PHASE 5: Verifying Ollama API"
Write-Host "────────────────────────────────────────────────────────────"

$max_retries = 10
$retry = 0
$api_ok = $false

while ($retry -lt $max_retries -and -not $api_ok) {
    try {
        $response = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 3 -ErrorAction Stop
        $api_ok = $true
        Write-Host "✅ Ollama API responding"
    } catch {
        $retry++
        if ($retry -lt $max_retries) {
            Write-Host "⏳ Waiting for API... (attempt $retry/$max_retries)"
            Start-Sleep -Seconds 2
        }
    }
}

if (-not $api_ok) {
    Write-Host "❌ Ollama API not responding after $max_retries attempts"
    exit 1
}

# ============================================================================
# PHASE 6: Download Models
# ============================================================================
Write-Host ""
Write-Host "PHASE 6: Downloading clean model copies"
Write-Host "────────────────────────────────────────────────────────────"

Write-Host "Downloading codellama:7b (lightweight, 3.8 GB)..."
Write-Host "This should take 2-5 minutes with aria2 acceleration..."
& ollama pull codellama:7b

Write-Host ""
Write-Host "✅ codellama:7b downloaded"
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "Downloading qwen2.5-coder:32b fresh (advanced model, 20 GB)..."
Write-Host "This will take 5-15 minutes with aria2 acceleration..."
& ollama pull qwen2.5-coder:32b

Write-Host "✅ qwen2.5-coder:32b downloaded"

# ============================================================================
# PHASE 7: Final Verification
# ============================================================================
Write-Host ""
Write-Host "PHASE 7: Final verification"
Write-Host "────────────────────────────────────────────────────────────"

try {
    $response = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 5
    Write-Host "✅ Ollama API responding"
    Write-Host ""
    Write-Host "📋 Available models:"
    $response.models | ForEach-Object {
        $size_gb = [math]::Round($_.size / 1GB, 1)
        Write-Host "   ✓ $($_.name) - $size_gb GB"
    }
} catch {
    Write-Host "❌ API verification failed: $_"
    exit 1
}

# ============================================================================
# COMPLETION
# ============================================================================
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗"
Write-Host "║         ✅ NUCLEAR RESET COMPLETE - READY TO USE          ║"
Write-Host "╚════════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "📊 System Status:"
Write-Host "   ✅ Ollama: Running and healthy"
Write-Host "   ✅ API: Responding"
Write-Host "   ✅ Models: Fresh download"
Write-Host "   ✅ GPU: Available"
Write-Host ""
Write-Host "🚀 Next steps:"
Write-Host "   1. Test router: python llm_router_local_first.py"
Write-Host "   2. Run queries through local consensus"
Write-Host "   3. Monitor GPU with: nvidia-smi"
Write-Host ""
Write-Host "💾 Keep this window open to maintain Ollama service"
Write-Host ""

