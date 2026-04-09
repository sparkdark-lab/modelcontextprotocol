# Ollama System Guide
# Centralized Ollama Management for Central Repository

## Overview

The OLLAMA_SYSTEM provides centralized Ollama management accessible from any workspace, following the same pattern as Master Reference Guide and Think Tank System.

## System Architecture

```
Central Repository/
├── Master_reference/          # Master Reference Guide v8.0
├── THINK_TANK_SYSTEM/         # Think Tank System
└── OLLAMA_SYSTEM/             # Ollama System (NEW)
    ├── config/
    │   └── ollama_config.json
    ├── scripts/
    │   └── ollama_manager.py
    ├── batch_files/
    │   └── start_ollama_gpu.ps1
    ├── docs/
    ├── models/
    └── logs/
```

## Usage from Any Workspace

### Basic Usage

```python
import sys
from pathlib import Path

# Add Central Repository to path
CENTRAL_REPO = Path(r'E:\AI_Tools\Central_Repository')
sys.path.insert(0, str(CENTRAL_REPO))

# Import Ollama System
from OLLAMA_SYSTEM.scripts.ollama_manager import get_ollama_system

# Get system instance
ollama = get_ollama_system()

# Check status
if not ollama.is_running():
    ollama.start_server()

# Query model
result = ollama.query("qwen2.5-coder:32b", "Explain Pine Script strategy development")
if result['success']:
    print(result['answer'])
```

### Integration with United Nations

The United Nations system automatically uses the centralized Ollama System:

```python
from THINK_TANK_SYSTEM.united_nations import UnitedNations

un = UnitedNations()  # Automatically uses OLLAMA_SYSTEM
result = un.consult("Your question here")
```

## Configuration

### Main Config File

Location: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\config\ollama_config.json`

Key settings:
- **Server**: URL, port, executable path
- **GPU**: CUDA settings, GPU layers per model
- **Models**: Context sizes, temperatures, purposes
- **Integration**: United Nations and Think Tank settings

### Model Configuration

Each model has optimized settings:

```json
{
  "qwen2.5-coder:32b": {
    "context": 4096,
    "gpu_layers": 40,
    "temperature": 0.7,
    "purpose": "code_generation"
  }
}
```

## Starting Ollama

### Method 1: PowerShell Script

```powershell
powershell -ExecutionPolicy Bypass -File "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\batch_files\start_ollama_gpu.ps1"
```

### Method 2: Python

```python
from OLLAMA_SYSTEM.scripts.ollama_manager import get_ollama_system
ollama = get_ollama_system()
ollama.start_server()
```

### Method 3: Manual

```bash
ollama serve
```

## Model Management

### Check Available Models

```python
ollama = get_ollama_system()
models = ollama.get_models()
for model in models:
    print(f"  - {model['name']}")
```

### Check Specific Model

```python
if ollama.has_model("qwen2.5-coder:32b"):
    print("qwen2.5-coder:32b is available")
```

### Download Models

```bash
ollama pull codellama:70b
ollama pull qwen2.5-coder:32b
ollama pull llama3.1:8b
ollama pull mistral:7b
ollama pull llama3.2:3b
```

## Path Reference

All paths are absolute and workspace-independent:

- **System**: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM`
- **Config**: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\config\ollama_config.json`
- **Scripts**: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\scripts\ollama_manager.py`
- **Logs**: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\logs\ollama_system.log`

## Integration Points

### United Nations System

- Uses `qwen2.5-coder:32b` for Sherlock Holmes/Tony Stark delegate
- Uses `qwen2.5-coder:32b` for Judge function
- Automatically loads from `OLLAMA_SYSTEM`

### Think Tank System

- Can use multiple Ollama models
- Configured in `ollama_config.json` → `integration.think_tank`

## File Organization

### Streamlined Structure

```
OLLAMA_SYSTEM/
├── config/              # Configuration files only
│   └── ollama_config.json
├── scripts/             # Python scripts only
│   └── ollama_manager.py
├── batch_files/         # Batch/PowerShell scripts only
│   └── start_ollama_gpu.ps1
├── docs/                # Documentation only
│   └── OLLAMA_SYSTEM_GUIDE.md
├── models/              # Model management (empty, managed by Ollama)
├── logs/                # System logs
│   └── ollama_system.log
├── __init__.py          # Package initialization
└── README.md            # Main documentation
```

### Principles

1. **Config**: All configuration in `config/` directory
2. **Scripts**: All Python code in `scripts/` directory
3. **Batch**: All batch/PowerShell in `batch_files/` directory
4. **Docs**: All documentation in `docs/` directory
5. **Logs**: All logs in `logs/` directory
6. **No clutter**: No loose files in root directory

## Status Checking

```python
from OLLAMA_SYSTEM.scripts.ollama_manager import get_ollama_system

ollama = get_ollama_system()

# Server status
print(f"Running: {ollama.is_running()}")

# Available models
models = ollama.get_models()
print(f"Models: {len(models)}")

# Specific model check
if ollama.has_model("qwen2.5-coder:32b"):
    print("✅ qwen2.5-coder:32b available")
```

## Troubleshooting

### Ollama Not Starting

1. Check executable path in config
2. Verify Ollama is installed
3. Check firewall/port 11434
4. Try manual start: `ollama serve`

### Model Not Found

1. Check if model is downloaded: `ollama list`
2. Download model: `ollama pull qwen2.5-coder:32b`
3. Verify in config file

### Connection Errors

1. Verify Ollama is running: `ollama list`
2. Check URL in config: `http://localhost:11434`
3. Test connection: `curl http://localhost:11434/api/tags`

## Similar Systems

This follows the same pattern as:

- **Master Reference**: `E:\AI_Tools\Central_Repository\Master_reference\MASTER_REFERENCE_Guide_v8`
- **Think Tank**: `E:\AI_Tools\Central_Repository\THINK_TANK_SYSTEM`
- **Ollama System**: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM`

All use absolute paths and can be referenced from any workspace.

