param(
    [switch]$AutoConfirm,
    [switch]$UseROBOX,
    [switch]$DryRun
)

# Consolidated safe relocation system
$scriptRoot = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM"
$blobsDir = Join-Path $scriptRoot "models\blobs"
$backupDir = Join-Path $scriptRoot ".ai-backups"
$trashDir = Join-Path $scriptRoot ".trash"
$logFile = Join-Path $scriptRoot "relocate_models_system_log.txt"

# Ensure support directories exist
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
New-Item -ItemType Directory -Path $trashDir -Force | Out-Null
New-Item -ItemType Directory -Path $blobsDir -Force | Out-Null

# User-provided list (canonical list from user)
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

# Normalize: keep only paths that exist
$existing = @()
foreach ($p in $modelPaths) {
    if (Test-Path $p) { $existing += (Get-Item $p) } else { Write-Host "Warning: path not found: $p" }
}

if ($existing.Count -eq 0) {
    Write-Host "No valid model files found in provided list. Exiting.";
    exit 1
}

# Group by filename, select newest
$latest = $existing | Group-Object Name | ForEach-Object { $_.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1 }

# Prepare planned actions
$actions = @()
foreach ($f in $latest) {
    $dest = Join-Path $blobsDir $f.Name
    $needsMove = -not (Test-Path $dest) -or ((Get-Item $dest).LastWriteTime -lt $f.LastWriteTime)
    $actions += [pscustomobject]@{ Source = $f.FullName; Name = $f.Name; SizeMB = [math]::Round($f.Length/1MB,2); Dest = $dest; Move = $needsMove }
}

# Show summary
Write-Host "Planned actions (dry-run=$DryRun):"
$actions | ForEach-Object { Write-Host ("{0} -> {1} ({2} MB)  Move={3}" -f $_.Source, $_.Dest, $_.SizeMB, $_.Move) }

if ($DryRun) { Write-Host "Dry-run complete. No changes made."; exit 0 }

if (-not $AutoConfirm) {
    $ok = Read-Host "Type YES to proceed with moves"
    if ($ok -ne 'YES') { Write-Host "Aborted by user."; exit 1 }
}

# Execute moves with safe pattern
$log = @()
foreach ($a in $actions) {
    if (-not $a.Move) { $log += "Skipped: $($a.Source) - up-to-date"; continue }
    try {
        # Backup destination if exists
        if (Test-Path $a.Dest) {
            $bname = "$($a.Name)~$(Get-Date -Format yyyyMMdd-HHmmss)"
            Copy-Item $a.Dest (Join-Path $backupDir $bname) -Force
            $log += "Backup: $($a.Dest) -> $backupDir\$bname"
        }
        # Safe copy to tmp then atomic move
        $tmp = "$($a.Dest).tmp"
        Copy-Item $a.Source $tmp -Force
        Move-Item $tmp $a.Dest -Force
        $log += "Moved: $($a.Source) -> $($a.Dest)"

        # Soft-delete other duplicates from provided list (move to trash)
        $duplicates = $existing | Where-Object { $_.Name -eq $a.Name -and $_.FullName -ne $a.Source }
        foreach ($d in $duplicates) {
            $trashName = "$($d.Name)~$(Get-Date -Format yyyyMMdd-HHmmss)"
            Move-Item $d.FullName (Join-Path $trashDir $trashName) -Force
            $log += "Soft-deleted duplicate: $($d.FullName) -> $trashDir\$trashName"
        }

    } catch {
        $log += "ERROR processing $($a.Source): $($_.Exception.Message)"
        Write-Host "Error: $($_.Exception.Message)"
    }
}

$log | Set-Content $logFile
Write-Host "Completed. Log: $logFile";
