# Relocate models using explicit user-provided list, with full safety and logging
$blobsDir = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs"
$backupDir = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\.ai-backups"
$logFile = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\relocate_models_log.txt"

# Ensure backup dir exists
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# User-provided list of model file paths
$modelPaths = @(
    'G:\AI_Tools\Central_Repository\system\LLM_SYSTEMS\llama_vulkan\models\qwen3.gguf',
    'D:\AI_Tools\Central_Repository\.trash\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
    'E:\AI_Tools\Central_Repository\.trash\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
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

# Group by filename, select the most recent
$latestModels = $modelPaths | Group-Object { [System.IO.Path]::GetFileName($_) } | ForEach-Object {
    $_.Group | Sort-Object { (Get-Item $_).LastWriteTime } -Descending | Select-Object -First 1
}

# Summarize planned actions
Write-Host "Planned actions:"
foreach ($modelPath in $latestModels) {
    $file = Get-Item $modelPath
    $dest = Join-Path $blobsDir $file.Name
    if (!(Test-Path $dest) -or ((Get-Item $dest).LastWriteTime -lt $file.LastWriteTime)) {
        Write-Host "Will move $($file.FullName) -> $dest (size: $([math]::Round($file.Length/1MB,2)) MB)"
    } else {
        Write-Host "Skip (already up-to-date): $($file.FullName)"
    }
}

# Ask for user approval
$approval = Read-Host "Proceed with these changes? Type YES to confirm"
if ($approval -ne "YES") {
    Write-Host "Aborted by user."
    exit 1
}

# Move the most recent version of each model to blobs, with backup and atomic replace
$log = @()
foreach ($modelPath in $latestModels) {
    $file = Get-Item $modelPath
    $dest = Join-Path $blobsDir $file.Name
    $action = ""
    if (!(Test-Path $dest) -or ((Get-Item $dest).LastWriteTime -lt $file.LastWriteTime)) {
        # Backup existing file if present
        if (Test-Path $dest) {
            $backupName = "$($file.Name)~$(Get-Date -Format yyyyMMdd-HHmmss)"
            Copy-Item $dest (Join-Path $backupDir $backupName) -Force
            $log += "Backup: $dest -> $backupDir\$backupName"
        }
        # Safe write: copy to .tmp, then atomic rename
        $tmp = "$dest.tmp"
        Copy-Item $file.FullName $tmp -Force
        Move-Item $tmp $dest -Force
        $action = "Moved: $($file.FullName) -> $dest"
    } else {
        $action = "Skipped (already up-to-date): $($file.FullName)"
    }
    Write-Host $action
    $log += $action
}

$log | Set-Content $logFile
Write-Host "Model relocation complete. Log saved to $logFile."
