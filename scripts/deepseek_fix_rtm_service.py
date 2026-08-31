"""
DeepSeek Fix: RTM Service Rewrite
===================================
The generated daayakattai_rtm_service.dart used non-existent Agora RTM APIs
(AgoraRtmClient, RtmTextMessage, RtmChannelEventHandler).

The agora_rtc_engine package does NOT include RTM.
Fix: Rewrite using a stub/interface pattern that:
  1. Works today with a local StreamController mock
  2. Has a clear interface ready to swap in real RTM (agora_rtm or Firebase) later
  3. Zero new dependencies needed

Uses deepseek-chat (V3) - this is a bounded rewrite, not complex logic.
"""
import os, sys, re, subprocess
from openai import OpenAI

ROOT_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE   = os.path.join(ROOT_DIR, "deepseek api")
TARGET     = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "services", "daayakattai_rtm_service.dart")
ENGINE     = os.path.join(ROOT_DIR, "daayakattai_app", "lib", "daayakattai_engine.dart")

def get_key():
    if os.environ.get("DEEPSEEK_API_KEY"):
        return os.environ["DEEPSEEK_API_KEY"]
    with open(KEY_FILE) as f:
        return f.read().strip()

def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()

def write(path, content):
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def extract(text):
    m = re.search(r"```dart\n(.*?)\n```", text, re.DOTALL | re.IGNORECASE)
    if m: return m.group(1)
    m = re.search(r"```\n(.*?)\n```", text, re.DOTALL)
    if m: return m.group(1)
    return None

def main():
    key    = get_key()
    client = OpenAI(api_key=key, base_url="https://api.deepseek.com/v1")

    # Read Move class definition from engine for context
    engine_src = read(ENGINE)
    move_section = ""
    for line in engine_src.split("\n"):
        if "class Move" in line or "class TurnResult" in line or "enum MoveKind" in line:
            move_section += line + "\n"

    prompt = """
Create a Flutter service file `daayakattai_rtm_service.dart` for Daayakattai game state sync.

IMPORTANT: Do NOT use AgoraRtmClient, RtmTextMessage, RtmChannelEventHandler, or any
Agora RTM SDK class. These do NOT exist in the agora_rtc_engine package.

Instead, implement a self-contained mock-ready sync service using StreamController
that can be swapped for real networking (Firebase, WebSocket, Agora RTM) later.

Requirements:
1. Imports: dart:async, dart:convert, package:flutter/foundation.dart

2. `enum MoveKind { deploy, outerMove, enterInner, innerMove, finish }`
   (copy from engine, needed for serialization)

3. Class `SyncMove` — a serializable move DTO:
   ```
   class SyncMove {
     final int playerId;
     final int pieceId;
     final String kind;    // MoveKind.name
     final int targetIndex;
     SyncMove({required this.playerId, required this.pieceId,
               required this.kind, required this.targetIndex});
     factory SyncMove.fromJson(Map<String, dynamic> json) => ...
     Map<String, dynamic> toJson() => ...
   }
   ```

4. Class `DaayakattaiRtmService` with ONLY these members:
   - `static final StreamController<SyncMove> _incomingController`
     `   = StreamController<SyncMove>.broadcast();`
   - `static Stream<SyncMove> get incomingMoves => _incomingController.stream;`
   - `static String _channelName = '';`
   - `static bool _isConnected = false;`
   - `static bool get isConnected => _isConnected;`

   - `static Future<void> joinChannel(String channelName)`:
       Sets `_channelName = channelName`, `_isConnected = true`
       debugPrint('[RTM] Joined channel: channelName')

   - `static Future<void> leaveChannel()`:
       Sets `_isConnected = false`, `_channelName = ''`
       debugPrint('[RTM] Left channel')

   - `static Future<void> sendMove(SyncMove move)`:
       If not connected: debugPrint warning and return
       Encodes move as JSON string
       debugPrint('[RTM] Sent move: json')
       // TODO: replace with real RTM send call
       // For local testing: echo back to own stream after 50ms delay
       Future.delayed(const Duration(milliseconds: 50), () {
         _incomingController.add(move);
       });

   - `static void dispose()`:
       `_incomingController.close()`
       `_isConnected = false`

5. No external packages beyond dart:async, dart:convert, package:flutter/foundation.dart

Output the COMPLETE file in a single ```dart code block.
"""
    print("[DeepSeek V3] Rewriting RTM service (stub pattern)...")
    resp = client.chat.completions.create(
        model="deepseek-chat",
        messages=[
            {"role": "system", "content": "You are a Flutter expert. Output only the complete Dart file in a ```dart code block."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.0,
        max_tokens=2500,
    )
    code = extract(resp.choices[0].message.content)
    if code:
        write(TARGET, code)
        print(f"  [OK] RTM service rewritten: {TARGET}")
    else:
        print("  [FAIL] Could not extract code")
        print(resp.choices[0].message.content[:400])
        sys.exit(1)

    # Quick analyze check
    print("\n  Running flutter analyze...")
    result = subprocess.run(
        [r"C:\src\flutter\bin\flutter.bat", "analyze"],
        cwd=os.path.join(ROOT_DIR, "daayakattai_app"),
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print("  [CLEAN] No issues found!")
    else:
        # Show only errors
        for line in result.stdout.split("\n"):
            if "error" in line.lower() and "rtm" in line.lower():
                print(f"  {line}")
        print("\n  [INFO] Full output saved. Run deepseek_autofix.py if needed.")

if __name__ == "__main__":
    main()
