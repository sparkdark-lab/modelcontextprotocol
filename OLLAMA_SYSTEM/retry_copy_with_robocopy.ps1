$pairs = @(
    @{ Src = 'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\Llama-3.1-Nemotron-Nano-8B-v1.gguf'; DestDir = 'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs' },
    @{ Src = 'D:\AI_Tools\llama_vulkan\models\phi4_expert.gguf'; DestDir = 'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs' },
    @{ Src = 'D:\Download\phi-4-reasoning-vision-q4_k_s.gguf'; DestDir = 'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs' },
    @{ Src = 'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\Llama-3.1-Nemotron-Nano-8B-v1-Q5_K_M.gguf'; DestDir = 'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs' },
    @{ Src = 'D:\Download\deepseek-coder-6.7b-instruct.Q6_K.gguf'; DestDir = 'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs' },
    @{ Src = 'D:\Central_Repository\OLLAMA_SYSTEM\models\manifests\model.gguf'; DestDir = 'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs' },
    @{ Src = 'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q2_K.gguf'; DestDir = 'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs' },
    @{ Src = 'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q5_K_M.gguf'; DestDir = 'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs' },
    @{ Src = 'D:\Central_Repository\OLLAMA_SYSTEM\models\gguf_downloads\codellama-7b-instruct.Q4_K_M.gguf'; DestDir = 'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs' }
)

$log = 'G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\robocopy_retry_log.txt'
"Retry copy run: $(Get-Date)" | Out-File $log

foreach ($p in $pairs) {
    $src = $p.Src
    $destDir = $p.DestDir
    if (-not (Test-Path $src)) {
        "MISSING: $src" | Out-File $log -Append
        continue
    }
    $fileName = Split-Path $src -Leaf
    $cmd = "robocopy `"$(Split-Path $src -Parent)`" `"$destDir`" `"$fileName`" /COPY:DAT /R:3 /W:5 /MT:16"
    "Running: $cmd" | Out-File $log -Append
    $proc = Start-Process -FilePath robocopy -ArgumentList "`"$(Split-Path $src -Parent)`" `"$destDir`" `"$fileName`" /COPY:DAT /R:3 /W:5 /MT:16" -NoNewWindow -Wait -PassThru
    $exit = $proc.ExitCode
    "Robocopy exit code: $exit" | Out-File $log -Append
    if ($exit -le 3) {
        "SUCCESS: $src -> $destDir\$fileName" | Out-File $log -Append
    } else {
        "FAIL: $src -> $destDir (robocopy code $exit)" | Out-File $log -Append
    }
}

"Done: $(Get-Date)" | Out-File $log -Append
