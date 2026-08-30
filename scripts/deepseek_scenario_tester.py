import os
import sys
import re
from openai import OpenAI

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEEPSEEK_KEY_FILE = os.path.join(ROOT_DIR, "deepseek api")
TARGET_FILE = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_board.dart")

def get_deepseek_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ.get("DEEPSEEK_API_KEY")
    if os.path.exists(DEEPSEEK_KEY_FILE):
        with open(DEEPSEEK_KEY_FILE, "r") as f:
            return f.read().strip()
    return None

def main():
    api_key = get_deepseek_key()
    if not api_key:
        print("Error: DeepSeek API Key not found.")
        sys.exit(1)

    print("Reading daayakattai_board.dart...")
    with open(TARGET_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    print("Querying DeepSeek to inject Scenario Tester Panel and debug command overlay...")
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com/v1")
    
    prompt = """
    Here is the board UI code for our Daayakattai game:
    ```dart
    [BOARD_CODE]
    ```
    
    Please refactor this file to inject a "Scenario Tester Panel" (accessible via a small bug/build icon button in the header row next to the Reset button).
    The Scenario Tester Panel should be a dialog or an overlay containing buttons to trigger these prebuilt testing scenarios:
    
    1. **"Forfeit Forfeiture" (3-Strike Scenario)**:
       - Resets the game to 2 Players.
       - Artificially triggers 2 bonus rolls (adds 12 and 1 to pending rolls, sets game consecutive bonus count to 2, and sets needsRoll to true).
       - Shows a snackbar: "Scenario: Roll once more to trigger 3-strike forfeit!"
       
    2. **"Jodu Block" (Pairs Blocking Scenario)**:
       - Resets the game to 4 Players (2v2).
       - Sets Player 0 pieces 0 and 1 onto outer index 5 (forming a Jodu/pair on unsafe cell).
       - Sets Player 1 piece 0 onto outer index 3 (behind them).
       - Adds a pending roll of [2] to the game.
       - Sets currentPlayerIndex to 1 (Player 1's turn).
       - Sets needsRoll to false (so they can immediately try moving the piece).
       - Shows a snackbar: "Scenario: Try moving Player 2's piece onto the Player 1 pair at cell 5 (blocked!)."
       
    3. **"Vettu Lock" (Vettu Entry Blocked Scenario)**:
       - Resets the game to 2 Players.
       - Sets Player 0 piece 0 onto outer index Board.outerLength (at starting gate).
       - Player 0 has no vettu (hasVettu = false).
       - Adds a pending roll of [3] to the game.
       - Sets currentPlayerIndex to 0.
       - Sets needsRoll to false.
       - Shows a snackbar: "Scenario: Try entering the inner track without making a capture (blocked!)."
       
    4. **"Vettu Unlock" (Inner Track Access Scenario)**:
       - Resets the game to 2 Players.
       - Sets Player 0 piece 0 onto outer index Board.outerLength (at starting gate).
       - Manually sets player 0's hasVettu to true (we can add a public setter `setVettu(bool)` in Player or a debug method in game, or update it via debug setup helper).
       - Adds a pending roll of [3] to the game.
       - Sets currentPlayerIndex to 0.
       - Sets needsRoll to false.
       - Shows a snackbar: "Scenario: Try entering inner track after capture (Allowed!)."
       
    Note: To support modifying Player hasVettu and adding custom pending rolls directly, make sure to add these debug setups cleanly.
    In `daayakattai_engine.dart` we have:
    `void debugSetupPiece(int playerId, int pieceId, PieceState state, {int outerSteps = 0, int innerIndex = 0})`
    We can add any needed minor setters there, or write them directly inside the scenario triggers if they are already accessible.
    
    Output the COMPLETE updated file. Do not truncate the file.
    """.replace("[BOARD_CODE]", content)

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": "You are a professional Flutter engineer. Output only the complete updated file code inside a single ```dart code block."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1
        )
        
        output = response.choices[0].message.content
        
        # Robust code block extraction
        new_code = ""
        code_match = re.search(r"```dart\n(.*?)\n```", output, re.DOTALL | re.IGNORECASE)
        if code_match:
            new_code = code_match.group(1)
        else:
            code_match2 = re.search(r"```\n(.*?)\n```", output, re.DOTALL | re.IGNORECASE)
            if code_match2:
                new_code = code_match2.group(1)
            elif "import " in output or "class " in output:
                new_code = output  # fallback if raw code was output directly
                
        if new_code:
            with open(TARGET_FILE, "w", encoding="utf-8") as f:
                f.write(new_code)
            print("Successfully injected Scenario Tester in daayakattai_board.dart using DeepSeek!")
        else:
            print("Failed to extract code block from DeepSeek response.")
            # Safe print unicode outputs without crash
            print(output.encode("ascii", errors="ignore").decode("ascii"))
    except Exception as e:
        # Safe print errors
        err_msg = str(e).encode("ascii", errors="ignore").decode("ascii")
        print(f"DeepSeek call failed: {err_msg}")

if __name__ == "__main__":
    main()
