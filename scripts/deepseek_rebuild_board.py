"""
DeepSeek Cruciform Rebuild Agent (R1)
=====================================
Rebuilds the engine and board to use the 4-arm cruciform Chaupat-style board:
  - North, South, East, West arms: 3 columns x 8 rows.
  - Center square: HOME (முற்றம்).
  - Walk loop: walking around the perimeter of the cross.
  - Safe zones (Malai): marked with 'X' in custom painter.

Rebuilds dice widget to display two spinning brass prism stick dice.
"""
import os, sys, re
from openai import OpenAI

ROOT_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE   = os.path.join(ROOT_DIR, "deepseek api")
ENGINE     = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_engine.dart")
BOARD      = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_board.dart")
DICE       = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "widgets", "dice_animation_widget.dart")

def get_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    with open(KEY_FILE) as f:
        return f.read().strip()

def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()

def write(path, content):
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def extract(text):
    m = re.search(r"```dart\n(.*?)\n```", text, re.DOTALL | re.IGNORECASE)
    if m: return m.group(1)
    m = re.search(r"```\n(.*?)\n```", text, re.DOTALL)
    if m: return m.group(1)
    return None

def main():
    key = get_key()
    client = OpenAI(api_key=key, base_url="https://api.deepseek.com/v1")

    # 1. Update Game Engine Coordinate Math (R1)
    print("[1/3] DeepSeek-R1: Rebuilding Game Engine with Cruciform Board loop math...")
    engine_prompt = """
Rewrite the coordinate, path mapping, and loop math in `daayakattai_engine.dart` to support a Chaupat cruciform board.

BOARD GEOMETRY:
- The board has a central 3x3-sized square called HOME (coordinate 3,3 to 5,5).
- 4 arms (North, South, East, West) extend from the center. Each arm is 3 columns wide and 8 rows long.
- Outer perimeter track: walking around the outer boundary of the arms (total 24 cells, or custom walk path).
  Let's define a clean 24-cell outer loop around the perimeter.
- Safe cells (Malai): The middle cell of the end of each arm, and the corner intersections.
- Players start at their designated arm's outer gate cell, loop around the outer track, and then branch into their arm's center column (the inner path) to reach the HOME center.

CURRENT ENGINE FILE:
[ENGINE]

Generate the revised `daayakattai_engine.dart` code. Ensure all constructors, properties, and methods match the public API exactly to prevent compile failures, but replace grid math with cross coordinates.
Return only the complete Dart file in a ```dart code block.
""".replace("[ENGINE]", read(ENGINE)[:6000]) # first part is enough for context

    resp = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[{"role": "user", "content": engine_prompt}],
        temperature=0.1
    )
    code = extract(resp.choices[0].message.content)
    if code:
        write(ENGINE, code)
        print("  [OK] Engine rebuilt.")
    else:
        print("  [FAIL] Engine parsing failed.")
        sys.exit(1)

    # 2. Update Board UI Painter (R1)
    print("\n[2/3] DeepSeek-R1: Rebuilding Custom Board Painter for Cruciform layout...")
    board_prompt = """
Rebuild `daayakattai_board.dart` to draw the Chaupat cruciform board:
- Center: HOME square (marked 'HOME' / 'முற்றம்').
- 4 arms extending out. Draw borders only for the active cells of the cross, leaving the empty spaces at corners blank (or dark background).
- Safe cells: Draw a clean X pattern in red or gold inside malai cells.
- Maintain all existing event listeners, gestures, audio services, settings toggle buttons, and scenario tester hooks.

CURRENT BOARD FILE:
[BOARD]

Generate the updated `daayakattai_board.dart` code. Return only the complete Dart file in a ```dart code block.
""".replace("[BOARD]", read(BOARD)[:6000])

    resp2 = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[{"role": "user", "content": board_prompt}],
        temperature=0.1
    )
    code2 = extract(resp2.choices[0].message.content)
    if code2:
        write(BOARD, code2)
        print("  [OK] Board UI rebuilt.")
    else:
        print("  [FAIL] Board UI parsing failed.")
        sys.exit(1)

    # 3. Update Dice Animation to render Brass Sticks (V3)
    print("\n[3/3] DeepSeek-V3: Upgrading Dice Widget to Brass Stick Dice...")
    dice_prompt = """
Rewrite `dice_animation_widget.dart` to draw **two long brass rectangular stick dice (Thayam / தாயக்கட்டை)**:
- Arrangement: Two horizontal/vertical bars with realistic metal gradient (gold/brass).
- Spin: Rotate, flip, or scale them to simulate rolling brass bars.
- Render marked dots on the visible faces based on final roll values.

CURRENT WIDGET FILE:
[DICE]

Generate the updated `dice_animation_widget.dart` code. Return only the complete Dart file in a ```dart code block.
""".replace("[DICE]", read(DICE))

    resp3 = client.chat.completions.create(
        model="deepseek-chat",
        messages=[{"role": "user", "content": dice_prompt}],
        temperature=0.1
    )
    code3 = extract(resp3.choices[0].message.content)
    if code3:
        write(DICE, code3)
        print("  [OK] Dice animation rebuilt.")
    else:
        print("  [FAIL] Dice animation parsing failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
