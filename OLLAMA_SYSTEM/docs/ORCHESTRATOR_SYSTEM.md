# Ollama Orchestrator System

## Overview

A sophisticated multi-model orchestration system that routes queries through a team of AI models with a judge for evaluation and feedback.

## Architecture

```
User Query
    ↓
Router (mistral:7b) - Routes query to Ollama
    ↓
Team Models (simultaneous):
    - qwen2.5-coder:32b (4 threads)
    - llama3.1:8b (4 threads)
    ↓
Judge (mistral:7b) - Evaluates both answers
    ↓
    ├─→ Final Answer (to User)
    └─→ Feedback (to both models)
```

## Components

### 1. Router (`ollama_router.py`)
- **Model**: mistral:7b
- **Purpose**: Routes all queries to Ollama
- **Function**: Processes and formats queries for the team
- **No system AI interaction** - everything goes through Ollama

### 2. Team System (`ollama_team.py`)
- **Models**:
  - `qwen2.5-coder:32b` (4 threads) - Code generation specialist
  - `llama3.1:8b` (4 threads) - General purpose
- **Function**: Both models receive questions simultaneously and formulate complete answers independently

### 3. Judge System (`ollama_judge.py`)
- **Model**: mistral:7b
- **Purpose**: Evaluates team answers
- **Functions**:
  1. Creates final corrected version for user
  2. Sends feedback to both models explaining selection basis

### 4. Orchestrator (`ollama_orchestrator.py`)
- **Purpose**: Main coordinator for the complete workflow
- **Manages**: Router → Team → Judge → Feedback → User

## Usage

### Simple Interface

```bash
python scripts/query_ollama_team.py "Your question here"
```

### Python API

```python
from scripts.ollama_orchestrator import OllamaOrchestrator

orchestrator = OllamaOrchestrator()
result = orchestrator.process_query("What is the capital of France?")

print(result["final_answer"])  # Final answer sent to user
print(result["team_answers"])  # Both team model answers
print(result["evaluation"])     # Judge's evaluation
```

### Programmatic Usage

```python
import sys
from pathlib import Path

CENTRAL_REPO = Path(r'E:\AI_Tools\Central_Repository')
sys.path.insert(0, str(CENTRAL_REPO))

from OLLAMA_SYSTEM.scripts.ollama_orchestrator import OllamaOrchestrator

orchestrator = OllamaOrchestrator()
result = orchestrator.process_query("Your question", send_feedback=True)
```

## Configuration

Configuration is in `config/ollama_config.json` under `integration.orchestrator`:

```json
{
  "orchestrator": {
    "enabled": true,
    "router": {
      "model": "mistral:7b",
      "threads": 4,
      "temperature": 0.3
    },
    "team": {
      "models": [
        {
          "name": "qwen2.5-coder:32b",
          "threads": 4,
          "purpose": "code_generation"
        },
        {
          "name": "llama3.1:8b",
          "threads": 4,
          "purpose": "general"
        }
      ]
    },
    "judge": {
      "model": "mistral:7b",
      "threads": 4,
      "temperature": 0.5
    },
    "send_feedback": true
  }
}
```

## Workflow Details

### Step 1: Router Processing
- Router (mistral:7b) receives user query
- Analyzes and formats query for team
- Routes to Ollama (no system AI interaction)

### Step 2: Team Consultation
- Both models receive query **simultaneously**
- Each model uses 4 threads
- Models formulate complete answers independently
- Answers collected in parallel

### Step 3: Judge Evaluation
- Judge (mistral:7b) receives both answers
- Evaluates for accuracy, completeness, quality
- Creates final corrected version
- Identifies better answer and reasoning

### Step 4: Feedback Loop
- Judge sends feedback to both models
- Feedback includes:
  - Strengths
  - Areas for improvement
  - Quality score
  - Selection basis

### Step 5: User Response
- Final corrected answer sent to user
- Complete workflow logged

## Response Structure

```python
{
    "success": True,
    "final_answer": "Final corrected answer for user",
    "user_query": "Original user question",
    "team_answers": {
        "qwen2.5-coder:32b": "Answer from model 1",
        "llama3.1:8b": "Answer from model 2"
    },
    "evaluation": {
        "better_answer": "model_name",
        "reasoning": "Why this answer was selected",
        "quality_score": "score out of 10"
    },
    "feedback_sent": {
        "model_name": {
            "success": True,
            "acknowledgment": "Model's acknowledgment"
        }
    },
    "workflow": {
        "timestamp": "ISO timestamp",
        "steps": {
            "router": {...},
            "team": {...},
            "judge": {...},
            "feedback": {...}
        }
    }
}
```

## Requirements

- Ollama server running on `http://localhost:11434`
- Required models available:
  - `mistral:7b` (router and judge)
  - `qwen2.5-coder:32b` (team member)
  - `llama3.1:8b` (team member)

## Thread Configuration

Each model uses 4 threads:
- Router: 4 threads
- Team models: 4 threads each (8 total)
- Judge: 4 threads

Total: 12 threads across all models

## No System AI Interaction

**Important**: The system AI (Cursor/Auto) has **no interaction** with this process. Everything goes through Ollama:
- Router uses Ollama
- Team uses Ollama
- Judge uses Ollama
- All communication is via Ollama API

## Logging

Session logs are maintained in the orchestrator:
```python
orchestrator.get_session_log()  # Get all queries
orchestrator.clear_session_log()  # Clear log
```

## Error Handling

The system includes fallback mechanisms:
- Router failure → uses original query
- Team model failure → continues with available answers
- Judge failure → returns team answers
- Feedback failure → continues without feedback

