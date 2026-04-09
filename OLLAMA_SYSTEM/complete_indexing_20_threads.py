#!/usr/bin/env python3
"""
Complete RAG Indexing - 20 Thread High Performance
Indexes all remaining content with maximum parallelization
"""

import sys
from pathlib import Path
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock

sys.path.insert(0, str(Path(__file__).parent.parent / "cursor auto local intelligence"))
from rag_system import get_rag_system

# Configuration
MAX_WORKERS = 8  # Reduced from 20 to prevent ChromaDB compaction errors
PROGRESS_LOCK = Lock()

def index_file(rag, file_path, repo_root, collection, file_type):
    """Index a single file"""
    try:
        content = file_path.read_text(encoding='utf-8', errors='ignore')
        
        if len(content.strip()) < 50:  # Skip tiny files
            return {"success": True, "skipped": True, "file": file_path.name}
        
        metadata = {
            "file": str(file_path.relative_to(repo_root)),
            "type": file_type,
            "title": file_path.stem
        }
        
        success = rag.store(collection, content, metadata)
        
        return {
            "success": success,
            "skipped": False,
            "file": file_path.name,
            "collection": collection
        }
    except Exception as e:
        return {
            "success": False,
            "skipped": False,
            "file": file_path.name,
            "error": str(e)[:100]
        }

def main():
    print("=" * 70)
    print("COMPLETE RAG INDEXING - 20 THREAD MODE")
    print("=" * 70)
    
    rag = get_rag_system()
    repo_root = Path(r"E:\AI_Tools\Central_Repository")
    
    # Show current status
    print("\nCurrent status:")
    for name, coll in rag.collections.items():
        try:
            print(f"  {name}: {coll.count():,} documents")
        except:
            print(f"  {name}: Error")
    
    print(f"\nUsing {MAX_WORKERS} parallel workers for maximum speed\n")
    
    # Collect all files to index
    files_to_index = []
    
    # 1. Python scripts from OLLAMA_SYSTEM
    ollama_dir = repo_root / "OLLAMA_SYSTEM"
    if ollama_dir.exists():
        py_files = [(f, "code_patterns", "python_script") 
                    for f in ollama_dir.rglob("*.py") 
                    if "__pycache__" not in str(f)]
        files_to_index.extend(py_files)
        print(f"Found {len(py_files)} Python files in OLLAMA_SYSTEM")
    
    # 2. Python scripts from RAG_SYSTEM
    rag_dir = repo_root / "RAG_SYSTEM"
    if rag_dir.exists():
        rag_py = [(f, "code_patterns", "python_script") 
                  for f in rag_dir.rglob("*.py") 
                  if "__pycache__" not in str(f)]
        files_to_index.extend(rag_py)
        print(f"Found {len(rag_py)} Python files in RAG_SYSTEM")
    
    # 3. Documentation from DOCUMENTATION
    doc_dir = repo_root / "DOCUMENTATION"
    if doc_dir.exists():
        doc_files = [(f, "mrg", "documentation") 
                     for f in doc_dir.rglob("*.md")]
        files_to_index.extend(doc_files)
        print(f"Found {len(doc_files)} documentation files")
    
    # 4. OLLAMA_SYSTEM docs
    ollama_docs = repo_root / "OLLAMA_SYSTEM" / "docs"
    if ollama_docs.exists():
        ollama_md = [(f, "mrg", "ollama_docs") 
                     for f in ollama_docs.rglob("*.md")]
        files_to_index.extend(ollama_md)
        print(f"Found {len(ollama_md)} OLLAMA_SYSTEM docs")
    
    print(f"\nTotal files to index: {len(files_to_index)}")
    print("=" * 70)
    
    if not files_to_index:
        print("\nNo files to index!")
        return
    
    # Index with high parallelization
    indexed = 0
    failed = 0
    skipped = 0
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {}
        for f, coll, ftype in files_to_index:
            future = executor.submit(index_file, rag, f, repo_root, coll, ftype)
            futures[future] = (f, coll, ftype)
            time.sleep(0.1)  # Throttled submission to prevent compaction errors
        
        for i, future in enumerate(as_completed(futures), 1):
            result = future.result()
            
            with PROGRESS_LOCK:
                if result.get("skipped"):
                    skipped += 1
                elif result["success"]:
                    indexed += 1
                    elapsed = time.time() - start_time
                    rate = indexed / elapsed if elapsed > 0 else 0
                    print(f"  [{indexed}/{len(files_to_index)}] {result['file'][:40]}... OK ({rate:.1f} files/sec)")
                    sys.stdout.flush()
                else:
                    failed += 1
                    if failed <= 5:
                        print(f"  [{i}/{len(files_to_index)}] {result['file'][:40]}... FAIL: {result.get('error', 'Unknown')[:50]}")
    
    elapsed = time.time() - start_time
    
    print("\n" + "=" * 70)
    print("INDEXING COMPLETE")
    print("=" * 70)
    
    print(f"\nResults:")
    print(f"  Indexed: {indexed}")
    print(f"  Skipped: {skipped}")
    print(f"  Failed: {failed}")
    print(f"  Time: {elapsed:.1f}s ({elapsed/60:.1f} min)")
    print(f"  Rate: {indexed/elapsed:.1f} files/sec")
    
    print("\nFinal collection counts:")
    total = 0
    for name, coll in rag.collections.items():
        try:
            count = coll.count()
            total += count
            print(f"  {name}: {count:,} documents")
        except:
            print(f"  {name}: Error")
    
    print(f"\nGrand Total: {total:,} documents")
    print("\n✅ All indexing complete!")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted")
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
