# Test Ollama in Foreground (Debug Mode)
Write-Host "Stopping existing Ollama..." -ForegroundColor Yellow
Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "Starting Ollama in foreground with MRG settings..." -ForegroundColor Yellow
Write-Host "Watch for error messages below..." -ForegroundColor Cyan
Write-Host ""

$env:OLLAMA_GPU_LAYERS = "28"
$env:OLLAMA_CONTEXT = "1024"
$env:CUDA_VISIBLE_DEVICES = "0"

ollama serve --gpu-layers 28 --context 1024 --batch 256 --threads 4
