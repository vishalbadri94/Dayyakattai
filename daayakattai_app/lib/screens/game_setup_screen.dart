import 'package:flutter/material.dart';
import '../daayakattai_engine.dart';
import '../daayakattai_board.dart';
import '../services/daayakattai_storage_service.dart';
import '../agora_video_header.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  List<FamilyGroup> _groups = [];
  List<PlayerProfile> _allProfiles = [];

  FamilyGroup? _selectedGroup;
  GameMode _selectedMode = GameMode.fourPlayerTeams;
  Map<int, PlayerProfile?> _seatAssignments = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final groups = await DaayakattaiStorageService.getFamilyGroups();
    final profiles = await DaayakattaiStorageService.getProfiles();
    setState(() {
      _groups = groups;
      _allProfiles = profiles;
      if (groups.isNotEmpty) {
        _selectedGroup = groups.first;
        _resetSeatAssignments();
      }
    });
  }

  int _getRequiredPlayerCount(GameMode mode) {
    switch (mode) {
      case GameMode.twoPlayer:
        return 2;
      case GameMode.threePlayer:
        return 3;
      case GameMode.fourPlayer:
      case GameMode.fourPlayerTeams:
        return 4;
      case GameMode.sixPlayerTeams:
        return 6;
      case GameMode.eightPlayerTeams:
        return 8;
      case GameMode.twelvePlayerTeams:
        return 12;
    }
  }

  void _resetSeatAssignments() {
    _seatAssignments.clear();
    final requiredCount = _getRequiredPlayerCount(_selectedMode);
    
    // Auto-populate seats if members are available
    if (_selectedGroup != null) {
      final members = _selectedGroup!.memberIds
          .map((id) => _allProfiles.firstWhere((p) => p.id == id, orElse: () => PlayerProfile(id: '', name: '', colorHex: '', avatarKey: '')))
          .where((p) => p.id.isNotEmpty)
          .toList();

      for (int i = 0; i < requiredCount; i++) {
        if (i < members.length) {
          _seatAssignments[i] = members[i];
        } else {
          _seatAssignments[i] = null; // Unassigned
        }
      }
    }
  }

  String _modeLabel(GameMode mode) {
    switch (mode) {
      case GameMode.twoPlayer:
        return '2 Players (Single)';
      case GameMode.threePlayer:
        return '3 Players (Single)';
      case GameMode.fourPlayer:
        return '4 Players (Single)';
      case GameMode.fourPlayerTeams:
        return '4 Players (2 Teams of 2)';
      case GameMode.sixPlayerTeams:
        return '6 Players (3 Teams of 2)';
      case GameMode.eightPlayerTeams:
        return '8 Players (4 Teams of 2)';
      case GameMode.twelvePlayerTeams:
        return '12 Players (4 Teams of 3)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiredCount = _getRequiredPlayerCount(_selectedMode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Match', style: TextStyle(color: Color(0xFFF1E4C4), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F0E0E),
        elevation: 0,
      ),
      body: _groups.isEmpty
          ? const Center(child: Text('Create a Family Group first to set up a game.', style: TextStyle(color: Colors.white30)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Family Group
                  const Text('Select Family Group', style: TextStyle(color: Color(0xFFD9A843), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FamilyGroup>(
                        value: _selectedGroup,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF3F0E0E),
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        onChanged: (group) {
                          if (group != null) {
                            setState(() {
                              _selectedGroup = group;
                              _resetSeatAssignments();
                            });
                          }
                        },
                        items: _groups.map((g) {
                          return DropdownMenuItem<FamilyGroup>(
                            value: g,
                            child: Text(g.name),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Select Game Mode
                  const Text('Select Game Mode', style: TextStyle(color: Color(0xFFD9A843), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<GameMode>(
                        value: _selectedMode,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF3F0E0E),
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        onChanged: (mode) {
                          if (mode != null) {
                            setState(() {
                              _selectedMode = mode;
                              _resetSeatAssignments();
                            });
                          }
                        },
                        items: GameMode.values.map((mode) {
                          return DropdownMenuItem<GameMode>(
                            value: mode,
                            child: Text(_modeLabel(mode)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Seat Assignments List
                  Text(
                    'Assign Seats ($requiredCount players required)',
                    style: const TextStyle(color: Color(0xFFD9A843), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requiredCount,
                    itemBuilder: (context, index) {
                      final assigned = _seatAssignments[index];
                      // Determine seat team color ring mapping
                      // Seats are assigned to teams based on mode:
                      final int teamId = index % 4;
                      final colors = [
                        const Color(0xFFD62E2E), // Red
                        const Color(0xFF2E6FD6), // Blue
                        const Color(0xFF2E9E4F), // Green
                        const Color(0xFFF4C531), // Yellow
                      ];
                      final seatColor = colors[teamId];

                      // Fetch list of profiles in group not already assigned to other seats
                      final assignedIds = _seatAssignments.values.where((p) => p != null).map((p) => p!.id).toSet();
                      final availableProfiles = _selectedGroup == null
                          ? <PlayerProfile>[]
                          : _selectedGroup!.memberIds
                              .map((id) => _allProfiles.firstWhere((p) => p.id == id))
                              .where((p) => !assignedIds.contains(p.id) || p.id == assigned?.id)
                              .toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x1F000000),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: seatColor.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(color: seatColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Player ${index + 1}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            DropdownButton<PlayerProfile>(
                              value: assigned,
                              hint: const Text('Unassigned', style: TextStyle(color: Colors.white30)),
                              dropdownColor: const Color(0xFF3F0E0E),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              onChanged: (p) {
                                setState(() {
                                  _seatAssignments[index] = p;
                                });
                              },
                              items: availableProfiles.map((p) {
                                return DropdownMenuItem<PlayerProfile>(
                                  value: p,
                                  child: Text('${p.avatarKey}  ${p.name}'),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Start Game Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD9A843),
                        foregroundColor: const Color(0xFF3F0E0E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                      ),
                      onPressed: () {
                        // Gather list of profiles assigned
                        final List<PlayerProfile> profiles = [];
                        for (int i = 0; i < requiredCount; i++) {
                          final p = _seatAssignments[i];
                          if (p != null) {
                            profiles.add(p);
                          } else {
                            // Fallback mock profile for unassigned seats
                            profiles.add(PlayerProfile(
                              id: 'fallback-$i',
                              name: 'Player ${i + 1}',
                              colorHex: '0xFF808080',
                              avatarKey: '👤',
                            ));
                          }
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              backgroundColor: const Color(0xFF3F0E0E),
                              appBar: AppBar(
                                title: Text(_modeLabel(_selectedMode), style: const TextStyle(color: Color(0xFFF1E4C4), fontWeight: FontWeight.bold)),
                                backgroundColor: const Color(0xFF3F0E0E),
                                elevation: 0,
                                leading: IconButton(
                                  icon: const Icon(Icons.close, color: Color(0xFFF1E4C4)),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              body: SafeArea(
                                child: Stack(
                                  children: [
                                    // The main board occupying the entire screen space
                                    Positioned.fill(
                                      child: DaayakattaiBoard(
                                        initialMode: _selectedMode,
                                        initialProfiles: profiles,
                                      ),
                                    ),
                                    // A small, elegant floating Video Header overlay at the top (semi-transparent)
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      right: 10,
                                      height: 100, // Compact height for floating video frames
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          child: AgoraVideoHeader(channelName: 'family-daayakattai-room'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'ஆட்டத்தைத் தொடங்கு / Start Match',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}