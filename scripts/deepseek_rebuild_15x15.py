"""
DeepSeek 15x15 Geometry Rebuilder (R1)
========================================
Updates engine.dart and board.dart to use the correct 15x15 grid specs:
- Arm length: 6 cells.
- Outer track length: 56 cells.
- Corner bases: 6x6.
- Center HOME: 3x3.
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

    print("[DeepSeek-R1] Rebuilding daayakattai_engine.dart for 15x15 grid...")
    engine_content = read(ENGINE)

    prompt = f"""
The game board has a central 3x3 square (HOME) and four arms extending North, South, East, and West.
Each arm is 3 columns wide and 6 rows long.
Total grid dimension: 6 (arm) + 3 (center) + 6 (arm) = 15x15.

Here is the current engine code:
{engine_content}

Please rewrite `daayakattai_engine.dart` to support this 15x15 Chaupat board.
Track Mapping details:
- `Board.outerLength` must be 56.
- `Board.outerTrack` should walk the perimeter clockwise around the 15x15 cross:
  - North left edge: from (5, 6) up to (0, 6)
  - North tip: (0, 6) -> (0, 7) -> (0, 8)
  - North right edge: (0, 8) down to (5, 8)
  - East top edge: from (6, 9) right to (6, 14)
  - East tip: (6, 14) -> (7, 14) -> (8, 14)
  - East bottom edge: (8, 14) left to (8, 9)
  - South right edge: from (9, 8) down to (14, 8)
  - South tip: (14, 8) -> (14, 7) -> (14, 6)
  - South left edge: (14, 6) up to (9, 6)
  - West bottom edge: from (8, 5) left to (8, 0)
  - West tip: (8, 0) -> (7, 0) -> (6, 0)
  - West top edge: (6, 0) right to (6, 5)
  (Total: 56 coordinates)
- `Board.startOuterIndices` should correspond to the entry/gate cell indices on the outer track for the 4 players:
  - North gate: (5, 7)
  - East gate: (7, 9)
  - South gate: (9, 7)
  - West gate: (7, 5)
- `Board.innerPaths` should go from the gate to the center (length 7 cells):
  - Top player: (0, 7) down to (6, 7)
  - Right player: (7, 14) left to (7, 8)
  - Bottom player: (14, 7) up to (8, 7)
  - Left player: (7, 0) right to (7, 6)
- `Board.malaiCells` must include tips, gates, and inner paths.

Ensure all class, enum, method, and variable names match the original code perfectly.
Return only the complete Dart file in a ```dart code block.
"""

    resp = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[{"role": "user", "content": prompt}]
    )
    
    code = extract(resp.choices[0].message.content)
    if code:
        write(ENGINE, code)
        print("  [OK] 15x15 Engine updated.")
    else:
        print("  [FAIL] Failed to update 15x15 Engine.")
        sys.exit(1)

    print("[DeepSeek-R1] Rebuilding daayakattai_board.dart for 15x15 grid...")
    board_content = read(BOARD)

    board_prompt = f"""
We have updated `daayakattai_engine.dart` to support a 15x15 grid.
Now, we need to update the custom painter and geometries in `daayakattai_board.dart` to match:
1. `_gridSize` is 15.
2. `DaayakattaiBoardGeometry.isUnusedCorner(row, col)`: corners are size 6x6 (row < 6 && col < 6, etc.).
3. `DaayakattaiBoardGeometry.isSafeCrossCell(row, col)`: safe cells are tips, gates, and inner path cells.
4. `homePieceOffset`: start bases are at (2,2) for Red, (2,11) for Blue, (11,11) for Green, and (11,2) for Yellow.
5. `_drawGridCells`:
   - Grid cells should be painted on a 15x15 matrix.
   - Center HOME is 3x3 block: rows 6, 7, 8 and cols 6, 7, 8.
   - Flanking junction cells around the center should have colored X marks as shown in the reference image (North-West junction, North-East, South-West, South-East).
   - Ensure the corner platform bases are drawn as nice wooden panels with recessed marble pockets.
   - Sizing should fill the available screen.

Here is the current board code:
{board_content}

Rewrite the file for 15x15. Keep all other widgets, state handlers, audio player connections, and imports identical.
Return only the complete Dart file in a ```dart code block.
"""

    resp2 = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[{"role": "user", "content": board_prompt}]
    )
    
    code2 = extract(resp2.choices[0].message.content)
    if code2:
        write(BOARD, code2)
        print("  [OK] 15x15 Board custom painter updated.")
    else:
        print("  [FAIL] Failed to update 15x15 Board. Writing raw content to board_raw.txt...")
        write(os.path.join(ROOT_DIR, "board_raw.txt"), resp2.choices[0].message.content)
        sys.exit(1)

if __name__ == "__main__":
    main()
