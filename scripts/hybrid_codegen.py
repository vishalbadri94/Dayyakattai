import os
import sys
import json
import re
import requests
from openai import OpenAI

# Paths
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEEPSEEK_KEY_FILE = os.path.join(ROOT_DIR, "deepseek api")
GEMINI_KEY_FILE = os.path.join(ROOT_DIR, "gemini api")

def get_deepseek_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ.get("DEEPSEEK_API_KEY")
    if os.path.exists(DEEPSEEK_KEY_FILE):
        with open(DEEPSEEK_KEY_FILE, "r") as f:
            return f.read().strip()
    return None

def get_gemini_key():
    if os.environ.get("GEMINI_API_KEY"):
        return os.environ.get("GEMINI_API_KEY")
    if os.path.exists(GEMINI_KEY_FILE):
        with open(GEMINI_KEY_FILE, "r") as f:
            return f.read().strip()
    return None

def log_api_usage(api_name, model_name, input_tokens, output_tokens):
    log_file = os.path.join(ROOT_DIR, "docs", "api_usage_log.md")
    
    cost = 0.0
    if model_name == "deepseek-chat":
        cost = (input_tokens * 0.14 + output_tokens * 0.28) / 1000000.0
    elif model_name == "deepseek-reasoner":
        cost = (input_tokens * 0.55 + output_tokens * 2.19) / 1000000.0
    elif "gemini-1.5-pro" in model_name:
        cost = (input_tokens * 1.25 + output_tokens * 5.00) / 1000000.0
    elif "gemini-1.5-flash" in model_name:
        cost = (input_tokens * 0.075 + output_tokens * 0.30) / 1000000.0
        
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    if not os.path.exists(log_file):
        os.makedirs(os.path.dirname(log_file), exist_ok=True)
        with open(log_file, "w", encoding="utf-8") as f:
            f.write("# API Token Usage and Cost Log\n\n")
            f.write("| Timestamp | API | Model | Input Tokens | Output Tokens | Estimated Cost ($) |\n")
            f.write("| :--- | :--- | :--- | :--- | :--- | :--- |\n")
            
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(f"| {timestamp} | {api_name} | {model_name} | {input_tokens} | {output_tokens} | ${cost:.6f} |\n")

def call_gemini(prompt, model="gemini-1.5-pro", api_key=None):
    if not api_key:
        api_key = get_gemini_key()
    if not api_key:
        print("Error: Gemini API Key not found. Please set GEMINI_API_KEY env var or create a 'gemini api' file.")
        sys.exit(1)

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    headers = {"Content-Type": "application/json"}
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt}
                ]
            }
        ]
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        res_data = response.json()
        
        # Log usage
        usage = res_data.get("usageMetadata", {})
        input_tokens = usage.get("promptTokenCount", 0)
        output_tokens = usage.get("candidatesTokenCount", 0)
        log_api_usage("Gemini", model, input_tokens, output_tokens)
        
        return res_data["candidates"][0]["content"]["parts"][0]["text"]
    except Exception as e:
        print(f"Gemini API call failed: {e}")
        if 'response' in locals():
            print(f"Response: {response.text}")
        sys.exit(1)

def call_deepseek(prompt, system_instruction, model="deepseek-chat", api_key=None):
    if not api_key:
        api_key = get_deepseek_key()
    if not api_key:
        print("Error: DeepSeek API Key not found. Please set DEEPSEEK_API_KEY env var or ensure 'deepseek api' file exists.")
        sys.exit(1)

    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com/v1")
    
    try:
        messages = [
            {"role": "system", "content": system_instruction},
            {"role": "user", "content": prompt}
        ]
        
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0.2 if model != "deepseek-reasoner" else None
        )
        
        # Log usage
        usage = response.usage
        if usage:
            input_tokens = usage.prompt_tokens
            output_tokens = usage.completion_tokens
            log_api_usage("DeepSeek", model, input_tokens, output_tokens)
            
        return response.choices[0].message.content
    except Exception as e:
        print(f"DeepSeek API call failed: {e}")
        sys.exit(1)

def extract_code_block(text):
    pattern = r"```(?:dart)?\n(.*?)\n```"
    match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
    if match:
        return match.group(1)
    return text

def cmd_test_connectivity():
    print("Testing connection endpoints...")
    
    ds_key = get_deepseek_key()
    if ds_key:
        print("[OK] DeepSeek API Key found.")
        # Try lightweight validation call
        try:
            client = OpenAI(api_key=ds_key, base_url="https://api.deepseek.com/v1")
            client.models.list()
            print("[OK] DeepSeek connection verified.")
        except Exception as e:
            print(f"[ERROR] DeepSeek connection failed: {e}")
    else:
        print("[ERROR] DeepSeek API Key missing.")

    gem_key = get_gemini_key()
    if gem_key:
        print("[OK] Gemini API Key found.")
        try:
            res = call_gemini("Say Hello", model="gemini-1.5-flash", api_key=gem_key)
            if res:
                print("[OK] Gemini connection verified.")
        except Exception as e:
            print(f"[ERROR] Gemini connection failed: {e}")
    else:
        print("[ERROR] Gemini API Key missing.")

def cmd_plan(spec_file, output_plan):
    print(f"Using Gemini to generate sprint plan from {spec_file}...")
    if not os.path.exists(spec_file):
        print(f"Error: Specification file '{spec_file}' not found.")
        sys.exit(1)
        
    with open(spec_file, "r", encoding="utf-8") as f:
        spec_content = f.read()

    prompt = (
        "You are Gemini 1.5 Pro, an expert architectural planner. "
        "Read the following system specifications and design requirements for the Daayakattai game:\n\n"
        f"{spec_content}\n\n"
        "Generate a structured sprint development plan. Identify the core game engine states, "
        "coordinate system maps, and linter-safe Flutter layouts required. Output your plan "
        "as a clean markdown checklist document."
    )
    
    plan = call_gemini(prompt)
    
    os.makedirs(os.path.dirname(output_plan), exist_ok=True)
    with open(output_plan, "w", encoding="utf-8") as f:
        f.write(plan)
    print(f"[OK] Sprint plan generated and saved to {output_plan}")

def cmd_code(plan_file, target_file):
    print(f"Using DeepSeek to generate code based on plan: {plan_file}...")
    if not os.path.exists(plan_file):
        print(f"Error: Plan file '{plan_file}' not found.")
        sys.exit(1)
        
    with open(plan_file, "r", encoding="utf-8") as f:
        plan_content = f.read()

    system_instruction = (
        "You are DeepSeek-V3, a programming assistant optimized for high-density, performant, and syntax-perfect code. "
        "Implement the requested logic exactly as detailed in the development plan. "
        "Output the final, working implementation code wrapped inside a ```dart ... ``` code block. "
        "Do not include conversational text."
    )
    
    prompt = (
        f"Based on the following development plan:\n\n{plan_content}\n\n"
        f"Implement or update the contents of '{os.path.basename(target_file)}'. Ensure clean imports "
        "and strict adherence to the coordinate system maps."
    )
    
    raw_code = call_deepseek(prompt, system_instruction)
    code = extract_code_block(raw_code)
    
    os.makedirs(os.path.dirname(target_file), exist_ok=True)
    with open(target_file, "w", encoding="utf-8") as f:
        f.write(code)
    print(f"[OK] Code written to {target_file}")

def cmd_audit(target_file):
    print(f"Using Gemini to audit code quality in {target_file}...")
    if not os.path.exists(target_file):
        print(f"Error: Target file '{target_file}' not found.")
        sys.exit(1)
        
    with open(target_file, "r", encoding="utf-8") as f:
        code_content = f.read()

    prompt = (
        "You are Gemini 1.5 Pro, an expert software auditor and linter. "
        "Scan the following Flutter/Dart source code file for any issues:\n\n"
        f"{code_content}\n\n"
        "Verify correctness against typical Chaupar/Daayakattai rules. Check for:\n"
        "1. Infinite loops or frame drops in CustomPainters.\n"
        "2. Teammate coordinate collisions on starting gates.\n"
        "3. Missing disposal/listeners leaks.\n"
        "Output your audit report as a clean markdown checklist highlighting any errors or warnings."
    )
    
    audit_report = call_gemini(prompt)
    print("\n=== AUDIT REPORT ===")
    print(audit_report)
    print("====================")

def print_help():
    print("Usage: python hybrid_codegen.py <command> [args]")
    print("\nCommands:")
    print("  test-connectivity                    Verify API endpoints connectivity")
    print("  plan <spec_html_path> <out_plan.md>  Use Gemini to create sprint plan")
    print("  code <plan_path> <target_file.dart> Use DeepSeek to write code based on plan")
    print("  audit <target_file.dart>            Use Gemini to audit code quality and rules compliance")

def main():
    if len(sys.argv) < 2:
        print_help()
        sys.exit(1)
        
    cmd = sys.argv[1]
    if cmd == "test-connectivity":
        cmd_test_connectivity()
    elif cmd == "plan":
        if len(sys.argv) < 4:
            print("Error: Missing arguments for plan. Usage: plan <spec_path> <out_path>")
            sys.exit(1)
        cmd_plan(sys.argv[2], sys.argv[3])
    elif cmd == "code":
        if len(sys.argv) < 4:
            print("Error: Missing arguments for code. Usage: code <plan_path> <target_path>")
            sys.exit(1)
        cmd_code(sys.argv[2], sys.argv[3])
    elif cmd == "audit":
        if len(sys.argv) < 3:
            print("Error: Missing arguments for audit. Usage: audit <target_path>")
            sys.exit(1)
        cmd_audit(sys.argv[2])
    else:
        print(f"Unknown command: {cmd}")
        print_help()

if __name__ == "__main__":
    main()
