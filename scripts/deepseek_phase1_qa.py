"""
DeepSeek Phase 1 QA Agent (R1)
================================
Tests Phase 1 implementation quality:
  1.1 - Bilingual TTS (Tamil + English)
  1.2 - Animated Dice Widget
  1.3 - WhatsApp Share Service

Uses deepseek-reasoner (R1) for thorough logic tracing.
Writes report to docs/deepseek_phase1_qa_report.md
"""
import os, sys, re
from openai import OpenAI

ROOT_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE   = os.path.join(ROOT_DIR, "deepseek api")
LIB_DIR    = os.path.join(ROOT_DIR, "daayakattai_app", "lib")
REPORT     = os.path.join(ROOT_DIR, "docs", "deepseek_phase1_qa_report.md")

FILES = {
    "audio_service":   os.path.join(LIB_DIR, "services", "daayakattai_audio_service.dart"),
    "dice_widget":     os.path.join(LIB_DIR, "widgets",  "dice_animation_widget.dart"),
    "share_service":   os.path.join(LIB_DIR, "services", "daayakattai_share_service.dart"),
    "board":           os.path.join(LIB_DIR, "daayakattai_board.dart"),
    "storage_service": os.path.join(LIB_DIR, "services", "daayakattai_storage_service.dart"),
}

def get_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    with open(KEY_FILE) as f:
        return f.read().strip()

def read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except:
        return "[not found]"

def main():
    key    = get_key()
    client = OpenAI(api_key=key, base_url="https://api.deepseek.com/v1")

    print("[Phase 1 QA] DeepSeek-R1 reviewing Phase 1 implementation...")

    sources = {k: read(v)[:3000] for k, v in FILES.items()}

    prompt = """
You are a senior QA engineer. Trace the code and produce a structured Markdown test report
for Phase 1 of the Daayakattai Flutter game app.

=== Phase 1 Features to Test ===

SCENARIO 1.1a - Tamil TTS: Roll Announcement
  Does `speakRoll(6)` produce the correct Tamil phrase 'தாயம் ஆறு'?
  Does `speakRoll(1)` produce 'தாயம் ஒன்று' (or equivalent)?
  Is `flutter_tts` language set to 'ta-IN' when Language.tamil is selected?

SCENARIO 1.1b - English TTS: Roll Announcement
  Does `speakRoll(6)` produce 'You rolled 6' in English mode?
  Is `flutter_tts` language set to 'en-US' when Language.english is selected?

SCENARIO 1.1c - Language Toggle Persistence
  When the TML/ENG button is tapped, does it:
    a) Call `DaayakattaiAudioService.setLanguage(...)`?
    b) Call `DaayakattaiStorageService.saveLanguage(...)`?
    c) Update `_selectedLanguage` state?
  On restart, does `initState()` restore the saved language?

SCENARIO 1.1d - TTS Board Event Wiring
  Is `speakRoll()` called in `_rollDice()`?
  Is `speakForfeit()` called on 3-strike forfeit?
  Is `speakCut()` called when `result.cutPieces.isNotEmpty`?
  Is `speakVictory()` called when `_game.isGameOver`?
  Is `speakTurn()` called on turn change?

SCENARIO 1.2a - Dice Animation Widget
  Does `DiceAnimationWidget` accept `rollValue` and `isRolling` parameters?
  Does it use `AnimationController` + `CustomPainter` for the animation?
  Does it show the correct face combination for roll values 1, 5, 6, 12?
  Does it show Tamil text labels for bonus values (1, 5, 6, 12)?
  Is `dart:async` imported for `Timer`?

SCENARIO 1.2b - Dice Widget Board Integration
  Is `DiceAnimationWidget` embedded in the board's build() method?
  Is it placed above the Roll Dice button?
  Does it receive `_game.currentRoll?.value ?? 0`?

SCENARIO 1.3a - Share Service
  Does `shareGameInvite()` generate Tamil message when `language == 'tamil'`?
  Does `shareGameInvite()` generate English message when `language == 'english'`?
  Does the message include channelName, gameMode, hostName, and appLink?
  Does `generateChannelName()` return a 6-char code starting with 'DAY'?

SCENARIO 1.3b - Share Board Integration
  Is a share `IconButton` (Icons.share) in the board header?
  Does tapping it call `DaayakattaiShareService.shareGameInvite(...)`?
  Does it pass `_selectedLanguage` to determine language?

=== Source Files ===

AUDIO SERVICE:
[AUDIO]

DICE WIDGET:
[DICE]

SHARE SERVICE:
[SHARE]

BOARD (header + initState + rollDice + handleMoveStatus sections):
[BOARD]

STORAGE SERVICE:
[STORAGE]

Produce a Markdown report with:
1. Summary table (Scenario | Status | Notes)
2. Detailed findings per scenario
3. Bugs/recommendations list
""".replace("[AUDIO]", sources["audio_service"])\
   .replace("[DICE]", sources["dice_widget"])\
   .replace("[SHARE]", sources["share_service"])\
   .replace("[BOARD]", sources["board"][:4000])\
   .replace("[STORAGE]", sources["storage_service"][:2000])

    print("  [DeepSeek-R1] Querying (this may take 60-90s)...")
    resp = client.chat.completions.create(
        model="deepseek-reasoner",
        messages=[
            {"role": "system", "content": "You are a senior QA engineer. Produce a thorough Markdown test report."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.0,
        max_tokens=4000,
    )
    report = resp.choices[0].message.content

    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    with open(REPORT, "w", encoding="utf-8") as f:
        f.write("# DeepSeek Phase 1 QA Report\n\n")
        f.write(report)

    print(f"\n[DONE] Report written: {REPORT}")
    # Print summary table lines
    in_table = False
    for line in report.split("\n")[:40]:
        if "|" in line:
            in_table = True
        if in_table:
            safe = line.encode("ascii", errors="replace").decode("ascii")
            print(safe)
        if in_table and line.strip() == "":
            break

if __name__ == "__main__":
    main()
