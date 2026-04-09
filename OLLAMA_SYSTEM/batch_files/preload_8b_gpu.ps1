# Preload llama3.1:8b onto NVIDIA GPU
# OLLAMA_SYSTEM - GPU Preloading Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PRELOADING llama3.1:8b TO NVIDIA GPU" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load configuration
$configPath = "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\config\ollama_config.json"
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        $gpuConfig = $config.gpu_configuration
        $modelConfig = $config.model_configuration.models."llama3.1:8b"
    } catch {
        Write-Host "Error parsing config file: $_" -ForegroundColor Red
        Write-Host "Using defaults" -ForegroundColor Yellow
        $gpuConfig = @{
            enabled = $true
            cuda_visible_devices = "0"
            num_gpu = 1
        }
        $modelConfig = @{
            gpu_layers = 28
        }
    }
} else {
    Write-Host "Config file not found, using defaults" -ForegroundColor Yellow
    $gpuConfig = @{
        enabled = $true
        cuda_visible_devices = "0"
        num_gpu = 1
    }
    $modelConfig = @{
        gpu_layers = 28
    }
}

$OLLAMA_URL = "http://localhost:11434"
$MODEL_NAME = "llama3.1:8b"
$KEEP_ALIVE = "30m"  # Keep model in GPU memory for 30 minutes

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Model: $MODEL_NAME" -ForegroundColor White
Write-Host "  GPU Layers: $($modelConfig.gpu_layers)" -ForegroundColor White
Write-Host "  Keep Alive: $KEEP_ALIVE" -ForegroundColor White
Write-Host "  Ollama URL: $OLLAMA_URL" -ForegroundColor White
Write-Host ""

# Check if Ollama is running
Write-Host "Checking Ollama status..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$OLLAMA_URL/api/tags" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    Write-Host "[OK] Ollama is running" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Ollama is not running or not accessible" -ForegroundColor Red
    Write-Host "Please start Ollama first using: start_ollama_gpu.ps1" -ForegroundColor Yellow
    exit 1
}

# Check GPU status
Write-Host ""
Write-Host "Checking GPU status..." -ForegroundColor Yellow
try {
    $nvidiaSmi = nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader,nounits 2>&1
    if ($LASTEXITCODE -eq 0) {
        $gpuInfo = $nvidiaSmi -split ","
        $gpuName = $gpuInfo[0].Trim()
        $memUsed = [int]$gpuInfo[1].Trim()
        $memTotal = [int]$gpuInfo[2].Trim()
        $memPercent = [math]::Round(($memUsed / $memTotal) * 100, 1)
        
        Write-Host "[OK] GPU detected: $gpuName" -ForegroundColor Green
        Write-Host "  Memory: $memUsed MB / $memTotal MB ($memPercent%)" -ForegroundColor White
    } else {
        Write-Host "[WARNING] Could not query GPU status (nvidia-smi not available)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[WARNING] Could not check GPU status: $_" -ForegroundColor Yellow
}

# Preload model using Ollama API
Write-Host ""
Write-Host "Preloading $MODEL_NAME to GPU..." -ForegroundColor Yellow
Write-Host "This may take 30-60 seconds on first load..." -ForegroundColor Gray

$preloadBody = @{
    model = $MODEL_NAME
    prompt = "test"
    stream = $false
    options = @{
        num_gpu = $modelConfig.gpu_layers
        keep_alive = $KEEP_ALIVE
    }
} | ConvertTo-Json -Depth 10

try {
    $startTime = Get-Date
    $response = Invoke-RestMethod -Uri "$OLLAMA_URL/api/generate" -Method Post -Body $preloadBody -ContentType "application/json" -TimeoutSec 120
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host "[OK] Model preloaded successfully!" -ForegroundColor Green
    Write-Host "  Duration: $([math]::Round($duration, 1)) seconds" -ForegroundColor White
    Write-Host "  Keep Alive: $KEEP_ALIVE (model will stay in GPU memory)" -ForegroundColor White
    Write-Host ""
    Write-Host "Model is now loaded in GPU memory and ready for fast inference." -ForegroundColor Green
    Write-Host "The model will remain loaded for $KEEP_ALIVE unless explicitly unloaded." -ForegroundColor Gray
    
} catch {
    Write-Host "[ERROR] Failed to preload model: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "  HTTP Status: $statusCode" -ForegroundColor Red
    }
    exit 1
}

# Verify model is loaded
Write-Host ""
Write-Host "Verifying model status..." -ForegroundColor Yellow
try {
    $psBody = @{
        name = $MODEL_NAME
    } | ConvertTo-Json
    
    $psResponse = Invoke-RestMethod -Uri "$OLLAMA_URL/api/ps" -Method Post -Body $psBody -ContentType "application/json" -TimeoutSec 5
    
    if ($psResponse.models) {
        Write-Host "[OK] Model confirmed in memory:" -ForegroundColor Green
        foreach ($model in $psResponse.models) {
            Write-Host "  - $($model.name) (expires in: $($model.expires_at))" -ForegroundColor White
        }
    } else {
        Write-Host "[WARNING] Model status check returned no models" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[WARNING] Could not verify model status: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PRELOAD COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The model is now loaded in GPU memory and ready for use." -ForegroundColor Green
Write-Host "Subsequent queries will be much faster (10-30 seconds vs 60-90 seconds)." -ForegroundColor Gray

