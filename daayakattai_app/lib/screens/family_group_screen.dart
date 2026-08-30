import 'package:flutter/material.dart';
import '../services/daayakattai_storage_service.dart';

class FamilyGroupScreen extends StatefulWidget {
  const FamilyGroupScreen({super.key});

  @override
  State<FamilyGroupScreen> createState() => _FamilyGroupScreenState();
}

class _FamilyGroupScreenState extends State<FamilyGroupScreen> {
  List<FamilyGroup> _groups = [];
  List<PlayerProfile> _allProfiles = [];

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
    });
  }

  void _showGroupDialog([FamilyGroup? group]) {
    final isEdit = group != null;
    final nameController = TextEditingController(text: group?.name ?? '');
    final List<String> selectedMemberIds = List.from(group?.memberIds ?? []);

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
                isEdit ? 'Edit Family Group' : 'Create Family Group',
                style: const TextStyle(color: Color(0xFFF1E4C4), fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Family Name', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0x33000000),
                          hintText: 'e.g. Badri Family',
                          hintStyle: const TextStyle(color: Colors.white30),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text('Select Members', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 8),
                      _allProfiles.isEmpty
                          ? const Text('No profiles found. Create profiles first.', style: TextStyle(color: Colors.white30))
                          : Column(
                              children: _allProfiles.map((p) {
                                final isSel = selectedMemberIds.contains(p.id);
                                return CheckboxListTile(
                                  activeColor: const Color(0xFFD9A843),
                                  checkColor: const Color(0xFF3F0E0E),
                                  title: Text('${p.avatarKey}  ${p.name}', style: const TextStyle(color: Colors.white, fontSize: 18)),
                                  value: isSel,
                                  onChanged: (bool? val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selectedMemberIds.add(p.id);
                                      } else {
                                        selectedMemberIds.remove(p.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                    ],
                  ),
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
                    final newGroup = FamilyGroup(
                      id: isEdit ? group.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      memberIds: selectedMemberIds,
                    );
                    await DaayakattaiStorageService.saveFamilyGroup(newGroup);
                    Navigator.pop(context);
                    _loadData();
                  },
                  child: Text(isEdit ? 'Save' : 'Create', style: const TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('Family Groups', style: TextStyle(color: Color(0xFFF1E4C4), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F0E0E),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD9A843),
        foregroundColor: const Color(0xFF3F0E0E),
        onPressed: () => _showGroupDialog(),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _groups.isEmpty
          ? const Center(child: Text('No family groups created yet.', style: TextStyle(color: Colors.white30)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final g = _groups[index];
                // Resolve member names for display
                final memberNames = g.memberIds
                    .map((id) {
                      final p = _allProfiles.firstWhere((p) => p.id == id, orElse: () => PlayerProfile(id: '', name: 'Unknown', colorHex: '', avatarKey: ''));
                      return p.name;
                    })
                    .where((name) => name != 'Unknown')
                    .join(', ');

                return Card(
                  color: const Color(0x33000000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              g.name,
                              style: const TextStyle(color: Color(0xFFF1E4C4), fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                  onPressed: () => _showGroupDialog(g),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_outlined, color: Colors.redAccent),
                                  onPressed: () async {
                                    await DaayakattaiStorageService.deleteFamilyGroup(g.id);
                                    _loadData();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Members: ${g.memberIds.length}',
                          style: const TextStyle(color: Color(0xFFD9A843), fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          memberNames.isEmpty ? 'No members added yet.' : memberNames,
                          style: const TextStyle(color: Colors.white54, fontSize: 15),
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
