"""
DeepSeek-R1 Premium Geometry Redesigner
=========================================
Uses deepseek-reasoner to rewrite daayakattai_board.dart.
Focuses on:
- Grid sizing: rendering the 8x8 corner bases as wooden blocks (instead of skipping them).
- Spec layout matching: warm teak wood background, dark borders, and drop shadows.
- Realistic glass marbles in recessed pockets.
- Elongated wooden dice sticks over the center.
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

    print("[DeepSeek-R1] Generating premium visual rendering updates...")
    board_content = read(BOARD)

    prompt = f"""
The game board visual quality in `daayakattai_board.dart` is poor. It looks small, and the empty corner spaces make the board look thin and squashed compared to the premium reference image.

Here is the current code:
{board_content}

We need to rewrite `daayakattai_board.dart` to make the board look exceptionally premium, matching the description:
1. Layout Sizing:
   - The board should occupy the maximum square space on the screen.
   - The four 8x8 corner areas (unused corners) should NOT be left blank. Paint them as beautiful raised wooden blocks/platforms with a dark engraved border and a thin gold inner frame.
   - Inside each 8x8 corner platform, draw four subtle circular recessed pockets (cup holders) where the starting glass marbles rest.
2. Materials & Colors:
   - Board Background: Medium-dark natural wood finish with fine dark horizontal grain lines.
   - Playing Grid: Muted natural light wood cells (e.g. Color(0xFFF0E3C4)) with dark engraved outlines.
   - Accents: Muted Red, Green, Blue, and Orange/Yellow.
   - Safe Cells: Draw a prominent thick colored X (Red, Green, Blue, Orange depending on arm) stretching across the cell.
   - Center (3x3 HOME): Divided diagonally into 4 triangles with fine engraved lines, and a decorative circular emblem in the middle.
   - Dice Sticks: Draw two elongated beveled wooden dice sticks with engraved circular pips lying over the center finishing area.
3. Marbles:
   - Smooth 3D radial-shaded marbles with drop-shadows and bright specular light highlights on top.

Keep the core game logic, state management, imports, classes, and constructor signatures exactly identical so that the game compiles cleanly.
Return only the complete Dart file in a ```dart code block.
"""

    resp = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[{"role": "user", "content": prompt}]
    )
    
    code = extract(resp.choices[0].message.content)
    if code:
        write(BOARD, code)
        print("  [OK] Premium custom painter updated.")
    else:
        print("  [FAIL] Failed to extract from code blocks. Writing raw content to board_raw.txt...")
        write(os.path.join(ROOT_DIR, "board_raw.txt"), resp.choices[0].message.content)
        sys.exit(1)

if __name__ == "__main__":
    main()
