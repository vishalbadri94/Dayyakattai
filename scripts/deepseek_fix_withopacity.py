"""
DeepSeek Fix Agent — Replace withOpacity with withValues()
==========================================================
Reads each affected file, replaces all .withOpacity(x) calls
with .withValues(alpha: x) and writes the files back.
"""
import os, re, glob

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB_DIR  = os.path.join(ROOT_DIR, "daayakattai_app", "lib")

# Scan ALL dart files in lib automatically
AFFECTED_FILES = glob.glob(os.path.join(LIB_DIR, "**", "*.dart"), recursive=True)

# Pattern: .withOpacity(0.15) -> .withValues(alpha: 0.15)
PATTERN = re.compile(r"\.withOpacity\(([^)]+)\)")
REPLACEMENT = r".withValues(alpha: \1)"

def fix_file(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    new_content, count = PATTERN.subn(REPLACEMENT, content)
    if count > 0:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"  Fixed {count} occurrence(s) in {os.path.basename(path)}")
    else:
        print(f"  No occurrences found in {os.path.basename(path)}")

def main():
    print("Replacing withOpacity() -> withValues(alpha:) in all affected files...")
    for filepath in AFFECTED_FILES:
        if os.path.exists(filepath):
            fix_file(filepath)
        else:
            print(f"  Skipped (not found): {filepath}")
    print("Done.")

if __name__ == "__main__":
    main()
