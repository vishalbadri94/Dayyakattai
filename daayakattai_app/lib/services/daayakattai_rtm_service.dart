import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

enum MoveKind { deploy, outerMove, enterInner, innerMove, finish }

class SyncMove {
  final int playerId;
  final int pieceId;
  final String kind; // MoveKind.name
  final int targetIndex;

  SyncMove({
    required this.playerId,
    required this.pieceId,
    required this.kind,
    required this.targetIndex,
  });

  factory SyncMove.fromJson(Map<String, dynamic> json) {
    return SyncMove(
      playerId: json['playerId'] as int,
      pieceId: json['pieceId'] as int,
      kind: json['kind'] as String,
      targetIndex: json['targetIndex'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'pieceId': pieceId,
      'kind': kind,
      'targetIndex': targetIndex,
    };
  }
}

class DaayakattaiRtmService {
  static final StreamController<SyncMove> _incomingController =
      StreamController<SyncMove>.broadcast();

  static Stream<SyncMove> get incomingMoves => _incomingController.stream;

  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  static Future<void> joinChannel(String channelName) async {
    _isConnected = true;
    debugPrint('[RTM] Joined channel: $channelName');
  }

  static Future<void> leaveChannel() async {
    _isConnected = false;
    debugPrint('[RTM] Left channel');
  }

  static Future<void> sendMove(SyncMove move) async {
    if (!_isConnected) {
      debugPrint('[RTM] Warning: Not connected, cannot send move');
      return;
    }

    final jsonString = jsonEncode(move.toJson());
    debugPrint('[RTM] Sent move: $jsonString');

    // TODO: replace with real RTM send call
    // For local testing: echo back to own stream after 50ms delay
    Future.delayed(const Duration(milliseconds: 50), () {
      _incomingController.add(move);
    });
  }

  static void dispose() {
    _incomingController.close();
    _isConnected = false;
  }
}