import 'package:flutter/material.dart';
import '../services/daayakattai_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<PlayerProfile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final list = await DaayakattaiStorageService.getProfiles();
    setState(() => _profiles = list);
  }

  void _showProfileDialog([PlayerProfile? profile]) {
    final isEdit = profile != null;
    final nameController = TextEditingController(text: profile?.name ?? '');
    String selectedColor = profile?.colorHex ?? '0xFFD62E2E';
    String selectedAvatar = profile?.avatarKey ?? '👴';

    final List<String> colors = [
      '0xFFD62E2E', // Red
      '0xFF2E6FD6', // Blue
      '0xFF2E9E4F', // Green
      '0xFFF4C531', // Yellow
      '0xFF9C27B0', // Purple
      '0xFFE91E63', // Pink
    ];

    final List<String> avatars = ['👴', '👵', '👨', '👩', '👦', '👧', '🦁', '🦉', '🦊', '🐻'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF3F0E0E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFD9A843), width: 2),
              ),
              title: Text(
                isEdit ? 'Edit Profile' : 'New Family Member',
                style: const TextStyle(color: Color(0xFFF1E4C4), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    const Text('Name', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0x33000000),
                        hintText: 'e.g. Grandma',
                        hintStyle: const TextStyle(color: Colors.white30),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Avatar Picker
                    const Text('Select Avatar', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: avatars.map((av) {
                          final isSel = selectedAvatar == av;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedAvatar = av),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSel ? const Color(0xFFD9A843) : Colors.transparent,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(av, style: const TextStyle(fontSize: 24)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Color Picker
                    const Text('Preferred Pawn Color', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: colors.map((colHex) {
                        final color = Color(int.parse(colHex));
                        final isSel = selectedColor == colHex;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = colHex),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9A843),
                    foregroundColor: const Color(0xFF3F0E0E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final newProfile = PlayerProfile(
                      id: isEdit ? profile.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      colorHex: selectedColor,
                      avatarKey: selectedAvatar,
                      gamesPlayed: isEdit ? profile.gamesPlayed : 0,
                      gamesWon: isEdit ? profile.gamesWon : 0,
                      dhavamsRolled: isEdit ? profile.dhavamsRolled : 0,
                      cutsMade: isEdit ? profile.cutsMade : 0,
                    );
                    await DaayakattaiStorageService.saveProfile(newProfile);
                    Navigator.pop(context);
                    _loadProfiles();
                  },
                  child: Text(isEdit ? 'Save' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members', style: TextStyle(color: Color(0xFFF1E4C4), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F0E0E),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD9A843),
        foregroundColor: const Color(0xFF3F0E0E),
        onPressed: () => _showProfileDialog(),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _profiles.isEmpty
          ? const Center(child: Text('No family profiles created yet.', style: TextStyle(color: Colors.white30)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                final p = _profiles[index];
                final col = Color(int.parse(p.colorHex));
                return Card(
                  color: const Color(0x33000000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: col.withValues(alpha: 0.15),
                      radius: 28,
                      child: Text(p.avatarKey, style: const TextStyle(fontSize: 28)),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(color: Color(0xFFF1E4C4), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Career: ${p.gamesPlayed} matches / ${p.gamesWon} wins',
                      style: const TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                          onPressed: () => _showProfileDialog(p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_outlined, color: Colors.redAccent),
                          onPressed: () async {
                            await DaayakattaiStorageService.deleteProfile(p.id);
                            _loadProfiles();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
