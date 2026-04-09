#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Quick Test: RAG System with Llama3.1:8b
"""

import sys
from pathlib import Path

# Fix encoding
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Add to path
sys.path.insert(0, str(Path(__file__).parent))

from ollama_rag_query import OllamaRAG

print("=" * 70)
print("🧪 QUICK TEST: RAG System with Llama3.1:8b")
print("=" * 70)

try:
    # Initialize
    print("\n1️⃣ Initializing RAG system...")
    rag = OllamaRAG(model="llama3.1:8b")
    
    # Get stats
    print("\n2️⃣ System Statistics:")
    stats = rag.get_stats()
    print(f"   Model: {stats['model']}")
    print(f"   Collections:")
    for coll, count in stats['collections'].items():
        if count > 0:
            print(f"      ✅ {coll}: {count:,} documents")
    
    # Test query
    print("\n3️⃣ Testing RAG Query...")
    question = "What is a moving average crossover strategy?"
    print(f"   Question: {question}")
    print(f"\n   Answer:")
    
    answer = rag.query(question, top_k=3, stream=False)
    print(f"   {answer[:200]}..." if len(answer) > 200 else f"   {answer}")
    
    print("\n" + "=" * 70)
    print("✅ TEST COMPLETE - RAG System is Working!")
    print("=" * 70)
    print("\nNext Steps:")
    print("  • Run interactive CLI: python ollama_rag_query.py")
    print("  • See examples: python examples/rag_examples.py")
    print("  • Read guide: docs/RAG_QUICK_START.md")
    
except Exception as e:
    print(f"\n❌ Test failed: {e}")
    print("\nTroubleshooting:")
    print("  1. Ensure Ollama is running: ollama serve")
    print("  2. Check model availability: ollama list")
    print("  3. Pull model if needed: ollama pull llama3.1:8b")
