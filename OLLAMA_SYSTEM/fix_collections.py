import chromadb
from chromadb.config import Settings
import sys

def fix_collections():
    try:
        path = r'E:\AI_Tools\Central_Repository\RAG_SYSTEM\chromadb_persistence'
        client = chromadb.PersistentClient(path=path, settings=Settings(anonymized_telemetry=False))
        
        print("Checking collections...")
        cols = client.list_collections()
        col_names = [c.name for c in cols]
        print(f"Found: {col_names}")
        
        if 'code_patterns' in col_names:
            print("Deleting code_patterns...")
            client.delete_collection('code_patterns')
            
        print("Creating fresh code_patterns collection...")
        client.get_or_create_collection('code_patterns')
        
        print("✅ SUCCESS: code_patterns collection reset.")
    except Exception as e:
        print(f"❌ ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    fix_collections()
