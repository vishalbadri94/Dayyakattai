import 'dart:math';

// ---------------------------------------------------------------------------
// Daayakattai 7x7 Pure Dart Game Engine
// ---------------------------------------------------------------------------

enum GameMode {
  twoPlayer,
  threePlayer,
  fourPlayer,
  fourPlayerTeams,
  sixPlayerTeams,
  eightPlayerTeams,
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
  static const int outerLength = 24;

  static const List<BoardCoordinate> outerTrack = [
    BoardCoordinate(0, 0),
    BoardCoordinate(0, 1),
    BoardCoordinate(0, 2),
    BoardCoordinate(0, 3),
    BoardCoordinate(0, 4),
    BoardCoordinate(0, 5),
    BoardCoordinate(0, 6),
    BoardCoordinate(1, 6),
    BoardCoordinate(2, 6),
    BoardCoordinate(3, 6),
    BoardCoordinate(4, 6),
    BoardCoordinate(5, 6),
    BoardCoordinate(6, 6),
    BoardCoordinate(6, 5),
    BoardCoordinate(6, 4),
    BoardCoordinate(6, 3),
    BoardCoordinate(6, 2),
    BoardCoordinate(6, 1),
    BoardCoordinate(6, 0),
    BoardCoordinate(5, 0),
    BoardCoordinate(4, 0),
    BoardCoordinate(3, 0),
    BoardCoordinate(2, 0),
    BoardCoordinate(1, 0),
  ];

  /// The 9 symmetric cross positions (Malai / safe cells).
  static const Set<BoardCoordinate> malaiCells = {
    BoardCoordinate(0, 3), // Top starting gate
    BoardCoordinate(1, 3),
    BoardCoordinate(2, 3),
    BoardCoordinate(3, 3), // Center goal
    BoardCoordinate(4, 3),
    BoardCoordinate(5, 3),
    BoardCoordinate(6, 3), // Bottom starting gate
    BoardCoordinate(3, 0), // Left starting gate
    BoardCoordinate(3, 1),
    BoardCoordinate(3, 2),
    BoardCoordinate(3, 4),
    BoardCoordinate(3, 5),
    BoardCoordinate(3, 6), // Right starting gate
  };

  /// Inner Pazham track arm for each player index:
  /// 0 = top, 1 = right, 2 = bottom, 3 = left.
  static const List<List<BoardCoordinate>> innerPaths = [
    [
      BoardCoordinate(1, 3),
      BoardCoordinate(2, 3),
      BoardCoordinate(3, 3),
    ],
    [
      BoardCoordinate(3, 5),
      BoardCoordinate(3, 4),
      BoardCoordinate(3, 3),
    ],
    [
      BoardCoordinate(5, 3),
      BoardCoordinate(4, 3),
      BoardCoordinate(3, 3),
    ],
    [
      BoardCoordinate(3, 1),
      BoardCoordinate(3, 2),
      BoardCoordinate(3, 3),
    ],
  ];

  /// The four outer-track entrance points.
  static const List<int> startOuterIndices = [3, 9, 15, 21];

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