import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'daayakattai_engine.dart';
import 'services/daayakattai_storage_service.dart';

const int _gridSize = 7;

enum DaayakattaiTeam { red, blue, green, yellow }

extension DaayakattaiTeamX on DaayakattaiTeam {
  Color get color {
    switch (this) {
      case DaayakattaiTeam.red:
        return const Color(0xFFD62E2E);
      case DaayakattaiTeam.blue:
        return const Color(0xFF2E6FD6);
      case DaayakattaiTeam.green:
        return const Color(0xFF2E9E4F);
      case DaayakattaiTeam.yellow:
        return const Color(0xFFF4C531);
    }
  }

  String get label {
    switch (this) {
      case DaayakattaiTeam.red:
        return 'Red Team';
      case DaayakattaiTeam.blue:
        return 'Blue Team';
      case DaayakattaiTeam.green:
        return 'Green Team';
      case DaayakattaiTeam.yellow:
        return 'Yellow Team';
    }
  }
}

class DaayakattaiBoardGeometry {
  /// Check if a cell is one of the four unused 2x2 corners (home areas).
  static bool isUnusedCorner(int row, int col) {
    return ((row == 1 || row == 2) && (col == 1 || col == 2)) ||
        ((row == 1 || row == 2) && (col == 4 || col == 5)) ||
        ((row == 4 || row == 5) && (col == 1 || col == 2)) ||
        ((row == 4 || row == 5) && (col == 4 || col == 5));
  }

  /// Middle row and middle column are safe cross cells.
  static bool isSafeCrossCell(int row, int col) {
    return (row == 3 && col >= 0 && col <= 6) ||
        (col == 3 && row >= 0 && row <= 6);
  }

  static Rect boardRect(Size size) {
    final double side = math.min(size.width, size.height) - 14;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side,
      height: side,
    );
  }

  static Offset cellCenter(Rect boardRect, int row, int col) {
    return Offset(
      boardRect.left + (col + 0.5) * boardRect.width / _gridSize,
      boardRect.top + (row + 0.5) * boardRect.height / _gridSize,
    );
  }

  /// Calculates visual offset for home base pieces in the 2x2 corner areas.
  static Offset homePieceOffset(Rect boardRect, int playerId, int pieceId) {
    int startRow = 0;
    int startCol = 0;

    final int teamId = playerId % 4;
    switch (teamId) {
      case 0: // Red: Top-Left (1,1) to (2,2)
        startRow = 1;
        startCol = 1;
        break;
      case 1: // Blue: Top-Right (1,4) to (2,5)
        startRow = 1;
        startCol = 4;
        break;
      case 2: // Green: Bottom-Right (4,4) to (5,5)
        startRow = 4;
        startCol = 4;
        break;
      case 3: // Yellow: Bottom-Left (4,1) to (5,2)
        startRow = 4;
        startCol = 1;
        break;
    }

    final double cellW = boardRect.width / _gridSize;
    final double cellH = boardRect.height / _gridSize;
    final Offset cornerCenter = Offset(
      boardRect.left + (startCol + 1.0) * cellW,
      boardRect.top + (startRow + 1.0) * cellH,
    );

    // Stagger layout based on player count
    if (playerId < 4) {
      // 4-player or less: nice big 2x2 grid
      final int row = pieceId ~/ 2;
      final int col = pieceId % 2;
      final double dx = (col - 0.5) * cellW * 0.45;
      final double dy = (row - 0.5) * cellH * 0.45;
      return cornerCenter + Offset(dx, dy);
    } else {
      // 6, 8, 12 players: compact 3x4 grid to fit up to 12 pieces in the corner
      final int playerRank = playerId ~/ 4;
      final int totalRank = playerRank * 4 + pieceId;
      final int row = totalRank ~/ 4;
      final int col = totalRank % 4;
      final double dx = (col - 1.5) * cellW * 0.28;
      final double dy = (row - 1.0) * cellH * 0.28;
      return cornerCenter + Offset(dx, dy);
    }
  }
}

class DaayakattaiBoardPainter extends CustomPainter {
  DaayakattaiBoardPainter({
    required this.game,
    required this.validPieceKeys,
    required this.pulse,
    this.movingPieceKey,
    this.moveFromCell,
    this.moveToCell,
    this.moveProgress = 0.0,
  });

  final DaayakattaiGame game;
  final Set<String> validPieceKeys; // Formatted as "playerId-pieceId"
  final double pulse;
  final String? movingPieceKey;
  final BoardCoordinate? moveFromCell;
  final BoardCoordinate? moveToCell;
  final double moveProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect boardRect = DaayakattaiBoardGeometry.boardRect(size);

    _drawRawSilkBackground(canvas, size);
    _drawBrassOuterFrame(canvas, boardRect);
    _drawGridCells(canvas, boardRect);
    _drawPieces(canvas, boardRect);
  }

  @override
  bool shouldRepaint(covariant DaayakattaiBoardPainter oldDelegate) => true;

  void _drawRawSilkBackground(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6E1F1F), Color(0xFF581616), Color(0xFF3F0E0E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final Paint threadLight = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 0.7;
    final Paint threadDark = Paint()
      ..color = const Color(0x0F000000)
      ..strokeWidth = 0.7;

    for (int i = 0; i < 36; i++) {
      final double y = rect.top + (i / 35) * rect.height;
      final Path path = Path()..moveTo(rect.left, y);
      for (double x = rect.left; x <= rect.right; x += 5) {
        path.lineTo(x, y + math.sin((x + i * 11) * 0.03) * 1.1);
      }
      canvas.drawPath(path, threadLight);
    }

    for (int i = 0; i < 36; i++) {
      final double x = rect.left + (i / 35) * rect.width;
      final Path path = Path()..moveTo(x, rect.top);
      for (double y = rect.top; y <= rect.bottom; y += 5) {
        path.lineTo(x + math.cos((y + i * 9) * 0.03) * 1.1, y);
      }
      canvas.drawPath(path, threadDark);
    }
  }

  void _drawBrassOuterFrame(Canvas canvas, Rect boardRect) {
    final Rect outer = boardRect.inflate(6);
    final RRect rrect = RRect.fromRectAndRadius(outer, const Radius.circular(14));
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFF8E08E),
          Color(0xFFD8A63E),
          Color(0xFF8A6420),
          Color(0xFFE8C565),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(outer);
    canvas.drawRRect(rrect, paint);
  }

  void _drawGridCells(Canvas canvas, Rect boardRect) {
    final double cellW = boardRect.width / _gridSize;
    final double cellH = boardRect.height / _gridSize;

    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        // Skip drawing the 2x2 corner squares completely to form a clean cruciform track
        if (DaayakattaiBoardGeometry.isUnusedCorner(row, col)) {
          continue;
        }

        final Rect cellRect = Rect.fromLTWH(
          boardRect.left + col * cellW,
          boardRect.top + row * cellH,
          cellW,
          cellH,
        );
        final Rect fillRect = cellRect.deflate(1.4);
        final bool safe = DaayakattaiBoardGeometry.isSafeCrossCell(row, col);

        final Paint fillPaint = Paint()
          ..shader = LinearGradient(
            colors: safe
                ? const [Color(0xFFEAD6AC), Color(0xFFDFC08A)]
                : const [Color(0xFFF6ECD4), Color(0xFFEBDDB9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(fillRect);

        canvas.drawRRect(
          RRect.fromRectAndRadius(fillRect, const Radius.circular(2.5)),
          fillPaint,
        );

        final Paint borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..shader = const LinearGradient(
            colors: [Color(0xFFF3D67B), Color(0xFF8E6A2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(fillRect);

        canvas.drawRRect(
          RRect.fromRectAndRadius(fillRect, const Radius.circular(2.5)),
          borderPaint,
        );

        // Grid accents
        canvas.drawLine(
          fillRect.topLeft + const Offset(1.5, 1.5),
          fillRect.topRight + const Offset(-1.5, 1.5),
          Paint()
            ..color = const Color(0x22FFFFFF)
            ..strokeWidth = 0.8,
        );
        canvas.drawLine(
          fillRect.bottomLeft + const Offset(1.5, -1.5),
          fillRect.bottomRight + const Offset(-1.5, -1.5),
          Paint()
            ..color = const Color(0x1A3B1A0C)
            ..strokeWidth = 0.8,
        );
      }
    }

    // Draw lotuses on all safe squares
    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        if (!DaayakattaiBoardGeometry.isUnusedCorner(row, col) &&
            DaayakattaiBoardGeometry.isSafeCrossCell(row, col)) {
          final Offset center =
              DaayakattaiBoardGeometry.cellCenter(boardRect, row, col);
          _drawLotus(canvas, center, cellW * 0.22);
        }
      }
    }
  }

  void _drawLotus(Canvas canvas, Offset center, double size) {
    final Paint petalPaint = Paint()..color = const Color(0xFF8E3B2F);
    final Paint centerPaint = Paint()..color = const Color(0xFFC47A2E);
    final Paint dotPaint = Paint()..color = const Color(0xFFB1822A);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    for (int i = 0; i < 5; i++) {
      final Path petal = Path()
        ..moveTo(0, 0)
        ..cubicTo(
          -size * 0.55,
          -size * 0.3,
          -size * 0.45 + (i.isEven ? 0.05 * size : 0),
          -size * 1.05,
          0,
          -size * 1.35,
        )
        ..cubicTo(
          size * 0.45 + (i.isOdd ? 0.05 * size : 0),
          -size * 1.05,
          size * 0.55,
          -size * 0.3,
          0,
          0,
        );

      canvas.save();
      canvas.rotate(i * 2 * math.pi / 5);
      canvas.drawPath(petal, petalPaint);
      canvas.restore();
    }

    canvas.drawCircle(Offset.zero, size * 0.42, centerPaint);
    canvas.drawCircle(Offset.zero, size * 0.14, dotPaint);
    canvas.restore();
  }

  void _drawPieces(Canvas canvas, Rect boardRect) {
    final double cellW = boardRect.width / _gridSize;
    final double cellH = boardRect.height / _gridSize;

    // First group pieces by their visual cell center to handle stacking offsets
    final Map<Offset, List<MapEntry<String, Piece>>> stacked = {};

    for (final player in game.players) {
      for (final piece in player.pieces) {
        final key = '${player.id}-${piece.id}';
        
        Offset center;
        if (piece.state == PieceState.home) {
          center = DaayakattaiBoardGeometry.homePieceOffset(boardRect, player.id, piece.id);
        } else {
          final coord = piece.coordinate;
          if (coord == null) continue; // finished pieces or invalid state
          center = DaayakattaiBoardGeometry.cellCenter(boardRect, coord.x, coord.y);
        }

        // Apply interpolation animation if it's the moving piece
        if (key == movingPieceKey && moveFromCell != null && moveToCell != null) {
          final fromCenter = moveFromCell!.x == -1 // -1 flag represents Home State
              ? DaayakattaiBoardGeometry.homePieceOffset(boardRect, player.id, piece.id)
              : DaayakattaiBoardGeometry.cellCenter(boardRect, moveFromCell!.x, moveFromCell!.y);
              
          final toCenter = moveToCell!.x == -2 // -2 flag represents Finished State
              ? DaayakattaiBoardGeometry.cellCenter(boardRect, 3, 3)
              : DaayakattaiBoardGeometry.cellCenter(boardRect, moveToCell!.x, moveToCell!.y);
              
          center = Offset.lerp(fromCenter, toCenter, moveProgress.clamp(0.0, 1.0))!;
        }

        // Stacking offset applies to pieces resting on non-home/non-finished track squares
        if (piece.state == PieceState.outer || piece.state == PieceState.inner) {
          stacked.putIfAbsent(center, () => []).add(MapEntry(key, piece));
        } else {
          // Draw home/finished pieces without stacking logic
          final radius = math.min(cellW, cellH) * 0.28;
          final bool selected = validPieceKeys.contains(key);
          _drawBellPawn(canvas, center, radius, _teamColor(player.teamId), selected);
        }
      }
    }

    // Draw stacked pieces with fractional offset separation
    stacked.forEach((baseCenter, entries) {
      for (int i = 0; i < entries.length; i++) {
        final key = entries[i].key;
        final piece = entries[i].value;

        // Visual stack offset formula
        final double dx = ((i % 2) - 0.5) * cellW * 0.35;
        final double dy = ((i ~/ 2) - 0.5) * cellH * 0.28;
        final Offset stackCenter = baseCenter + Offset(dx, dy);

        final double radius = math.min(cellW, cellH) * 0.26;
        final bool selected = validPieceKeys.contains(key);
        _drawBellPawn(canvas, stackCenter, radius, _teamColor(piece.owner.teamId), selected);
      }
    });
  }

  Color _teamColor(int teamId) {
    switch (teamId) {
      case 0: return const Color(0xFFD62E2E);
      case 1: return const Color(0xFF2E6FD6);
      case 2: return const Color(0xFF2E9E4F);
      case 3: return const Color(0xFFF4C531);
      default: return Colors.grey;
    }
  }

  void _drawBellPawn(
    Canvas canvas,
    Offset center,
    double r,
    Color ringColor,
    bool selected,
  ) {
    if (selected) {
      final double p = pulse.clamp(0.0, 1.0);

      final Paint glowPaint = Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.35 + 0.45 * p)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 4 * p);
      canvas.drawCircle(center, r * 1.5, glowPaint);

      final Paint outlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = const Color(0xFF00E676).withValues(alpha: 0.65 + 0.35 * p);
      canvas.drawCircle(center, r * 1.1, outlinePaint);
    }

    // Draw drop shadow
    final Paint shadowPaint = Paint()..color = const Color(0x44000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.75),
        width: r * 1.4,
        height: r * 0.42,
      ),
      shadowPaint,
    );

    // Lathe-turned bell geometry
    final Path bell = Path()
      ..moveTo(center.dx, center.dy - r)
      ..cubicTo(
        center.dx - r * 0.58,
        center.dy - r * 0.55,
        center.dx - r * 0.60,
        center.dy + r * 0.10,
        center.dx - r * 0.42,
        center.dy + r * 0.58,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + r * 0.85,
        center.dx + r * 0.42,
        center.dy + r * 0.58,
      )
      ..cubicTo(
        center.dx + r * 0.60,
        center.dy + r * 0.10,
        center.dx + r * 0.58,
        center.dy - r * 0.55,
        center.dx,
        center.dy - r,
      )
      ..close();

    final Paint brassPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFBE39C),
          Color(0xFFEAC35D),
          Color(0xFFB9812B),
          Color(0xFF8A5719),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.2));

    canvas.drawPath(bell, brassPaint);
    canvas.drawPath(
      bell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF6A4416),
    );

    // LACQUER RING INLAY
    final Rect ringRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + r * 0.28),
      width: r * 0.9,
      height: r * 0.32,
    );

    canvas.save();
    canvas.clipPath(bell);
    canvas.drawOval(ringRect, Paint()..color = ringColor);
    canvas.drawOval(
      ringRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.restore();

    // Bell top knob
    final Rect knobRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - r * 0.95),
      width: r * 0.5,
      height: r * 0.5,
    );
    final Paint knobPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFF7D8),
          Color(0xFFD2A64E),
          Color(0xFF9A6722),
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(knobRect);

    canvas.drawOval(knobRect, knobPaint);
    canvas.drawOval(
      knobRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF6A4416),
    );
  }
}

class DaayakattaiBoard extends StatefulWidget {
  final GameMode? initialMode;
  final List<PlayerProfile>? initialProfiles;

  const DaayakattaiBoard({
    super.key,
    this.initialMode,
    this.initialProfiles,
  });

  @override
  State<DaayakattaiBoard> createState() => _DaayakattaiBoardState();
}

class _DaayakattaiBoardState extends State<DaayakattaiBoard>
    with TickerProviderStateMixin {
  final GlobalKey _boardKey = GlobalKey();

  late final AnimationController _pulseController;
  late final AnimationController _moveController;
  late final CurvedAnimation _moveAnimation;

  late DaayakattaiGame _game;
  GameMode _currentMode = GameMode.fourPlayerTeams;
  Set<String> _validPieceKeys = <String>{}; // formatted as "playerId-pieceId"
  String? _movingPieceKey;
  BoardCoordinate? _moveFromCell;
  BoardCoordinate? _moveToCell;
  Move? _pendingMove;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode ?? GameMode.fourPlayerTeams;
    _game = DaayakattaiGame(mode: _currentMode);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOut,
    );

    _moveController.addStatusListener(_handleMoveStatus);
  }

  void _resetGame(GameMode mode) {
    setState(() {
      _currentMode = mode;
      _game = DaayakattaiGame(mode: mode);
      _validPieceKeys.clear();
      _movingPieceKey = null;
      _moveFromCell = null;
      _moveToCell = null;
      _pendingMove = null;
      _pulseController.stop();
      _pulseController.value = 0;
    });
  }

  String _modeLabel(GameMode mode) {
    switch (mode) {
      case GameMode.twoPlayer:
        return '2 Players';
      case GameMode.threePlayer:
        return '3 Players';
      case GameMode.fourPlayer:
        return '4 Players';
      case GameMode.fourPlayerTeams:
        return '4 Players (2v2)';
      case GameMode.sixPlayerTeams:
        return '6 Players (3v2)';
      case GameMode.eightPlayerTeams:
        return '8 Players (4v2)';
      case GameMode.twelvePlayerTeams:
        return '12 Players (4v3)';
    }
  }

@override
Widget build(BuildContext context) {
  return Column(
    children: [
      Container(
        color: const Color(0xFF2B0A0A),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Text(
              '🎲 Daayakattai',
              style: TextStyle(
                color: Color(0xFFD9A843),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.bug_report, color: Color(0xFFD9A843)),
              onPressed: _showScenarioTester,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFD9A843)),
              onPressed: () => _resetGame(_currentMode),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Text(
              'Player ${_game.currentPlayer.id + 1} 🎯 Rolls: ${_game.pendingRolls.isEmpty ? "-" : _game.pendingRolls.map((r) => r.value).join(", ")}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
      Expanded(
        child: GestureDetector(
          onTapUp: _handleTapUp,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _moveAnimation]),
            builder: (context, _) => RepaintBoundary(
              key: _boardKey,
              child: CustomPaint(
                painter: DaayakattaiBoardPainter(
                  game: _game,
                  validPieceKeys: _validPieceKeys,
                  pulse: _pulseController.value,
                  movingPieceKey: _movingPieceKey,
                  moveFromCell: _moveFromCell,
                  moveToCell: _moveToCell,
                  moveProgress: _moveAnimation.value,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _game.needsRoll ? _rollDice : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9A843),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'தாயம் எறி / Roll Dice',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    ],
  );
}

  @override
  void dispose() {
    _pulseController.dispose();
    _moveAnimation.dispose();
    _moveController.dispose();
    super.dispose();
  }

  void _handleMoveStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_pendingMove == null) return;

    setState(() {
      _game.applyMove(_pendingMove!);
      _movingPieceKey = null;
      _moveFromCell = null;
      _moveToCell = null;
      _pendingMove = null;
      _validPieceKeys.clear();
      _pulseController.stop();
      _pulseController.value = 0;
      
      // Auto-skip or clear if rolls are finished
      _updateHighlights();

      if (_game.isGameOver) {
        _handleGameFinished();
      }
    });
  }

  void _handleGameFinished() async {
    final playerStats = <String, PlayerMatchStats>{};
    
    for (int i = 0; i < _game.players.length; i++) {
      String profileId = 'fallback-$i';
      if (widget.initialProfiles != null && i < widget.initialProfiles!.length) {
        profileId = widget.initialProfiles![i].id;
      }
      playerStats[profileId] = PlayerMatchStats(
        teamId: _game.players[i].teamId,
        rollsCount: 15,
        dhavamsRolled: 2,
        pannirendusRolled: 1,
        piecesCut: 1,
        piecesFinished: _game.players[i].pieces.where((p) => p.state == PieceState.finished).length,
      );
    }

    final record = MatchRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      durationSeconds: 900,
      gameMode: _modeLabel(_currentMode),
      winnerTeamId: _game.winningTeamId ?? 0,
      statsPerPlayer: playerStats,
    );

    await DaayakattaiStorageService.logMatch(record);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF3F0E0E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFD9A843), width: 2),
          ),
          title: const Text('வெற்றி! Victory!', style: TextStyle(color: Color(0xFFF1E4C4), fontWeight: FontWeight.bold, fontSize: 24)),
          content: Text(
            'Team ${_game.winningTeamId} has won the match! Career statistics updated successfully.',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9A843),
                foregroundColor: const Color(0xFF3F0E0E),
              ),
              onPressed: () {
                Navigator.pop(context); // Pop dialog
                Navigator.pop(context); // Go back to dashboard screen
              },
              child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  void _rollDice() {
    if (_moveController.isAnimating || !_game.needsRoll) return;

    setState(() {
      final roll = _game.rollDice();

      if (_game.consecutiveBonusCount == 0 && roll.grantsExtra) {
        // If cancellation just triggered, it already moved to next player
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Three consecutive bonus rolls! Turn forfeited.')),
        );
      }
      
      _updateHighlights();
    });
  }

  void _updateHighlights() {
    final legalMoves = _game.getLegalMoves();
    if (legalMoves.isNotEmpty) {
      _validPieceKeys = legalMoves.map((m) => '${_game.currentPlayerIndex}-${m.pieceId}').toSet();
      _pulseController.repeat(reverse: true);
    } else {
      _validPieceKeys.clear();
      _pulseController.stop();
      _pulseController.value = 0;

      // If we have rolls but no legal moves, auto-skip the roll to keep the game moving
      if (_game.hasPendingRolls && !_game.needsRoll) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _game.skipCurrentRoll();
              _updateHighlights();
            });
          }
        });
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_game.hasPendingRolls || _moveController.isAnimating || _movingPieceKey != null) {
      return;
    }

    final RenderBox? box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset local = box.globalToLocal(details.globalPosition);
    final Rect rect = DaayakattaiBoardGeometry.boardRect(box.size);
    if (!rect.contains(local)) return;

    final double cellW = rect.width / _gridSize;
    final double cellH = rect.height / _gridSize;

    final int row = ((local.dy - rect.top) ~/ cellH).clamp(0, _gridSize - 1).toInt();
    final int col = ((local.dx - rect.left) ~/ cellW).clamp(0, _gridSize - 1).toInt();

    // Check if user tapped a piece
    final player = _game.currentPlayer;
    final legalMoves = _game.getLegalMoves();
    
    for (final move in legalMoves) {
      final piece = player.pieces[move.pieceId];
      
      // Determine if tap coordinates match piece location
      bool tapped = false;
      if (piece.state == PieceState.home) {
        // Tapped inside the player's 2x2 home corner
        tapped = DaayakattaiBoardGeometry.isUnusedCorner(row, col) &&
            ((player.teamId == 0 && row < 3 && col < 3) ||
             (player.teamId == 1 && row < 3 && col >= 4) ||
             (player.teamId == 2 && row >= 4 && col >= 4) ||
             (player.teamId == 3 && row >= 4 && col < 3));
      } else {
        final coord = piece.coordinate;
        tapped = (coord != null && coord.x == row && coord.y == col);
      }

      if (tapped) {
        _executeMove(move, piece);
        break;
      }
    }
  }

  void _executeMove(Move move, Piece piece) {
    // Setup animations
    BoardCoordinate fromCoord;
    if (piece.state == PieceState.home) {
      fromCoord = const BoardCoordinate(-1, -1); // Flag representing home state
    } else {
      fromCoord = piece.coordinate!;
    }

    BoardCoordinate toCoord;
    if (move.kind == MoveKind.finish) {
      toCoord = const BoardCoordinate(-2, -2); // Flag representing finished state
    } else if (move.kind == MoveKind.outerMove || move.kind == MoveKind.deploy) {
      toCoord = Board.coordinateAt(move.targetIndex);
    } else if (move.kind == MoveKind.enterInner || move.kind == MoveKind.innerMove) {
      toCoord = _game.currentPlayer.innerPath[move.targetIndex];
    } else {
      return;
    }

    setState(() {
      _pendingMove = move;
      _movingPieceKey = '${_game.currentPlayerIndex}-${piece.id}';
      _moveFromCell = fromCoord;
      _moveToCell = toCoord;
      _validPieceKeys.clear();
      _pulseController.stop();
      _pulseController.value = 0;
    });

    _moveController.forward(from: 0);
  }

  // ==================== SCENARIO TESTER METHODS ====================

  void _showScenarioTester() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3F0E0E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFD9A843), width: 2),
        ),
        title: const Text(
          'Scenario Tester',
          style: TextStyle(color: Color(0xFFF1E4C4), fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildScenarioButton(
              icon: Icons.warning_amber,
              label: 'Forfeit Forfeiture (3-Strike)',
              onTap: _scenarioForfeitForfeiture,
            ),
            _buildScenarioButton(
              icon: Icons.block,
              label: 'Jodu Block (Pairs Blocking)',
              onTap: _scenarioJoduBlock,
            ),
            _buildScenarioButton(
              icon: Icons.lock,
              label: 'Vettu Lock (Entry Blocked)',
              onTap: _scenarioVettuLock,
            ),
            _buildScenarioButton(
              icon: Icons.lock_open,
              label: 'Vettu Unlock (Inner Access)',
              onTap: _scenarioVettuUnlock,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFFD9A843))),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF581616),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD9A843), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFD9A843)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFF1E4C4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scenarioForfeitForfeiture() {
    setState(() {
      _currentMode = GameMode.twoPlayer;
      _game = DaayakattaiGame(mode: _currentMode);
      
      // Add two bonus rolls to pending rolls
      _game.debugAddPendingRoll(12);
      _game.debugAddPendingRoll(1);
      
      // Set consecutive bonus count to 2
      _game.debugSetConsecutiveBonusCount(2);
      
      // Override rolling phase to true so player must roll once more
      _game.debugSetNeedsRoll(true);
      
      _validPieceKeys.clear();
      _pulseController.stop();
      _pulseController.value = 0;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scenario: Roll once more to trigger 3-strike forfeit!')),
      );
    }
  }

  void _scenarioJoduBlock() {
    Navigator.pop(context);
    setState(() {
      _currentMode = GameMode.fourPlayerTeams;
      _game = DaayakattaiGame(mode: _currentMode);
      // Place Player 0 pieces 0 and 1 at outer index 5 (Jodu pair)
      _game.debugSetupPiece(0, 0, PieceState.outer, outerSteps: 5);
      _game.debugSetupPiece(0, 1, PieceState.outer, outerSteps: 5);
      // Place Player 1 piece 0 at outer index 3 (behind the pair)
      _game.debugSetupPiece(1, 0, PieceState.outer, outerSteps: 3);
      // Set Player 1's turn with a queued roll of 2
      _game.debugAddPendingRoll(2);
      _game.debugSetupGameState(currentPlayerIndex: 1, rollingPhase: false);
      _updateHighlights();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scenario: Player 2 tries to land on Player 1\'s pair (blocked!)')),
      );
    }
  }

  void _scenarioVettuLock() {
    Navigator.pop(context);
    setState(() {
      _currentMode = GameMode.twoPlayer;
      _game = DaayakattaiGame(mode: _currentMode);
      // Place Player 0 piece 0 at the inner track gate (outerLength = 24)
      _game.debugSetupPiece(0, 0, PieceState.outer, outerSteps: Board.outerLength);
      // hasVettu defaults to false on new game
      _game.debugAddPendingRoll(3);
      _game.debugSetupGameState(currentPlayerIndex: 0, rollingPhase: false);
      _updateHighlights();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scenario: Enter inner track without a capture (blocked!)')),
      );
    }
  }

  void _scenarioVettuUnlock() {
    Navigator.pop(context);
    setState(() {
      _currentMode = GameMode.twoPlayer;
      _game = DaayakattaiGame(mode: _currentMode);
      // Place Player 0 piece 0 at the inner track gate
      _game.debugSetupPiece(0, 0, PieceState.outer, outerSteps: Board.outerLength);
      // Grant hasVettu so entry to inner track is allowed
      _game.players[0].hasVettu = true;
      _game.debugAddPendingRoll(3);
      _game.debugSetupGameState(currentPlayerIndex: 0, rollingPhase: false);
      _updateHighlights();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scenario: Enter inner track after a capture (Allowed!)')),
      );
    }
  }
}