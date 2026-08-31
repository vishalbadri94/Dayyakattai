"""
DeepSeek Auto-Fix Loop
=======================
Level 1: Self-healing build loop.

Runs flutter analyze + flutter test, sends ALL errors to DeepSeek,
applies patches, loops until clean or max iterations reached.
Claude/Gemini does NOT need to be involved at all.

Usage:
  python scripts/deepseek_autofix.py
  python scripts/deepseek_autofix.py --max-iterations 5
"""
import os, sys, re, subprocess, json, argparse
from openai import OpenAI

ROOT_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE   = os.path.join(ROOT_DIR, "deepseek api")
LIB_DIR    = os.path.join(ROOT_DIR, "daayakattai_app", "lib")
FLUTTER    = r"C:\src\flutter\bin\flutter.bat"

def get_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    with open(KEY_FILE, "r") as f:
        return f.read().strip()

def run_analyze():
    """Returns (exit_code, output_text)"""
    r = subprocess.run(
        [FLUTTER, "analyze"],
        cwd=os.path.join(ROOT_DIR, "daayakattai_app"),
        capture_output=True, text=True
    )
    return r.returncode, r.stdout + r.stderr

def run_tests():
    """Returns (exit_code, output_text)"""
    r = subprocess.run(
        [FLUTTER, "test", "--reporter", "expanded"],
        cwd=os.path.join(ROOT_DIR, "daayakattai_app"),
        capture_output=True, text=True
    )
    return r.returncode, r.stdout + r.stderr

def parse_errors(analyze_output):
    """Extract error lines with file paths and line numbers."""
    errors = []
    # Match lines like:   error - message - lib\file.dart:42:10 - code
    pattern = re.compile(r'(error|warning)\s+-\s+(.+?)\s+-\s+lib[\\/](.+?):(\d+):\d+\s+-\s+(\w+)')
    for m in pattern.finditer(analyze_output):
        severity, message, filepath, line, code = m.groups()
        full_path = os.path.join(LIB_DIR, filepath.replace('\\', os.sep).replace('/', os.sep))
        errors.append({
            "severity": severity,
            "message": message.strip(),
            "file": full_path,
            "line": int(line),
            "code": code,
        })
    return errors

def read_file(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return "[file not readable]"

def write_file(path, content):
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def select_model(error_count):
    """Use R1 for complex multi-error fixes, V3 for single quick fixes."""
    return "deepseek-reasoner" if error_count > 3 else "deepseek-chat"

def fix_errors_with_deepseek(client, errors, analyze_output):
    """
    Groups errors by file, sends each file + errors to DeepSeek, gets fixed file back.
    Returns dict of {filepath: fixed_content}
    """
    # Group by file
    by_file = {}
    for e in errors:
        by_file.setdefault(e["file"], []).append(e)

    fixes = {}
    for filepath, file_errors in by_file.items():
        src = read_file(filepath)
        filename = os.path.basename(filepath)
        model = select_model(len(file_errors))

        error_list = "\n".join([
            f"  Line {e['line']}: [{e['severity']}] {e['message']} ({e['code']})"
            for e in file_errors
        ])

        prompt = f"""Fix ALL of the following {len(file_errors)} issue(s) in this Flutter/Dart file.

FILE: {filename}
ISSUES:
{error_list}

CURRENT FILE CONTENT:
```dart
{src}
```

Rules:
- Fix ONLY the listed issues. Do not change unrelated code.
- If issue is 'unused_import', remove that import line.
- If issue is 'undefined_getter' or 'undefined_identifier', use the correct existing API.
- If issue is 'unused_field', either use the field somewhere appropriate or remove it.
- Preserve ALL comments, docstrings, and existing logic.
- Output the COMPLETE fixed file in a single ```dart code block.
"""
        print(f"  [DeepSeek {model}] Fixing {len(file_errors)} issue(s) in {filename}...")
        resp = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You are a Flutter/Dart expert. Fix only the listed issues. Return the complete fixed file in a ```dart code block."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.0,
            max_tokens=8000,
        )
        output = resp.choices[0].message.content
        match = re.search(r"```dart\n(.*?)\n```", output, re.DOTALL | re.IGNORECASE)
        if not match:
            match = re.search(r"```\n(.*?)\n```", output, re.DOTALL)
        if match:
            fixes[filepath] = match.group(1)
            print(f"    [OK] Fix extracted for {filename}")
        else:
            print(f"    [WARN] Could not extract fix for {filename}, skipping")

    return fixes

def git_commit(message):
    subprocess.run(["git", "add", "."], cwd=ROOT_DIR, capture_output=True)
    subprocess.run(["git", "commit", "-m", message], cwd=ROOT_DIR, capture_output=True)
    subprocess.run(["git", "push", "origin", "main"], cwd=ROOT_DIR, capture_output=True)
    print(f"  [GIT] Committed: {message}")

def main():
    parser = argparse.ArgumentParser(description="DeepSeek Auto-Fix Loop")
    parser.add_argument("--max-iterations", type=int, default=5, help="Max fix iterations")
    parser.add_argument("--skip-tests", action="store_true", help="Skip flutter test")
    parser.add_argument("--no-commit", action="store_true", help="Skip git commit")
    args = parser.parse_args()

    key = get_key()
    client = OpenAI(api_key=key, base_url="https://api.deepseek.com/v1")

    print("=" * 60)
    print("DeepSeek Auto-Fix Loop")
    print("=" * 60)

    for iteration in range(1, args.max_iterations + 1):
        print(f"\n[Iteration {iteration}/{args.max_iterations}]")

        # Step 1: Analyze
        print("  Running: flutter analyze...")
        code, output = run_analyze()
        if code == 0:
            print("  [CLEAN] flutter analyze: No issues found!")
            break

        print(f"  [ISSUES] analyze returned exit code {code}")
        errors = parse_errors(output)
        error_only = [e for e in errors if e["severity"] == "error"]
        warnings    = [e for e in errors if e["severity"] == "warning"]
        print(f"  Found: {len(error_only)} error(s), {len(warnings)} warning(s)")

        if not errors:
            print("  [CLEAN] No parseable errors found. May be info-only.")
            break

        # Step 2: Fix with DeepSeek
        fixes = fix_errors_with_deepseek(client, errors, output)
        if not fixes:
            print("  [STUCK] DeepSeek could not generate fixes. Manual intervention needed.")
            break

        # Step 3: Apply fixes
        for filepath, content in fixes.items():
            write_file(filepath, content)
            print(f"  [APPLIED] {os.path.basename(filepath)}")

    # Step 4: Run tests
    if not args.skip_tests:
        print("\n  Running: flutter test...")
        test_code, test_out = run_tests()
        if test_code == 0:
            print("  [PASS] All tests passed!")
        else:
            print("  [FAIL] Some tests failed:")
            for line in test_out.split("\n"):
                if "FAIL" in line or "Error" in line or "Exception" in line:
                    print(f"    {line}")

    # Step 5: Final analyze check
    print("\n  Final analyze check...")
    final_code, final_out = run_analyze()
    if final_code == 0:
        print("  [CLEAN] No issues found!")
        if not args.no_commit:
            git_commit("DeepSeek autofix: clean build")
    else:
        print("  [WARN] Issues remain after max iterations.")
        print(final_out[-800:])

    print("\nDone.")

if __name__ == "__main__":
    main()
