# Temporary copy of the model move script for troubleshooting
$dest = "G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs"
$fileTypes = @("*.gguf", "*.bin")
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -match '^[CDEG]$' } | Select-Object -ExpandProperty Root
$excludedFolders = @(
    'C:\Windows',
    'C:\Program Files',
    'C:\Program Files (x86)',
    'C:\ProgramData',
    'C:\$Recycle.Bin',
    'C:\Users\\All Users',
    'C:\Users\\Default',
    'C:\Users\\Default User',
    'C:\Users\\Public',
    'C:\Recovery',
    'C:\System Volume Information',
    'D:\$RECYCLE.BIN',
    'E:\$RECYCLE.BIN',
    'G:\$RECYCLE.BIN'
)
$minSize = 100MB
foreach ($drive in $drives) {
    foreach ($pattern in $fileTypes) {
        Get-ChildItem -Path $drive -Recurse -Filter $pattern -ErrorAction SilentlyContinue | Where-Object {
            $file = $_
            $exclude = $false
            foreach ($ex in $excludedFolders) {
                if ($file.FullName -like "$ex*") { $exclude = $true; break }
            }
            return -not $exclude -and $file.Length -ge $minSize
        } | ForEach-Object {
            $target = Join-Path $dest $_.Name
            if (-not (Test-Path $target)) {
                Move-Item $_.FullName $target -Force
                Write-Host "Moved: $($_.FullName) -> $target"
            } else {
                Write-Host "Skipped (exists): $($_.FullName)"
            }
        }
    }
}
Write-Host "Model file move complete."
