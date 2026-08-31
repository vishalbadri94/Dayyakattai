"""
DeepSeek Cruciform Visuals Agent (R1)
======================================
Modifies ONLY:
  1. daayakattai_board.dart (DaayakattaiBoardPainter) to:
     - Render the 4-arm cross grid (North, East, South, West)
     - Blank out the 4 corner quadrants (representing the empty space on a Chaupat board)
     - Draw golden safe 'X' shapes on safe malai cells
  2. dice_animation_widget.dart (DiceAnimationWidget) to:
     - Render two long brass prism sticks
     - Perform a 3D horizontal/vertical rotation spin roll animation
"""
import os, sys, re
from openai import OpenAI

ROOT_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE   = os.path.join(ROOT_DIR, "deepseek api")
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

    # 1. Rebuild Board Painter (Cruciform cross layout)
    print("[1/2] DeepSeek-R1: Rebuilding Board CustomPainter to draw a cross-shaped Chaupat board...")
    board_prompt = """
Modify `daayakattai_board.dart` to draw a Chaupat cruciform board shape:
- The board coordinates range from (1,1) to (7,7) (1-indexed).
- The central 3x3 cells (3,3 to 5,5) represent HOME.
- The 4 arms are North: (1..2, 4), East: (4, 6..7), South: (6..7, 4), West: (4, 1..2).
- Wait, the Chaupat outerTrack cells defined in `daayakattai_engine.dart` are:
  North arm: (1,1) to (1,7) is top row? No, outerTrack lists:
    BoardCoordinate(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7)
    BoardCoordinate(2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7)
    BoardCoordinate(7, 6), (7, 5), (7, 4), (7, 3), (7, 2), (7, 1)
    BoardCoordinate(6, 1), (5, 1), (4, 1), (3, 1), (2, 1)
  This is a 7x7 outer square perimeter grid!
  Ah! The 24-cell outer loop represents the boundary of a 7x7 square.
  To draw the cruciform shape:
  - Empty quadrants (where cells should NOT be drawn) are:
    - Top-Left: (1,1) to (2,2)
    - Top-Right: (1,6) to (2,7)
    - Bottom-Left: (6,1) to (7,2)
    - Bottom-Right: (6,6) to (7,7)
  - All other cells form the classic cross (the 4 arms and the central HOME).
  - So in `_drawGridCells`, only paint a cell if it does NOT fall in the empty quadrants!
  - If a cell falls in these empty corner quadrants, skip drawing it (leave background blank).

Let's modify the `_drawGridCells` method in `daayakattai_board.dart` to skip drawing cells in these empty corners:
- Top-left corner: row < 2 && col < 2
- Top-right corner: row < 2 && col > 4
- Bottom-left corner: row > 4 && col < 2
- Bottom-right corner: row > 4 && col > 4
*(Note: standard grid indices in painter are 0 to 6).*

CURRENT BOARD FILE:
[BOARD]

Generate the updated `daayakattai_board.dart` file. Keep all existing event/interaction/sound/settings code exactly intact.
Return only the complete Dart file in a ```dart code block.
""".replace("[BOARD]", read(BOARD)[:6000])

    resp = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[{"role": "user", "content": board_prompt}],
        temperature=0.1
    )
    code = extract(resp.choices[0].message.content)
    if code:
        write(BOARD, code)
        print("  [OK] Board painter updated.")
    else:
        print("  [FAIL] Board painter update parsing failed.")
        sys.exit(1)

    # 2. Rebuild Dice Animation to draw two long brass sticks (V3)
    print("\n[2/2] DeepSeek-V3: Rebuilding Dice animation to draw 2 brass sticks...")
    dice_prompt = """
Modify `dice_animation_widget.dart` to render two long brass sticks:
- Draw two elongated rectangular bars side-by-side using brass gradient colors.
- During animation, rotate and scale the bars to show them rolling.
- Render dots on the faces representing the final roll values.

CURRENT DICE FILE:
[DICE]

Generate the updated `dice_animation_widget.dart` code. Return only the complete Dart file in a ```dart code block.
""".replace("[DICE]", read(DICE))

    resp2 = client.chat.completions.create(
        model="deepseek-chat",
        messages=[{"role": "user", "content": dice_prompt}],
        temperature=0.1
    )
    code2 = extract(resp2.choices[0].message.content)
    if code2:
        write(DICE, code2)
        print("  [OK] Dice widget updated.")
    else:
        print("  [FAIL] Dice widget update parsing failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
