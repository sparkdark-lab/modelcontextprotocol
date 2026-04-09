#!/usr/bin/env python3
r"""
Council Orchestrator - FINAL
Hardware: RTX 3060 12GB VRAM + CUDA
All 4 models load simultaneously (~8.8 GB total)
Judge-ready hook included (disabled until you're ready)
Path: D:\AI_Tools\Central_Repository\OLLAMA_SYSTEM
"""

import os
import sys
import json
try:
    import requests
except ImportError:
    print("Error: the 'requests' package is not installed. Run: pip install requests")
    sys.exit(1)
import concurrent.futures
from datetime import datetime
from tqdm import tqdm

# ══════════════════════════════════════════════════════════════════
# CONFIGURATION
# ══════════════════════════════════════════════════════════════════
OLLAMA_HOST = "http://127.0.0.1:11434"
WORKER_COUNT = 20
MAX_TOKENS = 512
TEMPERATURE = 0.7
USE_JUDGE = False  # ← flip to True when you're ready to add a judge

# Real VRAM sizes (verified):
# ruvltra-claude-code:Q4_K_M ~805 MB
# llama3.2:3b ~2.0 GB
# phi3:mini ~2.2 GB
# codellama:7b-instruct ~3.8 GB
# Total ~8.8 GB (fits in 12 GB with headroom)

MODELS = {
    "orchestrator": "hf.co/ruv/ruvltra-claude-code:Q4_K_M",
    "reasoning": "llama3.2:3b",
    "fast": "phi3:mini",
    "code": "codellama:7b-instruct",
}

# Future judge slot — populate when ready
JUDGE_MODEL = None  # e.g. "llama3.1:8b" or another Q4 model ≤ 3 GB

# Worker ID → role (cycles across 20 workers)
ROLE_CYCLE = ["orchestrator", "reasoning", "fast", "code"]

# ══════════════════════════════════════════════════════════════════
# SYSTEM PROMPTS
# ══════════════════════════════════════════════════════════════════
PROMPTS = {
    "orchestrator": (
        "You are a senior architect. Analyze the task, identify the core "
        "problem, and produce a structured implementation plan with clear priorities."
    ),
    "reasoning": (
        "You are a logical analyst. Break the task into facts, constraints, "
        "and decision points. Identify risks and edge cases. Be concise."
    ),
    "fast": (
        "You are a rapid-response specialist. Give one clear, direct answer "
        "or a single key insight. Maximum 3 sentences."
    ),
    "code": (
        "You are a code generation expert. Write clean, working code that "
        "directly addresses the task. Include only essential inline comments. "
        "Keep it under 25 lines unless complexity demands more."
    ),
    "judge": (
        "You are a strict quality judge. Review all provided answers. "
        "Score each 0-10 for accuracy, clarity, and completeness. "
        "Select the best elements and explain your final verdict in 2-3 sentences."
    ),
}

# ══════════════════════════════════════════════════════════════════
# OLLAMA API (uses /api/chat endpoint — correct for messages[])
# ══════════════════════════════════════════════════════════════════
def query_model(model: str, system: str, user: str,
                max_tokens: int = MAX_TOKENS,
                temperature: float = TEMPERATURE) -> str:
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        "stream": False,
        "options": {
            "num_predict": max_tokens,
            "temperature": temperature,
            "num_gpu": 99,  # use all available GPU layers (CUDA)
        },
    }
    try:
        r = requests.post(f"{OLLAMA_HOST}/api/chat", json=payload, timeout=180)
        r.raise_for_status()
        # Ollama API returns content as .message.content or .choices
        data = r.json()
        if isinstance(data, dict):
            return data.get("message", {}).get("content", "").strip() or data.get("choices", [{}])[0].get("message", {}).get("content", "")
        return ""
    except requests.exceptions.Timeout:
        return f"[TIMEOUT] {model} did not respond within 180s"
    except Exception as e:
        return f"[ERROR] {model}: {e}"

# ══════════════════════════════════════════════════════════════════
# WORKER
# ══════════════════════════════════════════════════════════════════
def run_worker(worker_id: int, task: str) -> dict:
    role = ROLE_CYCLE[worker_id % len(ROLE_CYCLE)]
    model = MODELS[role]
    resp = query_model(model, PROMPTS[role], task)
    return {"worker_id": worker_id, "role": role, "model": model, "response": resp}

# ══════════════════════════════════════════════════════════════════
# DISPATCH — all 4 models fit in GPU simultaneously
# Safe to run up to WORKER_COUNT threads; Ollama queues internally
# ══════════════════════════════════════════════════════════════════
def dispatch(task: str) -> list:
    results = []
    print(f"\n🚀 Dispatching {WORKER_COUNT} workers across 4 models...\n")
    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKER_COUNT) as ex:
        futures = {ex.submit(run_worker, wid, task): wid for wid in range(WORKER_COUNT)}
        for f in tqdm(concurrent.futures.as_completed(futures), total=WORKER_COUNT, desc="Council", unit="worker"):
            results.append(f.result())
    return sorted(results, key=lambda x: x["worker_id"])

# ══════════════════════════════════════════════════════════════════
# OPTIONAL JUDGE (runs after synthesis when USE_JUDGE=True)
# ══════════════════════════════════════════════════════════════════
def run_judge(task: str, synthesis: str) -> str:
    if not USE_JUDGE or not JUDGE_MODEL:
        return ""
    judge_input = (
        f"Original task:\n{task}\n\n"
        f"Synthesized answer:\n{synthesis}\n\n"
        "Please evaluate the above answer and provide your verdict."
    )
    print("\n⚖️ Running Judge...\n")
    return query_model(JUDGE_MODEL, PROMPTS["judge"], judge_input, max_tokens=512, temperature=0.2)

# ══════════════════════════════════════════════════════════════════
# SYNTHESIS — Orchestrator merges all worker responses
# ══════════════════════════════════════════════════════════════════
def synthesize(task: str, workers: list) -> str:
    council_dump = ""
    for w in workers:
        council_dump += (
            f"\n--- Worker {w['worker_id']} [{w['role']}] ---\n"
            f"{w['response']}\n"
        )

    synth_user = (
        f"Original task:\n{task}\n\n"
        f"Council responses ({len(workers)} workers):\n{council_dump}\n\n"
        "Instructions:\n"
        "1. Identify consensus points (appear in ≥2 responses) — highlight them.\n"
        "2. Discard noise and repetition.\n"
        "3. Produce ONE final, clear, actionable answer.\n"
        "4. If code was requested, include the best consolidated version.\n"
        "5. End with 'Next Steps:' — max 3 bullets."
    )
    synth_sys = (
        "You are the Council Orchestrator. You receive analysis from multiple "
        "specialist models and synthesize it into one authoritative, structured answer. "
        "Be precise, direct, and actionable. No filler."
    )
    print("\n🧠 Synthesizing final answer...\n")
    return query_model(MODELS["orchestrator"], synth_sys, synth_user, max_tokens=1024, temperature=0.2)

# ══════════════════════════════════════════════════════════════════
# LOGGING
# ══════════════════════════════════════════════════════════════════
LOG_DIR = r"D:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\logs"


def save_log(task: str, workers: list, final: str, verdict: str = ""):
    os.makedirs(LOG_DIR, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    path = os.path.join(LOG_DIR, f"council_{ts}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump({
            "timestamp": ts,
            "task": task,
            "worker_count": WORKER_COUNT,
            "models_used": list(MODELS.values()),
            "workers": workers,
            "final_answer": final,
            "judge_verdict": verdict,
        }, f, indent=2)
    print(f"\n💾 Log saved → {path}")


# ══════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════

def main():
    if len(sys.argv) < 2:
        print('Usage: python council_final.py "Your task here"')
        sys.exit(1)

    task = " ".join(sys.argv[1:])

    print("\n" + "═" * 62)
    print(" COUNCIL ORCHESTRATOR | 4 Models | RTX 3060 CUDA")
    print("═" * 62)
    print(f" Task : {task[:70]}{'...' if len(task)>70 else ''}")
    print(f" Judge: {'ENABLED → ' + str(JUDGE_MODEL) if USE_JUDGE else 'disabled (set USE_JUDGE=True to enable)'}")
    print("═" * 62)

    # 1. Dispatch 20 workers
    workers = dispatch(task)

    # 2. Synthesize
    final = synthesize(task, workers)

    # 3. Optional judge pass
    verdict = run_judge(task, final)

    # 4. Print result
    print("\n" + "═" * 62)
    print(" FINAL ANSWER")
    print("═" * 62)
    print(final)
    if verdict:
        print("\n⚖️ JUDGE VERDICT:\n" + verdict)
        print("═" * 62 + "\n")

    # 5. Save
    save_log(task, workers, final, verdict)


if __name__ == "__main__":
    main()
