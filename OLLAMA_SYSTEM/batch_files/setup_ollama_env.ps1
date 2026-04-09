# Ollama Environment Setup
# Sets OLLAMA_MODELS environment variable to point to OLLAMA_SYSTEM/models

$OLLAMA_MODELS = "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models"
$env:OLLAMA_MODELS = $OLLAMA_MODELS

Write-Host "OLLAMA_MODELS set to: $env:OLLAMA_MODELS"
Write-Host ""
Write-Host "To start Ollama with this configuration:"
Write-Host "  ollama serve"
Write-Host ""
Write-Host "Or run:"
Write-Host "  powershell -File `"$PSScriptRoot\start_ollama_gpu.ps1`""

