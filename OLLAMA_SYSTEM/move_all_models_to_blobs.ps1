# Automated script to register all unique .gguf models with Ollama
# For each unique .gguf file, finds the newest version, creates a folder, Modelfile, and runs ollama create

# List of all model file paths (add or update as needed)
$modelPaths = @(
    # Example entries (update with your actual paths or automate discovery)
    'G:\AI_Tools\Central_Repository\system\LLM_SYSTEMS\llama_vulkan\models\qwen3.gguf',
    'D:\AI_Tools\Central_Repository\.trash\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
    'D:\AI_Tools\llama_vulkan\models\phi4_expert.gguf',
    'D:\Download\phi-4-reasoning-vision-q4_k_s.gguf',
    'D:\Charlies_Angels\models\Llama-3.1-Nemotron-Nano-8B-v1-Q5_K_M.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\Llama-3.1-Nemotron-Nano-8B-v1-Q5_K_M.gguf',
    'D:\Download\microsoft-phi-4-reasoning-vision-15B.f16.gguf.Q2_K.gguf',
    'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs\deepseek_judge.gguf',
    'D:\AI_Tools\llama_vulkan\models\deepseek_judge.gguf',
    'D:\Download\deepseek-coder-6.7b-instruct.Q6_K.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\manifests\model.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q2_K.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q5_K_M.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q4_K_M.gguf',
    'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs\nomic-embed-text-v1.5.Q4_K_M.gguf'
)

# Group by filename, select the newest version for each
$uniqueModels = $modelPaths | Group-Object { [System.IO.Path]::GetFileName($_) } | ForEach-Object {
    $_.Group | Sort-Object { (Get-Item $_).LastWriteTime } -Descending | Select-Object -First 1
}

$ollamaModelsRoot = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models"

foreach ($modelPath in $uniqueModels) {
    $fileName = [System.IO.Path]::GetFileName($modelPath)
    $modelName = $fileName -replace '\.gguf$', ''
    $modelFolder = Join-Path $ollamaModelsRoot "local-$modelName"
    if (-not (Test-Path $modelFolder)) { New-Item -ItemType Directory -Path $modelFolder | Out-Null }
    $destModelPath = Join-Path $modelFolder $fileName
    # Move the file (or copy if you want to keep the original)
    Copy-Item -Path $modelPath -Destination $destModelPath -Force
    # Create Modelfile
    $modelfilePath = Join-Path $modelFolder 'Modelfile'
    "FROM ./$fileName" | Set-Content $modelfilePath
    # Run ollama create
    Push-Location $modelFolder
    Write-Host "Registering $modelName with Ollama..."
    ollama create $modelName -f Modelfile
    Pop-Location
}

Write-Host "All unique models have been registered with Ollama."
