# Start Ollama with GPU Acceleration
# OLLAMA_SYSTEM - Centralized Configuration

Write-Host "Starting Ollama with GPU Acceleration..." -ForegroundColor Green
Write-Host "OLLAMA_SYSTEM: E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM" -ForegroundColor Cyan

# Load configuration
$configPath = "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\config\ollama_config.json"
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        $gpuConfig = $config.gpu_configuration
        $serverConfig = $config.ollama_server
    } catch {
        Write-Host "Error parsing config file: $_" -ForegroundColor Red
        Write-Host "Using defaults" -ForegroundColor Yellow
        $gpuConfig = @{
            enabled = $true
            cuda_visible_devices = "0"
            num_gpu = 1
            num_thread = 8
            gpu_memory_fraction = 0.8
            flash_attention = $true
        }
        $serverConfig = @{
            executable_path = "C:\Users\Hectojr\AppData\Local\Programs\Ollama\ollama.exe"
        }
    }
} else {
    Write-Host "Config file not found, using defaults" -ForegroundColor Yellow
    $gpuConfig = @{
        enabled = $true
        cuda_visible_devices = "0"
        num_gpu = 1
        num_thread = 8
        gpu_memory_fraction = 0.8
        flash_attention = $true
    }
    $serverConfig = @{
        executable_path = "C:\Users\Hectojr\AppData\Local\Programs\Ollama\ollama.exe"
    }
}

# Set OLLAMA_MODELS environment variable (from config if available, otherwise default)
if ($serverConfig.models_directory) {
    $OLLAMA_MODELS = $serverConfig.models_directory
} else {
    $OLLAMA_MODELS = "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models"
}
$env:OLLAMA_MODELS = $OLLAMA_MODELS

Write-Host "Models Directory: $env:OLLAMA_MODELS" -ForegroundColor Cyan
Write-Host ""

# Set GPU environment variables - FULL ACCELERATION per MRG v8
if ($gpuConfig.enabled) {
    $env:CUDA_VISIBLE_DEVICES = $gpuConfig.cuda_visible_devices
    $env:OLLAMA_NUM_GPU = $gpuConfig.num_gpu
    $env:OLLAMA_NUM_THREAD = $gpuConfig.num_thread
    $env:OLLAMA_GPU_MEMORY_FRACTION = $gpuConfig.gpu_memory_fraction
    $env:OLLAMA_GPU_LAYERS = "28"  # MRG v8.0: Optimal for RTX 3060 (NOT 35)
    $env:OLLAMA_BATCH = "256"      # MRG v8: Batch processing
    $env:OLLAMA_CONTEXT = "1024"   # MRG v8: Context size
    $env:OLLAMA_LOW_VRAM = "0"     # MRG: Not low VRAM mode
    $env:OLLAMA_KEEP_ALIVE = "5m"  # Keep models loaded
    
    if ($gpuConfig.flash_attention) {
        $env:OLLAMA_FLASH_ATTENTION = "1"
    }
    if ($gpuConfig.f16_kv) {
        $env:OLLAMA_F16_KV = "1"
    } else {
        $env:OLLAMA_F16_KV = "0"
    }
    
    # Additional CUDA optimizations
    $env:TORCH_CUDA_ARCH_LIST = "8.6"        # RTX 3060 architecture
    $env:CUDA_LAUNCH_BLOCKING = "0"          # Non-blocking CUDA
    $env:CUDA_CACHE_DISABLE = "0"            # Enable CUDA cache
    $env:NUMBA_ENABLE_CUDASIM = "0"          # Real GPU, no simulation
}

Write-Host "GPU Configuration (FULL ACCELERATION - MRG v8):" -ForegroundColor Cyan
Write-Host "  CUDA_VISIBLE_DEVICES = $env:CUDA_VISIBLE_DEVICES"
Write-Host "  OLLAMA_NUM_GPU = $env:OLLAMA_NUM_GPU"
Write-Host "  OLLAMA_NUM_THREAD = $env:OLLAMA_NUM_THREAD"
$memoryValue = [double]$env:OLLAMA_GPU_MEMORY_FRACTION
$memoryPercent = [math]::Round($memoryValue * 100)
Write-Host "  OLLAMA_GPU_MEMORY_FRACTION = $env:OLLAMA_GPU_MEMORY_FRACTION ($memoryPercent%)" -ForegroundColor Green
Write-Host "  OLLAMA_GPU_LAYERS = $env:OLLAMA_GPU_LAYERS (Optimal for RTX 3060 per MRG v8.0)" -ForegroundColor Green
if ($env:OLLAMA_FLASH_ATTENTION -eq "1") {
    Write-Host "  OLLAMA_FLASH_ATTENTION = $env:OLLAMA_FLASH_ATTENTION (Enabled)" -ForegroundColor Green
} else {
    Write-Host "  OLLAMA_FLASH_ATTENTION = $env:OLLAMA_FLASH_ATTENTION (Disabled)" -ForegroundColor Yellow
}
if ($env:OLLAMA_F16_KV -eq "1") {
    Write-Host "  OLLAMA_F16_KV = $env:OLLAMA_F16_KV (Memory efficient)" -ForegroundColor Green
} else {
    Write-Host "  OLLAMA_F16_KV = $env:OLLAMA_F16_KV (Disabled)" -ForegroundColor Yellow
}
Write-Host "  OLLAMA_BATCH = $env:OLLAMA_BATCH (MRG v8)" -ForegroundColor White
Write-Host "  OLLAMA_CONTEXT = $env:OLLAMA_CONTEXT (MRG v8)" -ForegroundColor White
Write-Host ""

# Start Ollama
$ollamaPath = $serverConfig.executable_path
if (Test-Path $ollamaPath) {
    Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Minimized
    Write-Host "Ollama started with GPU acceleration" -ForegroundColor Green
    Write-Host "Waiting 5 seconds for initialization..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Verify
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -UseBasicParsing
        Write-Host "Ollama is running and responding" -ForegroundColor Green
        
        $models = ($response.Content | ConvertFrom-Json).models
        Write-Host "Available models: $($models.Count)" -ForegroundColor Cyan
        foreach ($model in $models) {
            Write-Host "  - $($model.name)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "Ollama may need more time to start" -ForegroundColor Yellow
    }
} else {
    Write-Host "Ollama not found at: $ollamaPath" -ForegroundColor Red
    Write-Host "Please install Ollama from https://ollama.com" -ForegroundColor Yellow
}

