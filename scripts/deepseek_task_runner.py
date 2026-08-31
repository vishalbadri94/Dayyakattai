"""
DeepSeek Task Runner — Level 2 & 3
=====================================
Reads tasks.json manifest and executes ALL tasks via DeepSeek autonomously.
Claude/Gemini only writes the manifest once. DeepSeek does everything else.

Task manifest format (tasks.json):
  [
    {
      "id": "phase2_rtm_sync",
      "phase": "2.1",
      "type": "full_file",       // V3 or R1 chosen automatically
      "description": "Build Agora RTM sync service",
      "output_file": "lib/services/daayakattai_rtm_service.dart",
      "prompt_file": "scripts/prompts/rtm_sync.txt",
      "depends_on": [],
      "done": false
    }
  ]

Usage:
  python scripts/deepseek_task_runner.py              # run all pending tasks
  python scripts/deepseek_task_runner.py --id phase2  # run specific task
  python scripts/deepseek_task_runner.py --list       # list all tasks
"""
import os, sys, re, json, argparse
from openai import OpenAI

ROOT_DIR     = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE     = os.path.join(ROOT_DIR, "deepseek api")
TASKS_FILE   = os.path.join(ROOT_DIR, "scripts", "tasks.json")
APP_DIR      = os.path.join(ROOT_DIR, "daayakattai_app")
PROMPTS_DIR  = os.path.join(ROOT_DIR, "scripts", "prompts")

MODEL_MAP = {
    "patch":        "deepseek-chat",      # V3: quick fix
    "ui":           "deepseek-chat",      # V3: widget generation
    "transform":    "deepseek-chat",      # V3: regex/text fix
    "full_file":    "deepseek-reasoner",  # R1: full rewrite
    "logic":        "deepseek-reasoner",  # R1: complex logic
    "test":         "deepseek-reasoner",  # R1: test generation
    "architecture": "deepseek-reasoner",  # R1: design
}

def get_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    with open(KEY_FILE) as f:
        return f.read().strip()

def load_tasks():
    if not os.path.exists(TASKS_FILE):
        return []
    with open(TASKS_FILE) as f:
        return json.load(f)

def save_tasks(tasks):
    with open(TASKS_FILE, "w") as f:
        json.dump(tasks, f, indent=2)

def extract_code(text, lang="dart"):
    m = re.search(rf"```{lang}\n(.*?)\n```", text, re.DOTALL | re.IGNORECASE)
    if m: return m.group(1)
    m = re.search(r"```\n(.*?)\n```", text, re.DOTALL)
    if m: return m.group(1)
    return None

def load_prompt(task):
    """Load prompt from prompt_file or inline prompt field."""
    if "prompt" in task:
        return task["prompt"]
    prompt_path = os.path.join(ROOT_DIR, task.get("prompt_file", ""))
    if os.path.exists(prompt_path):
        with open(prompt_path) as f:
            return f.read()
    return None

def execute_task(client, task):
    """Execute a single task via DeepSeek. Returns True on success."""
    task_type = task.get("type", "patch")
    model     = MODEL_MAP.get(task_type, "deepseek-chat")
    prompt    = load_prompt(task)

    if not prompt:
        print(f"  [SKIP] No prompt for task: {task['id']}")
        return False

    output_rel  = task.get("output_file", "")
    output_path = os.path.join(ROOT_DIR, "daayakattai_app", output_rel) if output_rel else None

    # Inject context files if specified
    context = ""
    for ctx_file in task.get("context_files", []):
        ctx_path = os.path.join(ROOT_DIR, "daayakattai_app", ctx_file)
        if os.path.exists(ctx_path):
            with open(ctx_path) as f:
                context += f"\n\n--- {ctx_file} ---\n{f.read()[:4000]}"

    full_prompt = prompt + ("\n\nContext files:\n" + context if context else "")
    code_lang   = task.get("code_language", "dart")

    print(f"  [DeepSeek {model}] Task: {task['id']} ({task_type})...")

    resp = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": f"You are a Flutter/Dart expert. Output code in a ```{code_lang} code block."},
            {"role": "user", "content": full_prompt}
        ],
        temperature=0.1,
        max_tokens=8000,
    )
    output = resp.choices[0].message.content
    code   = extract_code(output, code_lang)

    if code and output_path:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(code)
        print(f"  [OK] Written: {output_path}")
        return True
    elif output_path:
        print(f"  [FAIL] Could not extract code for {task['id']}")
        # Save raw output for inspection
        raw_path = output_path + ".deepseek_raw.txt"
        with open(raw_path, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"  [SAVED] Raw output: {raw_path}")
        return False
    else:
        # No output file — just print result (for patch tasks)
        print(f"  [OUTPUT] {output[:500]}")
        return True

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", help="Run specific task by ID")
    parser.add_argument("--list", action="store_true", help="List all tasks")
    parser.add_argument("--no-autofix", action="store_true", help="Skip autofix after tasks")
    parser.add_argument("--phase", help="Run all tasks in a specific phase e.g. '2.1'")
    args = parser.parse_args()

    tasks = load_tasks()

    if args.list:
        print(f"{'ID':<30} {'Phase':<8} {'Type':<14} {'Done':<6}")
        print("-" * 65)
        for t in tasks:
            done = "[x]" if t.get("done") else "[ ]"
            print(f"{t['id']:<30} {t.get('phase',''):<8} {t.get('type',''):<14} {done}")
        return

    key    = get_key()
    client = OpenAI(api_key=key, base_url="https://api.deepseek.com/v1")

    # Filter tasks
    pending = [t for t in tasks if not t.get("done", False)]
    if args.id:
        pending = [t for t in pending if t["id"] == args.id]
    if args.phase:
        pending = [t for t in pending if t.get("phase", "").startswith(args.phase)]

    if not pending:
        print("No pending tasks to run.")
        return

    print(f"Running {len(pending)} task(s)...")
    completed = []
    for task in pending:
        print(f"\n[Task] {task['id']} - {task.get('description', '')}")
        success = execute_task(client, task)
        if success:
            task["done"] = True
            completed.append(task["id"])
            save_tasks(tasks)

    print(f"\n{len(completed)}/{len(pending)} tasks completed: {completed}")

    if not args.no_autofix and completed:
        print("\nRunning DeepSeek autofix loop on results...")
        import subprocess
        subprocess.run([sys.executable,
                        os.path.join(ROOT_DIR, "scripts", "deepseek_autofix.py"),
                        "--max-iterations", "3"],
                       cwd=ROOT_DIR)

if __name__ == "__main__":
    main()
