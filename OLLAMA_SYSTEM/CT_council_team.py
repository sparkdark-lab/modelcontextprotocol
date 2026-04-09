#!/usr/bin/env python3
"""CT Council Team Orchestrator

CT = Council Team.
Handles CT model dispatch + CT consolidation.
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

# CT CONFIG
CT_OLLAMA_HOST = os.getenv("CT_OLLAMA_HOST", "http://127.0.0.1:11434")
CT_WORKER_COUNT = int(os.getenv("CT_WORKER_COUNT", "20"))
CT_MAX_TOKENS = int(os.getenv("CT_MAX_TOKENS", "512"))
CT_TEMPERATURE = float(os.getenv("CT_TEMPERATURE", "0.7"))
CT_USE_JUDGE = os.getenv("CT_USE_JUDGE", "0") in ["1", "true", "True"]

CT_MODELS = {
    "orchestrator": os.getenv("CT_ORCHESTRATOR_MODEL", "hf.co/ruv/ruvltra-claude-code:Q4_K_M"),
    "reasoning": os.getenv("CT_REASONING_MODEL", "llama3.2:3b"),
    "fast": os.getenv("CT_FAST_MODEL", "phi3:mini"),
    "code": os.getenv("CT_CODE_MODEL", "codellama:7b-instruct"),
}

CT_JUDGE_MODEL = os.getenv("CT_JUDGE_MODEL", "") or None
CT_ROLE_CYCLE = ["orchestrator", "reasoning", "fast", "code"]

CT_PROMPTS = {
    "orchestrator": "You are a CT architect. Analyze objective and provide structured plan.",
    "reasoning": "You are a CT reasoning analyst. Return facts, constraints, edge cases.",
    "fast": "You are a CT rapid specialist. Give 1 clear direct insight in 1-3 sentences.",
    "code": "You are a CT code builder. Provide concise working code w/ minimal comments.",
    "judge": "You are a CT judge. Score 0-10 accuracy/clarity/completeness and select best answer.",
}

# RAG CONFIG
CT_RAG_ENABLED = os.getenv("CT_RAG_ENABLED", "0") in ["1", "true", "True"]
CT_RAG_ENDPOINT = os.getenv("CT_RAG_ENDPOINT", "http://127.0.0.1:8000/v1/chat/completions")
CT_RAG_DEFAULT_SOURCE = os.getenv("CT_RAG_DEFAULT_SOURCE", "local_docs")

CT_LOG_DIR = os.path.join(os.path.dirname(__file__), "logs")


def _query_model(model: str, system: str, user: str, max_tokens: int = CT_MAX_TOKENS, temperature: float = CT_TEMPERATURE) -> str:
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
            "num_gpu": 99,
        },
    }
    try:
        r = requests.post(f"{CT_OLLAMA_HOST}/api/chat", json=payload, timeout=180)
        r.raise_for_status()
        data = r.json()
        if isinstance(data, dict):
            return (data.get("message", {}).get("content") or data.get("choices", [{}])[0].get("message", {}).get("content") or "").strip()
    except Exception as e:
        return f"[CT ERROR] {model}: {e}"
    return ""


def ct_rag_lookup(query: str) -> str:
    if not CT_RAG_ENABLED:
        return ""
    try:
        rag_payload = {
            "model": "kimi-k2-thinking",
            "messages": [
                {"role": "system", "content": "You are a RAG retrieval assistant. Use known sources."},
                {"role": "user", "content": f"Retrieve relevant context for: {query} (source={CT_RAG_DEFAULT_SOURCE})"},
            ],
            "stream": False,
        }
        r = requests.post(CT_RAG_ENDPOINT, json=rag_payload, timeout=180)
        r.raise_for_status()
        data = r.json()
        if isinstance(data, dict):
            return (data.get("message", {}).get("content") or data.get("choices", [{}])[0].get("message", {}).get("content") or "").strip()
    except Exception as e:
        return f"[RAG ERROR] {e}"
    return ""


def ct_run_worker(worker_id: int, task: str) -> dict:
    role = CT_ROLE_CYCLE[worker_id % len(CT_ROLE_CYCLE)]
    model = CT_MODELS[role]
    response = _query_model(model, CT_PROMPTS[role], task)
    return {"worker_id": worker_id, "role": role, "model": model, "response": response}


def ct_dispatch(task: str) -> list:
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=CT_WORKER_COUNT) as ex:
        futures = {ex.submit(ct_run_worker, i, task): i for i in range(CT_WORKER_COUNT)}
        for f in tqdm(concurrent.futures.as_completed(futures), total=CT_WORKER_COUNT, desc="CT Council", unit="worker"):
            results.append(f.result())
    return sorted(results, key=lambda x: x["worker_id"])


def ct_synthesize(task: str, workers: list) -> str:
    council_log = "\n".join([f"--- Worker {w['worker_id']} [{w['role']}] ---\n{w['response']}" for w in workers])
    synth_user = (
        f"Original task:\n{task}\n\nCouncil worker texts:\n{council_log}\n\n"
        "Instructions: produce one authoritative answer; ignore repetition; add Next Steps (max 3 bullets)."
    )
    synth_system = "You are CT Council Orchestrator. Synthesize multiple specialized outputs to one clear result."
    return _query_model(CT_MODELS["orchestrator"], synth_system, synth_user, max_tokens=1024, temperature=0.2)


def ct_run_judge(task: str, final_ans: str) -> str:
    if not CT_USE_JUDGE or not CT_JUDGE_MODEL:
        return ""
    judge_input = f"Task:\n{task}\n\nFinal answer:\n{final_ans}\n\nEvaluate this answer." 
    return _query_model(CT_JUDGE_MODEL, CT_PROMPTS["judge"], judge_input, max_tokens=512, temperature=0.2)


def ct_save_log(task: str, workers: list, final: str, judge: str) -> str:
    os.makedirs(CT_LOG_DIR, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    path = os.path.join(CT_LOG_DIR, f"CT_council_{ts}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump({
            "timestamp": ts,
            "task": task,
            "workers": workers,
            "final": final,
            "judge": judge,
            "models": CT_MODELS,
        }, f, indent=2)
    return path


def ct_run_task(task: str) -> dict:
    rag_context = ct_rag_lookup(task) if CT_RAG_ENABLED else ""
    enriched_task = f"{task}\n\n[RAG context]\n{rag_context}" if rag_context else task
    workers = ct_dispatch(enriched_task)
    final = ct_synthesize(enriched_task, workers)
    verdict = ct_run_judge(enriched_task, final) if CT_USE_JUDGE else ""
    log_path = ct_save_log(task, workers, final, verdict)
    return {"task": task, "rag_context": rag_context, "workers": workers, "final": final, "judge": verdict, "log_path": log_path}


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python CT_council_team.py \"<your task>\"")
        sys.exit(1)
    task_arg = " ".join(sys.argv[1:])
    print(f"CT Council Team: Running task: {task_arg}")
    result = ct_run_task(task_arg)
    print("\n=== CT FINAL ANSWER ===\n")
    print(result["final"])
    if result["judge"]:
        print("\n=== CT JUDGE ===\n", result["judge"])
    print(f"\nLog saved: {result['log_path']}")
