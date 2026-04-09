# ============================================================================
# FIX OLLAMA DOWNLOAD - TLS Error Resolution
# ============================================================================
# Problem: "max retries exceeded: local error: tls: bad record MAC"
# Cause: Network interruption, TLS handshake failure, or partial download
# Solution: Clean partial download and retry with network fixes
# ============================================================================

Write-Host "=============================================="
Write-Host "OLLAMA DOWNLOAD FIX - TLS ERROR RESOLUTION"
Write-Host "=============================================="
Write-Host ""

# Step 1: Stop Ollama to release file locks
Write-Host "[1/6] Stopping Ollama processes..."
$ollamaProcesses = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if ($ollamaProcesses) {
    Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "  Ollama processes stopped"
} else {
    Write-Host "  No Ollama processes running"
}

# Step 2: Locate Ollama models directory
Write-Host ""
Write-Host "[2/6] Locating Ollama models directory..."
$ollamaModelsDir = "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models"
if (Test-Path $ollamaModelsDir) {
    Write-Host "  Found: $ollamaModelsDir"
} else {
    # Fallback to default location
    $ollamaModelsDir = "$env:USERPROFILE\.ollama\models"
    Write-Host "  Using default: $ollamaModelsDir"
}

# Step 3: Find and remove partial qwen2.5-coder:32b download
Write-Host ""
Write-Host "[3/6] Cleaning partial download..."
$blobsDir = Join-Path $ollamaModelsDir "blobs"
if (Test-Path $blobsDir) {
    # Find the largest partial blob (likely the incomplete model)
    $largestBlob = Get-ChildItem -Path $blobsDir -Filter "sha256-*" -File -ErrorAction SilentlyContinue | 
                   Sort-Object Length -Descending | 
                   Select-Object -First 1
    
    if ($largestBlob -and $largestBlob.Length -gt 10GB) {
        Write-Host "  Found partial download: $($largestBlob.Name)"
        Write-Host "  Size: $([math]::Round($largestBlob.Length / 1GB, 2)) GB"
        
        # Remove the partial file
        try {
            Remove-Item -Path $largestBlob.FullName -Force -ErrorAction Stop
            Write-Host "  Partial download removed successfully"
        } catch {
            Write-Host "  WARNING: Could not remove partial file - removing read-only..."
            Set-ItemProperty -Path $largestBlob.FullName -Name IsReadOnly -Value $false
            Remove-Item -Path $largestBlob.FullName -Force
            Write-Host "  Partial download removed (after permission fix)"
        }
    } else {
        Write-Host "  No large partial downloads found"
    }
}

# Step 4: Clear DNS cache (helps with TLS issues)
Write-Host ""
Write-Host "[4/6] Clearing DNS cache..."
try {
    Clear-DnsClientCache -ErrorAction Stop
    Write-Host "  DNS cache cleared"
} catch {
    Write-Host "  DNS cache clear skipped (requires admin)"
}

# Step 5: Set Ollama environment variables for better network handling
Write-Host ""
Write-Host "[5/6] Setting network optimization variables..."
$env:OLLAMA_MAX_LOADED_MODELS = "1"
$env:OLLAMA_NUM_PARALLEL = "1"
$env:OLLAMA_MAX_QUEUE = "10"
$env:OLLAMA_KEEP_ALIVE = "5m"
Write-Host "  Network variables set"

# Step 6: Restart Ollama and retry download
Write-Host ""
Write-Host "[6/6] Starting fresh download..."
Write-Host ""
Write-Host "Starting Ollama server (hidden)..."
Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
Start-Sleep -Seconds 5

Write-Host "Initiating download with retry logic..."
Write-Host ""
Write-Host "COMMAND: ollama pull qwen2.5-coder:32b"
Write-Host ""
Write-Host "--------------------------------------------"
Write-Host "DOWNLOAD TIPS:"
Write-Host "--------------------------------------------"
Write-Host "1. This may take 30-60 minutes for 19GB"
Write-Host "2. Keep this window open and visible"
Write-Host "3. Don't start other large downloads"
Write-Host "4. If it fails again after 20+ minutes:"
Write-Host "   - Check your internet connection"
Write-Host "   - Try at a different time (less network load)"
Write-Host "   - Consider using a VPN if TLS issues persist"
Write-Host "5. Progress will show: XX% complete"
Write-Host "--------------------------------------------"
Write-Host ""

# Execute the download
ollama pull qwen2.5-coder:32b

Write-Host ""
Write-Host "=============================================="
Write-Host "DOWNLOAD ATTEMPT COMPLETE"
Write-Host "=============================================="
Write-Host ""
Write-Host "If successful: Model ready to use"
Write-Host "If failed again: Run this script again or try:"
Write-Host "  1. Restart your router/modem"
Write-Host "  2. Try download during off-peak hours"
Write-Host "  3. Check firewall/antivirus isn't blocking"
Write-Host ""

