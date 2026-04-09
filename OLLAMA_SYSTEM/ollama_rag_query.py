#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Ollama RAG Query System
Uses existing ChromaDB indexed data with llama3.1:8b for enhanced question-answering
"""

import sys
import json
import requests
from pathlib import Path
from typing import List, Dict, Optional
from datetime import datetime

# Fix encoding for Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Add RAG system to path
sys.path.insert(0, str(Path(__file__).parent.parent / "cursor auto local intelligence"))
from rag_system import get_rag_system


class OllamaRAG:
    """RAG system using existing ChromaDB with llama3.1:8b"""
    
    def __init__(self, model: str = "llama3.1:8b", ollama_url: str = "http://localhost:11434"):
        """
        Initialize RAG system
        
        Args:
            model: Ollama model to use (default: llama3.1:8b)
            ollama_url: Ollama API URL
        """
        self.model = model
        self.ollama_url = ollama_url
        self.generate_url = f"{ollama_url}/api/generate"
        self.chat_url = f"{ollama_url}/api/chat"
        
        # Initialize existing RAG system
        print(f"🔧 Initializing RAG system...")
        self.rag = get_rag_system()
        print(f"✅ RAG system loaded from: {self.rag.persist_directory}")
        
        # Conversation history
        self.history = []
        
        # Verify Ollama is running
        self._verify_ollama()
        
        # Check collections
        self._check_collections()
    
    def _verify_ollama(self):
        """Verify Ollama is running and model is available"""
        try:
            response = requests.get(f"{self.ollama_url}/api/tags", timeout=5)
            response.raise_for_status()
            
            models = response.json().get('models', [])
            model_names = [m.get('name', '') for m in models]
            
            if not any(self.model in name for name in model_names):
                print(f"⚠️  Warning: Model '{self.model}' not found in Ollama")
                print(f"   Available models: {', '.join(model_names[:5])}")
                print(f"   Pull with: ollama pull {self.model}")
            else:
                print(f"✅ Model '{self.model}' is available")
                
        except Exception as e:
            print(f"❌ Error connecting to Ollama: {e}")
            print(f"   Make sure Ollama is running: ollama serve")
            raise
    
    def _check_collections(self):
        """Check available collections and document counts"""
        if self.rag.use_chromadb:
            print(f"\n📚 Available Collections:")
            total_docs = 0
            for coll_name, collection in self.rag.collections.items():
                try:
                    count = collection.count()
                    total_docs += count
                    status = "✅" if count > 0 else "⏳"
                    print(f"   {status} {coll_name}: {count:,} documents")
                except Exception as e:
                    print(f"   ⚠️  {coll_name}: Error - {str(e)[:50]}")
            
            print(f"\n   Total: {total_docs:,} documents indexed")
            
            if total_docs == 0:
                print(f"\n⚠️  No documents indexed. RAG will not provide context.")
        else:
            print(f"⚠️  Using in-memory storage (no persistence)")
    
    def retrieve_context(self, query: str, top_k: int = 5, collection: str = None) -> List[Dict]:
        """
        Retrieve relevant context from RAG system
        
        Args:
            query: User query
            top_k: Number of documents to retrieve
            collection: Specific collection to search (None = search all)
            
        Returns:
            List of retrieved documents with metadata
        """
        try:
            results = self.rag.retrieve(query, collection_name=collection, top_k=top_k)
            return results
        except Exception as e:
            print(f"⚠️  Retrieval error: {e}")
            return []
    
    def format_context(self, results: List[Dict], max_length: int = 2000) -> str:
        """Format retrieved documents into context string"""
        if not results:
            return ""
        
        context_parts = ["=== RELEVANT CONTEXT ===\n"]
        total_length = len(context_parts[0])
        
        for i, result in enumerate(results, 1):
            collection = result.get("collection", "unknown")
            content = result.get("content", "")
            metadata = result.get("metadata", {})
            
            # Truncate content if too long
            if len(content) > 400:
                content = content[:400] + "..."
            
            context_part = f"\n[{i}] Source: {collection}"
            if metadata.get("file"):
                context_part += f" | File: {Path(metadata['file']).name}"
            if metadata.get("title"):
                context_part += f" | Title: {metadata['title']}"
            context_part += f"\n{content}\n"
            
            if total_length + len(context_part) > max_length:
                break
            
            context_parts.append(context_part)
            total_length += len(context_part)
        
        context_parts.append("\n=== END CONTEXT ===\n")
        return "\n".join(context_parts)
    
    def query(self, 
              question: str, 
              top_k: int = 5, 
              collection: str = None,
              temperature: float = 0.7,
              use_context: bool = True,
              stream: bool = False) -> str:
        """
        Query the RAG system with llama3.1:8b
        
        Args:
            question: User question
            top_k: Number of context documents to retrieve
            collection: Specific collection to search (None = all)
            temperature: LLM temperature (0.0-1.0)
            use_context: Whether to use RAG context
            stream: Whether to stream the response
            
        Returns:
            Generated answer
        """
        # Retrieve context
        context = ""
        sources = []
        
        if use_context:
            results = self.retrieve_context(question, top_k=top_k, collection=collection)
            if results:
                context = self.format_context(results)
                sources = results
        
        # Build prompt
        if context:
            prompt = f"""You are a helpful assistant. Use the provided context to answer the question accurately and concisely.

{context}

Question: {question}

Answer based on the context above. If the context doesn't contain relevant information, say so."""
        else:
            prompt = f"""You are a helpful assistant. Answer the following question concisely.

Question: {question}

Answer:"""
        
        # Generate response
        try:
            payload = {
                "model": self.model,
                "prompt": prompt,
                "temperature": temperature,
                "stream": stream
            }
            
            response = requests.post(
                self.generate_url,
                json=payload,
                timeout=60,
                stream=stream
            )
            response.raise_for_status()
            
            if stream:
                # Stream response
                answer = ""
                for line in response.iter_lines():
                    if line:
                        try:
                            chunk = json.loads(line)
                            if chunk.get("response"):
                                print(chunk["response"], end="", flush=True)
                                answer += chunk["response"]
                            if chunk.get("done"):
                                print()  # New line at end
                                break
                        except json.JSONDecodeError:
                            continue
                return answer
            else:
                # Non-streaming response
                result = response.json()
                answer = result.get("response", "")
                
                # Store in history
                self.history.append({
                    "timestamp": datetime.now().isoformat(),
                    "question": question,
                    "answer": answer,
                    "sources": len(sources),
                    "context_used": bool(context)
                })
                
                return answer
                
        except Exception as e:
            return f"❌ Error generating response: {e}"
    
    def query_with_sources(self, 
                          question: str, 
                          top_k: int = 5,
                          collection: str = None,
                          temperature: float = 0.7) -> Dict:
        """
        Query with source attribution
        
        Returns:
            Dict with 'answer' and 'sources' keys
        """
        # Retrieve context
        results = self.retrieve_context(question, top_k=top_k, collection=collection)
        context = self.format_context(results) if results else ""
        
        # Build prompt
        if context:
            prompt = f"""You are a helpful assistant. Use the provided context to answer the question accurately and concisely.

{context}

Question: {question}

Answer based on the context above. If the context doesn't contain relevant information, say so."""
        else:
            prompt = f"Question: {question}\n\nAnswer:"
        
        # Generate response
        try:
            payload = {
                "model": self.model,
                "prompt": prompt,
                "temperature": temperature,
                "stream": False
            }
            
            response = requests.post(self.generate_url, json=payload, timeout=60)
            response.raise_for_status()
            answer = response.json().get("response", "")
            
            return {
                "answer": answer,
                "sources": results,
                "context_used": bool(context)
            }
            
        except Exception as e:
            return {
                "answer": f"❌ Error: {e}",
                "sources": [],
                "context_used": False
            }
    
    def clear_history(self):
        """Clear conversation history"""
        self.history = []
        print("🗑️  Conversation history cleared")
    
    def get_stats(self) -> Dict:
        """Get system statistics"""
        stats = {
            "model": self.model,
            "conversations": len(self.history),
            "collections": {}
        }
        
        if self.rag.use_chromadb:
            for coll_name, collection in self.rag.collections.items():
                try:
                    stats["collections"][coll_name] = collection.count()
                except:
                    stats["collections"][coll_name] = 0
        
        return stats


def main():
    """Interactive CLI for RAG queries"""
    print("=" * 70)
    print("🤖 OLLAMA RAG QUERY SYSTEM")
    print("=" * 70)
    print()
    
    try:
        # Initialize RAG system
        rag = OllamaRAG(model="llama3.1:8b")
        
        print("\n" + "=" * 70)
        print("💬 Interactive Mode - Ask me anything!")
        print("=" * 70)
        print("\nCommands:")
        print("  /sources <question> - Show sources with answer")
        print("  /stats              - Show system statistics")
        print("  /clear              - Clear conversation history")
        print("  /help               - Show this help")
        print("  /exit or /quit      - Exit")
        print("\nJust type your question to get started!\n")
        
        while True:
            try:
                question = input("\n🔍 Question: ").strip()
                
                if not question:
                    continue
                
                # Handle commands
                if question.startswith("/"):
                    cmd = question.lower().split()[0]
                    
                    if cmd in ["/exit", "/quit"]:
                        print("\n👋 Goodbye!")
                        break
                    
                    elif cmd == "/help":
                        print("\nCommands:")
                        print("  /sources <question> - Show sources with answer")
                        print("  /stats              - Show system statistics")
                        print("  /clear              - Clear conversation history")
                        print("  /exit or /quit      - Exit")
                        continue
                    
                    elif cmd == "/clear":
                        rag.clear_history()
                        continue
                    
                    elif cmd == "/stats":
                        stats = rag.get_stats()
                        print(f"\n📊 System Statistics:")
                        print(f"   Model: {stats['model']}")
                        print(f"   Conversations: {stats['conversations']}")
                        print(f"   Collections:")
                        for coll, count in stats['collections'].items():
                            print(f"      - {coll}: {count:,} documents")
                        continue
                    
                    elif cmd == "/sources":
                        # Extract question after command
                        q = question[len(cmd):].strip()
                        if not q:
                            print("⚠️  Please provide a question after /sources")
                            continue
                        
                        print("\n🤖 Answer:")
                        result = rag.query_with_sources(q)
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
                                content = source.get('content', '')[:150]
                                print(f"       Preview: {content}...")
                        else:
                            print("\n📚 No sources found (answered without context)")
                        continue
                    
                    else:
                        print(f"⚠️  Unknown command: {cmd}")
                        print("   Type /help for available commands")
                        continue
                
                # Regular query
                print("\n🤖 Answer:")
                answer = rag.query(question, stream=True)
                print()  # Extra newline after answer
                
            except KeyboardInterrupt:
                print("\n\n👋 Goodbye!")
                break
            except Exception as e:
                print(f"\n❌ Error: {e}")
                continue
    
    except Exception as e:
        print(f"\n❌ Failed to initialize RAG system: {e}")
        print("\nTroubleshooting:")
        print("  1. Make sure Ollama is running: ollama serve")
        print("  2. Check if llama3.1:8b is available: ollama list")
        print("  3. Pull the model if needed: ollama pull llama3.1:8b")
        sys.exit(1)


if __name__ == "__main__":
    main()
