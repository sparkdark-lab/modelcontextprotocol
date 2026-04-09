# Secure relocation script for .gguf models with full safety, logging, and user approval
# Only operates in allowed paths, never touches system or secrets folders

$blobsDir = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs"
$backupDir = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\.ai-backups"
$trashDir = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\.trash"
$logFile = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\relocate_models_log.txt"
$drives = @('D:\', 'E:\', 'G:\')
$maxFileSizeMB = 20000  # 20GB
$maxFiles = 50
$maxDepth = 8

# Exclude system and secrets paths
$excluded = @('C:\Windows', 'C:\Program Files', 'C:\Program Files (x86)', 'C:\ProgramData', 'C:\$Recycle.Bin', '.git', '.ssh', 'browser', 'DB', 'System Volume Information')

# Ensure backup and trash dirs exist
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
New-Item -ItemType Directory -Path $trashDir -Force | Out-Null

# Find all .gguf files, excluding system paths
Write-Host "Scanning for .gguf files..."
$allModels = @()
foreach ($drive in $drives) {
    $allModels += Get-ChildItem -Path $drive -Recurse -Filter *.gguf -ErrorAction SilentlyContinue | Where-Object {
        $file = $_.FullName.ToLower()
        ($excluded | ForEach-Object { $file -notlike "*$_*" }) -notcontains $false
    }
}

# Enforce operation size/scope limits
if ($allModels.Count -gt $maxFiles) {
    Write-Host "Operation would affect $($allModels.Count) files. Limit is $maxFiles. Aborting."
    exit 1
}

# Group by filename, select the most recent
$latestModels = $allModels | Group-Object Name | ForEach-Object {
    $_.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

# Summarize planned actions
Write-Host "Planned actions:"
foreach ($model in $latestModels) {
    $dest = Join-Path $blobsDir $model.Name
    if (!(Test-Path $dest) -or ((Get-Item $dest).LastWriteTime -lt $model.LastWriteTime)) {
        Write-Host "Will move $($model.FullName) -> $dest (size: $([math]::Round($model.Length/1MB,2)) MB)"
    } else {
        Write-Host "Skip (already up-to-date): $($model.FullName)"
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
foreach ($model in $latestModels) {
    $dest = Join-Path $blobsDir $model.Name
    $action = ""
    if (!(Test-Path $dest) -or ((Get-Item $dest).LastWriteTime -lt $model.LastWriteTime)) {
        # Backup existing file if present
        if (Test-Path $dest) {
            $backupName = "$($model.Name)~$(Get-Date -Format yyyyMMdd-HHmmss)"
            Copy-Item $dest (Join-Path $backupDir $backupName) -Force
            $log += "Backup: $dest -> $backupDir\$backupName"
        }
        # Safe write: copy to .tmp, then atomic rename
        $tmp = "$dest.tmp"
        Copy-Item $model.FullName $tmp -Force
        Move-Item $tmp $dest -Force
        $action = "Moved: $($model.FullName) -> $dest"
    } else {
        $action = "Skipped (already up-to-date): $($model.FullName)"
    }
    Write-Host $action
    $log += $action
}

$log | Set-Content $logFile
Write-Host "Model relocation complete. Log saved to $logFile."
