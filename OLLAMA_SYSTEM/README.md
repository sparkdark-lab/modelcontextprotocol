# Ollama System - README
# Centralized Ollama Management for Central Repository

## Overview

The OLLAMA_SYSTEM provides centralized Ollama management that can be referenced from any workspace in the Central Repository, similar to how Master Reference Guide and Think Tank System are organized.

## Directory Structure

```
OLLAMA_SYSTEM/
├── config/
│   └── ollama_config.json          # Main configuration file
├── scripts/
│   └── ollama_manager.py           # Python management interface
├── batch_files/
│   └── start_ollama_gpu.ps1        # GPU-accelerated startup script
├── docs/
│   └── OLLAMA_SYSTEM_GUIDE.md     # System documentation
├── models/
│   └── (model management files)
└── logs/
    └── ollama_system.log           # System logs
```

## Quick Start

### From Any Workspace

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

# Check if running
if not ollama.is_running():
    ollama.start_server()

# Query a model
result = ollama.query("codellama:70b", "Your prompt here")
if result['success']:
    print(result['answer'])
```

## Configuration

Configuration is stored in `config/ollama_config.json`:

- **Server Settings**: URL, port, timeout
- **GPU Configuration**: CUDA settings, GPU layers per model
- **Model Configuration**: Context sizes, temperatures, purposes
- **Integration**: United Nations and Think Tank integration settings

## Integration with United Nations

The Ollama System is integrated with the United Nations system:

- **Sherlock Holmes/Tony Stark**: Uses `codellama:70b`
- **Judge Function**: Uses `codellama:70b` for answer evaluation

## Model Management

### Available Models

- `codellama:70b` - Code generation (40 GPU layers)
- `qwen2.5-coder:32b` - Code specialist (35 GPU layers)
- `llama3.1:8b` - General purpose (28 GPU layers)
- `mistral:7b` - Fast general (28 GPU layers)
- `llama3.2:3b` - Fast responses (20 GPU layers)

### Download Models

```bash
ollama pull codellama:70b
ollama pull qwen2.5-coder:32b
ollama pull llama3.1:8b
ollama pull mistral:7b
ollama pull llama3.2:3b
```

## GPU Acceleration

GPU settings are configured per-model in `ollama_config.json`. The system automatically applies:
- GPU layers based on model size
- Context window optimization
- Temperature and sampling parameters

## Status Checking

```python
from OLLAMA_SYSTEM.scripts.ollama_manager import get_ollama_system

ollama = get_ollama_system()

# Check server status
print(f"Running: {ollama.is_running()}")

# List available models
models = ollama.get_models()
for model in models:
    print(f"  - {model['name']}")

# Check specific model
if ollama.has_model("codellama:70b"):
    print("codellama:70b is available")
```

## Paths

All paths are absolute and can be referenced from any workspace:

- **Config**: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\config\ollama_config.json`
- **System**: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM`
- **Logs**: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\logs`

## Similar to Master Reference & Think Tank

Just like:
- **Master Reference**: `E:\AI_Tools\Central_Repository\Master_reference\MASTER_REFERENCE_Guide_v8`
- **Think Tank**: `E:\AI_Tools\Central_Repository\THINK_TANK_SYSTEM`

**Ollama System**: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM`

All can be referenced from any workspace using absolute paths.

