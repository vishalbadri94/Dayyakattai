# Dayyakattai — Next Steps Roadmap

## Current State (as of 2026-08-31)
- ✅ Game engine complete (dice, Jodu, Vettu, inner track, 3-strike forfeit, win detection)
- ✅ 4-tab dashboard (Game Setup, Profiles, Family Groups, Stats)
- ✅ Agora RTC video/audio bubbles (persistent across game)
- ✅ Tamil TTS audio service (voice announces dice rolls, turns, captures, victory)
- ✅ Scenario Tester Panel (4 prebuilt debug scenarios)
- ✅ Storage service (secure local storage, 100-entry history, batch writes)
- ✅ DeepSeek logic test report (6/7 PASS)
- ✅ Flutter analyze: No issues found

---

## Next Steps (Priority Order)

### PHASE 1 — Core Gameplay Polish (DeepSeek Builds)

#### 1.1 Wire Tamil TTS into Board Events
- `deepseek_wire_audio_final.py`: Connect `DaayakattaiAudioService` into `_rollDice()`, `_handleMoveStatus()`, and `_handleGameFinished()` in `daayakattai_board.dart`.
- Trigger: `speakRoll()` on dice roll, `speakCut()` on capture, `speakTurn()` on turn change, `speakVictory()` on game end.

#### 1.2 Animated Dice Roll Visual
- `deepseek_dice_animation.py`: Generate an animated dice widget that shows the stick throw animation (4 sticks flipping) before displaying the value.
- Use Flutter's `AnimationController` + `CustomPainter` for stick art.

#### 1.3 Game State Sharing (WhatsApp / URL)
- `deepseek_game_share.py`: Implement the `share_plus` + `url_launcher` integration:
  - Generate a game invite link with channel name, game mode, and player slots.
  - Share via WhatsApp with Tamil invite message.
  - Deep-link into game directly.

---

### PHASE 2 — Remote Play Infrastructure

#### 2.1 Agora Data Channel Sync (Game State)
- `deepseek_agora_sync.py`: Use Agora RTM (Real-Time Messaging) to sync game state across remote players.
- Encode `Move` objects as JSON messages; apply received moves via `game.applyMove()`.
- Show "waiting for remote player..." spinner during network lag.

#### 2.2 Room Management Screen
- `deepseek_room_screen.py`: Build a Room Lobby screen where the host creates a room, gets a code/link, and waits for remote players to join before starting.

#### 2.3 Reconnection Handling
- Read `agora-rtc-lifecycle` skill for retry + cleanup loop patterns.
- Auto-reconnect on network drops with exponential backoff.

---

### PHASE 3 — Accessibility & UX

#### 3.1 Grandparent Mode
- Read `grandparent-accessibility` skill and apply:
  - Minimum 18sp font sizes everywhere.
  - High-contrast button labels.
  - Haptic feedback on dice roll and piece movement.
  - Large tap target sizes (min 48×48dp).

#### 3.2 Onboarding Flow
- `deepseek_onboarding.py`: Build a 3-screen onboarding wizard shown on first launch:
  - Screen 1: "Welcome to Daayakattai" (Tamil + English)
  - Screen 2: How to play (dice values, Jodu, Vettu illustrated)
  - Screen 3: Create your profile and invite family

#### 3.3 Sound Effects
- Add short `.mp3` or `.ogg` sfx for: dice throw, piece move, capture, victory fanfare.
- Use `audioplayers` package alongside the TTS service.

---

### PHASE 4 — Distribution

#### 4.1 Android APK Build
- `flutter build apk --release` targeting Android 5.0+ (API 21+).
- Sign with keystore; generate install QR code for grandparents.

#### 4.2 Web Build
- `flutter build web --release` for remote family browser access.
- Deploy to Firebase Hosting or GitHub Pages.

#### 4.3 Analytics & Cost Tracking
- Finalize `docs/api_usage_log.md` auto-update via `hybrid_codegen.py`.
- Add session cost dashboard to Stats screen.

---

## DeepSeek Script Index

| Script | Purpose |
|---|---|
| `deepseek_refine.py` | Storage service code audit |
| `deepseek_refine_setup.py` | Setup screen routing refactor |
| `deepseek_create_audio_service.py` | Tamil TTS service generation |
| `deepseek_scenario_tester.py` | Scenario Tester Panel injection |
| `deepseek_restore_build.py` | Board build() method restoration |
| `deepseek_fix_withopacity.py` | Deprecation fix across all files |
| `deepseek_logic_test_agent.py` | QA logic correctness review |
| `deepseek_fix_tests.py` | Failing unit test repair |
| `deepseek_wire_audio_final.py` | TTS board wiring *(next)* |
| `deepseek_dice_animation.py` | Stick dice animation *(next)* |
| `deepseek_game_share.py` | WhatsApp invite sharing *(next)* |
| `deepseek_agora_sync.py` | RTM game state sync *(next)* |
