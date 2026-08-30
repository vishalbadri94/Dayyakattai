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

    print("Querying DeepSeek to wire audio service triggers into board UI...")
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com/v1")
    
    prompt = f"""
    Here is the Flutter board UI code:
    ```dart
    {content}
    ```
    
    Please refactor this file to integrate the `DaayakattaiAudioService` (defined in 'services/daayakattai_audio_service.dart'):
    1. Import `import 'services/daayakattai_audio_service.dart';` at the top.
    2. In `initState()`, initialize the audio service with `DaayakattaiAudioService().init();` and trigger `speakTurn` for the starting player.
    3. In `_rollDice()`, trigger `speakRoll(roll.value)` upon rolling dice, and `speakForfeit()` if three consecutive bonus rolls forfeit triggers.
    4. In `_handleMoveStatus()`, capture the `TurnResult` from `_game.applyMove(...)`. If `result.cutPieces.isNotEmpty`, trigger `speakCut()`. If `result.turnEnded` is true and game is not over, trigger `speakTurn(...)` for the next player name.
    5. In `_handleGameFinished()`, trigger `speakVictory(...)` celebrating the winning team ID.
    
    Output the COMPLETE updated file. Do not truncate the file.
    """

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
        code_match = re.search(r"```dart\n(.*?)\n```", output, re.DOTALL)
        if not code_match:
            code_match = re.search(r"```\n(.*?)\n```", output, re.DOTALL)
            
        if code_match:
            new_code = code_match.group(1)
            with open(TARGET_FILE, "w", encoding="utf-8") as f:
                f.write(new_code)
            print("Successfully wired Audio triggers in daayakattai_board.dart using DeepSeek!")
        else:
            print("Failed to extract code block from DeepSeek response.")
            print(output)
    except Exception as e:
        print(f"DeepSeek call failed: {e}")

if __name__ == "__main__":
    main()
