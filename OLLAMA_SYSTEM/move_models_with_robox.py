import sys
from pathlib import Path

# Add ROBOX to path
sys.path.append(r"E:\AI_Tools\Central_Repository")
from ROBOX import copy_recent_files

# Settings
source_dirs = [
    "D:\\",
    "E:\\",
    "G:\\"
]
dest_dir = r"G:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models\blobs"
exclude_dirs = [
    "$RECYCLE.BIN", "Windows", "Program Files", "Program Files (x86)", "ProgramData",
    "System Volume Information", "Users\\Default", "Users\\Public"
]

# Move all .gguf files (regardless of date, so use a large hours value)
for src in source_dirs:
    print(f"Scanning {src} for .gguf files...")
    result = copy_recent_files(
        source=src,
        dest=dest_dir,
        hours=24*365*10,  # Effectively all files
        exclude_dirs=exclude_dirs,
        threads=256
    )
    print(f"Copied {result.files_copied} files from {src} in {result.duration_seconds:.2f}s")

print("All model files have been moved with ROBOX.")
