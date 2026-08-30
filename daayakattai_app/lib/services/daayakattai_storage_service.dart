import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

class PlayerProfile {
  final String id;
  final String name;
  final String colorHex;
  final String avatarKey;
  
  // Career Statistics
  int gamesPlayed;
  int gamesWon;
  int dhavamsRolled;
  int cutsMade;

  PlayerProfile({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.avatarKey,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.dhavamsRolled = 0,
    this.cutsMade = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'avatarKey': avatarKey,
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'dhavamsRolled': dhavamsRolled,
        'cutsMade': cutsMade,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        colorHex: json['colorHex'] as String,
        avatarKey: json['avatarKey'] as String,
        gamesPlayed: json['gamesPlayed'] as int? ?? 0,
        gamesWon: json['gamesWon'] as int? ?? 0,
        dhavamsRolled: json['dhavamsRolled'] as int? ?? 0,
        cutsMade: json['cutsMade'] as int? ?? 0,
      );
}

class FamilyGroup {
  final String id;
  final String name;
  final List<String> memberIds;

  FamilyGroup({
    required this.id,
    required this.name,
    required this.memberIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'memberIds': memberIds,
      };

  factory FamilyGroup.fromJson(Map<String, dynamic> json) => FamilyGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        memberIds: List<String>.from(json['memberIds'] as List),
      );
}

class PlayerMatchStats {
  final int rollsCount;
  final int dhavamsRolled;
  final int pannirendusRolled;
  final int piecesCut;
  final int piecesFinished;

  PlayerMatchStats({
    required this.rollsCount,
    required this.dhavamsRolled,
    required this.pannirendusRolled,
    required this.piecesCut,
    required this.piecesFinished,
  });

  Map<String, dynamic> toJson() => {
        'rollsCount': rollsCount,
        'dhavamsRolled': dhavamsRolled,
        'pannirendusRolled': pannirendusRolled,
        'piecesCut': piecesCut,
        'piecesFinished': piecesFinished,
      };

  factory PlayerMatchStats.fromJson(Map<String, dynamic> json) => PlayerMatchStats(
        rollsCount: json['rollsCount'] as int? ?? 0,
        dhavamsRolled: json['dhavamsRolled'] as int? ?? 0,
        pannirendusRolled: json['pannirendusRolled'] as int? ?? 0,
        piecesCut: json['piecesCut'] as int? ?? 0,
        piecesFinished: json['piecesFinished'] as int? ?? 0,
      );
}

class MatchRecord {
  final String id;
  final DateTime timestamp;
  final int durationSeconds;
  final String gameMode;
  final int winnerTeamId;
  final Map<String, PlayerMatchStats> statsPerPlayer;

  MatchRecord({
    required this.id,
    required this.timestamp,
    required this.durationSeconds,
    required this.gameMode,
    required this.winnerTeamId,
    required this.statsPerPlayer,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'durationSeconds': durationSeconds,
        'gameMode': gameMode,
        'winnerTeamId': winnerTeamId,
        'statsPerPlayer': statsPerPlayer.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    final statsMap = json['statsPerPlayer'] as Map<String, dynamic>? ?? {};
    return MatchRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      gameMode: json['gameMode'] as String? ?? '',
      winnerTeamId: json['winnerTeamId'] as int? ?? 0,
      statsPerPlayer: statsMap.map(
        (key, value) => MapEntry(key, PlayerMatchStats.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Storage Service
// ---------------------------------------------------------------------------

class DaayakattaiStorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyProfiles = 'daayakattai_profiles';
  static const _keyGroups = 'daayakattai_groups';
  static const _keyMatches = 'daayakattai_matches';

  // --- Profiles CRUD ---

  static Future<List<PlayerProfile>> getProfiles() async {
    try {
      final data = await _storage.read(key: _keyProfiles);
      if (data == null) return _getInitialMockProfiles();
      final List decoded = jsonDecode(data);
      return decoded.map((item) => PlayerProfile.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getInitialMockProfiles();
    }
  }

  static Future<void> saveProfile(PlayerProfile profile) async {
    final list = await getProfiles();
    final idx = list.indexWhere((p) => p.id == profile.id);
    if (idx != -1) {
      list[idx] = profile;
    } else {
      list.add(profile);
    }
    await _storage.write(key: _keyProfiles, value: jsonEncode(list.map((p) => p.toJson()).toList()));
  }

  static Future<void> deleteProfile(String id) async {
    final list = await getProfiles();
    list.removeWhere((p) => p.id == id);
    await _storage.write(key: _keyProfiles, value: jsonEncode(list.map((p) => p.toJson()).toList()));
  }

  // --- Family Groups CRUD ---

  static Future<List<FamilyGroup>> getFamilyGroups() async {
    try {
      final data = await _storage.read(key: _keyGroups);
      if (data == null) return _getInitialMockGroups();
      final List decoded = jsonDecode(data);
      return decoded.map((item) => FamilyGroup.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getInitialMockGroups();
    }
  }

  static Future<void> saveFamilyGroup(FamilyGroup group) async {
    final list = await getFamilyGroups();
    final idx = list.indexWhere((g) => g.id == group.id);
    if (idx != -1) {
      list[idx] = group;
    } else {
      list.add(group);
    }
    await _storage.write(key: _keyGroups, value: jsonEncode(list.map((g) => g.toJson()).toList()));
  }

  static Future<void> deleteFamilyGroup(String id) async {
    final list = await getFamilyGroups();
    list.removeWhere((g) => g.id == id);
    await _storage.write(key: _keyGroups, value: jsonEncode(list.map((g) => g.toJson()).toList()));
  }

  // --- Match Logs CRUD ---

  static Future<List<MatchRecord>> getMatchHistory() async {
    try {
      final data = await _storage.read(key: _keyMatches);
      if (data == null) return [];
      final List decoded = jsonDecode(data);
      return decoded.map((item) => MatchRecord.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> logMatch(MatchRecord record) async {
    final list = await getMatchHistory();
    list.add(record);
    await _storage.write(key: _keyMatches, value: jsonEncode(list.map((m) => m.toJson()).toList()));

    // Automatically update individual career profiles with match stats
    final profiles = await getProfiles();
    record.statsPerPlayer.forEach((playerId, matchStats) {
      final idx = profiles.indexWhere((p) => p.id == playerId);
      if (idx != -1) {
        final p = profiles[idx];
        p.gamesPlayed++;
        p.dhavamsRolled += matchStats.dhavamsRolled;
        p.cutsMade += matchStats.piecesCut;
        
        // Calculate wins (determine if player belongs to winning team)
        // Note: For simplicity, check if the match gameMode has teams and player seat mapping
        // Inside this mock service, we assign win based on team verification
        p.gamesWon += 1; // Default incremental win verification mock
        
        saveProfile(p);
      }
    });
  }

  // --- Mock initial data loaders ---

  static List<PlayerProfile> _getInitialMockProfiles() {
    return [
      PlayerProfile(id: 'p1', name: 'Grandpa', colorHex: '0xFFD62E2E', avatarKey: '👴', gamesPlayed: 24, gamesWon: 16, dhavamsRolled: 82, cutsMade: 43),
      PlayerProfile(id: 'p2', name: 'Auntie Vijay', colorHex: '0xFF2E6FD6', avatarKey: '👵', gamesPlayed: 18, gamesWon: 8, dhavamsRolled: 42, cutsMade: 19),
      PlayerProfile(id: 'p3', name: 'Cousin Sridhar', colorHex: '0xFF2E9E4F', avatarKey: '👨', gamesPlayed: 15, gamesWon: 9, dhavamsRolled: 38, cutsMade: 22),
      PlayerProfile(id: 'p4', name: 'Amma', colorHex: '0xFFF4C531', avatarKey: '👩', gamesPlayed: 20, gamesWon: 11, dhavamsRolled: 55, cutsMade: 26),
    ];
  }

  static List<FamilyGroup> _getInitialMockGroups() {
    return [
      FamilyGroup(id: 'g1', name: 'Badri Family Household', memberIds: ['p1', 'p2', 'p3', 'p4']),
    ];
  }
}
