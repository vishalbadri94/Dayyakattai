import 'dart:math';

// ---------------------------------------------------------------------------
// Daayakattai 19x19 Pure Dart Game Engine
// ---------------------------------------------------------------------------

enum GameMode {
  twoPlayer,
  threePlayer,
  fourPlayer,
  fourPlayerTeams,
  sixPlayerTeams,
  eightPlayerTeams,
  twelvePlayerTeams,
}

class BoardCoordinate {
  final int x;
  final int y;

  const BoardCoordinate(this.x, this.y);

  @override
  bool operator ==(Object other) {
    return other is BoardCoordinate && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x, $y)';
}

class Board {
  static const int outerLength = 72;

  static const List<BoardCoordinate> outerTrack = [
    // North left edge: (7,8) up to (0,8)
    BoardCoordinate(7, 8),
    BoardCoordinate(6, 8),
    BoardCoordinate(5, 8),
    BoardCoordinate(4, 8),
    BoardCoordinate(3, 8),
    BoardCoordinate(2, 8),
    BoardCoordinate(1, 8),
    BoardCoordinate(0, 8),
    // North tip: (0,8) -> (0,9) -> (0,10)
    BoardCoordinate(0, 9),
    BoardCoordinate(0, 10),
    // North right edge: (0,10) down to (7,10)
    BoardCoordinate(1, 10),
    BoardCoordinate(2, 10),
    BoardCoordinate(3, 10),
    BoardCoordinate(4, 10),
    BoardCoordinate(5, 10),
    BoardCoordinate(6, 10),
    BoardCoordinate(7, 10),
    // East top edge: (8,11) right to (8,18)
    BoardCoordinate(8, 11),
    BoardCoordinate(8, 12),
    BoardCoordinate(8, 13),
    BoardCoordinate(8, 14),
    BoardCoordinate(8, 15),
    BoardCoordinate(8, 16),
    BoardCoordinate(8, 17),
    BoardCoordinate(8, 18),
    // East tip: (8,18) -> (9,18) -> (10,18)
    BoardCoordinate(9, 18),
    BoardCoordinate(10, 18),
    // East bottom edge: (10,18) left to (10,11)
    BoardCoordinate(10, 17),
    BoardCoordinate(10, 16),
    BoardCoordinate(10, 15),
    BoardCoordinate(10, 14),
    BoardCoordinate(10, 13),
    BoardCoordinate(10, 12),
    BoardCoordinate(10, 11),
    // South right edge: (11,10) down to (18,10)
    BoardCoordinate(11, 10),
    BoardCoordinate(12, 10),
    BoardCoordinate(13, 10),
    BoardCoordinate(14, 10),
    BoardCoordinate(15, 10),
    BoardCoordinate(16, 10),
    BoardCoordinate(17, 10),
    BoardCoordinate(18, 10),
    // South tip: (18,10) -> (18,9) -> (18,8)
    BoardCoordinate(18, 9),
    BoardCoordinate(18, 8),
    // South left edge: (18,8) up to (11,8)
    BoardCoordinate(17, 8),
    BoardCoordinate(16, 8),
    BoardCoordinate(15, 8),
    BoardCoordinate(14, 8),
    BoardCoordinate(13, 8),
    BoardCoordinate(12, 8),
    BoardCoordinate(11, 8),
    // West bottom edge: (10,7) left to (10,0)
    BoardCoordinate(10, 7),
    BoardCoordinate(10, 6),
    BoardCoordinate(10, 5),
    BoardCoordinate(10, 4),
    BoardCoordinate(10, 3),
    BoardCoordinate(10, 2),
    BoardCoordinate(10, 1),
    BoardCoordinate(10, 0),
    // West tip: (10,0) -> (9,0) -> (8,0)
    BoardCoordinate(9, 0),
    BoardCoordinate(8, 0),
    // West top edge: (8,0) right to (8,7)
    BoardCoordinate(8, 1),
    BoardCoordinate(8, 2),
    BoardCoordinate(8, 3),
    BoardCoordinate(8, 4),
    BoardCoordinate(8, 5),
    BoardCoordinate(8, 6),
    BoardCoordinate(8, 7),
  ];

  /// The 9 symmetric cross positions (Malai / safe cells).
  static final Set<BoardCoordinate> malaiCells = {
    // Arm tips
    BoardCoordinate(0, 9), // North tip
    BoardCoordinate(9, 18), // East tip
    BoardCoordinate(18, 9), // South tip
    BoardCoordinate(9, 0), // West tip
    // Starting gates
    BoardCoordinate(7, 9), // North gate
    BoardCoordinate(9, 11), // East gate
    BoardCoordinate(11, 9), // South gate
    BoardCoordinate(9, 7), // West gate
    // Inner path cells (all cells from gate to center)
    // North inner path
    BoardCoordinate(6, 9),
    BoardCoordinate(5, 9),
    BoardCoordinate(4, 9),
    BoardCoordinate(3, 9),
    BoardCoordinate(2, 9),
    BoardCoordinate(1, 9),
    // East inner path
    BoardCoordinate(9, 17),
    BoardCoordinate(9, 16),
    BoardCoordinate(9, 15),
    BoardCoordinate(9, 14),
    BoardCoordinate(9, 13),
    BoardCoordinate(9, 12),
    // South inner path
    BoardCoordinate(12, 9),
    BoardCoordinate(13, 9),
    BoardCoordinate(14, 9),
    BoardCoordinate(15, 9),
    BoardCoordinate(16, 9),
    BoardCoordinate(17, 9),
    // West inner path
    BoardCoordinate(9, 1),
    BoardCoordinate(9, 2),
    BoardCoordinate(9, 3),
    BoardCoordinate(9, 4),
    BoardCoordinate(9, 5),
    BoardCoordinate(9, 6),
    // Center HOME
    BoardCoordinate(8, 9),
    BoardCoordinate(9, 9),
    BoardCoordinate(10, 9),
    BoardCoordinate(8, 10),
    BoardCoordinate(9, 10),
    BoardCoordinate(10, 10),
    BoardCoordinate(8, 8),
    BoardCoordinate(9, 8),
    BoardCoordinate(10, 8),
  };

  /// Inner Pazham track arm for each player index:
  /// 0 = top, 1 = right, 2 = bottom, 3 = left.
  static const List<List<BoardCoordinate>> innerPaths = [
    // Top player: from (0,9) down to (8,9)
    [
      BoardCoordinate(0, 9),
      BoardCoordinate(1, 9),
      BoardCoordinate(2, 9),
      BoardCoordinate(3, 9),
      BoardCoordinate(4, 9),
      BoardCoordinate(5, 9),
      BoardCoordinate(6, 9),
      BoardCoordinate(7, 9),
      BoardCoordinate(8, 9),
    ],
    // Right player: from (9,18) left to (9,10)
    [
      BoardCoordinate(9, 18),
      BoardCoordinate(9, 17),
      BoardCoordinate(9, 16),
      BoardCoordinate(9, 15),
      BoardCoordinate(9, 14),
      BoardCoordinate(9, 13),
      BoardCoordinate(9, 12),
      BoardCoordinate(9, 11),
      BoardCoordinate(9, 10),
    ],
    // Bottom player: from (18,9) up to (10,9)
    [
      BoardCoordinate(18, 9),
      BoardCoordinate(17, 9),
      BoardCoordinate(16, 9),
      BoardCoordinate(15, 9),
      BoardCoordinate(14, 9),
      BoardCoordinate(13, 9),
      BoardCoordinate(12, 9),
      BoardCoordinate(11, 9),
      BoardCoordinate(10, 9),
    ],
    // Left player: from (9,0) right to (9,8)
    [
      BoardCoordinate(9, 0),
      BoardCoordinate(9, 1),
      BoardCoordinate(9, 2),
      BoardCoordinate(9, 3),
      BoardCoordinate(9, 4),
      BoardCoordinate(9, 5),
      BoardCoordinate(9, 6),
      BoardCoordinate(9, 7),
      BoardCoordinate(9, 8),
    ],
  ];

  /// The four outer-track entrance points.
  static const List<int> startOuterIndices = [7, 23, 39, 55];

  static bool isMalai(BoardCoordinate coordinate) {
    return malaiCells.contains(coordinate);
  }

  static BoardCoordinate coordinateAt(int outerIndex) {
    return outerTrack[outerIndex % outerLength];
  }

  static int? outerIndexAt(BoardCoordinate coordinate) {
    for (var i = 0; i < outerTrack.length; i++) {
      if (outerTrack[i] == coordinate) return i;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Dice
// ---------------------------------------------------------------------------

class DiceRoll {
  final int die1;
  final int die2;
  final int value;

  DiceRoll(this.die1, this.die2) : value = _computeValue(die1, die2);

  bool get grantsExtra =>
      value == 1 || value == 5 || value == 6 || value == 12;

  static int _computeValue(int a, int b) {
    if (a == 0 && b == 0) return 12;
    if ((a == 0 && b == 1) || (a == 1 && b == 0)) return 1;
    if ((a == 0 && b == 2) ||
        (a == 2 && b == 0) ||
        (a == 1 && b == 1)) {
      return 2;
    }
    if ((a == 0 && b == 3) ||
        (a == 3 && b == 0) ||
        (a == 1 && b == 2) ||
        (a == 2 && b == 1)) {
      return 3;
    }
    if ((a == 1 && b == 3) ||
        (a == 3 && b == 1) ||
        (a == 2 && b == 2)) {
      return 4;
    }
    if ((a == 2 && b == 3) || (a == 3 && b == 2)) return 5;
    if (a == 3 && b == 3) return 6;
    throw ArgumentError('Invalid dice values: $a, $b');
  }

  @override
  String toString() => 'DiceRoll($die1, $die2) -> $value';
}

class Dice {
  final Random _random;

  Dice({Random? random}) : _random = random ?? Random();

  DiceRoll roll() {
    final a = _random.nextInt(4);
    final b = _random.nextInt(4);
    return DiceRoll(a, b);
  }
}

// ---------------------------------------------------------------------------
// Pieces and Players
// ---------------------------------------------------------------------------

enum PieceState { home, outer, inner, finished }

class Piece {
  final int id;
  final Player owner;

  PieceState _state = PieceState.home;
  int _outerSteps = 0;
  int _innerIndex = 0;

  Piece(this.id, this.owner);

  PieceState get state => _state;
  int get outerSteps => _outerSteps;
  int get innerIndex => _innerIndex;

  int get outerIndex {
    if (_state != PieceState.outer) {
      throw StateError('Piece is not on the outer track');
    }
    return (owner.startOuterIndex + _outerSteps) % Board.outerLength;
  }

  bool get atGate {
    if (_state != PieceState.outer) return false;
    if (_outerSteps < Board.outerLength) return false;
    return _outerSteps % Board.outerLength == 0;
  }

  bool get hasCompletedLoop => _outerSteps >= Board.outerLength;

  BoardCoordinate? get coordinate {
    switch (_state) {
      case PieceState.home:
      case PieceState.finished:
        return null;
      case PieceState.outer:
        return Board.outerTrack[outerIndex];
      case PieceState.inner:
        return owner.innerPath[_innerIndex];
    }
  }

  void _deploy() {
    _state = PieceState.outer;
    _outerSteps = 0;
    _innerIndex = 0;
  }

  void _advanceOuter(int steps) {
    _outerSteps += steps;
  }

  void _enterInner(int index) {
    _state = PieceState.inner;
    _innerIndex = index;
  }

  void _advanceInner(int index) {
    _innerIndex = index;
  }

  void _finish() {
    _state = PieceState.finished;
    _innerIndex = 0;
    _outerSteps = 0;
  }

  void sendHome() {
    _state = PieceState.home;
    _outerSteps = 0;
    _innerIndex = 0;
  }

  @override
  String toString() => 'Piece($id, ${owner.id}, $_state)';
}

class Player {
  final int id;
  final int teamId;
  final int startOuterIndex;
  final List<BoardCoordinate> innerPath;

  bool hasVettu = false;
  late final List<Piece> pieces;

  Player(this.id, this.teamId, this.startOuterIndex, this.innerPath) {
    pieces = List.generate(4, (index) => Piece(index, this));
  }

  bool get allFinished => pieces.every((piece) => piece.state == PieceState.finished);

  @override
  String toString() => 'Player($id, team=$teamId, hasVettu=$hasVettu)';
}

// ---------------------------------------------------------------------------
// Moves
// ---------------------------------------------------------------------------

enum MoveKind { deploy, outerMove, enterInner, innerMove, finish }

class Move {
  final int playerId;
  final int pieceId;
  final MoveKind kind;
  final int targetIndex;

  const Move({
    required this.playerId,
    required this.pieceId,
    required this.kind,
    required this.targetIndex,
  });

  @override
  bool operator ==(Object other) {
    return other is Move &&
        other.playerId == playerId &&
        other.pieceId == pieceId &&
        other.kind == kind &&
        other.targetIndex == targetIndex;
  }

  @override
  int get hashCode => Object.hash(playerId, pieceId, kind, targetIndex);

  @override
  String toString() =>
      'Move(player=$playerId, piece=$pieceId, $kind, target=$targetIndex)';
}

// ---------------------------------------------------------------------------
// Turn Result
// ---------------------------------------------------------------------------

class TurnResult {
  final DiceRoll roll;
  final Move? move;
  final List<Piece> cutPieces;
  final bool extraRollGranted;
  final bool turnEnded;
  final int? winningTeamId;

  const TurnResult({
    required this.roll,
    this.move,
    required this.cutPieces,
    required this.extraRollGranted,
    required this.turnEnded,
    this.winningTeamId,
  });
}

// ---------------------------------------------------------------------------
// Game Engine
// ---------------------------------------------------------------------------

class DaayakattaiGame {
  final GameMode mode;
  final Dice _dice;
  final List<Player> _players;
  final List<DiceRoll> _pendingRolls = [];
  int _currentPlayerIndex = 0;
  int? _winningTeamId;

  // Rolling phase state
  int _consecutiveBonusCount = 0;
  bool _rollingPhase = true;

  DaayakattaiGame({
    this.mode = GameMode.fourPlayerTeams,
    Random? random,
  })  : _dice = Dice(random: random),
        _players = _createPlayers(mode);

  static List<Player> _createPlayers(GameMode mode) {
    switch (mode) {
      case GameMode.twoPlayer:
        return [
          Player(0, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(1, 1, Board.startOuterIndices[2], Board.innerPaths[2]),
        ];
      case GameMode.threePlayer:
        return [
          Player(0, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(1, 1, Board.startOuterIndices[1], Board.innerPaths[1]),
          Player(2, 2, Board.startOuterIndices[2], Board.innerPaths[2]),
        ];
      case GameMode.fourPlayer:
        return [
          Player(0, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(1, 1, Board.startOuterIndices[1], Board.innerPaths[1]),
          Player(2, 2, Board.startOuterIndices[2], Board.innerPaths[2]),
          Player(3, 3, Board.startOuterIndices[3], Board.innerPaths[3]),
        ];
      case GameMode.fourPlayerTeams:
        return [
          Player(0, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(1, 1, Board.startOuterIndices[1], Board.innerPaths[1]),
          Player(2, 0, Board.startOuterIndices[2], Board.innerPaths[2]),
          Player(3, 1, Board.startOuterIndices[3], Board.innerPaths[3]),
        ];
      case GameMode.sixPlayerTeams:
        return [
          Player(0, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(1, 1, Board.startOuterIndices[1], Board.innerPaths[1]),
          Player(2, 2, Board.startOuterIndices[2], Board.innerPaths[2]),
          Player(3, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(4, 1, Board.startOuterIndices[1], Board.innerPaths[1]),
          Player(5, 2, Board.startOuterIndices[2], Board.innerPaths[2]),
        ];
      case GameMode.eightPlayerTeams:
        return [
          Player(0, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(1, 1, Board.startOuterIndices[1], Board.innerPaths[1]),
          Player(2, 2, Board.startOuterIndices[2], Board.innerPaths[2]),
          Player(3, 3, Board.startOuterIndices[3], Board.innerPaths[3]),
          Player(4, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(5, 1, Board.startOuterIndices[1], Board.innerPaths[1]),
          Player(6, 2, Board.startOuterIndices[2], Board.innerPaths[2]),
          Player(7, 3, Board.startOuterIndices[3], Board.innerPaths[3]),
        ];
      case GameMode.twelvePlayerTeams:
        return [
          Player(0, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(1, 1, Board.startOuterIndices[1], Board.innerPaths[1]),
          Player(2, 2, Board.startOuterIndices[2], Board.innerPaths[2]),
          Player(3, 3, Board.startOuterIndices[3], Board.innerPaths[3]),
          Player(4, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(5, 1, Board.startOuterIndices[1], Board.innerPaths[1]),
          Player(6, 2, Board.startOuterIndices[2], Board.innerPaths[2]),
          Player(7, 3, Board.startOuterIndices[3], Board.innerPaths[3]),
          Player(8, 0, Board.startOuterIndices[0], Board.innerPaths[0]),
          Player(9, 1, Board.startOuterIndices[1], Board.innerPaths[1]),
          Player(10, 2, Board.startOuterIndices[2], Board.innerPaths[2]),
          Player(11, 3, Board.startOuterIndices[3], Board.innerPaths[3]),
        ];
    }
  }

  // -------------------------------------------------------------------------
  // Public state getters
  // -------------------------------------------------------------------------

  List<Player> get players => List.unmodifiable(_players);
  int get currentPlayerIndex => _currentPlayerIndex;
  Player get currentPlayer => _players[_currentPlayerIndex];
  bool get isGameOver => _winningTeamId != null;
  int? get winningTeamId => _winningTeamId;
  
  // Rolling phase controls
  bool get needsRoll => _rollingPhase && !isGameOver;
  bool get hasPendingRolls => _pendingRolls.isNotEmpty;
  DiceRoll? get currentRoll => _pendingRolls.isEmpty ? null : _pendingRolls.first;
  List<DiceRoll> get pendingRolls => List.unmodifiable(_pendingRolls);
  int get consecutiveBonusCount => _consecutiveBonusCount;
  
  // Debug helper method for unit testing to override private state of pieces
  void debugSetupPiece(int playerId, int pieceId, PieceState state, {int outerSteps = 0, int innerIndex = 0}) {
    final player = _players[playerId];
    final piece = player.pieces[pieceId];
    piece._state = state;
    piece._outerSteps = outerSteps;
    piece._innerIndex = innerIndex;
  }
  
  // Debug helper method for setting up game states in prebuilt testing scenarios
  void debugSetupGameState({
    int? currentPlayerIndex,
    int? consecutiveBonusCount,
    bool? rollingPhase,
    List<int>? customRolls,
  }) {
    if (currentPlayerIndex != null) {
      _currentPlayerIndex = currentPlayerIndex;
    }
    if (consecutiveBonusCount != null) {
      _consecutiveBonusCount = consecutiveBonusCount;
    }
    if (rollingPhase != null) {
      _rollingPhase = rollingPhase;
    }
    if (customRolls != null) {
      _pendingRolls.clear();
      for (final val in customRolls) {
        // Map a target value to a valid die1/die2 combination
        // die1=0 (blank), die2=0..3 represent the four sides; value drives which combo
        switch (val) {
          case 1: _pendingRolls.add(DiceRoll(0, 1)); break;
          case 2: _pendingRolls.add(DiceRoll(1, 1)); break;
          case 3: _pendingRolls.add(DiceRoll(1, 2)); break;
          case 4: _pendingRolls.add(DiceRoll(2, 2)); break;
          case 5: _pendingRolls.add(DiceRoll(2, 3)); break;
          case 6: _pendingRolls.add(DiceRoll(3, 3)); break;
          case 12: _pendingRolls.add(DiceRoll(0, 0)); break;
          default: _pendingRolls.add(DiceRoll(1, 1)); // default = 2
        }
      }
    }
  }

  /// Appends a single debug roll to the pending roll queue
  void debugAddPendingRoll(int value) {
    switch (value) {
      case 1: _pendingRolls.add(DiceRoll(0, 1)); break;
      case 2: _pendingRolls.add(DiceRoll(1, 1)); break;
      case 3: _pendingRolls.add(DiceRoll(1, 2)); break;
      case 4: _pendingRolls.add(DiceRoll(2, 2)); break;
      case 5: _pendingRolls.add(DiceRoll(2, 3)); break;
      case 6: _pendingRolls.add(DiceRoll(3, 3)); break;
      case 12: _pendingRolls.add(DiceRoll(0, 0)); break;
      default: _pendingRolls.add(DiceRoll(1, 1));
    }
    // Disable rolling phase so the queued rolls are consumed on move
    _rollingPhase = false;
  }

  /// Directly sets the consecutive bonus count (for scenario testing)
  void debugSetConsecutiveBonusCount(int count) {
    _consecutiveBonusCount = count;
  }

  /// Directly sets rolling phase flag (for scenario testing)
  void debugSetNeedsRoll(bool value) {
    _rollingPhase = value;
  }
  
  // Public check for landing rules, exposed for UI highlights and test suites
  bool canLandOn(BoardCoordinate coord, Player mover) {
    return _canLandOn(coord, mover);
  }

  // -------------------------------------------------------------------------
  // Turn controls
  // -------------------------------------------------------------------------

  DiceRoll rollDice() {
    if (isGameOver) throw StateError('Game is over');
    if (!needsRoll) throw StateError('Rolling phase is over. Please make moves.');

    final roll = _dice.roll();
    
    if (roll.grantsExtra) {
      _consecutiveBonusCount++;
      if (_consecutiveBonusCount == 3) {
        // 3 consecutive bonus rolls = cancellation & forfeit turn
        _pendingRolls.clear();
        _consecutiveBonusCount = 0;
        _rollingPhase = false;
        _advanceToNextPlayer();
        return roll;
      }
      _pendingRolls.add(roll);
      _rollingPhase = true; // can roll again
    } else {
      _pendingRolls.add(roll);
      _consecutiveBonusCount = 0;
      _rollingPhase = false; // rolling phase ends
    }
    
    return roll;
  }

  TurnResult skipCurrentRoll() {
    if (isGameOver) throw StateError('Game is over');
    if (_pendingRolls.isEmpty) throw StateError('No pending roll to skip');

    final roll = _pendingRolls.removeAt(0);

    final turnEnded = _pendingRolls.isEmpty;
    if (turnEnded && !isGameOver) {
      _advanceToNextPlayer();
    }

    return TurnResult(
      roll: roll,
      cutPieces: const [],
      extraRollGranted: false,
      turnEnded: turnEnded,
      winningTeamId: _winningTeamId,
    );
  }

  List<Move> getLegalMoves() {
    if (isGameOver || _pendingRolls.isEmpty) return const [];
    final roll = _pendingRolls.first;
    final player = currentPlayer;
    final moves = <Move>[];

    for (final piece in player.pieces) {
      moves.addAll(_legalMovesForPiece(player, piece, roll.value));
    }
    return moves;
  }

  List<Move> _legalMovesForPiece(
      Player player, Piece piece, int rollValue) {
    final moves = <Move>[];

    switch (piece.state) {
      case PieceState.home:
        if (rollValue == 1) {
          final targetCoord = Board.coordinateAt(player.startOuterIndex);
          if (_canLandOn(targetCoord, player)) {
            moves.add(Move(
              playerId: player.id,
              pieceId: piece.id,
              kind: MoveKind.deploy,
              targetIndex: player.startOuterIndex,
            ));
          }
        }
        break;

      case PieceState.outer:
        if (piece.atGate &&
            player.hasVettu &&
            rollValue <= player.innerPath.length) {
          final targetInner = rollValue - 1;
          final targetCoord = player.innerPath[targetInner];
          
          if (_canLandOn(targetCoord, player)) {
            if (targetInner == player.innerPath.length - 1) {
              moves.add(Move(
                playerId: player.id,
                pieceId: piece.id,
                kind: MoveKind.finish,
                targetIndex: targetInner,
              ));
            } else {
              moves.add(Move(
                playerId: player.id,
                pieceId: piece.id,
                kind: MoveKind.enterInner,
                targetIndex: targetInner,
              ));
            }
          }
        }

        final targetOuter = (piece.outerIndex + rollValue) % Board.outerLength;
        final targetCoord = Board.coordinateAt(targetOuter);
        if (_canLandOn(targetCoord, player)) {
          moves.add(Move(
            playerId: player.id,
            pieceId: piece.id,
            kind: MoveKind.outerMove,
            targetIndex: targetOuter,
          ));
        }
        break;

      case PieceState.inner:
        final targetInner = piece.innerIndex + rollValue;
        if (targetInner < player.innerPath.length) {
          final targetCoord = player.innerPath[targetInner];
          if (_canLandOn(targetCoord, player)) {
            if (targetInner == player.innerPath.length - 1) {
              moves.add(Move(
                playerId: player.id,
                pieceId: piece.id,
                kind: MoveKind.finish,
                targetIndex: targetInner,
              ));
            } else {
              moves.add(Move(
                playerId: player.id,
                pieceId: piece.id,
                kind: MoveKind.innerMove,
                targetIndex: targetInner,
              ));
            }
          }
        }
        break;

      case PieceState.finished:
        break;
    }

    return moves;
  }

  bool _canLandOn(BoardCoordinate coord, Player mover) {
    if (Board.isMalai(coord)) return true;

    int opponentPiecesCount = 0;
    int teammatePiecesCount = 0;

    for (final player in _players) {
      for (final piece in player.pieces) {
        if (piece.coordinate == coord) {
          if (player.teamId == mover.teamId) {
            teammatePiecesCount++;
          } else {
            opponentPiecesCount++;
          }
        }
      }
    }

    // Teammates cannot land on each other on unsafe cells
    if (teammatePiecesCount > 0) return false;

    // Pairs rule: a single piece cannot capture a double piece (pair)
    if (opponentPiecesCount >= 2) return false;

    return true;
  }

  TurnResult applyMove(Move move) {
    if (isGameOver) throw StateError('Game is over');
    if (_pendingRolls.isEmpty) throw StateError('No pending roll');
    if (!_isLegal(move)) throw ArgumentError('Illegal move: $move');

    final roll = _pendingRolls.removeAt(0);
    final player = _players[move.playerId];
    final piece = player.pieces[move.pieceId];
    final cutPieces = <Piece>[];

    switch (move.kind) {
      case MoveKind.deploy:
        piece._deploy();
        break;
      case MoveKind.outerMove:
        piece._advanceOuter(roll.value);
        break;
      case MoveKind.enterInner:
        piece._enterInner(move.targetIndex);
        break;
      case MoveKind.innerMove:
        piece._advanceInner(move.targetIndex);
        break;
      case MoveKind.finish:
        piece._finish();
        break;
    }

    if (move.kind == MoveKind.deploy || move.kind == MoveKind.outerMove) {
      cutPieces.addAll(_captureAtOuterIndex(move.targetIndex, player));
      if (cutPieces.isNotEmpty) {
        player.hasVettu = true;
      }
    }

    _winningTeamId = _checkWinner();

    if (isGameOver) {
      _pendingRolls.clear();
      return TurnResult(
        roll: roll,
        move: move,
        cutPieces: cutPieces,
        extraRollGranted: false,
        turnEnded: true,
        winningTeamId: _winningTeamId,
      );
    }

    final turnEnded = _pendingRolls.isEmpty;
    if (turnEnded) {
      _advanceToNextPlayer();
    }

    return TurnResult(
      roll: roll,
      move: move,
      cutPieces: cutPieces,
      extraRollGranted: false,
      turnEnded: turnEnded,
      winningTeamId: _winningTeamId,
    );
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  bool _isLegal(Move move) {
    if (move.playerId != currentPlayer.id) return false;
    return getLegalMoves().contains(move);
  }

  List<Piece> _captureAtOuterIndex(int outerIndex, Player mover) {
    final captured = <Piece>[];
    final coord = Board.coordinateAt(outerIndex);

    if (Board.isMalai(coord)) return captured;

    for (final player in _players) {
      if (player.teamId == mover.teamId) continue;
      for (final piece in player.pieces) {
        if (piece.state == PieceState.outer && piece.outerIndex == outerIndex) {
          piece.sendHome();
          captured.add(piece);
        }
      }
    }

    return captured;
  }

  int? _checkWinner() {
    for (final teamId in _players.map((p) => p.teamId).toSet()) {
      final teamPlayers = _players.where((p) => p.teamId == teamId);
      if (teamPlayers.every((p) => p.allFinished)) {
        return teamId;
      }
    }
    return null;
  }

  void _advanceToNextPlayer() {
    if (isGameOver) return;

    _consecutiveBonusCount = 0;
    _rollingPhase = true;

    do {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    } while (_players[_currentPlayerIndex].allFinished && !isGameOver);
  }
}