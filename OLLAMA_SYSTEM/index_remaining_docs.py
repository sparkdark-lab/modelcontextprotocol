#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Index Remaining Documents and Scripts
Indexes Python scripts, documentation, and Master Reference Guide into RAG system
"""

import sys
import os
from pathlib import Path
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

# Fix encoding for Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Add RAG system to path
sys.path.insert(0, str(Path(__file__).parent.parent / "cursor auto local intelligence"))
from rag_system import get_rag_system

# Configuration
MAX_WORKERS = 5  # Parallel workers
PROGRESS_INTERVAL = 5  # Print progress every N files

def index_python_scripts(rag, repo_root):
    """Index Python scripts from OLLAMA_SYSTEM and other key directories"""
    print("\n" + "=" * 70)
    print("INDEXING PYTHON SCRIPTS")
    print("=" * 70)
    
    # Find Python files in key directories
    python_files = []
    
    # OLLAMA_SYSTEM scripts
    ollama_system = repo_root / "OLLAMA_SYSTEM"
    if ollama_system.exists():
        ollama_scripts = list(ollama_system.rglob("*.py"))
        python_files.extend(ollama_scripts)
        print(f"Found {len(ollama_scripts)} Python files in OLLAMA_SYSTEM")
    
    # RAG_SYSTEM scripts
    rag_system = repo_root / "RAG_SYSTEM"
    if rag_system.exists():
        rag_scripts = list(rag_system.rglob("*.py"))
        python_files.extend(rag_scripts)
        print(f"Found {len(rag_scripts)} Python files in RAG_SYSTEM")
    
    # Cursor auto local intelligence
    cursor_dir = repo_root / "cursor auto local intelligence"
    if cursor_dir.exists():
        cursor_scripts = list(cursor_dir.glob("*.py"))
        python_files.extend(cursor_scripts)
        print(f"Found {len(cursor_scripts)} Python files in cursor auto local intelligence")
    
    # Remove duplicates
    python_files = list(set(python_files))
    
    print(f"\nTotal: {len(python_files)} Python files to index")
    print(f"Using {MAX_WORKERS} parallel workers\n")
    
    indexed = 0
    failed = 0
    skipped = 0
    start_time = time.time()
    
    def process_file(file_path):
        try:
            # Skip __pycache__ and test files if desired
            if '__pycache__' in str(file_path):
                return {"success": True, "skipped": True, "file": file_path.name}
            
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            
            # Skip very small files (likely empty or just imports)
            if len(content.strip()) < 100:
                return {"success": True, "skipped": True, "file": file_path.name}
            
            metadata = {
                "file": str(file_path.relative_to(repo_root)),
                "type": "python_script",
                "title": file_path.stem,
                "extension": ".py"
            }
            
            # Store in code_patterns collection
            success = rag.store("code_patterns", content, metadata)
            
            return {
                "success": success,
                "skipped": False,
                "file": file_path.name,
                "size": len(content)
            }
        except Exception as e:
            return {
                "success": False,
                "skipped": False,
                "file": file_path.name,
                "error": str(e)
            }
    
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(process_file, f): f for f in python_files}
        
        for i, future in enumerate(as_completed(futures), 1):
            result = future.result()
            
            if result.get("skipped"):
                skipped += 1
            elif result["success"]:
                indexed += 1
                if indexed % PROGRESS_INTERVAL == 0:
                    print(f"  [{indexed + skipped}/{len(python_files)}] {result['file'][:50]}... [OK]")
            else:
                failed += 1
                error_msg = result.get("error", "Unknown error")
                print(f"  [{i}/{len(python_files)}] {result['file'][:50]}... [FAIL] - {error_msg[:50]}")
    
    elapsed = time.time() - start_time
    print(f"\n✅ Python Scripts: {indexed} indexed, {skipped} skipped, {failed} failed ({elapsed:.1f}s)")
    return indexed, failed

def index_documentation(rag, repo_root):
    """Index markdown documentation files"""
    print("\n" + "=" * 70)
    print("INDEXING DOCUMENTATION")
    print("=" * 70)
    
    md_files = []
    
    # DOCUMENTATION directory
    doc_dir = repo_root / "DOCUMENTATION"
    if doc_dir.exists():
        doc_files = list(doc_dir.rglob("*.md"))
        md_files.extend(doc_files)
        print(f"Found {len(doc_files)} markdown files in DOCUMENTATION")
    
    # OLLAMA_SYSTEM docs
    ollama_docs = repo_root / "OLLAMA_SYSTEM" / "docs"
    if ollama_docs.exists():
        ollama_md = list(ollama_docs.rglob("*.md"))
        md_files.extend(ollama_md)
        print(f"Found {len(ollama_md)} markdown files in OLLAMA_SYSTEM/docs")
    
    # RAG_SYSTEM docs
    rag_docs = repo_root / "RAG_SYSTEM"
    if rag_docs.exists():
        rag_md = list(rag_docs.glob("*.md"))
        md_files.extend(rag_md)
        print(f"Found {len(rag_md)} markdown files in RAG_SYSTEM")
    
    # Remove duplicates
    md_files = list(set(md_files))
    
    print(f"\nTotal: {len(md_files)} documentation files to index")
    print(f"Using {MAX_WORKERS} parallel workers\n")
    
    indexed = 0
    failed = 0
    start_time = time.time()
    
    def process_file(file_path):
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            
            metadata = {
                "file": str(file_path.relative_to(repo_root)),
                "type": "documentation",
                "title": file_path.stem,
                "extension": ".md"
            }
            
            # Store in mrg collection (Master Reference/General docs)
            success = rag.store("mrg", content, metadata)
            
            return {
                "success": success,
                "file": file_path.name,
                "size": len(content)
            }
        except Exception as e:
            return {
                "success": False,
                "file": file_path.name,
                "error": str(e)
            }
    
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(process_file, f): f for f in md_files}
        
        for i, future in enumerate(as_completed(futures), 1):
            result = future.result()
            
            if result["success"]:
                indexed += 1
                if indexed % PROGRESS_INTERVAL == 0:
                    print(f"  [{indexed}/{len(md_files)}] {result['file'][:50]}... [OK]")
            else:
                failed += 1
                error_msg = result.get("error", "Unknown error")
                print(f"  [{i}/{len(md_files)}] {result['file'][:50]}... [FAIL] - {error_msg[:50]}")
    
    elapsed = time.time() - start_time
    print(f"\n✅ Documentation: {indexed} indexed, {failed} failed ({elapsed:.1f}s)")
    return indexed, failed

def index_master_reference_guide(rag, repo_root):
    """Index Master Reference Guide"""
    print("\n" + "=" * 70)
    print("INDEXING MASTER REFERENCE GUIDE")
    print("=" * 70)
    
    # Find Master Reference Guide v9
    mrg_path = repo_root / "MASTER_REFERENCE" / "MASTER_REFERENCE_Guide_v9"
    
    if not mrg_path.exists():
        print(f"⚠️  Master Reference Guide not found at: {mrg_path}")
        return 0, 0
    
    mrg_files = list(mrg_path.rglob("*.md"))
    print(f"Found {len(mrg_files)} files in Master Reference Guide v9")
    print(f"Using {MAX_WORKERS} parallel workers\n")
    
    indexed = 0
    failed = 0
    start_time = time.time()
    
    def process_file(file_path):
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            
            metadata = {
                "file": str(file_path.relative_to(repo_root)),
                "type": "master_reference",
                "title": file_path.stem,
                "extension": ".md",
                "source": "MRG_v9"
            }
            
            # Store in mrg collection
            success = rag.store("mrg", content, metadata)
            
            return {
                "success": success,
                "file": file_path.name,
                "size": len(content)
            }
        except Exception as e:
            return {
                "success": False,
                "file": file_path.name,
                "error": str(e)
            }
    
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(process_file, f): f for f in mrg_files}
        
        for i, future in enumerate(as_completed(futures), 1):
            result = future.result()
            
            if result["success"]:
                indexed += 1
                if indexed % PROGRESS_INTERVAL == 0:
                    print(f"  [{indexed}/{len(mrg_files)}] {result['file'][:50]}... [OK]")
            else:
                failed += 1
                error_msg = result.get("error", "Unknown error")
                print(f"  [{i}/{len(mrg_files)}] {result['file'][:50]}... [FAIL] - {error_msg[:50]}")
    
    elapsed = time.time() - start_time
    print(f"\n✅ Master Reference Guide: {indexed} indexed, {failed} failed ({elapsed:.1f}s)")
    return indexed, failed

def show_final_stats(rag):
    """Show final collection statistics"""
    print("\n" + "=" * 70)
    print("FINAL COLLECTION STATISTICS")
    print("=" * 70)
    
    if rag.use_chromadb:
        total_docs = 0
        for coll_name, collection in rag.collections.items():
            try:
                count = collection.count()
                total_docs += count
                print(f"  ✅ {coll_name}: {count:,} documents")
            except Exception as e:
                print(f"  ⚠️  {coll_name}: Error - {str(e)[:50]}")
        
        print(f"\n  📊 Total: {total_docs:,} documents indexed")
    else:
        print("  ⚠️  Using in-memory storage (no persistence)")

def main():
    print("=" * 70)
    print("RAG SYSTEM - INDEX REMAINING DOCUMENTS AND SCRIPTS")
    print("=" * 70)
    
    # Initialize RAG system
    print("\n🔧 Initializing RAG system...")
    rag = get_rag_system()
    
    if rag.use_chromadb:
        print(f"✅ Using ChromaDB at: {rag.persist_directory}")
    else:
        print("⚠️  Using in-memory storage")
    
    repo_root = Path(r"E:\AI_Tools\Central_Repository")
    
    # Show current stats
    print("\n📊 Current Collection Status:")
    if rag.use_chromadb:
        for coll_name, collection in rag.collections.items():
            try:
                count = collection.count()
                print(f"  {coll_name}: {count:,} documents")
            except:
                print(f"  {coll_name}: Error reading count")
    
    start_time = time.time()
    
    # Index Python scripts
    py_indexed, py_failed = index_python_scripts(rag, repo_root)
    
    # Index documentation
    doc_indexed, doc_failed = index_documentation(rag, repo_root)
    
    # Index Master Reference Guide
    mrg_indexed, mrg_failed = index_master_reference_guide(rag, repo_root)
    
    # Show final statistics
    show_final_stats(rag)
    
    total_time = time.time() - start_time
    
    print("\n" + "=" * 70)
    print("INDEXING COMPLETE")
    print("=" * 70)
    print(f"\n📈 Summary:")
    print(f"  Python Scripts:    {py_indexed} indexed, {py_failed} failed")
    print(f"  Documentation:     {doc_indexed} indexed, {doc_failed} failed")
    print(f"  Master Reference:  {mrg_indexed} indexed, {mrg_failed} failed")
    print(f"\n  Total Time: {total_time/60:.1f} minutes")
    print(f"\n✅ RAG system is ready to use!")
    print(f"\nNext steps:")
    print(f"  • Test queries: python OLLAMA_SYSTEM/ollama_rag_query.py")
    print(f"  • Run examples: python OLLAMA_SYSTEM/examples/rag_examples.py")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
