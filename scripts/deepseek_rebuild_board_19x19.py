"""
DeepSeek Board Rebuilder (V3)
==============================
Focuses purely on translating daayakattai_board.dart to use the 19x19 layout:
- const int _gridSize = 19
- Unused corners: size 8x8 (row < 8 && col < 8, etc.)
- Safe cell coloring: gates, tips, center, and inner path cells
- Base slots and offsets adjusted to fit the new 8x8 base quadrants.
"""
import os, sys, re
from openai import OpenAI

ROOT_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE   = os.path.join(ROOT_DIR, "deepseek api")
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

    print("[DeepSeek-V3] Updating daayakattai_board.dart visual geometry...")
    board_content = read(BOARD)

    prompt = f"""
We have updated the engine to a 19x19 Chaupat structure.
Now we need to update the custom painter and math in `daayakattai_board.dart` to match:
1. `_gridSize` is 19.
2. `DaayakattaiBoardGeometry.isUnusedCorner(row, col)`:
   - Returns true if the cell falls in the 8x8 corner areas:
     - Top-Left: row < 8 && col < 8
     - Top-Right: row < 8 && col > 10
     - Bottom-Left: row > 10 && col < 8
     - Bottom-Right: row > 10 && col > 10
3. `DaayakattaiBoardGeometry.isSafeCrossCell(row, col)`:
   - Returns true if the cell is:
     - Tip of West arm: (9, 0)
     - Tip of East arm: (9, 18)
     - Tip of North arm: (0, 9)
     - Tip of South arm: (18, 9)
     - Gates: West (9, 7), East (9, 11), North (7, 9), South (11, 9)
     - Inner path cells (all cells from gates to center):
       - North inner: col 9, row 1 to 7
       - South inner: col 9, row 11 to 17
       - West inner: row 9, col 1 to 7
       - East inner: row 9, col 11 to 17
4. `homePieceOffset`:
   - Start row/col bases for the 4 players should sit inside the 8x8 corner areas:
     - Red (Top-Left): start row 3, col 3
     - Blue (Top-Right): start row 3, col 13
     - Green (Bottom-Right): start row 13, col 13
     - Yellow (Bottom-Left): start row 13, col 3
5. `_drawGridCells`:
   - Grid cells should be painted on the 19x19 matrix.
   - Center HOME is 3x3 block: rows 8, 9, 10 and cols 8, 9, 10.
   - Safe cells should have a lotus painted in them.
   - Paint diagonal divisions on the 3x3 HOME area.

Here is the original `daayakattai_board.dart`:
{board_content}

Rewrite the file for 19x19. Make sure all original State classes, variables, event callbacks, imports, and audio triggers remain exactly identical.
Return only the complete Dart file in a ```dart code block.
"""

    resp = client.chat.completions.create(
        model="deepseek-chat",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.1
    )
    
    code = extract(resp.choices[0].message.content)
    if code:
        write(BOARD, code)
        print("  [OK] 19x19 Board updated successfully.")
    else:
        print("  [FAIL] Failed to extract from code blocks. Writing raw content to board_raw.txt...")
        write(os.path.join(ROOT_DIR, "board_raw.txt"), resp.choices[0].message.content)
        sys.exit(1)

if __name__ == "__main__":
    main()
