# 🎲 Traditional South Indian Daayakattai (Dhayam) Mobile App

A premium, modern Flutter implementation of **Daayakattai (Dhayam)**—the ancient Tamil board game of strategy and racing. Built with real-time video chat capabilities for long-distance families, featuring a senior-friendly design and local-first execution.

---

## 📁 Repository Structure

```
Dayyakattai/
├── .agents/                    # Workspace Customizations & Agent-guidelines
│   ├── rules/
│   │   └── gstack-AGENTS.md    # YC design and scope guidelines
│   └── skills/
│       ├── agora-rtc-lifecycle/ # WebRTC cleanup & permission guidelines
│       ├── flutter-custom-painter/ # Canvas painter optimization rules
│       └── grandparent-accessibility/ # Senior usability guidelines
├── docs/                       # Project specifications & resource docs
│   ├── Daayakattai_App_Master_Blueprint.pdf
│   ├── daayakattai_full_specification_blueprint.html
│   └── video_transcript.txt    # Hindi game rules reference transcript
├── scripts/                    # Python setup & helper scripts
│   ├── download_image.py       # Fetches traditional board layout layouts
│   ├── generate_code.py        # Connects with DeepSeek API to build assets
│   └── get_transcript.py       # Pulls Hindi video transcript
├── daayakattai_app/            # Flutter Mobile App Workspace
│   ├── lib/
│   │   ├── main.dart           # App bootstraps & layout routing
│   │   ├── daayakattai_board.dart # CustomPainter traditional cloth board
│   │   ├── daayakattai_engine.dart # Core game engine and state machine
│   │   ├── agora_video_header.dart # Agora bubble WebRTC layout
│   │   └── family_invite_service.dart # WhatsApp link generation service
│   └── pubspec.yaml            # Project dependencies & configurations
└── .gitignore                  # Project-wide exclusion rules
```

---

## ⚡ Game Engine Architecture

The core of the game is implemented as a strict, deterministic state machine inside [`daayakattai_engine.dart`](file:///c:/Users/visha/Desktop/Dayyakattai/daayakattai_app/lib/daayakattai_engine.dart):
* **Upfront Rolling Phase**: Players roll all available moves first. Bonus numbers (`1`, `5`, `6`, `12`) grant extra rolls.
* **Three-Strike Forfeit**: Rolling three consecutive bonus numbers cancels all accumulated moves for that turn and forfeits the turn to the next player.
* **Jodu (Pairs) Blocking**: Single pieces cannot capture or land on a cell occupied by an opponent's pair (2 or more stacked pieces).
* **Safe Gates (Malai)**: The 9 symmetric cross positions double as safe zones where multiple players can coexist safely without getting captured.

---

## 🎨 Traditional Visual Design

The UI is rendered using Flutter's [`CustomPainter`](file:///c:/Users/visha/Desktop/Dayyakattai/daayakattai_app/lib/daayakattai_board.dart) to recreate a authentic feel:
* **Silk-weaving Texture**: The board renders a raw silk weave fabric pattern using high-frequency sine/cosine paint threads.
* **Cruciform Grid**: Unused 2x2 corner grids are masked out, creating a clean cruciform cross-board identical to Chaupar/Pachisi.
* **Bell-shaped Lathe Pawns**: Pieces are drawn as brass lathe-turned bells with a player-specific colored lacquer ring inlay.
* **Home Base Corners**: Pieces resting at Home occupy the empty 2x2 corner quadrants acting as team-colored base trays.

---

## 🚀 How to Run the App

1. Move the `daayakattai_app` folder to a machine with Flutter installed.
2. In your terminal, navigate to the folder:
   ```bash
   cd daayakattai_app
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app on a connected emulator or real device:
   ```bash
   flutter run
   ```

---

## 🛠️ Workspace Customizations & Agent Skills
This workspace is pre-loaded with **Agentic Skills** in the `.agents/` folder. Any AI agent (using Antigravity, Claude Code, or Codex) opening this repository will automatically read and adhere to these guidelines:
* **[`flutter-custom-painter`](file:///c:/Users/visha/Desktop/Dayyakattai/.agents/skills/flutter-custom-painter/SKILL.md)**: Standard rules for avoiding lag on CustomPainters (e.g. repainting isolation with `RepaintBoundary`, optimizing loops).
* **[`grandparent-accessibility`](file:///c:/Users/visha/Desktop/Dayyakattai/.agents/skills/grandparent-accessibility/SKILL.md)**: Enforces senior readability (minimum target sizes $\ge 64$dp, large font styles, Tamil localization).
* **[`agora-rtc-lifecycle`](file:///c:/Users/visha/Desktop/Dayyakattai/.agents/skills/agora-rtc-lifecycle/SKILL.md)**: Guarantees correct background behavior, mic/camera requests, and hardware cleanup.
* **[`gstack-AGENTS.md`](file:///c:/Users/visha/Desktop/Dayyakattai/.agents/rules/gstack-AGENTS.md)**: YC startup-ethos rules for scope minimization, high-end aesthetics, and anti-guessing.

---

## 📱 On-Device AI: Gemini Nano Integration
For real-time accessibility, theme suggestions, and on-device design auditing:
* **Gemini Nano**: Targeted for execution directly on-device (via Android AICore / Google Play Services) to handle:
  * **Grandparent Assist**: Real-time voice guidance and step explanations in Tamil/English locally without network latency.
  * **Dynamic Accessibility Theming**: Auto-adjusting UI contrast ratios and layout text scaling factors based on ambient lighting conditions and user fatigue.
  * **Privacy-First AI**: Handles all user profile configurations and pass-and-play voice assistance completely offline.

