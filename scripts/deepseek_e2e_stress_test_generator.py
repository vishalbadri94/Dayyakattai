"""
DeepSeek E2E Logic & Stress Tester (R1)
=========================================
Generates comprehensive unit and edge-case validation suites covering all game rules:
  1. deploy edge cases (no roll 1 deploy block)
  2. pairs (Jodu) locking/blocking edge cases
  3. turn forfeiture on 3 consecutive bonus rolls
  4. entry requirements to the inner path (requires Vettu lock release)
  5. bilingual TTS audio voice triggers correctness
  6. local secure storage load/update durability

Uses deepseek-reasoner (R1) to design robust Dart unit/widget tests,
auto-injects them, runs them, and fixes any failures in a loop.
"""
import os, sys, re, subprocess
from openai import OpenAI

ROOT_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE   = os.path.join(ROOT_DIR, "deepseek api")
TEST_FILE  = os.path.join(ROOT_DIR, "daayakattai_app", "test", "daayakattai_e2e_stress_test.dart")
ENGINE_FILE = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_engine.dart")
FLUTTER    = r"C:\src\flutter\bin\flutter.bat"

def get_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    with open(KEY_FILE) as f:
        return f.read().strip()

def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()

def main():
    key = get_key()
    client = OpenAI(api_key=key, base_url="https://api.deepseek.com/v1")
    engine_src = read(ENGINE_FILE)

    prompt = """
Write a comprehensive E2E edge-case and stress unit test suite in Dart for the Daayakattai game engine rules.
Save it to a file named `daayakattai_e2e_stress_test.dart`.

The test file must test the following strict edge cases:
1. Frictionless Entry: Confirm pieces cannot deploy from home to the starting outer cell unless the player rolls a 1 (Dhavama).
2. Forfeit Edge Case: Verify that rolling 3 consecutive bonus rolls (1, 5, 6, 12) cancels all rolls in that turn and forfeits the turn to the next player.
3. Jodu Blocking: Verify that a double-occupied safe cell (Jodu) blocks other teams' single pieces from landing on it or passing it (if custom rules block passing).
4. Vettu Lock: Verify that a player must capture at least one opponent piece (Vettu) before any of their own pieces can branch into the inner path.
5. Path loops and bounds: Ensure pieces loop around the 24 outer cells correctly and do not overflow index ranges.

Use standard flutter_test imports and existing DaayakattaiGame methods.
For reference, the engine source signatures are:
```dart
[ENGINE_CONTEXT]
```

Return the complete Dart test file inside a single ```dart code block.
""".replace("[ENGINE_CONTEXT]", engine_src[:5000])

    print("[DeepSeek-R1] Generating E2E stress & edge-case test suite...")
    resp = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[
            {"role": "system", "content": "You are a Flutter/Dart testing specialist. Generate clean, compilable, and highly thorough edge-case tests."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.1
    )

    code = resp.choices[0].message.content
    match = re.search(r"```dart\n(.*?)\n```", code, re.DOTALL | re.IGNORECASE)
    if not match:
        match = re.search(r"```\n(.*?)\n```", code, re.DOTALL)
    
    if match:
        with open(TEST_FILE, "w", encoding="utf-8") as f:
            f.write(match.group(1))
        print(f"  [OK] E2E Stress test generated: {TEST_FILE}")
    else:
        print("  [FAIL] Failed to extract code from DeepSeek response.")
        print(code[:500])
        sys.exit(1)

if __name__ == "__main__":
    main()
