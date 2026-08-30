"""
DeepSeek Build Agent — Restore Board build() method
=====================================================
Reads the current board file and asks DeepSeek to restore the missing
build() method and any other methods that reference _rollDice, _resetGame,
_handleTapUp which are declared but not referenced (likely referenced inside build).
"""
import os
import sys
import re
from openai import OpenAI

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEEPSEEK_KEY_FILE = os.path.join(ROOT_DIR, "deepseek api")
TARGET_FILE = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_board.dart")

def get_deepseek_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    if os.path.exists(DEEPSEEK_KEY_FILE):
        with open(DEEPSEEK_KEY_FILE, "r") as f:
            return f.read().strip()
    return None

def main():
    api_key = get_deepseek_key()
    if not api_key:
        print("ERROR: DeepSeek API key not found.")
        sys.exit(1)

    with open(TARGET_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    print("Querying DeepSeek to restore missing build() method...")
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com/v1")

    prompt = """
The following Flutter Dart file is missing its `build(BuildContext context)` method in the
`_DaayakattaiBoardState` class. The class also has private methods declared but unused,
which means they are called from inside the missing build() method:
  - `_resetGame()`
  - `_rollDice()`
  - `_handleTapUp(TapUpDetails)`
  - `_showScenarioTester()`

Please generate ONLY the `@override Widget build(BuildContext context)` method body
that should be inserted into the `_DaayakattaiBoardState` class BEFORE `dispose()`.

The board widget should:
1. Wrap everything in a `Column` with a dark red background `Color(0xFF2B0A0A)`.
2. A top header `Row` containing:
   - A `Text` showing "🎲 Daayakattai" in gold `Color(0xFFD9A843)`, bold, size 20.
   - A `Spacer()`.
   - A small icon button with `Icons.bug_report` (gold) that calls `_showScenarioTester()`.
   - A small icon button with `Icons.refresh` (gold) that calls `_resetGame()`.
3. A `Row` showing current player info: "Player [n] 🎯 Roll: [last roll]" in white text size 16.
4. An `Expanded` widget containing a `GestureDetector` with `onTapUp: _handleTapUp` wrapping
   a `RepaintBoundary` > `CustomPaint` with a `DaayakattaiBoardPainter` (or the appropriate painter).
5. A bottom `Row` with a large ElevatedButton in gold that calls `_rollDice()` and shows
   "தாயம் எறி / Roll Dice", disabled if `!_game.needsRoll`.

Note: `_game.currentPlayer` returns the current `Player`. `_game.needsRoll` is a bool.
`_game.pendingRolls` returns a list of `DiceRoll`. Use `_boardKey` for the board `RepaintBoundary`.

Current file for context (look for the existing painter/CustomPaint usage to match style):
[CONTENT]

Output ONLY the `@override Widget build(BuildContext context)` method, inside a ```dart code block.
Do not output the entire file. Just the build method.
""".replace("[CONTENT]", content[:8000])  # trim to avoid token overflow

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": "You are a Flutter expert. Output ONLY the build() method inside a ```dart code block."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1,
        )
        output = response.choices[0].message.content
        code_match = re.search(r"```dart\n(.*?)\n```", output, re.DOTALL | re.IGNORECASE)
        if not code_match:
            code_match = re.search(r"```\n(.*?)\n```", output, re.DOTALL)

        if code_match:
            build_method = code_match.group(1)
            print("DeepSeek returned build method. Injecting before dispose()...")

            # Find the insertion point — just before the first dispose() method
            insert_marker = "  @override\n  void dispose()"
            if insert_marker not in content:
                # Try CRLF variant
                insert_marker = "  @override\r\n  void dispose()"

            if insert_marker in content:
                new_content = content.replace(
                    insert_marker,
                    build_method.strip() + "\n\n" + insert_marker,
                    1
                )
                with open(TARGET_FILE, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print("Successfully restored build() method in daayakattai_board.dart!")
            else:
                print("Could not find dispose() insertion point.")
                print(build_method.encode("ascii", errors="ignore").decode("ascii"))
        else:
            print("Failed to extract build() method from DeepSeek response.")
            print(output.encode("ascii", errors="ignore").decode("ascii"))
    except Exception as e:
        err = str(e).encode("ascii", errors="ignore").decode("ascii")
        print(f"DeepSeek call failed: {err}")

if __name__ == "__main__":
    main()
