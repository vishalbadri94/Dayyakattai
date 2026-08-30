import os
import sys
from openai import OpenAI

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEEPSEEK_KEY_FILE = os.path.join(ROOT_DIR, "deepseek api")
TARGET_FILE = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "services", "daayakattai_audio_service.dart")

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

    print("Querying DeepSeek to create daayakattai_audio_service.dart...")
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com/v1")
    
    prompt = """
    Create a new Flutter service file `daayakattai_audio_service.dart`.
    The service must use the `flutter_tts` package to speak localized Tamil instructions for the game.
    
    Requirements:
    1. Import `package:flutter_tts/flutter_tts.dart`.
    2. Define a singleton class `DaayakattaiAudioService` with an initializer `Future<void> init()`.
    3. In `init()`, configure the TTS language to 'ta-IN' (Tamil, India), and adjust pitch (1.0) and speech rate (0.45) for clear grandparent-friendly hearing.
    4. Provide the following public voice triggers:
       - `Future<void> speakRoll(int value)`: Translates dice rolls to Tamil (e.g. 1 is 'தாயம்' (Dhayam), 12 is 'பன்னிரண்டு' (Pannirendu), 2 is 'இரண்டு' (Irandu), etc.) and announces them.
       - `Future<void> speakTurn(String playerName)`: Announces player turn in Tamil (e.g. '[Player Name], உங்கள் முறை' (your turn)).
       - `Future<void> speakCut()`: Announces captured pawn in Tamil ('வெட்டு! காய் வெட்டப்பட்டது!' (Capture! Pawn captured!)).
       - `Future<void> speakForfeit()`: Announces 3-strike forfeit in Tamil ('மூன்று முறை தாயம்! வாய்ப்பு இழந்தது.' (Three times Dhayam! Turn forfeited)).
       - `Future<void> speakVictory(int teamId)`: Announces victory celebration in Tamil ('வெற்றி! குழு [teamId] வெற்றி பெற்றது!' (Victory! Team [teamId] won!)).
    5. Implement robust null/exception safety and fallback debug prints if TTS fails or is unsupported.
    
    Output only the complete code inside a single ```dart code block.
    """

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": "You are a professional Flutter engineer. Output only the complete code inside a single ```dart code block."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1
        )
        
        output = response.choices[0].message.content
        import re
        code_match = re.search(r"```dart\n(.*?)\n```", output, re.DOTALL)
        if not code_match:
            code_match = re.search(r"```\n(.*?)\n```", output, re.DOTALL)
            
        if code_match:
            new_code = code_match.group(1)
            os.makedirs(os.path.dirname(TARGET_FILE), exist_ok=True)
            with open(TARGET_FILE, "w", encoding="utf-8") as f:
                f.write(new_code)
            print("Successfully created daayakattai_audio_service.dart using DeepSeek!")
        else:
            print("Failed to extract code block from DeepSeek response.")
            print(output)
    except Exception as e:
        print(f"DeepSeek call failed: {e}")

if __name__ == "__main__":
    main()
