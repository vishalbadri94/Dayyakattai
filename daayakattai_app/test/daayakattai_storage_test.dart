import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:daayakattai_app/services/daayakattai_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup FlutterSecureStorage mock before running tests
  setUpAll(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final Map<String, String> mockValues = {};

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      final args = methodCall.arguments as Map?;
      switch (methodCall.method) {
        case 'write':
          final key = args?['key'] as String;
          final val = args?['value'] as String;
          mockValues[key] = val;
          return null; // Success response
        case 'read':
          final key = args?['key'] as String;
          return mockValues[key] ?? ''; // Return empty string if not found
        case 'delete':
          final key = args?['key'] as String;
          mockValues.remove(key);
          return null; // Success response
        case 'clear':
          mockValues.clear();
          return null; // Success response
        default:
          return null;
      }
    });
  });

  group('DaayakattaiStorageService Tests', () {
    test('Should load default mock profiles when storage is empty', () async {
      final profiles = await DaayakattaiStorageService.getProfiles();
      expect(profiles, isNotEmpty);
      expect(profiles.any((p) => p.name == 'Grandpa'), isTrue);
    });

    test('Should create and retrieve new PlayerProfile correctly', () async {
      final customProfile = PlayerProfile(
        id: 'test-user-99',
        name: 'Uncle Ramesh',
        colorHex: '0xFF9C27B0',
        avatarKey: '🦁',
      );

      await DaayakattaiStorageService.saveProfile(customProfile);
      final profiles = await DaayakattaiStorageService.getProfiles();
      
      final found = profiles.firstWhere((p) => p.id == 'test-user-99');
      expect(found.name, equals('Uncle Ramesh'));
      expect(found.avatarKey, equals('🦁'));
    });

    test('Should update career profiles automatically when a match is logged', () async {
      final matchStats = <String, PlayerMatchStats>{
        'p1': PlayerMatchStats(
          teamId: 0,
          rollsCount: 20,
          dhavamsRolled: 3,
          pannirendusRolled: 1,
          piecesCut: 2,
          piecesFinished: 4,
        ),
      };

      final record = MatchRecord(
        id: 'match-101',
        timestamp: DateTime.now(),
        durationSeconds: 600,
        gameMode: '4 Players (2v2)',
        winnerTeamId: 0,
        statsPerPlayer: matchStats,
      );

      // Get profile career stats before match log
      final profilesBefore = await DaayakattaiStorageService.getProfiles();
      final p1Before = profilesBefore.firstWhere((p) => p.id == 'p1');
      final beforePlayed = p1Before.gamesPlayed;

      // Log match
      await DaayakattaiStorageService.logMatch(record);

      // Get profile career stats after match log
      final profilesAfter = await DaayakattaiStorageService.getProfiles();
      final p1After = profilesAfter.firstWhere((p) => p.id == 'p1');

      expect(p1After.gamesPlayed, equals(beforePlayed + 1));
      expect(p1After.dhavamsRolled, equals(p1Before.dhavamsRolled + 3));
      expect(p1After.cutsMade, equals(p1Before.cutsMade + 2));
    });
  });
}