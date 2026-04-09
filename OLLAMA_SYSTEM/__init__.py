# -*- coding: utf-8 -*-
# Ollama System - Centralized Configuration
# Reference this from any workspace using:
# from OLLAMA_SYSTEM.scripts.ollama_manager import get_ollama_system

"""
OLLAMA_SYSTEM Configuration
============================

Central Repository Path: E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM

Usage from any workspace:
    import sys
    from pathlib import Path
    CENTRAL_REPO = Path(r'E:\AI_Tools\Central_Repository')
    sys.path.insert(0, str(CENTRAL_REPO))
    
    from OLLAMA_SYSTEM.scripts.ollama_manager import get_ollama_system
    ollama = get_ollama_system()
    result = ollama.query("codellama:70b", "Your prompt here")

Configuration File:
    E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\config\ollama_config.json

System Structure:
    OLLAMA_SYSTEM/
     config/          - Configuration files
     scripts/         - Python management scripts
     batch_files/     - Batch/PowerShell scripts
     docs/            - Documentation
     models/          - Model management
     logs/            - System logs
"""

from pathlib import Path

# Export paths for easy reference
OLLAMA_SYSTEM_PATH = Path(r'E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM')
OLLAMA_CONFIG_PATH = OLLAMA_SYSTEM_PATH / 'config' / 'ollama_config.json'

