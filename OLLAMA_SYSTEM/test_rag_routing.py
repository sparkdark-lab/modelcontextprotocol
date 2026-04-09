import time
from ollama_rag_query import OllamaRAG

# Define test questions and models
TEST_CASES = [
    {"question": "What is a MACD indicator?", "model": "llama3.1:8b"},
    {"question": "Explain the difference between supervised and unsupervised learning.", "model": "phi3:latest"},
    {"question": "Write a Python function to calculate Fibonacci numbers.", "model": "qwen2.5-coder:32b"},
    {"question": "What is the capital of France?", "model": "mistral:7b"},
    {"question": "How do I optimize a trading strategy?", "model": "llama3.1:8b"},
]

rag = OllamaRAG()

results = []

for case in TEST_CASES:
    print(f"\n=== Testing: {case['question']} (Model: {case['model']}) ===")
    start = time.time()
    answer = rag.query(
        question=case["question"],
        top_k=5,
        temperature=0.7,
        use_context=True,
        stream=False,
        model=case["model"]
    )
    elapsed = time.time() - start
    print(f"Answer: {answer}")
    print(f"Time taken: {elapsed:.2f} seconds")
    results.append({
        "question": case["question"],
        "model": case["model"],
        "answer": answer,
        "time": elapsed
    })

# Log results to file
with open("OLLAMA_SYSTEM/test_rag_routing_results.log", "w", encoding="utf-8") as f:
    for r in results:
        f.write(f"Question: {r['question']}\nModel: {r['model']}\nTime: {r['time']:.2f}s\nAnswer: {r['answer']}\n{'-'*40}\n")

print("\nAll tests complete. Results logged to OLLAMA_SYSTEM/test_rag_routing_results.log")
