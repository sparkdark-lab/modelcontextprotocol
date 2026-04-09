#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ensure Ollama is running with GPU acceleration enabled
    
.DESCRIPTION
    Checks if Ollama is running with GPU acceleration and restarts it if needed
    Sets all required environment variables for NVIDIA GPU acceleration
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Ollama GPU Acceleration Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set GPU environment variables (must be set before Ollama starts)
$env:OLLAMA_GPU_ENABLED = "1"
$env:OLLAMA_NUM_GPU = "1"
$env:OLLAMA_GPU_LAYERS = "28"
$env:CUDA_VISIBLE_DEVICES = "0"
$env:HIP_VISIBLE_DEVICES = ""
$env:OCL_ICD_VENDORS = "nvidia.icd"
$env:VK_ICD_FILENAMES = "nvidia_icd.json"
$env:AMD_VULKAN_ICD = "RADV"
$env:RADV_PERFTEST = "0"

Write-Host "[1/4] GPU Environment Variables Set" -ForegroundColor Green
Write-Host "  OLLAMA_GPU_ENABLED = $env:OLLAMA_GPU_ENABLED"
Write-Host "  OLLAMA_GPU_LAYERS = $env:OLLAMA_GPU_LAYERS (RTX 3060 optimal)"
Write-Host "  CUDA_VISIBLE_DEVICES = $env:CUDA_VISIBLE_DEVICES (NVIDIA only)"
Write-Host ""

# Check if Ollama is running
Write-Host "[2/4] Checking Ollama Status..." -ForegroundColor Yellow
$ollamaProcess = Get-Process -Name "ollama" -ErrorAction SilentlyContinue

if ($ollamaProcess) {
    Write-Host "  Ollama is running (PID: $($ollamaProcess.Id))" -ForegroundColor Green
    
    # Check if Ollama is responding
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  Ollama API is responding" -ForegroundColor Green
        
        # Check GPU usage via nvidia-smi if available
        $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
        if ($nvidiaSmi) {
            Write-Host ""
            Write-Host "[3/4] Checking GPU Usage..." -ForegroundColor Yellow
            $gpuInfo = nvidia-smi --query-gpu=name, utilization.gpu, memory.used, memory.total --format=csv, noheader
            Write-Host "  GPU Status:" -ForegroundColor Cyan
            $gpuInfo | ForEach-Object { Write-Host "    $_" }
        }
    }
    catch {
        Write-Host "  WARNING: Ollama API not responding" -ForegroundColor Yellow
        Write-Host "  Ollama may need to be restarted with GPU acceleration" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  Ollama is NOT running" -ForegroundColor Red
    Write-Host "  Starting Ollama with GPU acceleration..." -ForegroundColor Yellow
    
    # Start Ollama in background with GPU environment variables
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden -Environment @{
        "OLLAMA_GPU_ENABLED"   = "1"
        "OLLAMA_NUM_GPU"       = "1"
        "OLLAMA_GPU_LAYERS"    = "28"
        "CUDA_VISIBLE_DEVICES" = "0"
        "HIP_VISIBLE_DEVICES"  = ""
        "OCL_ICD_VENDORS"      = "nvidia.icd"
        "VK_ICD_FILENAMES"     = "nvidia_icd.json"
        "AMD_VULKAN_ICD"       = "RADV"
        "RADV_PERFTEST"        = "0"
    }
    
    Write-Host "  Ollama started with GPU acceleration" -ForegroundColor Green
    Start-Sleep -Seconds 3
}

# Verify GPU acceleration
Write-Host ""
Write-Host "[4/4] Verifying GPU Acceleration..." -ForegroundColor Yellow

# Check if nvidia-smi shows Ollama using GPU
$nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($nvidiaSmi) {
    $gpuProcesses = nvidia-smi --query-compute-apps=pid, process_name, used_memory --format=csv, noheader
    $ollamaOnGpu = $gpuProcesses | Select-String -Pattern "ollama"
    
    if ($ollamaOnGpu) {
        Write-Host "  ✅ Ollama is using GPU acceleration" -ForegroundColor Green
        Write-Host "  GPU Process Info:" -ForegroundColor Cyan
        $ollamaOnGpu | ForEach-Object { Write-Host "    $_" }
    }
    else {
        Write-Host "  ⚠️  Ollama may not be using GPU (check if model is loaded)" -ForegroundColor Yellow
        Write-Host "  Note: GPU usage only appears when model is actively processing" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  ⚠️  nvidia-smi not found - cannot verify GPU usage" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GPU Acceleration Check Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment Variables (Current Session):" -ForegroundColor Cyan
Write-Host "  OLLAMA_GPU_ENABLED = $env:OLLAMA_GPU_ENABLED"
Write-Host "  OLLAMA_GPU_LAYERS = $env:OLLAMA_GPU_LAYERS"
Write-Host "  CUDA_VISIBLE_DEVICES = $env:CUDA_VISIBLE_DEVICES"
Write-Host ""
Write-Host "Note: For persistent GPU acceleration, set these as system-wide environment variables" -ForegroundColor Yellow
Write-Host "      Use: active\apply_universal_nvidia_gpu.bat" -ForegroundColor Yellow

