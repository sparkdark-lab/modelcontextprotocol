# DocSpool Integration with OLLAMA_SYSTEM

**Status**: ✅ **INTEGRATED**  
**Date**: 2025-12-23

---

## Overview

DocSpool is integrated with OLLAMA_SYSTEM to provide instant Markdown generation using Ollama models. This integration ensures all documentation uses the centralized Ollama system for consistent, high-quality output.

---

## Integration Points

### 1. Ollama Backend
- DocSpool uses OLLAMA_SYSTEM for model queries
- Leverages GPU acceleration via `start_ollama_gpu.ps1`
- Supports all configured models

### 2. Model Selection
DocSpool automatically selects models based on content type:
- **Code Documentation**: `qwen2.5-coder:32b`
- **General Documentation**: `llama3.1:8b`
- **Technical Docs**: `mistral:7b`

### 3. Startup Integration
The wrapper script (`use_docspool_for_markdown.ps1`) automatically:
- Checks if Ollama is running
- Starts Ollama if needed using `start_ollama_gpu.ps1`
- Waits for initialization
- Proceeds with generation

---

## Usage

### From Charlies Angels

```powershell
cd "F:\Charlies_Angels"
.\use_docspool_for_markdown.ps1 -FilePath "DOC.md" -Prompt "Your prompt"
```

### Direct Integration

```powershell
# Import DocSpool
Import-Module "E:\AI_Tools\Central_Repository\systems\LLM_SYSTEMS\DocSpool\DocSpool.psm1"

# Ensure Ollama is running
& "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\batch_files\start_ollama_gpu.ps1"

# Generate documentation
Invoke-DocSpool -Prompt "Document the Ollama orchestrator system" -OutputFile "ORCHESTRATOR.md"
```

---

## Configuration

### Ollama Settings
DocSpool respects OLLAMA_SYSTEM configuration:
- Server URL: `http://localhost:11434`
- GPU acceleration: Enabled via environment variables
- Model selection: Based on `ollama_config.json`

### Performance
- Uses GPU-accelerated models
- Leverages keep_alive for faster responses
- Optimized token generation (512-1024 tokens)

---

## Troubleshooting

### Ollama Not Running
The wrapper script automatically starts Ollama, but if issues persist:

```powershell
# Manual start
& "E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\batch_files\start_ollama_gpu.ps1"

# Verify
Test-NetConnection localhost -Port 11434
```

### Model Not Available
```powershell
# Check available models
ollama list

# Pull required model
ollama pull llama3.1:8b
```

---

## References

- **DocSpool Module**: `E:\AI_Tools\Central_Repository\systems\LLM_SYSTEMS\DocSpool\`
- **Wrapper Script**: `F:\Charlies_Angels\use_docspool_for_markdown.ps1`
- **Integration Guide**: `F:\Charlies_Angels\DOCSPOOL_INTEGRATION.md`
- **Ollama System**: `E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\`

---

**Integration Complete** ✅

