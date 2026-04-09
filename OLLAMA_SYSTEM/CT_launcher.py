#!/usr/bin/env python3
"""CT Launcher for Council Team

Usage:
    python CT_launcher.py

This script verifies OLLAMA & starts the CT Flask UI.
"""

import os
import subprocess
import sys
import time
import urllib.request

CT_UI_SCRIPT = os.path.join(os.path.dirname(__file__), 'CT_council_ui.py')
CT_OLLAMA_HOST = os.getenv('CT_OLLAMA_HOST', 'http://127.0.0.1:11434')
CT_OLLAMA_FALLBACK_HOST = os.getenv('CT_OLLAMA_FALLBACK_HOST', 'http://127.0.0.1:8000')


def check_ollama():
    for host in [CT_OLLAMA_HOST, CT_OLLAMA_FALLBACK_HOST]:
        health_url = host.rstrip('/') + '/health'
        try:
            with urllib.request.urlopen(health_url, timeout=5) as r:
                data = r.read().decode('utf-8')
                print(f'Using OLLAMA host: {host}')
                return True, data
        except Exception as e:
            print(f'Health check failed for {host}: {e}')
    return False, f"No reachable OLLAMA host ({CT_OLLAMA_HOST}, {CT_OLLAMA_FALLBACK_HOST})"
    try:
        with urllib.request.urlopen(CT_OLLAMA_HEALTH, timeout=5) as r:
            data = r.read().decode('utf-8')
            return True, data
    except Exception as e:
        return False, str(e)


def run_ct_ui():
    print('Launching CT Council Team UI...')
    subprocess.Popen([sys.executable, CT_UI_SCRIPT], cwd=os.path.dirname(__file__))
    print('Waiting for UI to start...')
    time.sleep(3)
    print('Open browser at http://127.0.0.1:5000')


if __name__ == '__main__':
    ok, info = check_ollama()
    if not ok:
        print('CT Launcher error: OLLAMA health check failed:', info)
        sys.exit(1)
    print('CT Launcher: OLLAMA is reachable:', info)
    run_ct_ui()
