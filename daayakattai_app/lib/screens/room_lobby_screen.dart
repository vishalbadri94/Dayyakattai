import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../daayakattai_engine.dart';
import '../services/daayakattai_share_service.dart';

class RoomLobbyScreen extends StatefulWidget {
  final bool isHost;
  final String? initialRoomCode;

  const RoomLobbyScreen({
    super.key,
    required this.isHost,
    this.initialRoomCode,
  });

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  static const Color _darkRed = Color(0xFF2B0A0A);
  static const Color _gold = Color(0xFFD9A843);
  static const Color _ivory = Color(0xFFF1E4C4);

  late bool _isHost;
  late String _roomCode;
  final TextEditingController _roomCodeController = TextEditingController();
  GameMode _selectedMode = GameMode.twoPlayer;
  bool _isJoining = false;
  String _joinStatus = '';
  bool _isReady = false;
  String? _hostGameMode;

  // Placeholder players for host mode
  final List<String> _players = [];

  @override
  void initState() {
    super.initState();
    _isHost = widget.isHost;
    _roomCode = widget.initialRoomCode ?? DaayakattaiShareService.generateChannelName();
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  String _getGameModeLabel(GameMode mode) {
    switch (mode) {
      case GameMode.twoPlayer:
        return '2 Player';
      case GameMode.threePlayer:
        return '3 Player';
      case GameMode.fourPlayer:
        return '4 Player';
      case GameMode.fourPlayerTeams:
        return '4 Player Teams';
      case GameMode.sixPlayerTeams:
        return '6 Player Teams';
      case GameMode.eightPlayerTeams:
        return '8 Player Teams';
      case GameMode.twelvePlayerTeams:
        return '12 Player Teams';
    }
  }

  bool _validateRoomCode(String code) {
    final upperCode = code.toUpperCase().trim();
    if (upperCode.length != 6) return false;
    if (!upperCode.startsWith('DAY')) return false;
    return RegExp(r'^[A-Z0-9]{3}$').hasMatch(upperCode.substring(3));
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _roomCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room code copied to clipboard!'),
          backgroundColor: _gold,
        ),
      );
    }
  }

  Future<void> _shareViaWhatsApp() async {
    await DaayakattaiShareService.shareGameInvite(
      channelName: _roomCode,
      gameMode: _getGameModeLabel(_selectedMode),
      hostName: 'Host',
      language: 'english',
    );
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.toUpperCase().trim();
    if (!_validateRoomCode(code)) {
      setState(() {
        _joinStatus = 'Invalid code. Format: DAY + 3 characters';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _joinStatus = 'Connecting...';
    });

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isJoining = false;
        _isReady = true;
        _hostGameMode = '2 Player'; // Placeholder - would come from actual connection
        _joinStatus = 'Connected!';
      });
    }
  }

  void _startGame() {
    if (_players.length < 2) return;
    Navigator.pop(context, {
      'channelName': _roomCode,
      'gameMode': _selectedMode,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkRed,
      appBar: AppBar(
        backgroundColor: _darkRed,
        foregroundColor: _ivory,
        elevation: 0,
        title: const Text(
          'Room Lobby',
          style: TextStyle(
            color: _ivory,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode Toggle
              Container(
                decoration: BoxDecoration(
                  color: _darkRed.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeButton('Host', _isHost),
                    ),
                    Expanded(
                      child: _buildModeButton('Guest', !_isHost),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (_isHost) ...[
                _buildHostMode(),
              ] else ...[
                _buildGuestMode(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isHost = label == 'Host';
          if (_isHost) {
            _roomCode = DaayakattaiShareService.generateChannelName();
          }
          _isJoining = false;
          _joinStatus = '';
          _isReady = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _gold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? _darkRed : _ivory,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHostMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room Code Display
        Text(
          'ROOM CODE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ivory.withValues(alpha: 0.7),
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _roomCode,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _gold,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.copy,
                label: 'Copy Code',
                onTap: _copyCode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.share,
                label: 'Share via WhatsApp',
                onTap: _shareViaWhatsApp,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Players List
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _darkRed.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLAYERS (${_players.length})',
                style: TextStyle(
                  color: _ivory.withValues(alpha: 0.7),
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              if (_players.isEmpty)
                _buildWaitingForPlayers()
              else
                ..._players.map((player) => _buildPlayerTile(player)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Game Mode Selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _darkRed.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GAME MODE',
                style: TextStyle(
                  color: _ivory.withValues(alpha: 0.7),
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GameMode>(
                value: _selectedMode,
                dropdownColor: _darkRed,
                style: const TextStyle(color: _ivory),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _darkRed.withValues(alpha: 0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _gold),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _gold.withValues(alpha: 0.5)),
                  ),
                ),
                items: GameMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(
                      _getGameModeLabel(mode),
                      style: const TextStyle(color: _ivory),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMode = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Start Game Button
        ElevatedButton(
          onPressed: _players.length >= 2 ? _startGame : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            disabledBackgroundColor: _gold.withValues(alpha: 0.3),
            foregroundColor: _darkRed,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Start Game',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _players.length >= 2 ? _darkRed : _ivory.withValues(alpha: 0.5),
            ),
          ),
        ),
        if (_players.length < 2)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Need at least 2 players to start',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ivory.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWaitingForPlayers() {
    return Row(
      children: [
        Text(
          'Waiting for players',
          style: TextStyle(
            color: _ivory.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 4),
        _AnimatedDots(),
      ],
    );
  }

  Widget _buildPlayerTile(String playerName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.person, color: _gold, size: 20),
          const SizedBox(width: 8),
          Text(
            playerName,
            style: const TextStyle(color: _ivory, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _gold.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _gold, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ivory,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room Code Input
        TextField(
          controller: _roomCodeController,
          enabled: !_isJoining && !_isReady,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            color: _ivory,
            fontSize: 24,
            letterSpacing: 4,
          ),
          decoration: InputDecoration(
            labelText: 'Enter Room Code',
            labelStyle: TextStyle(color: _ivory.withValues(alpha: 0.7)),
            hintText: 'DAYXXX',
            hintStyle: TextStyle(color: _ivory.withValues(alpha: 0.3)),
            filled: true,
            fillColor: _darkRed.withValues(alpha: 0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _gold),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _gold.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _gold, width: 2),
            ),
          ),
          onSubmitted: (_) => _joinRoom(),
        ),
        const SizedBox(height: 16),

        // Join Button
        ElevatedButton(
          onPressed: _isJoining || _isReady ? null : _joinRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            disabledBackgroundColor: _gold.withValues(alpha: 0.3),
            foregroundColor: _darkRed,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isJoining
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _darkRed,
                  ),
                )
              : Text(
                  _isReady ? 'Joined' : 'Join',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Status
        if (_joinStatus.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isReady
                  ? Colors.green.withValues(alpha: 0.1)
                  : _gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isReady ? Colors.green : _gold,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isReady ? Icons.check_circle : Icons.info,
                  color: _isReady ? Colors.green : _gold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _joinStatus,
                    style: TextStyle(
                      color: _isReady ? Colors.green : _ivory,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Host Game Mode Display
        if (_isReady && _hostGameMode != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _darkRed.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOST GAME MODE',
                  style: TextStyle(
                    color: _ivory.withValues(alpha: 0.7),
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hostGameMode!,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Ready Status
        if (_isReady) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Ready to play!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dotCount = 3;
        final activeDot = (_controller.value * dotCount).floor() % dotCount;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(dotCount, (index) {
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == activeDot
                    ? const Color(0xFFD9A843)
                    : const Color(0xFFF1E4C4).withValues(alpha: 0.3),
              ),
            );
          }),
        );
      },
    );
  }
}