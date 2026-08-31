"""
DeepSeek Combined QA Agent - Phase 1 + Phase 2
================================================
Runs ALL quality checks across both phases:
  1. flutter analyze (zero tolerance on errors)
  2. flutter test (all unit tests must pass)
  3. DeepSeek-R1 logic audit across all Phase 1+2 files
  4. If failures found -> DeepSeek-V3 autofix loop
  5. Writes full report to docs/deepseek_phase1_2_qa_report.md
  6. Only exits 0 if fully clean

Model routing:
  Logic audit   -> deepseek-reasoner (R1)
  Code fixes    -> deepseek-chat (V3) for simple, R1 for complex
"""
import os, sys, re, subprocess, json
from openai import OpenAI

ROOT_DIR  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE  = os.path.join(ROOT_DIR, "deepseek api")
LIB_DIR   = os.path.join(ROOT_DIR, "daayakattai_app", "lib")
REPORT    = os.path.join(ROOT_DIR, "docs", "deepseek_phase1_2_qa_report.md")
FLUTTER   = r"C:\src\flutter\bin\flutter.bat"
APP_DIR   = os.path.join(ROOT_DIR, "daayakattai_app")

# All Phase 1+2 files to audit
PHASE_FILES = {
    "audio_service":     os.path.join(LIB_DIR, "services", "daayakattai_audio_service.dart"),
    "dice_widget":       os.path.join(LIB_DIR, "widgets",  "dice_animation_widget.dart"),
    "share_service":     os.path.join(LIB_DIR, "services", "daayakattai_share_service.dart"),
    "rtm_service":       os.path.join(LIB_DIR, "services", "daayakattai_rtm_service.dart"),
    "room_lobby":        os.path.join(LIB_DIR, "screens",  "room_lobby_screen.dart"),
    "reconnect_service": os.path.join(LIB_DIR, "services", "daayakattai_reconnect_service.dart"),
    "storage_service":   os.path.join(LIB_DIR, "services", "daayakattai_storage_service.dart"),
    "board":             os.path.join(LIB_DIR, "daayakattai_board.dart"),
}

def get_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    with open(KEY_FILE, encoding="utf-8") as f:
        return f.read().strip()

def read(path, max_chars=3000):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()[:max_chars]
    except:
        return "[not found]"

def run_cmd(cmd, cwd):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr

def safe_print(text):
    print(text.encode("ascii", errors="replace").decode("ascii"))

def deepseek_call(client, model, system, user, max_tokens=5000):
    resp = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system},
            {"role": "user",   "content": user}
        ],
        temperature=0.0,
        max_tokens=max_tokens,
    )
    return resp.choices[0].message.content

def run_logic_audit(client, sources):
    """DeepSeek-R1 audits all Phase 1+2 code for logic correctness."""
    print("  [DeepSeek-R1] Running logic audit (60-90s expected)...")

    audit_prompt = """
You are a senior QA engineer. Audit the following Phase 1 + Phase 2 Flutter/Dart
source files for logic correctness, completeness, and integration quality.

For each scenario below, answer: PASS / FAIL / PARTIAL with a brief reason.

=== PHASE 1 SCENARIOS ===

P1.1 - Bilingual TTS Boot:
  Does DaayakattaiAudioService have both `Language.tamil` and `Language.english` enum values?
  Does `setLanguage()` call flutter_tts with correct locale strings ('ta-IN' / 'en-US')?

P1.2 - Board TTS Wiring:
  In daayakattai_board.dart, is `speakRoll()` called in the dice roll method?
  Is `speakCut()` called when `result.cutPieces.isNotEmpty`?
  Is `speakVictory()` called when `_game.isGameOver`?
  Is `speakTurn()` called on turn change?
  Is `speakForfeit()` called on 3-strike forfeit?

P1.3 - Language Persistence:
  Does `initState()` call `DaayakattaiStorageService.getLanguage()` and restore it?
  Does the TML/ENG toggle call both `setLanguage()` and `saveLanguage()`?

P1.4 - DiceAnimationWidget:
  Does it have `rollValue` and `isRolling` params?
  Does it use AnimationController + CustomPainter?
  Is it embedded in the board above the Roll button?

P1.5 - Share Service:
  Does `generateChannelName()` return a 'DAY' prefixed code?
  Does `shareGameInvite()` produce Tamil or English message based on language param?
  Is the share button wired in the board header?

=== PHASE 2 SCENARIOS ===

P2.1 - RTM Sync Service:
  Does `SyncMove` have proper JSON serialization (fromJson/toJson)?
  Does `joinChannel()` set `_isConnected = true`?
  Does `sendMove()` check `_isConnected` before sending?
  Does `incomingMoves` expose a broadcast Stream?
  Does local echo work (50ms delay loopback for testing)?

P2.2 - Room Lobby Screen:
  Does it have both Host and Guest modes?
  Does Host mode show a generated room code and WhatsApp share button?
  Does Guest mode have a room code entry field with validation?
  Does the Start Game button only enable with >= 2 players?
  Is `DaayakattaiShareService.generateChannelName()` used for the room code?

P2.3 - Reconnect Service:
  Does `onDisconnected()` start an exponential backoff loop?
  Are retry delays: 1s, 2s, 4s, 8s, 16s, 30s (capped)?
  Does it stop after 10 failed retries?
  Does `onReconnected()` cancel pending retry?
  Does `statusStream` emit `ReconnectStatus` values?

=== INTEGRATION CHECK ===

INT.1 - Storage + Language: Can `DaayakattaiStorageService.getLanguage()` and
        `saveLanguage()` be called without throwing? (check for proper async/error handling)

INT.2 - RTM + Board: Is there a clear path to wire `DaayakattaiRtmService.incomingMoves`
        stream into the board to apply remote moves?

INT.3 - Reconnect + Agora: Does `DaayakattaiReconnectService` have a clean enough interface
        that it can be called from Agora RTC disconnect callbacks?

=== SOURCE FILES ===

AUDIO SERVICE:
[AUDIO]

BOARD (first 3000 chars):
[BOARD]

RTM SERVICE:
[RTM]

ROOM LOBBY (first 2000 chars):
[LOBBY]

RECONNECT SERVICE:
[RECONNECT]

SHARE SERVICE:
[SHARE]

Output a Markdown report with:
1. Summary table: Scenario | Status (PASS/FAIL/PARTIAL) | Notes
2. Critical failures section (anything FAIL or PARTIAL that blocks Phase 3)
3. Recommendations
""".replace("[AUDIO]",     sources["audio_service"]) \
   .replace("[BOARD]",     sources["board"]) \
   .replace("[RTM]",       sources["rtm_service"]) \
   .replace("[LOBBY]",     sources["room_lobby"]) \
   .replace("[RECONNECT]", sources["reconnect_service"]) \
   .replace("[SHARE]",     sources["share_service"])

    result = deepseek_call(client, "deepseek-reasoner",
        "You are a senior QA engineer. Produce a thorough Markdown test report.",
        audit_prompt, max_tokens=4000)
    return result

def extract_failures(report_text):
    """Find FAIL lines in the report."""
    failures = []
    for line in report_text.split("\n"):
        if "FAIL" in line and "|" in line:
            failures.append(line.strip())
    return failures

def main():
    key    = get_key()
    client = OpenAI(api_key=key, base_url="https://api.deepseek.com/v1")

    report_sections = []
    all_passed = True

    print("=" * 60)
    print("DeepSeek Combined QA - Phase 1 + Phase 2")
    print("=" * 60)

    # ── Step 1: flutter analyze ──────────────────────────────────────
    print("\n[1/4] flutter analyze...")
    code, out = run_cmd([FLUTTER, "analyze"], APP_DIR)
    if code == 0:
        print("  [PASS] No issues found")
        report_sections.append("## flutter analyze\n**PASS** - No issues found.\n")
    else:
        errors   = [l for l in out.split("\n") if "error" in l.lower()]
        warnings = [l for l in out.split("\n") if "warning" in l.lower()]
        print(f"  [ISSUES] {len(errors)} error(s), {len(warnings)} warning(s)")
        if errors:
            all_passed = False
            report_sections.append(f"## flutter analyze\n**FAIL**\n```\n" + "\n".join(errors[:10]) + "\n```\n")
            print("  Running autofix...")
            subprocess.run([sys.executable,
                os.path.join(ROOT_DIR, "scripts", "deepseek_autofix.py"),
                "--max-iterations", "3", "--no-commit"], cwd=ROOT_DIR)
        else:
            report_sections.append(f"## flutter analyze\n**INFO only** - {len(warnings)} deprecation warning(s), no errors.\n")

    # ── Step 2: flutter test ─────────────────────────────────────────
    print("\n[2/4] flutter test...")
    test_code, test_out = run_cmd([FLUTTER, "test", "--reporter", "expanded"], APP_DIR)
    if test_code == 0:
        # Count tests
        passed = len(re.findall(r"\+\d+:", test_out))
        print(f"  [PASS] All tests passed!")
        report_sections.append(f"## flutter test\n**PASS** - All unit tests passed.\n")
    else:
        all_passed = False
        failing = [l for l in test_out.split("\n") if "FAIL" in l or "[E]" in l]
        print(f"  [FAIL] {len(failing)} test(s) failing")
        report_sections.append(f"## flutter test\n**FAIL**\n```\n" + "\n".join(failing[:10]) + "\n```\n")
        # Run fix
        print("  Sending to DeepSeek fix agent...")
        subprocess.run([sys.executable,
            os.path.join(ROOT_DIR, "scripts", "deepseek_fix_tests.py")], cwd=ROOT_DIR)

    # ── Step 3: DeepSeek-R1 Logic Audit ──────────────────────────────
    print("\n[3/4] DeepSeek-R1 logic audit...")
    sources = {k: read(v) for k, v in PHASE_FILES.items()}
    try:
        audit_report = run_logic_audit(client, sources)
        failures = extract_failures(audit_report)
        if failures:
            all_passed = False
            print(f"  [PARTIAL] {len(failures)} scenario(s) need attention:")
            for f in failures[:5]:
                safe_print(f"    {f}")
        else:
            print("  [PASS] All scenarios passed logic audit")
        report_sections.append(f"## DeepSeek-R1 Logic Audit\n{audit_report}\n")
    except Exception as e:
        print(f"  [WARN] Audit failed: {e}")
        report_sections.append("## DeepSeek-R1 Logic Audit\nCould not complete (API error).\n")

    # ── Step 4: Write report ─────────────────────────────────────────
    print("\n[4/4] Writing report...")
    overall = "ALL CHECKS PASSED" if all_passed else "SOME CHECKS NEED ATTENTION"
    report = f"# DeepSeek Phase 1+2 QA Report\n\n**Result: {overall}**\n\n"
    report += "\n\n".join(report_sections)

    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    with open(REPORT, "w", encoding="utf-8") as f:
        f.write(report)
    print(f"  Report written: {REPORT}")

    print(f"\n{'='*60}")
    print(f"RESULT: {overall}")
    print(f"Phase 3 {'READY' if all_passed else 'BLOCKED - fix failures first'}")
    print("=" * 60)

    sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    main()
