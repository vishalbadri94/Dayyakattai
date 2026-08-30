"""
DeepSeek Logic Test Agent
=========================
Reads the game engine + board source files and asks DeepSeek to act as a
QA engineer — reviewing logic correctness for all key game scenarios.
Results are written to docs/deepseek_logic_test_report.md
"""
import os
import sys
from openai import OpenAI

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEEPSEEK_KEY_FILE = os.path.join(ROOT_DIR, "deepseek api")
ENGINE_FILE  = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_engine.dart")
BOARD_FILE   = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_board.dart")
STORAGE_FILE = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "services", "daayakattai_storage_service.dart")
REPORT_FILE  = os.path.join(ROOT_DIR, "docs", "deepseek_logic_test_report.md")

def get_deepseek_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    if os.path.exists(DEEPSEEK_KEY_FILE):
        with open(DEEPSEEK_KEY_FILE, "r") as f:
            return f.read().strip()
    return None

def read_file(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        return f"[Could not read file: {e}]"

def main():
    api_key = get_deepseek_key()
    if not api_key:
        print("ERROR: DeepSeek API key not found.")
        sys.exit(1)

    engine_code  = read_file(ENGINE_FILE)
    board_code   = read_file(BOARD_FILE)
    storage_code = read_file(STORAGE_FILE)

    print("DeepSeek Logic Test Agent starting...")
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com/v1")

    prompt = """
You are a senior QA engineer specialising in board game logic correctness.

Review the following Dart source files for the Daayakattai (Tamil dice board game) app.
Then provide a structured test report covering the scenarios listed below.
For each scenario, state: PASS / FAIL / PARTIAL, explain the logic flow you traced, and list any bugs found.

=== Daayakattai Rules Reminder ===
- 2 or 4 sticks (Dhayam set). Values 1, 5, 6, 12 grant a bonus roll.
- Three consecutive bonus rolls forfeit the turn (3-strike rule).
- Pawns must deploy from Home with a roll of 1 (Dhayam).
- A pawn can block if it is a Jodu (pair of same player on same cell). Enemy cannot land on Jodu.
- A pawn must make a "Vettu" (cut/capture of an enemy) before entering the inner Pazham track.
- The first team to finish all pawns wins.

=== Scenarios to Test ===

SCENARIO 1 — Basic Deployment
  Does a roll of 1 (Dhayam) correctly allow a home pawn to deploy to the start outer index?
  Does rolling anything other than 1 while all pawns are home result in a skipped turn?

SCENARIO 2 — Bonus Roll Chain
  Does a roll of 5, 6, or 12 grant an additional roll correctly?
  Does rolling 1, 5, 6, or 12 three times consecutively forfeit the turn?

SCENARIO 3 — Jodu Blocking
  If two pawns of the same player occupy the same outer cell, does the engine prevent
  an enemy pawn from landing on that cell?

SCENARIO 4 — Vettu (Capture)
  When an enemy pawn lands on a non-safe (non-Malai) cell occupied by a single friendly pawn,
  does the engine correctly send that pawn home?
  Does a successful capture set hasVettu = true on the capturing player?

SCENARIO 5 — Inner Track Gate (Pazham Entry)
  Can a pawn enter the inner Pazham track without hasVettu?
  Can a pawn enter the inner Pazham track with hasVettu?

SCENARIO 6 — Win Condition
  Does the game correctly detect and declare victory when all of a team's pawns finish?

SCENARIO 7 — Match Statistics Storage
  After logMatch() is called, does the storage service:
    (a) correctly limit history to 100 entries?
    (b) only increment gamesWon for players on the winning team?
    (c) batch profile writes in a single disk write?

=== Source Files ===

--- ENGINE (daayakattai_engine.dart) ---
[ENGINE]

--- BOARD UI (daayakattai_board.dart) ---
[BOARD]

--- STORAGE SERVICE (daayakattai_storage_service.dart) ---
[STORAGE]

Produce a Markdown report with:
1. A summary table (Scenario | Status | Notes)
2. A detailed findings section per scenario
3. A list of bugs/recommendations
""".replace("[ENGINE]", engine_code).replace("[BOARD]", board_code).replace("[STORAGE]", storage_code)

    try:
        print("Querying DeepSeek Logic Test Agent (this may take up to 60s)...")
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": "You are a senior QA engineer. Trace the code logic carefully and produce a structured Markdown test report."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.0,
            max_tokens=4096
        )
        report = response.choices[0].message.content

        os.makedirs(os.path.dirname(REPORT_FILE), exist_ok=True)
        with open(REPORT_FILE, "w", encoding="utf-8") as f:
            f.write("# DeepSeek Logic Test Report\n\n")
            f.write(report)

        print(f"Report written to: {REPORT_FILE}")
        # Print first 60 lines safely
        lines = report.split("\n")[:60]
        for line in lines:
            print(line.encode("ascii", errors="ignore").decode("ascii"))
    except Exception as e:
        err = str(e).encode("ascii", errors="ignore").decode("ascii")
        print(f"DeepSeek call failed: {err}")

if __name__ == "__main__":
    main()
