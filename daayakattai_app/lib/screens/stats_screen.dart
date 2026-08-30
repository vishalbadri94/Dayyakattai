import 'package:flutter/material.dart';
import '../services/daayakattai_storage_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<PlayerProfile> _profiles = [];
  List<MatchRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final profiles = await DaayakattaiStorageService.getProfiles();
    final history = await DaayakattaiStorageService.getMatchHistory();
    setState(() {
      _profiles = profiles;
      // Sort history descending by timestamp
      _history = history.reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort profiles by career wins descending to determine leader
    final leaderboard = List<PlayerProfile>.from(_profiles);
    leaderboard.sort((a, b) => b.gamesWon.compareTo(a.gamesWon));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Stats & History', style: TextStyle(color: Color(0xFFF1E4C4), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F0E0E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Career Leaderboard Card
            const Text(
              'Hall of Fame (விருதுகள்)',
              style: TextStyle(color: Color(0xFFD9A843), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD9A843).withOpacity(0.3)),
              ),
              child: leaderboard.isEmpty
                  ? const Center(child: Text('No stats available.', style: TextStyle(color: Colors.white30)))
                  : Column(
                      children: leaderboard.map((p) {
                        final idx = leaderboard.indexOf(p);
                        final rankEmoji = idx == 0 ? '🏆 ' : idx == 1 ? '🥈 ' : idx == 2 ? '🥉 ' : '👤 ';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(rankEmoji, style: const TextStyle(fontSize: 20)),
                                  Text(
                                    p.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${p.gamesWon} Wins',
                                    style: const TextStyle(color: Color(0xFFD9A843), fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${p.gamesPlayed} Played)',
                                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 28),

            // Roll / Action Metrics list
            const Text(
              'Individual Achievements',
              style: TextStyle(color: Color(0xFFD9A843), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _profiles.isEmpty
                ? const Text('No data loaded.', style: TextStyle(color: Colors.white30))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final p = _profiles[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x1F000000),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${p.avatarKey} ${p.name}',
                              style: const TextStyle(color: Color(0xFFF1E4C4), fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text('🎲 Dhayams: ${p.dhavamsRolled}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            Text('⚔️ Opponents Cut: ${p.cutsMade}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 28),

            // Recent Match Logs
            const Text(
              'Recent Match History',
              style: TextStyle(color: Color(0xFFD9A843), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _history.isEmpty
                ? const Text('No matches logged yet.', style: TextStyle(color: Colors.white30))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final record = _history[index];
                      final dateStr = '${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year}';
                      return Card(
                        color: const Color(0x1F000000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.white10),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            'Winner Team: Team ${record.winnerTeamId}',
                            style: const TextStyle(color: Color(0xFFF1E4C4), fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(
                            'Mode: ${record.gameMode} | Duration: ${(record.durationSeconds / 60).round()} mins',
                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                          trailing: Text(
                            dateStr,
                            style: const TextStyle(color: Color(0xFFD9A843), fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
