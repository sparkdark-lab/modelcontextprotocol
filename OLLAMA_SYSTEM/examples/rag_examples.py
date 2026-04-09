#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Simple RAG Example with Llama3.1:8b
Demonstrates basic RAG functionality using existing ChromaDB
"""

import sys
from pathlib import Path

# Fix encoding for Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Add OLLAMA_SYSTEM to path
sys.path.insert(0, str(Path(__file__).parent))

from ollama_rag_query import OllamaRAG


def example_basic_query():
    """Example 1: Basic RAG query"""
    print("=" * 70)
    print("EXAMPLE 1: Basic RAG Query")
    print("=" * 70)
    
    # Initialize RAG system
    rag = OllamaRAG(model="llama3.1:8b")
    
    # Ask a question
    question = "What is a MACD indicator?"
    print(f"\n🔍 Question: {question}")
    print("\n🤖 Answer:")
    
    answer = rag.query(question, top_k=3)
    print(answer)
    print()


def example_with_sources():
    """Example 2: Query with source attribution"""
    print("\n" + "=" * 70)
    print("EXAMPLE 2: Query with Sources")
    print("=" * 70)
    
    rag = OllamaRAG(model="llama3.1:8b")
    
    question = "How do I optimize a trading strategy?"
    print(f"\n🔍 Question: {question}")
    
    result = rag.query_with_sources(question, top_k=3)
    
    print("\n🤖 Answer:")
    print(result['answer'])
    
    if result['sources']:
        print(f"\n📚 Sources ({len(result['sources'])}):")
        for i, source in enumerate(result['sources'], 1):
            metadata = source.get('metadata', {})
            print(f"\n   [{i}] Collection: {source.get('collection', 'unknown')}")
            if metadata.get('file'):
                print(f"       File: {Path(metadata['file']).name}")
            if metadata.get('title'):
                print(f"       Title: {metadata['title']}")
    print()


def example_specific_collection():
    """Example 3: Query specific collection"""
    print("\n" + "=" * 70)
    print("EXAMPLE 3: Query Specific Collection")
    print("=" * 70)
    
    rag = OllamaRAG(model="llama3.1:8b")
    
    # Query only the 'mrg' (Master Reference Guide) collection
    question = "What are the best practices for GPU optimization?"
    print(f"\n🔍 Question: {question}")
    print(f"📁 Collection: mrg (Master Reference Guide)")
    
    print("\n🤖 Answer:")
    answer = rag.query(question, top_k=3, collection="mrg")
    print(answer)
    print()


def example_no_context():
    """Example 4: Query without RAG context (pure LLM)"""
    print("\n" + "=" * 70)
    print("EXAMPLE 4: Query Without Context (Pure LLM)")
    print("=" * 70)
    
    rag = OllamaRAG(model="llama3.1:8b")
    
    question = "What is the capital of France?"
    print(f"\n🔍 Question: {question}")
    print("ℹ️  Using pure LLM (no RAG context)")
    
    print("\n🤖 Answer:")
    answer = rag.query(question, use_context=False)
    print(answer)
    print()


def example_stats():
    """Example 5: Show system statistics"""
    print("\n" + "=" * 70)
    print("EXAMPLE 5: System Statistics")
    print("=" * 70)
    
    rag = OllamaRAG(model="llama3.1:8b")
    
    stats = rag.get_stats()
    
    print(f"\n📊 System Statistics:")
    print(f"   Model: {stats['model']}")
    print(f"   Conversations: {stats['conversations']}")
    print(f"\n   Collections:")
    
    total_docs = 0
    for coll, count in stats['collections'].items():
        total_docs += count
        status = "✅" if count > 0 else "⏳"
        print(f"      {status} {coll}: {count:,} documents")
    
    print(f"\n   Total Documents: {total_docs:,}")
    print()


def main():
    """Run all examples"""
    print("\n" + "🤖 " * 35)
    print("OLLAMA RAG SYSTEM - EXAMPLES")
    print("Using llama3.1:8b with existing ChromaDB")
    print("🤖 " * 35 + "\n")
    
    try:
        # Run examples
        example_stats()
        
        print("\n" + "⏸️ " * 35)
        input("Press Enter to continue with Example 1 (Basic Query)...")
        example_basic_query()
        
        print("\n" + "⏸️ " * 35)
        input("Press Enter to continue with Example 2 (With Sources)...")
        example_with_sources()
        
        print("\n" + "⏸️ " * 35)
        input("Press Enter to continue with Example 3 (Specific Collection)...")
        example_specific_collection()
        
        print("\n" + "⏸️ " * 35)
        input("Press Enter to continue with Example 4 (No Context)...")
        example_no_context()
        
        print("\n" + "=" * 70)
        print("✅ ALL EXAMPLES COMPLETE")
        print("=" * 70)
        print("\nTo use the interactive CLI, run:")
        print("   python ollama_rag_query.py")
        print()
        
    except KeyboardInterrupt:
        print("\n\n👋 Examples interrupted. Goodbye!")
    except Exception as e:
        print(f"\n❌ Error running examples: {e}")
        print("\nMake sure:")
        print("  1. Ollama is running")
        print("  2. llama3.1:8b model is available")
        print("  3. ChromaDB is installed: pip install chromadb")


if __name__ == "__main__":
    main()
