"""
DeepSeek 19x19 Surgical Geometry Rebuilder (V3)
================================================
Updates the engine track coordinates to a 19x19 grid size:
- Outer perimeter track is 72 cells.
- Center is 3x3 (rows 8, 9, 10).
- Malai (safe cells) are located at tips, gates, and inner paths.
- Keeping API signatures identical to avoid compile errors.
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

    print("[DeepSeek-V3] Rebuilding daayakattai_engine.dart outerTrack and innerPaths for 19x19 grid...")
    
    engine_content = read(ENGINE)
    board_content = read(BOARD)

    prompt = f"""
We are updating the Dayyakattai board size to a 19x19 grid (Chaupat structure).
Arms are 8 cells long and 3 columns wide.
Center HOME is rows 8, 9, 10 and cols 8, 9, 10.

Here is the original engine code:
{engine_content}

Please rewrite `daayakattai_engine.dart` to change the grid coordinates to 19x19.
Key changes:
- `Board.outerLength` must be 72.
- `Board.outerTrack` should walk the perimeter clockwise around the 19x19 cross:
  - North left edge: from (7, 8) up to (0, 8)
  - North tip: (0, 8) -> (0, 9) -> (0, 10)
  - North right edge: (0, 10) down to (7, 10)
  - East top edge: from (8, 11) right to (8, 18)
  - East tip: (8, 18) -> (9, 18) -> (10, 18)
  - East bottom edge: (10, 18) left to (10, 11)
  - South right edge: from (11, 10) down to (18, 10)
  - South tip: (18, 10) -> (18, 9) -> (18, 8)
  - South left edge: (18, 8) up to (11, 8)
  - West bottom edge: from (10, 7) left to (10, 0)
  - West tip: (10, 0) -> (9, 0) -> (8, 0)
  - West top edge: (8, 0) right to (8, 7)
  (Total: 72 coordinates)
- `Board.startOuterIndices` should correspond to the indices of the entry/gate cells on the outer track for the 4 players:
  - Top player entry (North gate): (7, 9) or (7, 8). Let's trace where the gates are.
  - Top gate: (7, 9)
  - Right gate: (9, 11)
  - Bottom gate: (11, 9)
  - Left gate: (9, 7)
- `Board.innerPaths` should go from the gate to the center (length 9 cells):
  - Top player: (0, 9) down to (8, 9)
  - Right player: (9, 18) left to (9, 10)
  - Bottom player: (18, 9) up to (10, 9)
  - Left player: (9, 0) right to (9, 8)
- `Board.malaiCells` must include the arm tips, starting gates, and inner path cells.

Ensure the classes (BoardCoordinate, Board, DiceRoll, PieceState, Piece, DaayakattaiGame, etc.) and enums (GameMode) are intact and signatures are identical to original code. Do not remove any existing public methods or fields.
Return only the complete Dart file in a ```dart code block.
"""

    resp = client.chat.completions.create(
        model="deepseek-chat",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.1
    )
    
    code = extract(resp.choices[0].message.content)
    if code:
        write(ENGINE, code)
        print("  [OK] 19x19 Engine updated.")
    else:
        print("  [FAIL] Failed to update 19x19 Engine.")
        sys.exit(1)

    print("[DeepSeek-V3] Rebuilding daayakattai_board.dart for 19x19 grid custom painter...")
    # Now let's update board.dart's gridSize and helper geometries
    board_prompt = f"""
We have updated `daayakattai_engine.dart` to support a 19x19 grid.
Now, we need to update the custom painter in `daayakattai_board.dart` to draw cells on a 19x19 layout.

Here is the original `daayakattai_board.dart`:
{board_content}

Please rewrite `daayakattai_board.dart` to change:
- `_gridSize` to 19.
- `DaayakattaiBoardGeometry.isUnusedCorner(row, col)`: corners are size 8x8 (row < 8 && col < 8, row < 8 && col > 10, etc.).
- `DaayakattaiBoardGeometry.isSafeCrossCell(row, col)`: safe cells are tip, center, gates, and inner paths.
- Update `homePieceOffset` to position the start bases in the 8x8 corner areas.
- Update `_drawGridCells` to paint the 19x19 grid, leaving the 3x3 center HOME area as diagonal divisions.
- Keep all other widget structures, state variables, imports, and audio triggers intact.
Return only the complete Dart file in a ```dart code block.
"""

    resp2 = client.chat.completions.create(
        model="deepseek-chat",
        messages=[{"role": "user", "content": board_prompt}],
        temperature=0.1
    )
    
    code2 = extract(resp2.choices[0].message.content)
    if code2:
        write(BOARD, code2)
        print("  [OK] 19x19 Board custom painter updated.")
    else:
        print("  [FAIL] Failed to update 19x19 Board.")
        sys.exit(1)

if __name__ == "__main__":
    main()
