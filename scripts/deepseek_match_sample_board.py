"""
DeepSeek Premium Board Rebuild Agent (R1)
===========================================
Rebuilds the engine and custom painter to match the user's reference board:
- Layout: 19x19 coordinate space.
- 4 arms: 3 columns wide x 8 rows long.
- Center: 3x3 HOME square, divided diagonally into 4 triangles.
- Safe cells (Malai / X):
  - Arm tips (middle column, row 8 of each arm).
  - Gate cells (2 cells flanking the arm entrance where it joins the center).
- Corner labels: Gold Tamil text ("தாயம்" / "விளையாட்டு").
- Wood texture paint for background.
"""
import os, sys, re
from openai import OpenAI

ROOT_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE   = os.path.join(ROOT_DIR, "deepseek api")
ENGINE     = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_engine.dart")
BOARD      = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_board.dart")

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

    # 1. Update Game Engine (R1)
    print("[1/2] DeepSeek-R1: Rebuilding Engine for 19x19 Cruciform board (3x8 arms, 3x3 center)...")
    engine_prompt = """
Rewrite `daayakattai_engine.dart` to support the Chaupat layout from the reference image:
- Board is defined on a 19x19 coordinate grid.
- Central HOME is the 3x3 area from x=8..10, y=8..10 (0-indexed).
- The 4 arms are:
  - North: x=8..10, y=0..7
  - South: x=8..10, y=11..18
  - West: x=0..7, y=8..10
  - East: x=11..18, y=8..10
- The outer loop is 24 cells perimeter walking path (or custom loop corresponding to outer track).
- Safe cells (Malai):
  - Arm tips: (9, 0), (18, 9), (9, 18), (0, 9).
  - Gate cells where players start.
- Ensure all public API classes (BoardCoordinate, Board, Piece, Player, DaayakattaiGame, Move) maintain identical names and constructor signatures so existing test suites and storage services compile.

CURRENT ENGINE:
[ENGINE]

Generate the revised `daayakattai_engine.dart`.
Return only the complete Dart file in a ```dart code block.
""".replace("[ENGINE]", read(ENGINE)[:6000])

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

    # 2. Update Board Painter (R1)
    print("\n[2/2] DeepSeek-R1: Rebuilding Board Painter to draw the polished wooden board...")
    board_prompt = """
Rebuild `daayakattai_board.dart` to match the polished wooden board in the reference image:
- Background: Polished wood finish texture (teak/walnut wood gradient color with golden inlay border).
- Central 3x3 HOME: Draw diagonal division lines forming 4 triangles pointing to the arms.
- Arms: Draw 3x8 arms. Draw colored safe cells (Purple, Green, Red, Blue) with dark 'X' lines.
- Labels: Add gold Tamil corner labels: "தாயம்" (top-left) and "விளையாட்டு" (top-right).
- Tokens: Draw them as shiny, round, glass marbles (Red/Orange, Blue, Green, Black).
- Align touch gestures to the 19x19 grid coordinates.

CURRENT BOARD:
[BOARD]

Generate the updated `daayakattai_board.dart` file. Keep all existing event/interaction/sound/settings code exactly intact.
Return only the complete Dart file in a ```dart code block.
""".replace("[BOARD]", read(BOARD)[:6000])

    resp2 = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[{"role": "user", "content": board_prompt}],
        temperature=0.1
    )
    code2 = extract(resp2.choices[0].message.content)
    if code2:
        write(BOARD, code2)
        print("  [OK] Board painter updated.")
    else:
        print("  [FAIL] Board painter update parsing failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
