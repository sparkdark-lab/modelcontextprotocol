# Non-destructive copy-only relocator: copies newest models to blobs, keeps originals
param(
    [switch]$AutoConfirm
)

$scriptRoot = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM"
$blobsDir = Join-Path $scriptRoot "models\blobs"
$backupDir = Join-Path $scriptRoot ".ai-backups"
$logFile = Join-Path $scriptRoot "relocate_models_safe_copy_log.txt"

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
New-Item -ItemType Directory -Path $blobsDir -Force | Out-Null

# Use the validated list the user provided
$modelPaths = @(
    'G:\AI_Tools\Central_Repository\system\LLM_SYSTEMS\llama_vulkan\models\qwen3.gguf',
    'G:\AI_Tools\Central_Repository\system\LLM_SYSTEMS\llama_vulkan\models\qwen3.gguf',
    'D:\AI_Tools\Central_Repository\.trash\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
    'D:\AI_Tools\Central_Repository\.trash\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
    'D:\AI_Tools\Central_Repository\.trash\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
    'E:\AI_Tools\Central_Repository\.trash\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
    'E:\AI_Tools\Central_Repository\.trash\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\Llama-3.1-Nemotron-Nano-8B-v1.gguf',
    'D:\AI_Tools\llama_vulkan\models\phi4_expert.gguf',
    'D:\AI_Tools\llama_vulkan\models\phi4_expert.gguf',
    'D:\Download\phi-4-reasoning-vision-q4_k_s.gguf',
    'D:\Download\phi-4-reasoning-vision-q4_k_s.gguf',
    'D:\Charlies_Angels\models\Llama-3.1-Nemotron-Nano-8B-v1-Q5_K_M.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\Llama-3.1-Nemotron-Nano-8B-v1-Q5_K_M.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\Llama-3.1-Nemotron-Nano-8B-v1-Q5_K_M.gguf',
    'D:\Download\microsoft-phi-4-reasoning-vision-15B.f16.gguf.Q2_K.gguf',
    'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs\deepseek_judge.gguf',
    'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs\deepseek_judge.gguf',
    'D:\AI_Tools\llama_vulkan\models\deepseek_judge.gguf',
    'D:\Download\deepseek-coder-6.7b-instruct.Q6_K.gguf',
    'D:\Download\deepseek-coder-6.7b-instruct.Q6_K.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\manifests\model.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\manifests\model.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q2_K.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q2_K.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q5_K_M.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q4_K_M.gguf',
    'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q2_K.gguf',
    'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs\nomic-embed-text-v1.5.Q4_K_M.gguf'
)

# Keep only existing files
$existing = @()
foreach ($p in $modelPaths) {
    if (Test-Path $p) { $existing += (Get-Item $p) } else { Write-Host "Note: not found: $p" }
}

if ($existing.Count -eq 0) { Write-Host "No sources found; exiting."; exit 0 }

# Choose newest per filename
$latest = $existing | Group-Object Name | ForEach-Object { $_.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1 }

# Summary
Write-Host "Planned copy actions (copy-only, originals untouched):"
$actions = @()
foreach ($f in $latest) {
    $dest = Join-Path $blobsDir $f.Name
    $needsCopy = -not (Test-Path $dest) -or ((Get-Item $dest).LastWriteTime -lt $f.LastWriteTime)
    $actions += [pscustomobject]@{ Source=$f.FullName; Dest=$dest; SizeMB=[math]::Round($f.Length/1MB,2); Copy=$needsCopy }
    Write-Host ("{0} -> {1}  ({2} MB) Copy={3}" -f $f.FullName, $dest, [math]::Round($f.Length/1MB,2), $needsCopy)
}

if (-not $AutoConfirm) {
    $ok = Read-Host "Type YES to proceed with copy-only run"
    if ($ok -ne 'YES') { Write-Host "Aborted."; exit 0 }
}

# Execute copy-only with safe write and backups
$log = @()
foreach ($a in $actions) {
    if (-not $a.Copy) { $log += "Skipped (up-to-date): $($a.Source)"; continue }
    try {
        # Backup existing dest if present
        if (Test-Path $a.Dest) {
            $bname = "$([System.IO.Path]::GetFileName($a.Dest))~$(Get-Date -Format yyyyMMdd-HHmmss)"
            Copy-Item $a.Dest (Join-Path $backupDir $bname) -Force
            $log += "Backup: $($a.Dest) -> $backupDir\$bname"
        }
        # Copy to tmp then atomic move into place
        $tmp = "$($a.Dest).tmp"
        Copy-Item $a.Source $tmp -Force
        Move-Item $tmp $a.Dest -Force
        $log += "Copied: $($a.Source) -> $($a.Dest)"
    } catch {
        $err = $_.Exception.Message
        $log += "ERROR copying $($a.Source): $err"
    }
}

$log | Set-Content $logFile
Write-Host "Copy-only run complete. Log: $logFile"
