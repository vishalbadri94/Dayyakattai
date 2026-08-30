# 🎲 Daayakattai (Dhayam) — Traditional South Indian Board Game App

A premium, modern **Flutter** implementation of **Daayakattai (Dhayam)** — the ancient Tamil board game of strategy and racing. Built for long-distance families with **real-time video chat** (Agora RTC), **Tamil + English voice assistance** (TTS), and a **senior-friendly, grandparent-first** design. Everything is local-first and works pass-and-play out of the box.

---

## ✨ Features

- 🎮 **Full deterministic game engine** in pure Dart — dice rolling, capture (Vettu), pair blocking (Jodu), safe gates (Malai), inner-track finish, and win detection.
- 👨‍👩‍👧 **4-tab dashboard**: Start Game, Profiles, Family Groups, and Career Stats.
- 📹 **Real-time video chat** — persistent 4-seat Agora RTC video bubbles with active-speaker glow, mute/camera controls, and low-bandwidth (240p) optimization.
- 🗣️ **Tamil/English text-to-speech** — announces dice rolls, turns, captures, forfeits, and victories in a slow, clear voice.
- 👴 **Grandparent-friendly UI** — large fonts, high-contrast gold/brass-on-maroon theme, big tap targets, Tamil-first labels.
- 🔒 **Local secure storage** — family profiles, family groups, language preference, and match history via `flutter_secure_storage` (history capped at 100 matches).
- 📊 **Career stats & leaderboard** — Hall of Fame rankings, per-player achievements (Dhayams rolled, cuts made), and recent match history.
- 📲 **Family invite links** — generate `dhayam.app/join` deep links and share via WhatsApp with a Tamil invite message.
- 🎨 **Hand-painted board** — raw silk weave texture, brass-lathed bell pawns, and lotus motifs on safe cells, all rendered with `CustomPainter`.

---

## 📁 Repository Structure

```
Dayyakattai/
├── .agents/                      # Agent guidelines & reusable skills
│   ├── rules/
│   │   └── gstack-AGENTS.md      # YC startup-ethos scope/aesthetic rules
│   └── skills/
│       ├── agora-rtc-lifecycle/      # WebRTC permission & cleanup rules
│       ├── flutter-custom-painter/   # Canvas painter optimization rules
│       └── grandparent-accessibility/ # Senior usability guidelines
│
├── daayakattai_app/              # Flutter mobile app workspace
│   ├── lib/
│   │   ├── main.dart                       # App entry + 4-tab dashboard
│   │   ├── daayakattai_engine.dart         # Pure-Dart game engine & state machine
│   │   ├── daayakattai_board.dart          # CustomPainter board + game UI
│   │   ├── agora_video_header.dart         # Agora 4-seat video bubbles
│   │   ├── family_invite_service.dart      # WhatsApp invites + deep links
│   │   ├── screens/
│   │   │   ├── game_setup_screen.dart      # Family group + mode + seat assignment
│   │   │   ├── profile_screen.dart         # Family member CRUD
│   │   │   ├── family_group_screen.dart    # Family group CRUD
│   │   │   └── stats_screen.dart           # Leaderboard, achievements, match log
│   │   └── services/
│   │       ├── daayakattai_audio_service.dart   # Tamil/English TTS voice assistant
│   │       └── daayakattai_storage_service.dart # Secure local storage + models
│   ├── test/
│   │   ├── daayakattai_engine_test.dart    # Game rules unit tests
│   │   └── daayakattai_storage_test.dart   # Storage service tests (mocked)
│   └── pubspec.yaml            # Dependencies & config
│
├── docs/                        # Project specifications & reports
│   ├── Daayakattai_App_Master_Blueprint.pdf
│   ├── daayakattai_full_specification_blueprint.html
│   ├── deepseek_logic_test_report.md    # Engine QA scenario report (7 scenarios)
│   ├── api_usage_log.md                 # API token/cost tracking log
│   ├── next_steps.md                    # Roadmap & DeepSeek script index
│   └── video_transcript.txt             # Hindi rules reference transcript
│
├── scripts/                     # Python automation (DeepSeek codegen pipeline)
│   ├── generate_code.py         # Runs blueprint prompts through DeepSeek API
│   ├── hybrid_codegen.py        # Gemini planning/audit + DeepSeek coding
│   ├── get_transcript.py        # Fetches YouTube game-rules transcript
│   ├── download_image.py        # Downloads reference board images
│   └── deepseek_*.py            # Per-feature build/fix/test agents
│
├── venv/                        # Python 3.11 virtual environment (gitignored)
├── deepseek api                 # DeepSeek API key file (gitignored — never commit)
└── .gitignore                   # Project-wide exclusion rules
```

---

## ⚡ Game Engine Architecture

The core is a strict, deterministic state machine in [`daayakattai_engine.dart`](daayakattai_app/lib/daayakattai_engine.dart):

- **Upfront Rolling Phase** — Players roll all available moves first. Bonus numbers (`1`, `5`, `6`, `12`) grant extra rolls.
- **Three-Strike Forfeit** — Rolling three consecutive bonus numbers cancels all accumulated moves for the turn and forfeits to the next player.
- **Jodu (Pairs) Blocking** — A single piece cannot capture or land on a cell occupied by an opponent's pair (2+ stacked pieces).
- **Safe Gates (Malai)** — The cross positions (middle row/column) act as safe zones where multiple players coexist without capture.
- **Vettu (Capture) Lock** — A piece must first capture an opponent to gain `hasVettu`; only then can it enter the inner track and finish.
- **Game Modes** — 2, 3, 4 players (free-for-all), plus team modes for 4 (2v2), 6, 8, and 12 players.

The engine is fully testable: `Dice` accepts an injected `Random`, and `debugSetupPiece` / `debugSetupGameState` helpers let tests and the in-app **Scenario Tester** (bug icon on the board) construct edge-case positions.

---

## 🎨 Traditional Visual Design

The UI is rendered with Flutter's [`CustomPainter`](daayakattai_app/lib/daayakattai_board.dart):

- **Silk-weaving Texture** — raw silk weave fabric pattern drawn with high-frequency sine/cosine paint threads.
- **Cruciform Grid** — the unused 2×2 corners are masked out to create the classic cruciform cross-board.
- **Brass-Lathed Pawns** — bell-shaped brass pieces with player-colored lacquer ring inlays and top knobs.
- **Lotus Motifs** — hand-drawn lotus flowers mark every safe cell.
- **Home Base Corners** — pieces at home rest in team-colored 2×2 corner trays with staggered layouts for up to 12 players.

---

## 🚀 How to Run the App

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>=3.0.0`).

```bash
cd daayakattai_app
flutter pub get
flutter run
```

Run the test suite:

```bash
flutter test
```

> **Note:** The Agora video header runs in *placeholder mode* until you provide an Agora `appId`. Set it in [`agora_video_header.dart`](daayakattai_app/lib/agora_video_header.dart) (`AgoraVideoHeader(appId: ...)`) to enable real video calls.

---

## 🧪 Testing

| Test file | Coverage |
|---|---|
| `test/daayakattai_engine_test.dart` | Deploy rule (must roll 1), three-strike forfeit, Jodu pair blocking, Vettu gate lock |
| `test/daayakattai_storage_test.dart` | Default mock profiles, profile CRUD, automatic career-stat updates when logging a match |

The engine QA report in [`docs/deepseek_logic_test_report.md`](docs/deepseek_logic_test_report.md) documents 7 traced scenarios (6 PASS / 1 PARTIAL with notes).

---

## 🛠️ Scripts & Agentic Development

The repo is built around an AI-assisted pipeline:

- [`generate_code.py`](scripts/generate_code.py) — extracts `### PROMPT` blocks from the HTML blueprint and generates each Dart file through the DeepSeek API (`deepseek-chat` / `--reasoner`).
- [`hybrid_codegen.py`](scripts/hybrid_codegen.py) — orchestrates Gemini planning/auditing with DeepSeek coding, and updates `docs/api_usage_log.md`.
- `scripts/deepseek_*.py` — one-shot agents used for specific tasks (TTS service, scenario tester, test fixes, deprecation fixes, audio wiring, etc.).

The `.agents/` folder ships agentic guidelines so any AI assistant (Antigravity, Claude Code, Codex) follows the project's rules automatically:

- **`flutter-custom-painter`** — repaint isolation (`RepaintBoundary`) and loop optimization to avoid jank.
- **`grandparent-accessibility`** — minimum target sizes, large fonts, Tamil localization.
- **`agora-rtc-lifecycle`** — correct mic/camera permissions, background behavior, and hardware cleanup.
- **`gstack-AGENTS.md`** — YC-style scope minimization, high-end aesthetics, anti-guessing.

---

## 🗺️ Roadmap

See [`docs/next_steps.md`](docs/next_steps.md) for the full priority list. Highlights:

- **Phase 1** — Animated stick-dice visuals, deeper TTS wiring, game-state sharing via WhatsApp/URL.
- **Phase 2** — Remote play: Agora RTM state sync, room lobby screen, reconnection handling.
- **Phase 3** — Grandparent mode polish, onboarding wizard, sound effects.
- **Phase 4** — Android APK build (with install QR for grandparents), web build, analytics.

---

## 🔒 Security & Credentials

- The `deepseek api` file contains a secret API key and is **gitignored** — do not commit it.
- All game data (profiles, groups, matches, language) is stored locally via `flutter_secure_storage`; no backend or cloud database is required to play.
