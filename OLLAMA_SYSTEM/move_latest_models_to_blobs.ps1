# Fool-proof script to move only the most recent version of each .gguf model to the blobs directory
# Scans all drives, picks the newest, and logs actions

$blobsDir = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs"
$logFile = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\move_models_log.txt"
$drives = @('D:\', 'E:\', 'G:\')

# Find all .gguf files
Write-Host "Scanning for .gguf files..."
$allModels = @()
foreach ($drive in $drives) {
    $allModels += Get-ChildItem -Path $drive -Recurse -Filter *.gguf -ErrorAction SilentlyContinue
}

# Group by filename, select the most recent
$latestModels = $allModels | Group-Object Name | ForEach-Object {
    $_.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

# Move the most recent version of each model to blobs
$log = @()
foreach ($model in $latestModels) {
    $dest = Join-Path $blobsDir $model.Name
    $action = ""
    if (!(Test-Path $dest) -or ((Get-Item $dest).LastWriteTime -lt $model.LastWriteTime)) {
        Move-Item -Path $model.FullName -Destination $dest -Force
        $action = "Moved: $($model.FullName) -> $dest"
    } else {
        $action = "Skipped (already up-to-date): $($model.FullName)"
    }
    Write-Host $action
    $log += $action
}

$log | Set-Content $logFile
Write-Host "Model relocation complete. Log saved to $logFile."
