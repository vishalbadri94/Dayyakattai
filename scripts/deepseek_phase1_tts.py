"""
DeepSeek Build Agent — Phase 1.1
=================================
Step 1: Upgrade DaayakattaiAudioService to support both Tamil and English,
        with a runtime-selectable language preference.
Step 2: Update DaayakattaiStorageService to persist the language preference.
Step 3: Wire audio service calls into daayakattai_board.dart game events.
Step 4: Add language toggle to the Stats/Settings area and board header.

All code generation delegated to DeepSeek-V3.
"""
import os
import sys
import re
from openai import OpenAI

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEEPSEEK_KEY_FILE = os.path.join(ROOT_DIR, "deepseek api")

AUDIO_FILE   = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "services", "daayakattai_audio_service.dart")
STORAGE_FILE = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "services", "daayakattai_storage_service.dart")
BOARD_FILE   = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_board.dart")

def get_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    if os.path.exists(DEEPSEEK_KEY_FILE):
        with open(DEEPSEEK_KEY_FILE, "r") as f:
            return f.read().strip()
    return None

def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def write_file(path, content):
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def extract_code(text):
    m = re.search(r"```dart\n(.*?)\n```", text, re.DOTALL | re.IGNORECASE)
    if m: return m.group(1)
    m2 = re.search(r"```\n(.*?)\n```", text, re.DOTALL)
    if m2: return m2.group(1)
    return None

def deepseek(client, system_msg, user_msg):
    resp = client.chat.completions.create(
        model="deepseek-chat",
        messages=[
            {"role": "system", "content": system_msg},
            {"role": "user", "content": user_msg}
        ],
        temperature=0.1,
        max_tokens=6000,
    )
    return resp.choices[0].message.content

def main():
    key = get_key()
    if not key:
        print("ERROR: DeepSeek API key not found."); sys.exit(1)

    client = OpenAI(api_key=key, base_url="https://api.deepseek.com/v1")

    # ── STEP 1: Bilingual Audio Service ──────────────────────────────────────
    print("\n[Step 1] DeepSeek: Upgrading audio service to bilingual (Tamil + English)...")
    audio_src = read_file(AUDIO_FILE)

    audio_prompt = """
Upgrade the following DaayakattaiAudioService to support BOTH Tamil and English:

CURRENT FILE:
```dart
[AUDIO]
```

Requirements:
1. Add a `Language` enum: `enum Language { tamil, english }`
2. Add a static settable property: `static Language language = Language.tamil;`
3. Add a static `Future<void> setLanguage(Language lang)` that:
   - Sets `language = lang`
   - Calls `_flutterTts.setLanguage(lang == Language.tamil ? 'ta-IN' : 'en-US')`
4. Add English text constants alongside Tamil ones. Specifically:
   - `speakRoll(int value)`:
     - Tamil: 'தாயம் [tamilNumber]'  (e.g. 'தாயம் ஆறு' for 6)
     - English: 'You rolled [value]' (e.g. 'You rolled 6')
   - `speakTurn(String playerName)`:
     - Tamil: '[playerName], உங்கள் முறை'
     - English: '[playerName], your turn'
   - `speakCut()`:
     - Tamil: 'வெட்டு! காய் வெட்டப்பட்டது!'
     - English: 'Cut! Pawn captured!'
   - `speakForfeit()`:
     - Tamil: 'மூன்று முறை தாயம்! வாய்ப்பு இழந்தது.'
     - English: 'Three bonus rolls! Turn forfeited.'
   - `speakVictory(int teamId)`:
     - Tamil: 'வெற்றி! குழு [teamId] வெற்றி பெற்றது!'
     - English: 'Victory! Team [teamId] wins!'
5. Keep all existing init/dispose/stop logic intact.
6. Import: `package:flutter/foundation.dart` is already imported.

Output the COMPLETE updated file in a single ```dart code block.
""".replace("[AUDIO]", audio_src)

    result = deepseek(client,
        "You are a Flutter expert. Output the complete updated file in a ```dart code block.",
        audio_prompt)
    code = extract_code(result)
    if code:
        write_file(AUDIO_FILE, code)
        print("  [OK] Audio service upgraded (bilingual)")
    else:
        print("  [FAIL] Failed to extract audio service code")
        print(result.encode("ascii", errors="ignore").decode("ascii")[:400])
        sys.exit(1)

    # ── STEP 2: Persist language preference in storage ──────────────────────
    print("\n[Step 2] DeepSeek: Adding language preference to storage service...")
    storage_src = read_file(STORAGE_FILE)

    storage_prompt = """
Add language preference persistence to the following storage service:

CURRENT FILE:
```dart
[STORAGE]
```

Requirements:
1. Add a new static const key: `static const String _keyLanguage = 'daayakattai_language';`
2. Add `static Future<String> getLanguage()` that reads from storage,
   returns 'tamil' by default if not set.
3. Add `static Future<void> saveLanguage(String lang)` that writes the value.
4. These methods follow the same error-handling pattern as the existing CRUD methods.

Output the COMPLETE updated file in a single ```dart code block.
""".replace("[STORAGE]", storage_src)

    result2 = deepseek(client,
        "You are a Flutter expert. Output the complete updated file in a ```dart code block.",
        storage_prompt)
    code2 = extract_code(result2)
    if code2:
        write_file(STORAGE_FILE, code2)
        print("  [OK] Language preference persistence added to storage")
    else:
        print("  [FAIL] Failed to extract storage code")

    # ── STEP 3: Wire audio into board events ─────────────────────────────────
    print("\n[Step 3] DeepSeek: Wiring bilingual audio into board events...")
    board_src = read_file(BOARD_FILE)

    board_prompt = """
Wire the DaayakattaiAudioService into the following board file:

CURRENT FILE:
```dart
[BOARD]
```

Requirements:
1. Add import: `import 'services/daayakattai_audio_service.dart';`
   (if not already present)
2. In `initState()`, after setting up animations, call:
   `DaayakattaiAudioService().init();`
3. In `_rollDice()`, after rolling the dice and updating state:
   - Call `DaayakattaiAudioService().speakRoll(roll.value);`
   - If forfeit triggered (consecutiveBonusCount == 0 after roll with grantsExtra),
     also call `DaayakattaiAudioService().speakForfeit();`
4. In `_handleMoveStatus()` (the AnimationStatus.completed branch),
   after applying the move:
   - If result has cut pieces: `DaayakattaiAudioService().speakCut();`
   - If game is over: `DaayakattaiAudioService().speakVictory(_game.winningTeamId ?? 0);`
   - Else if turn ended: `DaayakattaiAudioService().speakTurn(_game.currentPlayer.id.toString());`
5. Add a language toggle IconButton in the build() header row next to the bug icon:
   - Shows 'TML' text if current language is tamil, 'ENG' if english.
   - On tap: toggles between Tamil/English by calling
     `DaayakattaiAudioService.setLanguage(...)` and saving via
     `DaayakattaiStorageService.saveLanguage(...)`.
   - Store the selected language in a `Language _selectedLanguage` state field,
     initialized from `DaayakattaiStorageService.getLanguage()` in `initState()`.

Output the COMPLETE updated file. Do NOT truncate.
""".replace("[BOARD]", board_src[:12000])

    result3 = deepseek(client,
        "You are a Flutter expert. Output only the complete updated file in a ```dart code block. Do not truncate.",
        board_prompt)
    code3 = extract_code(result3)
    if code3:
        write_file(BOARD_FILE, code3)
        print("  [OK] Audio wired into board events with language toggle")
    else:
        print("  [FAIL] Failed to extract board code -- will patch manually")
        print(result3.encode("ascii", errors="ignore").decode("ascii")[:400])

    print("\n[Phase 1.1 Complete] All DeepSeek steps done. Run: flutter analyze")

if __name__ == "__main__":
    main()
