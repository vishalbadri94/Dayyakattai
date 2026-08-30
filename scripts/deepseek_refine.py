import os
import sys
from openai import OpenAI

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEEPSEEK_KEY_FILE = os.path.join(ROOT_DIR, "deepseek api")
TARGET_FILE = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "services", "daayakattai_storage_service.dart")

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

    if not os.path.exists(TARGET_FILE):
        print(f"Error: Target file {TARGET_FILE} not found.")
        sys.exit(1)

    print("Reading daayakattai_storage_service.dart...")
    with open(TARGET_FILE, "r", encoding="utf-8") as f:
        code_content = f.read()

    print("Querying DeepSeek for performance and clean code audit...")
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com/v1")
    
    prompt = f"""
    Please audit the following Dart secure storage service code for performance, memory leaks, and safety.
    Provide a concise list of suggestions or code optimizations:
    
    ```dart
    {code_content}
    ```
    """

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": "You are an expert Flutter/Dart code auditor specializing in clean code and memory performance."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.2
        )
        print("\n=== DeepSeek Audit Report ===")
        print(response.choices[0].message.content)
    except Exception as e:
        print(f"DeepSeek call failed: {e}")

if __name__ == "__main__":
    main()
