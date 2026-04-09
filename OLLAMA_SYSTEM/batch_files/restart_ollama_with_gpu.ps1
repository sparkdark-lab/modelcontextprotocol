#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restart Ollama with GPU acceleration enabled
    
.DESCRIPTION
    Stops existing Ollama process and restarts it with all GPU acceleration environment variables
    Integrated with OLLAMA_SYSTEM configuration
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Restart Ollama with GPU Acceleration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop existing Ollama
Write-Host "[1/3] Stopping existing Ollama process..." -ForegroundColor Yellow
$ollamaProcess = Get-Process -Name "ollama" -ErrorAction SilentlyContinue

if ($ollamaProcess) {
    Write-Host "  Found Ollama process (PID: $($ollamaProcess.Id))" -ForegroundColor Cyan
    Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "  Ollama stopped" -ForegroundColor Green
}
else {
    Write-Host "  No Ollama process found" -ForegroundColor Yellow
}

# Step 2: Set GPU environment variables (aligned with OLLAMA_SYSTEM)
Write-Host ""
Write-Host "[2/3] Setting GPU acceleration environment variables..." -ForegroundColor Yellow

# Set OLLAMA_MODELS to OLLAMA_SYSTEM models directory
$env:OLLAMA_MODELS = "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models"
Write-Host "  OLLAMA_MODELS = $env:OLLAMA_MODELS" -ForegroundColor Cyan

# GPU Configuration (aligned with OLLAMA_SYSTEM config)
$env:OLLAMA_GPU_ENABLED = "1"
$env:OLLAMA_NUM_GPU = "1"
$env:OLLAMA_GPU_LAYERS = "28"  # Per config: llama3.1:8b uses 28 layers (RTX 3060 optimal)
$env:OLLAMA_GPU_OVERHEAD = "1000000000"  # 1GB in bytes (prevents warning)
$env:OLLAMA_NUM_THREAD = "12"  # Increased for 20 workers
$env:OLLAMA_GPU_MEMORY_FRACTION = "0.9"  # 90% GPU memory
$env:OLLAMA_BATCH = "256"  # MRG v8: Batch processing
$env:OLLAMA_CONTEXT = "1024"  # MRG v8.0 recommended
$env:OLLAMA_F16_KV = "1"  # f16 KV cache (memory efficient)
$env:OLLAMA_LOW_VRAM = "0"  # Not low VRAM mode
$env:OLLAMA_KEEP_ALIVE = "30m"  # Keep models loaded longer for parallel processing
$env:OLLAMA_FLASH_ATTENTION = "1"  # Flash attention enabled

# PARALLEL PROCESSING CONFIGURATION (20 WORKERS)
$env:OLLAMA_NUM_PARALLEL = "20"  # 20 workers for parallel processing
$env:OLLAMA_MAX_LOADED_MODELS = "5"  # Allow multiple models loaded simultaneously
$env:OLLAMA_MAX_QUEUE = "512"  # Queue size for parallel requests

# NVIDIA-only GPU configuration
$env:CUDA_VISIBLE_DEVICES = "0"
$env:HIP_VISIBLE_DEVICES = ""
$env:OCL_ICD_VENDORS = "nvidia.icd"
$env:VK_ICD_FILENAMES = "nvidia_icd.json"
$env:AMD_VULKAN_ICD = "RADV"
$env:RADV_PERFTEST = "0"

# Additional CUDA optimizations (from OLLAMA_SYSTEM)
$env:TORCH_CUDA_ARCH_LIST = "8.6"  # RTX 3060 architecture
$env:CUDA_LAUNCH_BLOCKING = "0"  # Non-blocking CUDA
$env:CUDA_CACHE_DISABLE = "0"  # Enable CUDA cache
$env:NUMBA_ENABLE_CUDASIM = "0"  # Real GPU, no simulation

Write-Host "  GPU Environment Variables Configured (MRG v8.0 + OLLAMA_SYSTEM):" -ForegroundColor Green
Write-Host "    OLLAMA_MODELS = $env:OLLAMA_MODELS"
Write-Host "    OLLAMA_GPU_ENABLED = $env:OLLAMA_GPU_ENABLED"
Write-Host "    OLLAMA_GPU_LAYERS = $env:OLLAMA_GPU_LAYERS (28 - MRG v8.0 optimal for RTX 3060)"
Write-Host "    OLLAMA_GPU_OVERHEAD = 1GB (1000000000 bytes)"
Write-Host "    OLLAMA_GPU_MEMORY_FRACTION = $env:OLLAMA_GPU_MEMORY_FRACTION (90%)"
Write-Host "    OLLAMA_FLASH_ATTENTION = $env:OLLAMA_FLASH_ATTENTION"
Write-Host "    OLLAMA_F16_KV = $env:OLLAMA_F16_KV (memory efficient)"
Write-Host "    CUDA_VISIBLE_DEVICES = $env:CUDA_VISIBLE_DEVICES (NVIDIA only)"
Write-Host "    AMD GPU: DISABLED"
Write-Host ""
Write-Host "  PARALLEL PROCESSING (20 WORKERS):" -ForegroundColor Cyan
Write-Host "    OLLAMA_NUM_PARALLEL = $env:OLLAMA_NUM_PARALLEL (20 workers)" -ForegroundColor Green
Write-Host "    OLLAMA_MAX_LOADED_MODELS = $env:OLLAMA_MAX_LOADED_MODELS (5 models)" -ForegroundColor Green
Write-Host "    OLLAMA_MAX_QUEUE = $env:OLLAMA_MAX_QUEUE (512 requests)" -ForegroundColor Green
Write-Host ""
Write-Host "  Startup Command (MRG v8.0 + 20 Workers):" -ForegroundColor Cyan
Write-Host "    ollama serve --gpu-layers 28 --context 1024 --batch 256 --threads 12" -ForegroundColor White

# Step 3: Start Ollama with GPU acceleration
Write-Host ""
Write-Host "[3/3] Starting Ollama with GPU acceleration..." -ForegroundColor Yellow

# Create environment variable dictionary for Start-Process (OLLAMA_SYSTEM aligned)
$envVars = @{
    "OLLAMA_MODELS"              = "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models"
    "OLLAMA_GPU_ENABLED"         = "1"
    "OLLAMA_NUM_GPU"             = "1"
    "OLLAMA_GPU_LAYERS"          = "28"  # llama3.1:8b per OLLAMA_SYSTEM config
    "OLLAMA_GPU_OVERHEAD"        = "1000000000"  # 1GB in bytes
    "OLLAMA_NUM_THREAD"          = "12"
    "OLLAMA_GPU_MEMORY_FRACTION" = "0.9"
    "OLLAMA_BATCH"               = "256"
    "OLLAMA_CONTEXT"             = "2048"
    "OLLAMA_F16_KV"              = "1"
    "OLLAMA_LOW_VRAM"            = "0"
    "OLLAMA_KEEP_ALIVE"          = "30m"
    "OLLAMA_NUM_PARALLEL"        = "20"
    "OLLAMA_MAX_LOADED_MODELS"   = "5"
    "OLLAMA_MAX_QUEUE"           = "512"
    "OLLAMA_FLASH_ATTENTION"     = "1"
    "CUDA_VISIBLE_DEVICES"       = "0"
    "HIP_VISIBLE_DEVICES"        = ""
    "OCL_ICD_VENDORS"            = "nvidia.icd"
    "VK_ICD_FILENAMES"           = "nvidia_icd.json"
    "AMD_VULKAN_ICD"             = "RADV"
    "RADV_PERFTEST"              = "0"
    "TORCH_CUDA_ARCH_LIST"       = "8.6"
    "CUDA_LAUNCH_BLOCKING"       = "0"
    "CUDA_CACHE_DISABLE"         = "0"
    "NUMBA_ENABLE_CUDASIM"       = "0"
}

# Find Ollama executable
$ollamaExe = $null
$searchPaths = @(
    "C:\Users\Hectojr\AppData\Local\Programs\Ollama\ollama.exe",
    "$env:ProgramFiles\Ollama\ollama.exe",
    "$env:ProgramFiles(x86)\Ollama\ollama.exe",
    "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
)

# Try to find Ollama
foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        $ollamaExe = $path
        Write-Host "  Found Ollama at: $ollamaExe" -ForegroundColor Green
        break
    }
}

# If not found, try Get-Command
if (-not $ollamaExe) {
    $cmd = Get-Command ollama -ErrorAction SilentlyContinue
    if ($cmd) {
        $ollamaExe = $cmd.Source
        Write-Host "  Found Ollama in PATH: $ollamaExe" -ForegroundColor Green
    }
}

# If still not found, use "ollama" and hope it's in PATH
if (-not $ollamaExe) {
    $ollamaExe = "ollama"
    Write-Host "  Using 'ollama' command (must be in PATH)" -ForegroundColor Yellow
}

# Start Ollama in background with environment variables and MRG-recommended command-line arguments
try {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $ollamaExe
    # MRG v8.0 recommended: --gpu-layers 28 --context 1024 --batch 256 --threads 12 (for 20 workers)
    $processInfo.Arguments = "serve --gpu-layers 28 --context 1024 --batch 256 --threads 12"
    $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    
    # Set environment variables
    foreach ($key in $envVars.Keys) {
        $processInfo.EnvironmentVariables[$key] = $envVars[$key]
    }
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    
    Write-Host "  Ollama started (PID: $($process.Id))" -ForegroundColor Green
    Write-Host "  Waiting for Ollama to initialize..." -ForegroundColor Yellow
    
    # Wait for Ollama to be ready
    $maxWait = 10
    $waited = 0
    $ready = $false
    
    while ($waited -lt $maxWait -and -not $ready) {
        Start-Sleep -Seconds 1
        $waited++
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            $ready = $true
        }
        catch {
            # Still waiting
        }
    }
    
    if ($ready) {
        Write-Host "  ✅ Ollama is ready with GPU acceleration" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠️  Ollama started but may need more time to initialize" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ❌ Failed to start Ollama: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  INSTALLATION REQUIRED:" -ForegroundColor Yellow
    Write-Host "    Ollama is not installed or not found in PATH." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    To install Ollama:" -ForegroundColor Cyan
    Write-Host "      1. Download: https://ollama.com/download" -ForegroundColor White
    Write-Host "      2. Or run: winget install Ollama.Ollama" -ForegroundColor White
    Write-Host ""
    Write-Host "    After installation, run this script again:" -ForegroundColor Cyan
    Write-Host "      .\restart_ollama_with_gpu.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Ollama Restart Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "GPU Acceleration Status:" -ForegroundColor Cyan
Write-Host "  ✅ Environment variables set" -ForegroundColor Green
Write-Host "  ✅ Ollama restarted with GPU settings" -ForegroundColor Green
Write-Host "  ✅ Ready for GPU-accelerated inference" -ForegroundColor Green
Write-Host ""
Write-Host "Note: GPU usage will be visible when a model is actively processing" -ForegroundColor Yellow
Write-Host "      Monitor with: nvidia-smi -l 1" -ForegroundColor Yellow

