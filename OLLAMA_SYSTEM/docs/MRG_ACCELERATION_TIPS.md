# MRG Acceleration Tips & Why Ollama is Slow

**Source**: Master Reference Guide v9.0  
**Date**: 2025-12-23  
**Status**: ✅ **VERIFIED FROM MRG**

---

## 🚀 Key Acceleration Tips from MRG

### 1. GPU Layers Configuration (CRITICAL)

**MRG Recommendation for RTX 3060:**
```powershell
OLLAMA_GPU_LAYERS=28  # NOT 35 - MRG v8.0 corrected this
```

**Why 28, not 35?**
- RTX 3060 has 12GB VRAM
- 28 layers = optimal balance
- 35 layers = too aggressive, causes memory issues
- **Result**: 4.2 GB VRAM usage (optimal) vs 8GB+ (problematic)

**Current Status**: Your config should use `28` layers.

---

### 2. Keep-Alive Settings (MAJOR SPEEDUP)

**MRG Recommendation:**
```json
"keep_alive": "30m"  // Keep models in VRAM for 30 minutes
```

**Why This Matters:**
- **First query**: 5-10 seconds (model loads into VRAM)
- **Subsequent queries**: **INSTANT** (model already in VRAM)
- **Without keep_alive**: Every query = 5-10 second load time

**Impact**: 10x faster for subsequent queries!

**Current Status**: ✅ Already added to your orchestrator!

---

### 3. Optimal Startup Command (MRG v8.0)

**MRG Recommended:**
```powershell
ollama serve --gpu-layers 28 --context 1024 --batch 256 --threads 4
```

**Parameters Explained:**
- `--gpu-layers 28`: Optimal for RTX 3060
- `--context 1024`: Context window size
- `--batch 256`: Batch processing size
- `--threads 4`: CPU thread count

**Expected Results:**
- ✅ VRAM: 4.2 GB max
- ✅ Solve Time: 14 seconds (or 8 seconds in extreme mode)
- ✅ Fan Speed: 9% (quiet)

---

### 4. Environment Variables (MRG v8.0)

**Critical Settings:**
```powershell
CUDA_VISIBLE_DEVICES=0               # RTX 3060 only
OLLAMA_NUM_GPU=1                     # Single GPU
OLLAMA_GPU_LAYERS=28                 # Optimal (NOT 35)
OLLAMA_BATCH=256                     # Batch processing
OLLAMA_CONTEXT=1024                  # Context window
OLLAMA_F16_KV=1                      # Memory efficient
OLLAMA_FLASH_ATTENTION=1             # Fast attention
OLLAMA_KEEP_ALIVE=5m                 # Model persistence
OLLAMA_GPU_MEMORY_FRACTION=0.9       # Use 90% of VRAM
```

**Current Status**: Check your `start_ollama_gpu.ps1` script.

---

## 🐌 Why Ollama is Slow - Root Causes

### 1. Model Loading (Cold Start)

**Problem:**
- First request: Model must load into VRAM
- **Time**: 5-10 seconds for 32B models
- **Time**: 60-90 seconds for 70B models

**Solution:**
- ✅ Use `keep_alive: "30m"` (already done)
- ✅ Preload models with a simple query
- ✅ Keep models in VRAM between requests

**Current Status**: ✅ Fixed in orchestrator!

---

### 2. GPU Memory Exhaustion

**Problem:**
- VRAM fills up over time
- Residual processes hold memory
- No headroom for inference

**Symptoms:**
- Model loads but inference times out
- GPU utilization drops to 0%
- "CUDA out of memory" errors

**Solution:**
```powershell
# Quick fix (30 seconds)
taskkill /f /im ollama.exe /t
taskkill /f /im python.exe /t
Start-Sleep -Seconds 10
nvidia-smi  # Verify <20% used
# Restart Ollama
```

**Check GPU Memory:**
```powershell
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
# Expected: Used < 2GB when idle
```

---

### 3. Windows Defender Controlled Folder Access (CRITICAL)

**Problem:**
- Windows Defender silently terminates Ollama child processes
- `/api/tags` works (health check passes)
- `/api/generate` fails with "An error occurred while sending the request"
- **No error body** - process killed before logging

**Symptoms:**
- Ollama tray icon appears and immediately disappears
- Request never reaches Ollama backend
- Issue persists across Ollama versions

**Solution:**
1. Open Windows Settings (Win+I)
2. Go to: **Privacy & security > Windows Security**
3. Click: **Virus & threat protection**
4. Click: **Manage ransomware protection**
5. Turn OFF **"Controlled folder access"**
6. **REBOOT** (important!)

**Alternative**: Add exclusions:
- `C:\Users\<YourUsername>\AppData\Local\Programs\Ollama`
- `C:\Users\<YourUsername>\.ollama`

**Timeline**: 5-10 minutes (including reboot)

---

### 4. Wrong GPU Layers Setting

**Problem:**
- Using `OLLAMA_GPU_LAYERS=35` (too aggressive)
- Causes memory fragmentation
- Slower performance

**Solution:**
- Use `OLLAMA_GPU_LAYERS=28` (MRG v8.0 optimal)
- Check your `ollama_config.json` and `start_ollama_gpu.ps1`

---

### 5. Model Too Large for System

**Problem:**
- 32B models require ~10 GB VRAM on RTX 3060
- Operating at 83% capacity
- Single model at limit

**Solution:**
- Use smaller models for faster responses
- `llama3.2:3b` = 2-4 seconds
- `mistral:7b` = 5-8 seconds
- `qwen2.5-coder:32b` = 10-20 seconds

**Model Selection Strategy (MRG):**
| Use Case | Primary | Load Time |
|----------|---------|-----------|
| Fast responses | llama3.2:3b | 2-4s |
| General queries | mistral:7b | 5-8s |
| Code generation | qwen2.5-coder:32b | 10-20s |

---

### 6. No Keep-Alive (Major Slowdown)

**Problem:**
- Every query = model load time
- 5-10 seconds per query wasted

**Solution:**
- ✅ Already fixed in orchestrator!
- Models stay in VRAM for 30 minutes

**Impact**: 10x faster for subsequent queries!

---

## 📊 Performance Expectations (MRG)

### With Optimizations Applied

**First Query (Cold Start):**
- Router: 2-5s (or skipped)
- Team: 15-30s (32B model loading)
- Judge: 10-20s
- **Total: 27-55s**

**Subsequent Queries (Warm):**
- Router: 1-2s (or skipped)
- Team: 5-10s (models in VRAM)
- Judge: 3-5s
- **Total: 9-17s** ⚡

**Improvement**: ~75% faster with keep_alive!

---

## ✅ Verification Checklist

Check these settings:

- [ ] `OLLAMA_GPU_LAYERS=28` (not 35)
- [ ] `keep_alive: "30m"` in all model queries
- [ ] Windows Defender Controlled Folder Access OFF
- [ ] GPU memory <50% before inference
- [ ] Models preloaded (run simple query first)
- [ ] `CUDA_VISIBLE_DEVICES=0` set
- [ ] `OLLAMA_NUM_GPU=1` set

---

## 🔧 Quick Fixes (MRG)

### Fix 1: GPU Memory Exhausted (30 seconds)

```powershell
taskkill /f /im ollama.exe /t
taskkill /f /im python.exe /t
Start-Sleep -Seconds 10
nvidia-smi  # Verify <20% used
# Restart Ollama
```

### Fix 2: Windows Defender (5-10 minutes)

1. Disable Controlled Folder Access
2. Reboot
3. Test: `ollama run phi3:mini "Say hello"`

### Fix 3: Preload Models (1 minute)

```powershell
# Warm up VRAM with simple query
ollama run llama3.1:8b "Hello"
# Now subsequent queries are instant
```

---

## 📚 MRG References

- **GPU Optimization**: `modules/gpu_performance_optimization.md`
- **Ollama Recovery**: `modules/ollama_system_recovery.md`
- **LLM Optimization**: `modules/LLM_OPTIMIZATION_GUIDE.md`

---

## 🎯 Summary

**Top 3 Reasons Ollama is Slow:**

1. **No keep_alive** → Every query = 5-10s load time
   - ✅ **Fixed**: Already added to orchestrator!

2. **Windows Defender** → Kills child processes
   - ⚠️ **Action Needed**: Disable Controlled Folder Access + reboot

3. **GPU Memory Exhaustion** → No headroom for inference
   - ✅ **Fix**: Kill processes, wait 10s, restart

**Top 3 Acceleration Tips:**

1. ✅ **Use keep_alive: "30m"** (already done!)
2. ✅ **Set OLLAMA_GPU_LAYERS=28** (check your config)
3. ✅ **Preload models** (run simple query first)

---

**All optimizations from MRG v9.0 documented and ready to apply!** ⚡

