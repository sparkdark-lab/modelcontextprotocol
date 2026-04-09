# Ollama Testing Guide

**Fast, efficient testing with timeout handling**

---

## ✅ Test Results (Just Now)

**Ollama Status:** ✅ OPERATIONAL  
**Models Available:** 10  
**GPU Status:** codellama:70b loaded  
**Response Time:** 2.06s  

---

## New Fast Testing Scripts

### 1. **Quick Python Test** (Recommended)

```powershell
# Fast test (no inference, ~3 seconds)
python test_ollama_quick.py --fast

# Full test with inference (~30 seconds)
python test_ollama_quick.py
```

**Features:**
- ✅ 5-second timeouts
- ✅ Tests connection, models, health, GPU
- ✅ Optional inference test
- ✅ Sorted models by size (fastest first)

**Output Example:**
```
✅ Connected in 2.06s
✅ Found 10 models
✅ API is healthy
✅ codellama:70b loaded in GPU
Ollama Status: ✅ OPERATIONAL
```

---

### 2. **PowerShell Quick Test**

```powershell
# Fast test (no inference)
.\test_ollama_fast.ps1

# With inference test
.\test_ollama_fast.ps1 -Inference
```

**Features:**
- ✅ Checks Ollama process
- ✅ Verifies port 11434
- ✅ Tests API connection
- ✅ Lists available models
- ✅ Optional quick inference

---

### 3. **Model-Specific Testing**

```powershell
# Test specific model
python test_ollama_models.py llama3.2:3b

# Test with custom prompt
python test_ollama_models.py codellama:7b "Write hello world in Python"

# List all models and quick test
python test_ollama_models.py
```

**Features:**
- ✅ Test any installed model
- ✅ Custom prompts
- ✅ 30-60 second timeouts
- ✅ Shows response time

---

## Available Models (Sorted by Speed)

| # | Model | Size | Best For |
|---|-------|------|----------|
| 1 | **llama3.2:3b** | 1.88 GB | ⚡ Fastest testing |
| 2 | **codellama:7b** | 3.56 GB | ⚡ Fast coding |
| 3 | **mistral:7b** | 4.07 GB | ⚡ Fast general |
| 4 | **dolphin-llama3** | 4.34 GB | Fast chat |
| 5 | **llama3.1:8b** | 4.58 GB | Balanced |
| 6 | **qwen2.5-coder:32b** | 18.49 GB | Advanced coding |
| 7 | **codellama:70b** | 36.20 GB | 🎯 Best quality (slower) |

---

## Quick Reference

### Test Comparison

| Script | Time | Features | Use Case |
|--------|------|----------|----------|
| `test_ollama_quick.py --fast` | ~3s | Connection, models, health | ⚡ Fastest check |
| `test_ollama_fast.ps1` | ~5s | Process, port, API | Quick verification |
| `test_ollama_quick.py` | ~30s | Full test + inference | Complete test |
| `test_ollama_models.py <model>` | ~30s | Model-specific | Test specific model |
| `llm_router.py "prompt"` | 60s+ | Full routing test | End-to-end test |

---

## Problem Solved

### ❌ Old Method (Slow)
```powershell
python llm_router.py "test"
# Problem: Uses codellama:70b (36 GB model)
# Result: 60+ second wait, often timeouts
```

### ✅ New Method (Fast)
```powershell
python test_ollama_quick.py --fast
# Solution: Connection tests only, no inference
# Result: 2-3 seconds, instant feedback
```

---

## Usage Examples

### Example 1: Quick Status Check
```powershell
# Just verify Ollama is working
python test_ollama_quick.py --fast
```

**Output:**
```
✅ Connected in 2.06s
✅ Found 10 models
✅ API is healthy
✅ codellama:70b loaded in GPU
Ollama Status: ✅ OPERATIONAL
```

### Example 2: Test Fastest Model
```powershell
# Test with smallest/fastest model
python test_ollama_models.py llama3.2:3b
```

**Output:**
```
Testing: llama3.2:3b
Prompt: What is 2+2?
Sending request... ✅ (4.2s)

Response:
----------------------------------------------------------
The answer is 4.
----------------------------------------------------------

✅ Ollama is working! (4.2s)
```

### Example 3: Test Specific Coding Model
```powershell
# Test coding model with custom prompt
python test_ollama_models.py codellama:7b "Write a Python function to add two numbers"
```

### Example 4: PowerShell Quick Check
```powershell
# Fast PowerShell test
.\test_ollama_fast.ps1
```

**Output:**
```
[Test 1] Ollama Process...
  ✅ Ollama is running (PID: 21832)

[Test 2] Port 11434...
  ✅ Port 11434 is listening

[Test 3] API Connection...
  ✅ API is responding
  ✅ Found 10 models

Ollama Status: ✅ OPERATIONAL
```

---

## Troubleshooting

### Test Failed: Connection Error

**Check if Ollama is running:**
```powershell
Get-Process -Name "ollama"
```

**Start Ollama:**
```powershell
Start-Process "C:\Users\Hectojr\AppData\Local\Programs\Ollama\ollama.exe"
```

### Test Failed: Timeout

**Solution:** Use smaller model
```powershell
# Instead of codellama:70b (slow)
python test_ollama_models.py llama3.2:3b
```

### Test Failed: Model Not Found

**List available models:**
```powershell
python test_ollama_quick.py --fast
# or
ollama list
```

---

## Script Locations

All scripts in: `C:\Users\Hectojr\.kai_system_pristine\active\contexts\agents\`

- **test_ollama_quick.py** - Fast Python test suite
- **test_ollama_fast.ps1** - Fast PowerShell test
- **test_ollama_models.py** - Model-specific testing
- **llm_router.py** - Full router test (slow)

---

## Performance Tips

1. **For quick checks:** Use `--fast` flag (no inference)
2. **For testing inference:** Use smallest model (llama3.2:3b)
3. **For production:** Use codellama:70b or qwen2.5-coder:32b
4. **Monitor GPU:** `nvidia-smi -l 1` in separate window

---

## Summary

| Need | Command | Time |
|------|---------|------|
| Is Ollama working? | `python test_ollama_quick.py --fast` | 3s |
| Test inference | `python test_ollama_models.py llama3.2:3b` | 5s |
| Test coding | `python test_ollama_models.py codellama:7b "code task"` | 10s |
| Full system test | `python test_ollama_quick.py` | 30s |

---

**✅ Ollama is working and ready!**

Current status:
- 10 models installed
- codellama:70b (36 GB) loaded in GPU
- API responding in ~2 seconds
- All systems operational

