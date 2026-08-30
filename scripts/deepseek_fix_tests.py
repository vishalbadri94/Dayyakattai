"""
DeepSeek Test Fix Agent
========================
Reads failing test files, diagnoses failures, and writes corrected versions.

Failures to fix:
1. ENGINE TEST: outerIndex returns 8 not 5 — debugSetupPiece uses outerSteps relative
   to player's startOuterIndex, not absolute. Need absolute outer index 5 for Player 0
   who starts at index 3, so outerSteps should be 2 (3+2=5). OR test expectation is wrong.
2. STORAGE TEST: MissingPluginException for flutter_secure_storage write on two tests —
   the mock binary messenger was set up for 'read' but not 'write'. Need to handle 'write'
   in the mock handler too.
"""
import os
import sys
import re
from openai import OpenAI

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEEPSEEK_KEY_FILE = os.path.join(ROOT_DIR, "deepseek api")
ENGINE_TEST  = os.path.join(ROOT_DIR, "daayakattai_app", "test", "daayakattai_engine_test.dart")
STORAGE_TEST = os.path.join(ROOT_DIR, "daayakattai_app", "test", "daayakattai_storage_test.dart")
ENGINE_FILE  = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_engine.dart")

def get_deepseek_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    if os.path.exists(DEEPSEEK_KEY_FILE):
        with open(DEEPSEEK_KEY_FILE, "r") as f:
            return f.read().strip()
    return None

def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def write_file(path, content):
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def extract_code(output):
    match = re.search(r"```dart\n(.*?)\n```", output, re.DOTALL | re.IGNORECASE)
    if match:
        return match.group(1)
    match2 = re.search(r"```\n(.*?)\n```", output, re.DOTALL)
    if match2:
        return match2.group(1)
    return None

def fix_with_deepseek(client, description, file_content, engine_context, output_path):
    prompt = """
Fix the following failing Dart test file.

FAILURE DESCRIPTION:
[DESC]

ENGINE SOURCE (for context on outerIndex computation):
```dart
[ENGINE]
```

CURRENT TEST FILE:
```dart
[TEST]
```

Fix the tests so they pass correctly. Return the COMPLETE corrected test file in a single ```dart code block.
""".replace("[DESC]", description).replace("[ENGINE]", engine_context[:4000]).replace("[TEST]", file_content)

    print(f"  Querying DeepSeek to fix: {os.path.basename(output_path)}...")
    response = client.chat.completions.create(
        model="deepseek-chat",
        messages=[
            {"role": "system", "content": "You are a Flutter/Dart testing expert. Fix the test file and return the complete corrected version in a ```dart code block."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.1
    )
    code = extract_code(response.choices[0].message.content)
    if code:
        write_file(output_path, code)
        print(f"  Fixed and written: {os.path.basename(output_path)}")
        return True
    else:
        print(f"  Failed to extract code from DeepSeek response.")
        safe_output = response.choices[0].message.content.encode("ascii", errors="ignore").decode("ascii")
        print(safe_output[:500])
        return False

def main():
    api_key = get_deepseek_key()
    if not api_key:
        print("ERROR: DeepSeek API key not found.")
        sys.exit(1)

    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com/v1")
    engine_src = read_file(ENGINE_FILE)

    # Fix 1: Engine test - Jodu blocking outerIndex mismatch
    engine_desc = """
Test 'Pairs (Jodu) Blocking' FAILS:
  Expected: <5>
  Actual: <8>

Root cause: Player 0's startOuterIndex is 3 (Board.startOuterIndices[0] = 3).
When debugSetupPiece sets outerSteps=5, the outerIndex is calculated as:
  (startOuterIndex + outerSteps) % outerLength = (3 + 5) % 24 = 8

So the piece is actually at outer index 8, not 5.
Fix: Either change outerSteps so the piece lands at absolute index 5,
meaning outerSteps = (5 - startOuterIndex + outerLength) % outerLength = (5-3+24)%24 = 2.
OR update the expectation to check outerIndex == 8.
Also fix canLandOn test accordingly — Player 1 starts at index 9, so their piece
at outerSteps=0 is at absolute index 9, not 0.

For the Jodu block to work, we want Player 1's piece to be right behind or able to
land exactly on the Jodu pair. Restructure the test to be valid and correct.
"""
    engine_test_content = read_file(ENGINE_TEST)
    fix_with_deepseek(client, engine_desc, engine_test_content, engine_src, ENGINE_TEST)

    # Fix 2: Storage test - MissingPluginException for 'write'
    storage_desc = """
Tests FAIL with: MissingPluginException(No implementation found for method write
on channel plugins.it_nomads.com/flutter_secure_storage)

Root cause: The setUpAll mock binary messenger only handles 'read' method calls.
The 'write' and 'delete' methods are not mocked, so they throw MissingPluginException.

Fix: In setUpAll(), expand the mock TestDefaultBinaryMessengerBinding handler
to also return a success response (empty ByteData or null) for 'write' and 'delete' methods.
Use a switch on method name in the handler, returning null for write/delete (which signals success
in flutter_secure_storage's protocol) and returning encoded empty string for read.
"""
    storage_test_content = read_file(STORAGE_TEST)
    fix_with_deepseek(client, storage_desc, storage_test_content, engine_src[:1000], STORAGE_TEST)

    print("\nDeepSeek test fixes complete. Run: flutter test --reporter expanded")

if __name__ == "__main__":
    main()
