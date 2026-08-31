"""
DeepSeek Premium Board Painter (V3)
=====================================
Modifies the CustomPainter inside daayakattai_board.dart to replicate the target reference layout exactly:
- Warm medium/dark brown natural wood finish background with visible grain lines.
- Thick raised wooden border/frame around the 4 sides.
- Small brass corner protectors at the outer corners.
- Engraved cells: light natural-wood interior, dark engraved outlines.
- Muted team colors for the home paths and safe gates/tips.
- Large prominent X markings across the safe cells.
- Subtle gold/brown line-carved floral motifs in the bottom corners.
- 3D glossy glass marbles for playing pieces with realistic specular highlights.
- Redefines text style to use a clean Tamil serif overlay.
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

    print("[DeepSeek-V3] Redesigning daayakattai_board.dart painter to match premium wooden specifications...")
    board_content = read(BOARD)

    prompt = f"""
We want to update the visual appearance of the game board in `daayakattai_board.dart` to look exactly like the premium wooden board specification.

Here is the original `daayakattai_board.dart`:
{board_content}

Modify only the visual drawing methods inside `DaayakattaiBoardPainter` and `DaayakattaiBoard` to meet these premium visual details:
1. `_drawRawSilkBackground`:
   - Paint a beautiful, detailed medium-brown wood grain background. You can achieve this by drawing a base wood color, and then drawing subtle darker horizontal/diagonal micro-lines to simulate organic wood grain fibers.
   - Paint a thick, raised wooden frame around the border of the board (e.g. using a dark-brown beveled rect).
   - Draw antique-brass corner brackets at the four corners of the frame.
   - Draw traditional subtle gold line-engraved leaf/floral motifs in the bottom corners of the wooden board area.
2. Tamil Labels:
   - "தாயம்" (top-left) and "விளையாட்டு" (top-right) should look engraved into the wood. Give them a dark brown color with a thin gold/light shadow offset.
3. `_drawGridCells`:
   - The cell tracks should look engraved. Use a light natural-wood interior color (e.g., Color(0xFFF7E7C4)) for the squares, with dark-brown burned borders.
   - Safe cells (with lotuses/crosses) should have large, prominent, color-toned **X** markings stretching from corner to corner. The X lines should look burned/engraved.
   - Central HOME finishing area (3x3): Paint the diagonal divisions with fine engraved lines, and place a small decorative wooden emblem in the center.
4. Pieces (`_drawPieces` or piece rendering method):
   - Render the playing pieces as **glossy 3D marbles** rather than flat markers. Draw a smooth radial gradient representing the team color, overlay a dark drop-shadow below the marble, and paint a bright white offset circle near the top-left edge representing a shiny light highlight reflect.
5. Sizing:
   - Ensure the board expands nicely to fill the screen with clear tap bounds for players to select marbles easily.

Ensure all imports, parameters, engine states, state managers, and click listeners remain identical so the code compiles and E2E tests run perfectly.
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
        print("  [OK] Premium custom painter generated successfully.")
    else:
        print("  [FAIL] Failed to extract from code blocks. Writing raw content to board_raw.txt...")
        write(os.path.join(ROOT_DIR, "board_raw.txt"), resp.choices[0].message.content)
        sys.exit(1)

if __name__ == "__main__":
    main()
