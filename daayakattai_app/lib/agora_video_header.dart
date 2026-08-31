// agora_video_header.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// A 4-player board game video header built with Agora.
///
/// Renders 4 circular video bubbles at the screen corners, one for every
/// board-game seat. The local user is bottom-right; remote users fill the
/// remaining three seats in join order.
class AgoraVideoHeader extends StatefulWidget {
  const AgoraVideoHeader({
    super.key,
    this.appId = '',
    required this.channelName,
    this.token = '',
    this.localUid = 1000,
    this.avatarRadius = 36,
    this.child,
  });

  final String appId;
  final String channelName;
  final String token;
  final int localUid;
  final Widget? child;

  /// Radius of each circular video bubble.
  final double avatarRadius;

  @override
  State<AgoraVideoHeader> createState() => _AgoraVideoHeaderState();
}

class _AgoraVideoHeaderState extends State<AgoraVideoHeader>
    with SingleTickerProviderStateMixin {
  RtcEngine? _engine;
  late final AnimationController _glowController;

  // Seat order: 0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right (local).
  final List<int?> _slotUids = List<int?>.filled(4, null);

  final Set<int> _activeSpeakerUids = {};

  bool _muted = false;
  bool _cameraEnabled = true;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Bottom-right always belongs to the local player.
    _slotUids[3] = widget.localUid;

    _initAgora();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _cleanupAgora();
    super.dispose();
  }

  Future<void> _initAgora() async {
    if (_initializing) return;
    if (widget.appId.isEmpty) {
      debugPrint('Agora App ID not provided. Running in placeholder mode.');
      return;
    }
    _initializing = true;

    try {
      final granted = await _requestPermissions();
      if (!granted) {
        throw Exception('Camera and microphone permissions are required.');
      }
      if (!mounted) return;

      final engine = createAgoraRtcEngine();
      _engine = engine;

      await engine.initialize(RtcEngineContext(appId: widget.appId));

      // Communication profile fits a private, interactive board game call.
      await engine.setChannelProfile(
        ChannelProfileType.channelProfileCommunication,
      );

      // Speech-optimised audio with low-latency game streaming scenario.
      await engine.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      // Audio-aware mode gives audio priority over video in congested networks.
      await engine.setParameters('{"che.video.audioAware": true}');

      await engine.enableAudio();
      await engine.enableVideo();

      // --- Low bandwidth configuration ---
      // 240p @ 15 FPS, balanced bitrate, and frame-rate preservation when
      // bandwidth degrades. This keeps the experience smooth on budget phones.
      await engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 320, height: 240),
          frameRate: 15,
          bitrate: 300,
          degradationPreference: DegradationPreference.maintainFramerate,
        ),
      );

      // Allow remote users to subscribe to a lower-quality small stream.
      await engine.enableDualStreamMode(enabled: true);
      await engine.setRemoteDefaultVideoStreamType(VideoStreamType.videoStreamLow);

      // Receive active-speaker volume indications every 200ms.
      await engine.enableAudioVolumeIndication(interval: 200, smooth: 3, reportVad: true);
      await engine.setEnableSpeakerphone(true);

      _registerEventHandlers(engine);

      await engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: widget.localUid,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      debugPrint('AgoraVideoHeader init error: $e');
    } finally {
      _initializing = false;
    }
  }

  Future<bool> _requestPermissions() async {
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    return camera.isGranted && mic.isGranted;
  }

  void _registerEventHandlers(RtcEngine engine) {
    final handler = RtcEngineEventHandler(
      onUserJoined: (connection, remoteUid, elapsed) {
        if (!mounted || remoteUid == widget.localUid) return;
        if (_slotUids.contains(remoteUid)) return;

        final emptyIndex = _slotUids.indexWhere((uid) => uid == null);
        if (emptyIndex != -1) {
          setState(() => _slotUids[emptyIndex] = remoteUid);
        }

        // Subscribe to the low-bitrate stream for this remote user.
        engine.setRemoteVideoStreamType(
          uid: remoteUid,
          streamType: VideoStreamType.videoStreamLow,
        );
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (!mounted) return;
        final index = _slotUids.indexOf(remoteUid);
        if (index != -1) {
          setState(() {
            _slotUids[index] = null;
            _activeSpeakerUids.remove(remoteUid);
          });
        }
      },
      onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
        if (!mounted) return;

        final active = <int>{};
        for (final info in speakers) {
          final uid = info.uid ?? 0;
          final volume = info.volume ?? 0;
          final adjustedUid = uid == 0 ? widget.localUid : uid;
          if (volume > 30) {
            active.add(adjustedUid);
          }
        }

        if (!_sameSet(active, _activeSpeakerUids)) {
          setState(() {
            _activeSpeakerUids
              ..clear()
              ..addAll(active);
          });
        }
      },
    );

    engine.registerEventHandler(handler);
  }

  bool _sameSet(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  Future<void> _toggleMute() async {
    final engine = _engine;
    if (engine == null) return;

    final muted = !_muted;
    setState(() => _muted = muted);
    await engine.muteLocalAudioStream(muted);
  }

  Future<void> _toggleCamera() async {
    final engine = _engine;
    if (engine == null) return;

    final enabled = !_cameraEnabled;
    setState(() => _cameraEnabled = enabled);
    await engine.muteLocalVideoStream(!enabled);
  }

  Future<void> _cleanupAgora() async {
    final engine = _engine;
    if (engine == null) return;

    try {
      await engine.leaveChannel();
      await engine.release();
    } catch (e) {
      debugPrint('AgoraVideoHeader cleanup error: $e');
    } finally {
      _engine = null;
    }
  }

  bool _isActiveSpeaker(int? uid) {
    return uid != null && _activeSpeakerUids.contains(uid);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final boardSize = math.min(w, h) * 0.90;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // The actual game board (passed as child) or fallback mock board
              Center(
                child: Container(
                  width: boardSize,
                  height: boardSize,
                  child: widget.child ?? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4E342E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'BOARD',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Top-left remote seat.
              Positioned(
                left: 8,
                top: 8,
                child: _buildBubble(_slotUids[0], isLocal: false),
              ),

              // Top-right remote seat.
              Positioned(
                right: 8,
                top: 8,
                child: _buildBubble(_slotUids[1], isLocal: false),
              ),

              // Bottom-left remote seat.
              Positioned(
                left: 8,
                bottom: 8,
                child: _buildBubble(_slotUids[2], isLocal: false),
              ),

              // Bottom-right is the local player.
              Positioned(
                right: 8,
                bottom: 8,
                child: _buildBubble(_slotUids[3], isLocal: true),
              ),

              // Mute / camera controls.
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(child: _buildControls()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBubble(int? uid, {required bool isLocal}) {
    final r = widget.avatarRadius;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final isSpeaking = _isActiveSpeaker(uid);
        final t = _glowController.value; // 0.0 -> 1.0 -> 0.0

        return Container(
          width: r * 2,
          height: r * 2,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xCC102030),
            border: Border.all(
              color: isSpeaking
                  ? Colors.amber.withValues(alpha: 0.6 + 0.4 * t)
                  : Colors.white.withValues(alpha: 0.35),
              width: isSpeaking ? 3 : 1.5,
            ),
            boxShadow: isSpeaking
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.35 + 0.65 * t),
                      blurRadius: 6 + 14 * t,
                      spreadRadius: 1 + 3 * t,
                    ),
                  ]
                : const [],
          ),
          child: ClipOval(child: child),
        );
      },
      child: _buildAvatarContent(uid, isLocal: isLocal),
    );
  }

  Widget _buildAvatarContent(int? uid, {required bool isLocal}) {
    final engine = _engine;

    if (uid == null) {
      return _buildPlaceholder(icon: Icons.person_outline);
    }

    if (isLocal && !_cameraEnabled) {
      return _buildPlaceholder(icon: Icons.videocam_off_outlined);
    }

    if (engine == null) {
      return _buildPlaceholder(icon: Icons.person_outline);
    }

    return AgoraVideoView(
      controller: isLocal
          ? VideoViewController(
              rtcEngine: engine,
              canvas: const VideoCanvas(uid: 0),
            )
          : VideoViewController.remote(
              rtcEngine: engine,
              canvas: VideoCanvas(uid: uid),
              connection: RtcConnection(channelId: widget.channelName),
            ),
    );
  }

  Widget _buildPlaceholder({required IconData icon}) {
    return ColoredBox(
      color: const Color(0xFF1B2A3A),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white70,
          size: widget.avatarRadius * 0.9,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: _muted ? 'Unmute microphone' : 'Mute microphone',
              icon: Icon(
                _muted ? Icons.mic_off : Icons.mic,
                color: _muted ? Colors.redAccent : Colors.white,
              ),
              onPressed: _toggleMute,
            ),
            IconButton(
              tooltip: _cameraEnabled ? 'Turn camera off' : 'Turn camera on',
              icon: Icon(
                _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                color: _cameraEnabled ? Colors.white : Colors.orangeAccent,
              ),
              onPressed: _toggleCamera,
            ),
          ],
        ),
      ),
    );
  }
}