import 'dart:math';
import 'package:share_plus/share_plus.dart';

class DaayakattaiShareService {
  static const String _appBaseUrl = 'https://daayakattai.app';

  static Future<void> shareGameInvite({
    required String channelName,
    required String gameMode,
    required String hostName,
    required String language,
  }) async {
    final String appLink = '$_appBaseUrl/join/$channelName';
    final String message;

    if (language == 'tamil') {
      message = 'வணக்கம்! $hostName உங்களை Daayakattai விளையாட்டிற்கு அழைக்கிறார். '
          'விளையாட்டு: $gameMode. சேர குறியீடு: $channelName. '
          'பதிவிறக்கம்: $appLink';
    } else {
      // Default to English
      message = 'Hi! $hostName invites you to play Daayakattai. '
          'Mode: $gameMode. Join code: $channelName. '
          'Download: $appLink';
    }

    await Share.share(message, subject: 'Daayakattai Invite');
  }

  static Future<void> shareMatchResult({
    required int winnerTeamId,
    required String gameMode,
    required String language,
  }) async {
    final String message;

    if (language == 'tamil') {
      message = 'Daayakattai - குழு $winnerTeamId வெற்றி பெற்றது! '
          'விளையாட்டு: $gameMode. நீங்களும் விளையாடுங்கள்: $_appBaseUrl';
    } else {
      // Default to English
      message = 'Daayakattai - Team $winnerTeamId wins! '
          'Mode: $gameMode. Play now: $_appBaseUrl';
    }

    await Share.share(message);
  }

  static String generateChannelName() {
    const String prefix = 'DAY';
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random();
    final StringBuffer buffer = StringBuffer(prefix);

    for (int i = 0; i < 3; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }

    return buffer.toString();
  }
}