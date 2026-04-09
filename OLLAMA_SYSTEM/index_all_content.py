#!/usr/bin/env python3
"""
Index All Remaining Content - Working Version
Uses the actual RAG system store() method
"""

import sys
from pathlib import Path
import time

sys.path.insert(0, str(Path(__file__).parent.parent / "cursor auto local intelligence"))
from rag_system import get_rag_system

def main():
    print("=" * 70)
    print("INDEXING ALL REMAINING CONTENT")
    print("=" * 70)
    
    rag = get_rag_system()
    repo_root = Path(r"E:\AI_Tools\Central_Repository")
    
    # Show current status
    print("\nCurrent collection status:")
    for name, coll in rag.collections.items():
        try:
            count = coll.count()
            print(f"  {name}: {count:,} documents")
        except:
            print(f"  {name}: Error")
    
    total_indexed = 0
    total_failed = 0
    
    # 1. Index Master Reference Guide
    print("\n" + "=" * 70)
    print("INDEXING MASTER REFERENCE GUIDE")
    print("=" * 70)
    
    mrg_path = repo_root / "MASTER_REFERENCE" / "MASTER_REFERENCE_Guide_v9"
    if mrg_path.exists():
        mrg_files = list(mrg_path.rglob("*.md"))
        print(f"Found {len(mrg_files)} MRG files\n")
        
        for i, file_path in enumerate(mrg_files, 1):
            try:
                if i % 10 == 0:
                    print(f"  Progress: {i}/{len(mrg_files)}...")
                
                content = file_path.read_text(encoding='utf-8', errors='ignore')
                metadata = {
                    "file": str(file_path.relative_to(repo_root)),
                    "type": "master_reference",
                    "title": file_path.stem
                }
                
                if rag.store("mrg", content, metadata):
                    total_indexed += 1
                else:
                    total_failed += 1
            except Exception as e:
                total_failed += 1
                if total_failed <= 3:
                    print(f"  Error: {file_path.name}: {str(e)[:50]}")
        
        print(f"✅ MRG: {len(mrg_files)} processed")
    
    # 2. Index DOCUMENTATION
    print("\n" + "=" * 70)
    print("INDEXING DOCUMENTATION")
    print("=" * 70)
    
    doc_dir = repo_root / "DOCUMENTATION"
    if doc_dir.exists():
        doc_files = list(doc_dir.rglob("*.md"))
        print(f"Found {len(doc_files)} documentation files\n")
        
        for i, file_path in enumerate(doc_files, 1):
            try:
                if i % 5 == 0:
                    print(f"  Progress: {i}/{len(doc_files)}...")
                
                content = file_path.read_text(encoding='utf-8', errors='ignore')
                metadata = {
                    "file": str(file_path.relative_to(repo_root)),
                    "type": "documentation",
                    "title": file_path.stem
                }
                
                if rag.store("mrg", content, metadata):
                    total_indexed += 1
                else:
                    total_failed += 1
            except Exception as e:
                total_failed += 1
                if total_failed <= 3:
                    print(f"  Error: {file_path.name}: {str(e)[:50]}")
        
        print(f"✅ Documentation: {len(doc_files)} processed")
    
    # 3. Index OLLAMA_SYSTEM Python scripts
    print("\n" + "=" * 70)
    print("INDEXING OLLAMA_SYSTEM SCRIPTS")
    print("=" * 70)
    
    ollama_dir = repo_root / "OLLAMA_SYSTEM"
    if ollama_dir.exists():
        py_files = [f for f in ollama_dir.rglob("*.py") if "__pycache__" not in str(f)]
        print(f"Found {len(py_files)} Python files\n")
        
        for i, file_path in enumerate(py_files, 1):
            try:
                if i % 5 == 0:
                    print(f"  Progress: {i}/{len(py_files)}...")
                
                content = file_path.read_text(encoding='utf-8', errors='ignore')
                if len(content.strip()) < 100:  # Skip tiny files
                    continue
                
                metadata = {
                    "file": str(file_path.relative_to(repo_root)),
                    "type": "python_script",
                    "title": file_path.stem
                }
                
                if rag.store("code_patterns", content, metadata):
                    total_indexed += 1
                else:
                    total_failed += 1
            except Exception as e:
                total_failed += 1
                if total_failed <= 3:
                    print(f"  Error: {file_path.name}: {str(e)[:50]}")
        
        print(f"✅ Python scripts: {len(py_files)} processed")
    
    # Final status
    print("\n" + "=" * 70)
    print("FINAL STATUS")
    print("=" * 70)
    
    print("\nFinal collection counts:")
    grand_total = 0
    for name, coll in rag.collections.items():
        try:
            count = coll.count()
            grand_total += count
            print(f"  {name}: {count:,} documents")
        except:
            print(f"  {name}: Error")
    
    print(f"\nGrand Total: {grand_total:,} documents")
    print(f"Newly indexed: ~{total_indexed}")
    print(f"Failed: {total_failed}")
    print("\n✅ Indexing complete!")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted")
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
