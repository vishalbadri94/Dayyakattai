import 'dart:async';

import 'package:flutter/foundation.dart';

/// Status of the Agora reconnection process.
enum ReconnectStatus {
  connected,
  disconnected,
  retrying,
  failed,
}

/// Service for managing Agora RTC disconnections with exponential backoff.
///
/// The retry delays are: 1s, 2s, 4s, 8s, 16s, 30s (capped at 30s).
/// Maximum number of retries is 10.
class DaayakattaiReconnectService {
  DaayakattaiReconnectService._();

  static const List<Duration> _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 30),
    Duration(seconds: 30),
    Duration(seconds: 30),
    Duration(seconds: 30),
    Duration(seconds: 30),
  ];

  static final StreamController<ReconnectStatus> _statusController =
      StreamController<ReconnectStatus>.broadcast();

  static Timer? _retryTimer;
  static int _retryCount = 0;
  static VoidCallback? _reconnectCallback;
  static ReconnectStatus _currentStatus = ReconnectStatus.connected;
  static bool _disposed = false;

  /// Stream that emits the current reconnection status.
  static Stream<ReconnectStatus> get statusStream {
    if (_disposed || _statusController.isClosed) {
      return const Stream.empty();
    }
    return _statusController.stream;
  }

  /// Returns the current reconnection status.
  static ReconnectStatus get currentStatus => _currentStatus;

  /// Starts the exponential backoff retry loop.
  ///
  /// Call this when Agora reports a disconnection.
  /// [reconnectCallback] should contain the logic to attempt a reconnection.
  static void onDisconnected(VoidCallback reconnectCallback) {
    if (_disposed) return;

    _reconnectCallback = reconnectCallback;
    _cancelTimer();
    _retryCount = 0;
    _setStatus(ReconnectStatus.disconnected);
    _scheduleNextRetry();
  }

  /// Cancels any pending retry and marks the connection as reconnected.
  ///
  /// Call this when Agora successfully reconnects.
  static void onReconnected() {
    if (_disposed) return;

    _cancelTimer();
    _retryCount = 0;
    _reconnectCallback = null;
    _setStatus(ReconnectStatus.connected);
  }

  /// Cleans up timers and closes the stream controller.
  static void dispose() {
    if (_disposed) return;

    _disposed = true;
    _cancelTimer();
    _reconnectCallback = null;
    _statusController.close();
  }

  static void _scheduleNextRetry() {
    if (_disposed) return;

    // Safety check: if we have already exhausted all retries, emit failed.
    if (_retryCount >= _retryDelays.length) {
      _setStatus(ReconnectStatus.failed);
      return;
    }

    final delay = _retryDelays[_retryCount];
    _retryTimer = Timer(delay, _onRetryTimerFired);
  }

  static void _onRetryTimerFired() {
    if (_disposed) return;

    // Capture the current attempt number and its delay before incrementing.
    final attemptNumber = _retryCount + 1;
    final delay = _retryDelays[_retryCount];
    _retryCount++;

    _setStatus(ReconnectStatus.retrying);
    debugPrint(
      'DaayakattaiReconnectService: Retry attempt $attemptNumber '
      'after ${delay.inSeconds}s delay',
    );

    final callback = _reconnectCallback;
    if (callback != null) {
      // The callback may synchronously call `onReconnected`, which will
      // cancel the retry timer and set `_retryTimer` to null.
      callback();
    }

    // If `onReconnected` was called during the callback, stop here.
    if (_retryTimer == null) return;

    // If we have used all retries, emit failed and stop.
    if (_retryCount >= _retryDelays.length) {
      _retryTimer = null;
      _reconnectCallback = null;
      _setStatus(ReconnectStatus.failed);
      return;
    }

    // Schedule the next retry with the next delay.
    _scheduleNextRetry();
  }

  static void _cancelTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  static void _setStatus(ReconnectStatus status) {
    _currentStatus = status;
    if (_disposed || _statusController.isClosed) return;
    _statusController.add(status);
  }
}