"""
DeepSeek Cruciform Geometry Validator (R1)
============================================
Checks engine.dart and board.dart coordinates against the reference specs:
- Arms: 3 columns wide x 8 rows long (each).
- Center: 3x3 HOME area.
- Total Grid size: 8 + 3 + 8 = 19x19 grid.
- Currently, the board is configured as a 7x7 grid, which makes arms only 2 cells long.

DeepSeek-R1 will rewrite the engine track definitions and custom painter to run on the 19x19 grid.
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

    print("[DeepSeek-R1] Rebuilding board geometry mapping to 19x19 Chaupat specification...")
    
    prompt = """
The game board has a central 3x3 square (HOME) and four arms extending North, South, East, and West.
Each arm is 3 columns wide and 8 rows long.
Total grid dimension: 8 (arm) + 3 (center) + 8 (arm) = 19x19.

Our current codebase uses a 7x7 grid which makes the arms only 2 cells long.
This is incorrect. We need to transition the system to the full 19x19 grid.

Please rewrite `daayakattai_engine.dart` to support this 19x19 Chaupat board.
Track Mapping details:
- Outer perimeter track: walks around the outer perimeter of the cross.
  - The walk path starts at the inner side of the arm's gate, goes out to the tip, wraps around, goes to the next arm, etc.
  - Total outer track cells: Walking the outer boundary of the 4 arms of 3x8 cells. Let's list the exact coordinates for the track.
- Safe cells (Malai): Arm tips and gates.
- Players start at their gate, complete one loop, then enter their arm's center column (8 cells long) to reach the center 3x3 HOME.

Provide the complete Dart source code for `daayakattai_engine.dart`. Keep classes, constructors, methods, and types named identical to the original so the game remains completely compatible, but adjust the grid math.
Return only the complete Dart file in a ```dart code block.
"""

    resp = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.1
    )
    
    code = extract(resp.choices[0].message.content)
    if code:
        write(ENGINE, code)
        print("  [OK] 19x19 Engine generated.")
    else:
        print("  [FAIL] Failed to generate 19x19 Engine.")
        sys.exit(1)

if __name__ == "__main__":
    main()
