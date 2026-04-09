#!/usr/bin/env python3
"""CT Council Team Web UI (Flask)"""

import os
import threading
import webbrowser
try:
    from flask import Flask, request, jsonify, render_template_string
except ImportError:
    print("Error: the 'flask' package is not installed. Run: pip install flask")
    import sys
    sys.exit(1)

from CT_council_team import ct_run_task

app = Flask(__name__)

HTML_PAGE = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>CT Council Team Interface</title>
  <style>
    body { font-family: Arial, sans-serif; background:#f6f8fa; padding: 20px; }
    input, textarea, button { width: 100%; margin: 8px 0; }
    pre { background:#fff; padding:12px; border:1px solid #ddd; white-space: pre-wrap; }
  </style>
</head>
<body>
  <h1>CT Council Team Interface</h1>
  <form id="task-form">
    <label>Task:</label>
    <textarea id="task" rows="4" placeholder="Describe what you want CT to do"></textarea>
    <button type="button" onclick="submitTask()">Run CT Council</button>
  </form>
  <p id="status">Status: idle</p>
  <h2>Final Answer</h2>
  <pre id="final">No results yet.</pre>

  <script>
    async function submitTask() {
      const taskText = document.getElementById('task').value.trim();
      if (!taskText) { alert('Enter a task.'); return; }
      document.getElementById('status').innerText = 'Status: running... (this may take 1-3 min)';
      document.getElementById('final').innerText = 'Running...';
      const resp = await fetch('/api/run', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task: taskText })
      });
      const data = await resp.json();
      document.getElementById('status').innerText = data.status;
      if (data.final) {
        document.getElementById('final').innerText = data.final;
      } else {
        document.getElementById('final').innerText = 'No answer. ' + JSON.stringify(data);
      }
    }
  </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_PAGE)

@app.route('/api/run', methods=['POST'])
def run_task_api():
    payload = request.get_json(force=True)
    task = payload.get('task', '').strip()
    if not task:
        return jsonify({'status': 'error', 'message': 'task required'}), 400
    try:
        result = ct_run_task(task)
        return jsonify({'status': 'done', 'final': result['final'], 'judge': result.get('judge'), 'log': result['log_path']})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/health')
def health():
    return jsonify({'status': 'ok', 'service': 'CT Council Team UI'})

if __name__ == '__main__':
    print('CT Council Team UI starting on http://127.0.0.1:5000')
    threading.Timer(1.0, lambda: webbrowser.open('http://127.0.0.1:5000')).start()
    app.run(host='127.0.0.1', port=5000, debug=False)
