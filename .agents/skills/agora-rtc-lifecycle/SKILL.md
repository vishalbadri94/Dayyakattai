---
name: agora-rtc-lifecycle
description: "Guidelines for managing permissions, background states, and cleanup loops of Agora RTC widgets in Flutter."
---

# Agora RTC Widget Lifecycle Guidelines

Use this skill when editing video conferencing widgets like `agora_video_header.dart` or any video-calling modules.

## 1. Clean Hardware Disposals
* Always call `_engine.release()` or `_engine.leaveChannel()` inside the state's `dispose()` lifecycle. Failing to release raw pointers causes camera locks or audio hardware leaks in Android/iOS.
* Clean up local video view render controllers when leaving screens.

## 2. Safe Permissions Verification
* Before instantiating the RTC engine, check and request permission for the Microphone and Camera using the `permission_handler` package.
* Provide clean, friendly error messages or dialogs asking grandparents to check system settings if permission is denied.

## 3. Graceful Background Suspensions
* Listen to `AppLifecycleState` changes.
* Pause the video track when the app goes into the background (`AppLifecycleState.paused`), and resume it when it returns to the foreground (`AppLifecycleState.resumed`) to save device battery and bandwidth.
