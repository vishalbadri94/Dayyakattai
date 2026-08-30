"""
DeepSeek Build Agent — Phase 1.2 + 1.3
========================================
1.2: Animated Dice Widget (4 sticks, CustomPainter flip animation)
1.3: WhatsApp Game Sharing (share_plus + invite link)

Model: deepseek-chat (V3) — UI generation tasks
"""
import os, sys, re
from openai import OpenAI

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE = os.path.join(ROOT_DIR, "deepseek api")
LIB_DIR  = os.path.join(ROOT_DIR, "daayakattai_app", "lib")
PUBSPEC  = os.path.join(ROOT_DIR, "daayakattai_app", "pubspec.yaml")
BOARD    = os.path.join(LIB_DIR, "daayakattai_board.dart")
DICE_FILE    = os.path.join(LIB_DIR, "widgets", "dice_animation_widget.dart")
SHARE_FILE   = os.path.join(LIB_DIR, "services", "daayakattai_share_service.dart")

def get_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    if os.path.exists(KEY_FILE):
        with open(KEY_FILE, "r") as f:
            return f.read().strip()
    return None

def read(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def extract(text):
    m = re.search(r"```dart\n(.*?)\n```", text, re.DOTALL | re.IGNORECASE)
    if m: return m.group(1)
    m = re.search(r"```\n(.*?)\n```", text, re.DOTALL)
    if m: return m.group(1)
    return None

def call_ds(client, model, system, user, max_tokens=4096):
    print(f"  [DeepSeek {model}] querying...")
    r = client.chat.completions.create(
        model=model,
        messages=[{"role":"system","content":system},{"role":"user","content":user}],
        temperature=0.1,
        max_tokens=max_tokens,
    )
    return r.choices[0].message.content

def main():
    key = get_key()
    if not key: print("ERROR: No API key."); sys.exit(1)
    client = OpenAI(api_key=key, base_url="https://api.deepseek.com/v1")

    # -------------------------------------------------------------------------
    # PHASE 1.2 — Animated Dice Widget
    # -------------------------------------------------------------------------
    print("\n[Phase 1.2] DeepSeek-V3: Generating DiceAnimationWidget...")
    dice_prompt = """
Create a Flutter widget file: `dice_animation_widget.dart`.

The widget is `DiceAnimationWidget` — a beautiful animated dice for the
Daayakattai (Tamil board game) that shows 4 stick-style dice being thrown.

Requirements:
1. StatefulWidget that accepts:
   - `int rollValue` (1-12, the final dice result)
   - `bool isRolling` (true = show animation, false = show result)
   - `VoidCallback? onAnimationComplete`

2. Use `AnimationController` (duration: 800ms) + `CustomPainter` to draw:
   - 4 rectangular sticks arranged in a 2x2 grid
   - Each stick is a rounded rectangle, dark brown `Color(0xFF3B1A1A)`
   - The "white" face (marked side) is shown in ivory `Color(0xFFF1E4C4)`
   - The "dark" face (blank) is dark `Color(0xFF2B0A0A)`
   - During animation: each stick randomly flips between white/dark every 80ms
   - After animation: show the correct face combination for the `rollValue`:
     * 12 = all 4 blank (0 white faces)
     * 1  = 1 white face
     * 2  = 2 white faces
     * 3  = 3 white faces
     * 4  = 4 white faces (impossible in standard set, use visual indicator)
     * 5  = all blank with gold dot in center (special)
     * 6  = all white
   - Surround each stick with a thin gold `Color(0xFFD9A843)` border

3. Show the numeric value below the sticks in Tamil:
   - 1 → "1 - தாயம்" (gold, bold 18sp)
   - 5 → "5 - வைகல்" (gold, bold 18sp)
   - 6 → "6 - ஆறு" (gold, bold 18sp)
   - 12 → "12 - பன்னிரண்டு" (gold, bold 18sp)
   - Others → just the number in white

4. If `isRolling` is true, show a pulsing "Rolling..." text in gold instead.

5. Widget size: 160x160dp.

6. Use `dart:math` Random for the animation flip states.

Output the COMPLETE file in a single ```dart code block.
No external dependencies beyond flutter/material.dart and dart:math.
"""
    result = call_ds(client, "deepseek-chat",
        "You are a Flutter expert. Output only the complete Dart file in a ```dart code block.",
        dice_prompt, max_tokens=3500)
    code = extract(result)
    if code:
        write(DICE_FILE, code)
        print("  [OK] DiceAnimationWidget created:", DICE_FILE)
    else:
        print("  [FAIL] Could not extract DiceAnimationWidget code")
        print(result.encode("ascii","ignore").decode("ascii")[:300])

    # -------------------------------------------------------------------------
    # PHASE 1.3 — WhatsApp Share Service
    # -------------------------------------------------------------------------
    print("\n[Phase 1.3] DeepSeek-V3: Generating DaayakattaiShareService...")
    share_prompt = """
Create a Flutter service file: `daayakattai_share_service.dart`

The service handles sharing game invites via WhatsApp and other apps.

Requirements:
1. Class `DaayakattaiShareService` with static methods only.

2. `static Future<void> shareGameInvite({required String channelName, required String gameMode, required String hostName, required String language})`:
   - If `language == 'tamil'`:
     Message = "வணக்கம்! [hostName] உங்களை Daayakattai விளையாட்டிற்கு அழைக்கிறார். விளையாட்டு: [gameMode]. சேர குறியீடு: [channelName]. பதிவிறக்கம்: [appLink]"
   - If `language == 'english'`:
     Message = "Hi! [hostName] invites you to play Daayakattai. Mode: [gameMode]. Join code: [channelName]. Download: [appLink]"
   - `appLink` = "https://daayakattai.app/join/[channelName]"
   - Use the `share_plus` package: `Share.share(message, subject: 'Daayakattai Invite')`

3. `static Future<void> shareMatchResult({required int winnerTeamId, required String gameMode, required String language})`:
   - Tamil: "Daayakattai - குழு [winnerTeamId] வெற்றி பெற்றது! விளையாட்டு: [gameMode]. நீங்களும் விளையாடுங்கள்: https://daayakattai.app"
   - English: "Daayakattai - Team [winnerTeamId] wins! Mode: [gameMode]. Play now: https://daayakattai.app"
   - Use `Share.share(message)`

4. `static String generateChannelName()`:
   - Returns a random 6-character alphanumeric code e.g. "DAY4K2"
   - Prefix always "DAY" + 3 random uppercase alphanumeric chars

5. Imports needed:
   - `package:share_plus/share_plus.dart`
   - `dart:math`

Output the COMPLETE file in a single ```dart code block.
"""
    result2 = call_ds(client, "deepseek-chat",
        "You are a Flutter expert. Output only the complete Dart file in a ```dart code block.",
        share_prompt, max_tokens=2000)
    code2 = extract(result2)
    if code2:
        write(SHARE_FILE, code2)
        print("  [OK] DaayakattaiShareService created:", SHARE_FILE)
    else:
        print("  [FAIL] Could not extract ShareService code")
        print(result2.encode("ascii","ignore").decode("ascii")[:300])

    # -------------------------------------------------------------------------
    # Add share_plus to pubspec.yaml
    # -------------------------------------------------------------------------
    print("\n[Pubspec] Adding share_plus dependency...")
    pubspec = read(PUBSPEC)
    if "share_plus" not in pubspec:
        pubspec = pubspec.replace(
            "  flutter_secure_storage:",
            "  share_plus: ^10.1.4\n  flutter_secure_storage:"
        )
        write(PUBSPEC, pubspec)
        print("  [OK] share_plus added to pubspec.yaml")
    else:
        print("  [SKIP] share_plus already in pubspec.yaml")

    # -------------------------------------------------------------------------
    # Wire DiceAnimationWidget + share button into board header
    # -------------------------------------------------------------------------
    print("\n[Phase 1.2+1.3] DeepSeek-V3: Generating board integration patches...")
    board_src = read(BOARD)

    patch_prompt = f"""
Given the following board file header (first 4000 chars):
```dart
{board_src[:4000]}
```

Generate a JSON object (not Dart code) with exactly these fields:
{{
  "dice_import": "the import line to add for the DiceAnimationWidget",
  "share_import": "the import line to add for DaayakattaiShareService",
  "share_button_code": "a single IconButton widget (Icon: Icons.share, gold color) that calls DaayakattaiShareService.shareGameInvite(channelName: 'DAY000', gameMode: _modeLabel(_currentMode), hostName: 'Host', language: _selectedLanguage == Language.tamil ? 'tamil' : 'english')"
}}

Output ONLY valid JSON. No markdown, no explanation.
"""
    patch_result = call_ds(client, "deepseek-chat",
        "Output only valid JSON with the fields requested. No markdown.",
        patch_prompt, max_tokens=500)

    import json
    try:
        # Strip any accidental markdown
        clean = re.sub(r"```[a-z]*\n?", "", patch_result).strip()
        patch = json.loads(clean)
        dice_import  = patch.get("dice_import", "import 'widgets/dice_animation_widget.dart';")
        share_import = patch.get("share_import", "import 'services/daayakattai_share_service.dart';")
        share_btn    = patch.get("share_button_code",
            "IconButton(icon: const Icon(Icons.share, color: Color(0xFFD9A843)), onPressed: () => DaayakattaiShareService.shareGameInvite(channelName: DaayakattaiShareService.generateChannelName(), gameMode: _modeLabel(_currentMode), hostName: 'Host', language: _selectedLanguage == Language.tamil ? 'tamil' : 'english'),)")
    except Exception:
        dice_import  = "import 'widgets/dice_animation_widget.dart';"
        share_import = "import 'services/daayakattai_share_service.dart';"
        share_btn    = "IconButton(icon: const Icon(Icons.share, color: Color(0xFFD9A843)), onPressed: () => DaayakattaiShareService.shareGameInvite(channelName: DaayakattaiShareService.generateChannelName(), gameMode: _modeLabel(_currentMode), hostName: 'Host', language: _selectedLanguage == Language.tamil ? 'tamil' : 'english'),)"

    # Inject imports
    new_board = board_src
    if "dice_animation_widget" not in new_board:
        new_board = new_board.replace(
            "import 'services/daayakattai_audio_service.dart';",
            "import 'services/daayakattai_audio_service.dart';\n" + dice_import + "\n" + share_import
        )

    # Inject share button before the existing TML toggle
    if "Icons.share" not in new_board:
        new_board = new_board.replace(
            "// Language toggle: TML <=> ENG",
            share_btn + ",\n            // Language toggle: TML <=> ENG"
        )
        if "Icons.share" not in new_board:
            # fallback: inject before the language GestureDetector
            new_board = new_board.replace(
                "// Language toggle: TML",
                share_btn + ",\n            const SizedBox(width: 4),\n            // Language toggle: TML"
            )

    write(BOARD, new_board)
    print("  [OK] Board patched with dice import + share button")

    print("\n[Phase 1.2 + 1.3 Complete]")
    print("  Run: flutter pub get && flutter analyze")

if __name__ == "__main__":
    main()
