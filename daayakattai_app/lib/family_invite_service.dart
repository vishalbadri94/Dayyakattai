import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Model for a permanently saved delegated profile.
///
/// This replaces full user authentication for older users who only need a
/// display name and a pinned family circle to keep playing.
class DelegatedProfile {
  final String displayName;
  final String familyCircleId;

  const DelegatedProfile({
    required this.displayName,
    required this.familyCircleId,
  });

  Map<String, String> toJson() => {
        'displayName': displayName,
        'familyCircleId': familyCircleId,
      };

  factory DelegatedProfile.fromJson(Map<String, dynamic> json) {
    return DelegatedProfile(
      displayName: json['displayName'] as String? ?? '',
      familyCircleId: json['familyCircleId'] as String? ?? '',
    );
  }
}

/// Central service for family invite links, deep link handling and delegated
/// profile persistence.
class FamilyInviteService {
  FamilyInviteService({
    FlutterSecureStorage? secureStorage,
    AppLinks? appLinks,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _appLinks = appLinks ?? AppLinks();

  final FlutterSecureStorage _secureStorage;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  static const String _profileStorageKey = 'dhayam_delegated_profile';
  static const String _defaultHost = 'dhayam.app';
  static const String _joinPath = '/join';

  // ---------------------------------------------------------------------
  // Invite generation & WhatsApp sharing
  // ---------------------------------------------------------------------

  /// Builds the deep link that is shared with family members.
  ///
  /// Example:
  /// `https://dhayam.app/join?room=ROOM_ID`
  String buildInviteLink(String roomId) {
    return Uri(
      scheme: 'https',
      host: _defaultHost,
      path: _joinPath,
      queryParameters: {'room': roomId},
    ).toString();
  }

  String _inviteMessage(String roomId, String? inviterName) {
    final who = (inviterName == null || inviterName.isEmpty)
        ? 'Thatha'
        : inviterName;
    return 'Namaste! $who is inviting you to play Daayakattai with video: ${buildInviteLink(roomId)}';
  }

  /// Sends the invite through the WhatsApp intent.
  ///
  /// If WhatsApp is not installed or cannot be launched, the system share
  /// sheet will open as a fallback (which still allows selecting WhatsApp).
  Future<bool> sendWhatsAppInvite({
    required String roomId,
    String? inviterName,
  }) async {
    final message = _inviteMessage(roomId, inviterName);
    final encoded = Uri.encodeComponent(message);

    final whatsappUri = Uri.parse('whatsapp://send?text=$encoded');
    final webWhatsappUri = Uri.parse('https://api.whatsapp.com/send?text=$encoded');

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (_) {
      // Fall through to web WhatsApp URL.
    }

    try {
      await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
      return true;
    } catch (_) {
      // Fall through to system share sheet.
    }

    await Share.share(message, subject: 'Daayakattai Game Invite');
    return false;
  }

  /// Shares the invite via the native share sheet.
  Future<void> shareInvite({
    required String roomId,
    String? inviterName,
  }) async {
    final message = _inviteMessage(roomId, inviterName);
    await Share.share(message, subject: 'Daayakattai Game Invite');
  }

  // ---------------------------------------------------------------------
  // Deep link handling
  // ---------------------------------------------------------------------

  /// Starts listening for incoming invite links.
  ///
  /// [onRoomInvite] is called immediately for the initial link (cold start)
  /// and for every subsequent link while the app is running.
  ///
  /// The callback should navigate straight to the active `GameView`, bypassing
  /// all login screens.
  Future<void> initDeepLinks({
    required void Function(String roomId) onRoomInvite,
  }) async {
    final initialLink = await _getInitialLinkSafely();
    if (initialLink != null) {
      final roomId = _roomIdFromUri(initialLink);
      if (roomId != null) {
        onRoomInvite(roomId);
      }
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      final roomId = _roomIdFromUri(uri);
      if (roomId != null) {
        onRoomInvite(roomId);
      }
    });
  }

  /// Handles a single explicit deep link outside of the normal initial link /
  /// stream flow, such as from a push notification payload.
  Future<void> handleDeepLink(
    Uri uri, {
    required void Function(String roomId) onRoomInvite,
  }) async {
    final roomId = _roomIdFromUri(uri);
    if (roomId != null) {
      onRoomInvite(roomId);
    }
  }

  String? _roomIdFromUri(Uri uri) {
    final isUniversalLink =
        uri.scheme == 'https' && uri.host == _defaultHost && uri.path == _joinPath;
    final isCustomScheme =
        uri.scheme == 'dhayam' && uri.path == _joinPath;

    if (isUniversalLink || isCustomScheme) {
      return uri.queryParameters['room'];
    }

    return null;
  }

  Future<Uri?> _getInitialLinkSafely() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  // ---------------------------------------------------------------------
  // Delegated profile storage
  // ---------------------------------------------------------------------

  /// Saves the delegated profile permanently in secure storage.
  ///
  /// Once saved, the user can be treated as onboarded and will never be
  /// forced through the login screens again.
  Future<void> saveDelegatedProfile(DelegatedProfile profile) async {
    await _secureStorage.write(
      key: _profileStorageKey,
      value: jsonEncode(profile.toJson()),
    );
  }

  /// Convenience method for saving the profile fields individually.
  Future<void> saveDelegatedProfileDetails({
    required String displayName,
    required String familyCircleId,
  }) async {
    await saveDelegatedProfile(
      DelegatedProfile(
        displayName: displayName,
        familyCircleId: familyCircleId,
      ),
    );
  }

  /// Loads the previously stored delegated profile, if any.
  Future<DelegatedProfile?> loadDelegatedProfile() async {
    try {
      final raw = await _secureStorage.read(key: _profileStorageKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return DelegatedProfile.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Whether a valid delegated profile already exists.
  Future<bool> hasDelegatedProfile() async {
    final profile = await loadDelegatedProfile();
    return profile != null &&
        profile.displayName.isNotEmpty &&
        profile.familyCircleId.isNotEmpty;
  }

  /// Removes the stored delegated profile.
  Future<void> clearDelegatedProfile() async {
    await _secureStorage.delete(key: _profileStorageKey);
  }
}