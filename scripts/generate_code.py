import os
import sys
import re
from html.parser import HTMLParser
from openai import OpenAI

class PromptParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_prompt_box = False
        self.current_prompt = []
        self.prompts = []

    def handle_starttag(self, tag, attrs):
        if tag == "div":
            attrs_dict = dict(attrs)
            if attrs_dict.get("class") == "prompt-box":
                self.in_prompt_box = True
                self.current_prompt = []

    def handle_endtag(self, tag):
        if tag == "div" and self.in_prompt_box:
            self.in_prompt_box = False
            self.prompts.append("".join(self.current_prompt).strip())

    def handle_data(self, data):
        if self.in_prompt_box:
            self.current_prompt.append(data)

def extract_prompts(html_path):
    print(f"Reading blueprints from {html_path}...")
    with open(html_path, "r", encoding="utf-8") as f:
        html_content = f.read()
    
    parser = PromptParser()
    parser.feed(html_content)
    
    # We are looking for prompts starting with "### PROMPT"
    game_prompts = []
    for p in parser.prompts:
        if p.startswith("### PROMPT"):
            game_prompts.append(p)
            
    print(f"Successfully extracted {len(game_prompts)} prompts.")
    return game_prompts

def extract_code_block(text, file_name):
    # Regex to find markdown code blocks, specifically for dart
    pattern = r"```(?:dart)?\n(.*?)\n```"
    match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
    if match:
        return match.group(1)
    
    # Fallback to the whole text if no code blocks are found
    print(f"Warning: No markdown code block found in response for {file_name}. Saving raw response.")
    return text

def main():
    use_reasoner = "--reasoner" in sys.argv
    model_name = "deepseek-reasoner" if use_reasoner else "deepseek-chat"
    
    print(f"Using DeepSeek model: {model_name}")
    
    # Read API Key
    key_file = "deepseek api"
    if not os.path.exists(key_file):
        print(f"Error: {key_file} file not found.")
        sys.exit(1)
        
    with open(key_file, "r") as f:
        api_key = f.read().strip()
        
    if not api_key:
        print("Error: API key is empty.")
        sys.exit(1)
        
    # Extract Prompts
    html_path = "daayakattai_full_specification_blueprint.html"
    if not os.path.exists(html_path):
        print(f"Error: Specification file {html_path} not found.")
        sys.exit(1)
        
    prompts = extract_prompts(html_path)
    if not prompts:
        print("Error: No prompts starting with '### PROMPT' found.")
        sys.exit(1)
        
    # Initialize OpenAI Client (configured for DeepSeek)
    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com/v1")
    
    # Output Directory
    out_dir = os.path.join("daayakattai_app", "lib")
    os.makedirs(out_dir, exist_ok=True)
    
    # Process each prompt
    for prompt in prompts:
        # Determine the filename from the first line of the prompt
        # Format is usually: "### PROMPT 1: PURE DART GAME ENGINE (daayakattai_engine.dart)"
        first_line = prompt.split("\n")[0]
        file_match = re.search(r"\(([^)]+\.dart)\)", first_line)
        if not file_match:
            print(f"Skipping prompt without target filename: {first_line}")
            continue
            
        file_name = file_match.group(1)
        file_path = os.path.join(out_dir, file_name)
        
        print(f"\n==================================================")
        print(f"Generating {file_name}...")
        print(f"Prompt: {first_line}")
        print(f"==================================================")
        
        try:
            # We add instructions asking the model to return ONLY code in a standard markdown block
            system_instruction = (
                "You are an expert Flutter and Dart developer. Complete the requested development task "
                "carefully following all specification details. Output the final, working implementation code "
                "wrapped inside a ```dart ... ``` code block. Do not include introductory or concluding conversational text."
            )
            
            messages = [
                {"role": "system", "content": system_instruction},
                {"role": "user", "content": prompt}
            ]
            
            response = client.chat.completions.create(
                model=model_name,
                messages=messages,
                temperature=0.2 if not use_reasoner else None  # reasoner doesn't support temp in some versions
            )
            
            generated_text = response.choices[0].message.content
            code_content = extract_code_block(generated_text, file_name)
            
            with open(file_path, "w", encoding="utf-8") as out_f:
                out_f.write(code_content)
                
            print(f"Saved generated code to {file_path} ({len(code_content)} chars)")
            
        except Exception as e:
            print(f"Error calling DeepSeek API for {file_name}: {e}")

if __name__ == "__main__":
    main()
