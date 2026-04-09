# CALI Router - System AI Routing Guide

## Overview

The CALI Router is a fast passthrough system that routes queries to CALI (Ollama Orchestrator) immediately, with minimal System AI intervention.

## Router Behavior

### Default: Route to CALI
- **All queries** → Route to CALI immediately
- **No commentary** from System AI
- **No modification** of CALI's responses
- **Fast passthrough** - minimal delay

### Exception: Direct Address
Only if user explicitly addresses System AI:
- "Auto, what is..."
- "you, help me..."
- "Auto, help..."

Then System AI may answer directly (ultimate fallback only).

## System AI Role

### ❌ DON'T:
- Add commentary or analysis
- Modify CALI's responses
- Use Cursor's default AI capabilities
- Provide fallback responses (except ultimate fallback)
- Process or filter CALI's output
- Delay routing - route immediately

### ✅ DO:
- Route queries to CALI immediately
- Pass through responses unchanged
- Act as fast passthrough router
- Only intercept if explicitly addressed

## Usage

### Python API

```python
from OLLAMA_SYSTEM.scripts.cali_router import process_query

# Route to CALI (default)
response = process_query("What is the capital of Germany?")
print(response)  # CALI's response, unchanged

# Explicit address to System AI
response = process_query("Auto, what is your role?")
print(response)  # System AI responds directly
```

### CLI

```bash
python scripts/cali_router.py "Your question here"
```

## Routing Logic

```
User Query
    ↓
Is it addressed to "Auto" or "you"?
    ├─ Yes → System AI answers (ultimate fallback)
    └─ No → Route to CALI immediately
         ↓
    CALI Orchestrator
         ↓
    Response (passed through unchanged)
```

## Integration

The router can be integrated into Cursor's AI system to automatically route all queries to CALI, ensuring:

1. **No System AI interference** - CALI handles everything
2. **Fast routing** - Minimal delay
3. **Unmodified responses** - CALI's output is passed through
4. **Exception handling** - Only answers directly if explicitly asked

## Configuration

No configuration needed - works out of the box. The router automatically:
- Detects direct addresses
- Routes to CALI for all other queries
- Passes responses through unchanged

---

**System AI acts as a transparent router - CALI does the work!**

