import os
import sys
import re
from openai import OpenAI

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEEPSEEK_KEY_FILE = os.path.join(ROOT_DIR, "deepseek api")
TARGET_FILE = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "screens", "game_setup_screen.dart")

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

    print("Reading game_setup_screen.dart...")
    with open(TARGET_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    print("Querying DeepSeek to refactor the routing block...")
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com/v1")
    
    prompt = f"""
    Here is a Flutter screen file:
    ```dart
    {content}
    ```
    
    Please refactor the Navigator.push block (lines 295-311 in the original file) so that:
    1. It imports '../agora_video_header.dart' at the top of the file if needed.
    2. The route body wraps both `AgoraVideoHeader(channelName: 'family-daayakattai-room')` and `DaayakattaiBoard(...)` in a `Column` inside a `SafeArea`.
    3. The AppBar has a custom back button or exit button so the user can easily leave the match.
    
    Return the COMPLETE refactored file content inside a single code block. Do not truncate the file.
    """

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": "You are a professional Flutter engineer. Rewrite the requested file fully with the routing changes. Output only the complete code inside a single code block."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1
        )
        
        output = response.choices[0].message.content
        # Extract content between ```dart and ```
        code_match = re.search(r"```dart\n(.*?)\n```", output, re.DOTALL)
        if not code_match:
            code_match = re.search(r"```\n(.*?)\n```", output, re.DOTALL)
            
        if code_match:
            new_code = code_match.group(1)
            with open(TARGET_FILE, "w", encoding="utf-8") as f:
                f.write(new_code)
            print("Successfully updated game_setup_screen.dart using DeepSeek!")
        else:
            print("Failed to extract code block from DeepSeek response.")
            print(output)
    except Exception as e:
        print(f"DeepSeek call failed: {e}")

if __name__ == "__main__":
    main()
