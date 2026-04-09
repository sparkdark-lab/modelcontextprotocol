
import sys
from pathlib import Path

# Add the directory to sys.path
sys.path.insert(0, r'e:\AI_Tools\Central_Repository\OLLAMA_SYSTEM')
from ollama_rag_query import OllamaRAG

def run_query():
    rag = OllamaRAG()
    question = """
    Analyze Woodies CCI trading patterns (Zero Line Reject, Ghost, Vegas Trade) 
    and suggest Pine Script v6 improvements for Head and Shoulders detection.
    Also, identify any inefficiencies in this logic:
    - Woodies CCI standard parameters
    - LSMA/EMA angle logic for ChopZone
    - Pattern detection responsiveness
    """
    
    print("\n🔍 Querying RAG system...")
    results = rag.query_with_sources(question)
    
    print("\n" + "="*50)
    print("🤖 RAG EVALUATION")
    print("="*50)
    print(results['answer'])
    
    print("\n" + "="*50)
    print("📚 SOURCES RETRIEVED")
    print("="*50)
    for s in results['sources']:
        print(f"📄 {s.metadata.get('file')} [{s.metadata.get('type')}]")

if __name__ == "__main__":
    run_query()
