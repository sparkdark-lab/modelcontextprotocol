# RAG System with Llama3.1:8b - Quick Start Guide

## Overview

This RAG (Retrieval-Augmented Generation) system combines your existing ChromaDB indexed documents with Ollama's llama3.1:8b model to provide enhanced question-answering capabilities with source attribution.

## Quick Start

### 1. Verify Ollama is Running

```powershell
# Check Ollama status
ollama list
```

If not running, start it:
```powershell
cd E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\batch_files
.\start_ollama_gpu.ps1
```

### 2. Interactive CLI

Launch the interactive query interface:

```powershell
cd E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM
python ollama_rag_query.py
```

**Available Commands:**
- Just type your question to get an answer
- `/sources <question>` - Show sources with answer
- `/stats` - Show system statistics
- `/clear` - Clear conversation history
- `/help` - Show help
- `/exit` or `/quit` - Exit

### 3. Run Examples

See practical usage examples:

```powershell
cd E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\examples
python rag_examples.py
```

## Features

### ✅ Context-Aware Responses
The system retrieves relevant documents from your indexed collections and uses them to provide accurate, contextual answers.

### ✅ Source Attribution
See which documents were used to generate each answer, including file names and collection sources.

### ✅ Multiple Collections
Query across all collections or target specific ones:
- `strategies` - Pine Script trading strategies
- `code_patterns` - Code patterns and functions
- `mrg` - Master Reference Guide documentation
- `conversations` - Previous Q&A interactions

### ✅ Flexible Querying
- Use RAG context for domain-specific questions
- Disable context for general knowledge questions
- Adjust number of retrieved documents (top_k)
- Control response temperature

## Usage Examples

### Example 1: Basic Query
```python
from ollama_rag_query import OllamaRAG

rag = OllamaRAG(model="llama3.1:8b")
answer = rag.query("What is a MACD indicator?")
print(answer)
```

### Example 2: Query with Sources
```python
result = rag.query_with_sources("How do I optimize a trading strategy?")
print(result['answer'])

for i, source in enumerate(result['sources'], 1):
    print(f"[{i}] {source['metadata'].get('file', 'Unknown')}")
```

### Example 3: Query Specific Collection
```python
# Only search Master Reference Guide
answer = rag.query(
    "What are GPU optimization best practices?",
    collection="mrg",
    top_k=3
)
```

### Example 4: Without Context (Pure LLM)
```python
# General knowledge question without RAG
answer = rag.query(
    "What is the capital of France?",
    use_context=False
)
```

## Configuration

The system uses sensible defaults but can be customized:

```python
rag = OllamaRAG(
    model="llama3.1:8b",           # Ollama model to use
    ollama_url="http://localhost:11434"  # Ollama API URL
)

answer = rag.query(
    question="Your question here",
    top_k=5,                        # Number of documents to retrieve
    collection=None,                # Specific collection or None for all
    temperature=0.7,                # LLM temperature (0.0-1.0)
    use_context=True,               # Whether to use RAG context
    stream=False                    # Stream response or not
)
```

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Query                                │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              OllamaRAG Query System                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1. Retrieve Context from ChromaDB                   │  │
│  │     - Generate query embedding (nomic-embed-text)    │  │
│  │     - Search indexed collections                     │  │
│  │     - Return top-k relevant documents                │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  2. Build Prompt with Context                        │  │
│  │     - Format retrieved documents                     │  │
│  │     - Combine with user question                     │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  3. Generate Response (llama3.1:8b)                  │  │
│  │     - Send prompt to Ollama                          │  │
│  │     - Stream or return complete response             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│         Answer + Sources (optional)                          │
└─────────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Issue: "ChromaDB not available"
**Solution**: Install ChromaDB
```powershell
pip install chromadb
```

### Issue: "Model not found"
**Solution**: Pull the llama3.1:8b model
```powershell
ollama pull llama3.1:8b
```

### Issue: "Ollama connection error"
**Solution**: Start Ollama service
```powershell
ollama serve
# Or use GPU-accelerated startup:
cd E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\batch_files
.\start_ollama_gpu.ps1
```

### Issue: "No documents indexed"
**Solution**: Your existing RAG system should have documents. Check status:
```powershell
cd E:\AI_Tools\Central_Repository\RAG_SYSTEM
python check_rag_status_simple.py
```

### Issue: Slow responses
**Possible causes:**
- Large context (reduce `top_k` parameter)
- Cold start (first query is slower)
- GPU not being used (verify Ollama GPU setup)

**Solutions:**
- Reduce `top_k` from 5 to 3
- Use streaming mode for faster perceived response
- Ensure Ollama is using GPU acceleration

## Performance Tips

1. **Use Streaming**: Set `stream=True` for faster perceived response time
2. **Adjust top_k**: Lower values (3) are faster, higher values (7-10) provide more context
3. **Target Collections**: Query specific collections instead of all
4. **GPU Acceleration**: Ensure Ollama is using GPU for faster inference
5. **Temperature**: Lower values (0.3-0.5) for factual answers, higher (0.7-0.9) for creative responses

## Files Created

- `OLLAMA_SYSTEM/ollama_rag_query.py` - Main RAG query interface with CLI
- `OLLAMA_SYSTEM/examples/rag_examples.py` - Usage examples
- `OLLAMA_SYSTEM/docs/RAG_QUICK_START.md` - This guide

## Next Steps

1. **Try the Interactive CLI**: `python ollama_rag_query.py`
2. **Run Examples**: `python examples/rag_examples.py`
3. **Integrate into Your Workflow**: Import `OllamaRAG` class in your scripts
4. **Customize**: Adjust parameters for your specific use case

## Support

For issues or questions:
1. Check existing RAG system status: `python RAG_SYSTEM/check_rag_status_simple.py`
2. Verify Ollama models: `ollama list`
3. Review Ollama logs for errors
4. Check ChromaDB persistence directory: `E:\AI_Tools\Central_Repository\RAG_SYSTEM\chromadb_persistence`

---

**Status**: ✅ Ready to Use  
**Model**: llama3.1:8b (4.9 GB)  
**Embedding**: nomic-embed-text:latest  
**Storage**: ChromaDB (Persistent)
