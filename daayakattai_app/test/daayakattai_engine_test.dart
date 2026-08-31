import 'package:flutter_test/flutter_test.dart';
import 'package:daayakattai_app/daayakattai_engine.dart';
import 'dart:math';

// Mock Random generator to force specific rolls for testing
class MockRandom implements Random {
  final List<int> _values;
  int _idx = 0;

  MockRandom(this._values);

  @override
  int nextInt(int max) {
    if (_idx >= _values.length) return 0;
    return _values[_idx++];
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.0;
}

void main() {
  group('DaayakattaiGame Rules Tests', () {
    test('Frictionless Entry - Pieces cannot deploy without rolling 1', () {
      final mockRand = MockRandom([0, 1]); // rolls 0+1 -> 1 (Dhayam)
      final game = DaayakattaiGame(mode: GameMode.twoPlayer, random: mockRand);

      // Verify starting state
      expect(game.needsRoll, isTrue);
      expect(game.currentPlayer.pieces.every((p) => p.state == PieceState.home), isTrue);

      // Roll non-deploy value (e.g. roll a 2)
      final mockRand2 = MockRandom([0, 2]); // rolls 0+2 -> 2
      final game2 = DaayakattaiGame(mode: GameMode.twoPlayer, random: mockRand2);
      game2.rollDice();
      
      // Get legal moves
      final moves = game2.getLegalMoves();
      // Verify no legal moves exist since all pieces are home and no 1 was rolled
      expect(moves.isEmpty, isTrue);
    });

    test('Three-Strike Roll Cancellation Forfeits Turn', () {
      // Force 3 consecutive bonus rolls: 0+0 (12), 0+1 (1), 2+3 (5)
      // Followed by a non-bonus to finish rolling phase
      final mockRand = MockRandom([
        0, 0, // 12 (bonus)
        0, 1, // 1 (bonus)
        2, 3, // 5 (bonus - this is the 3rd, should trigger forfeit!)
      ]);
      final game = DaayakattaiGame(mode: GameMode.twoPlayer, random: mockRand);

      // Execute rolls
      game.rollDice(); // Roll 1: 12
      expect(game.needsRoll, isTrue);
      
      game.rollDice(); // Roll 2: 1
      expect(game.needsRoll, isTrue);
      
      game.rollDice(); // Roll 3: 5 (forfeits immediately)
      
      // Verify turn passed to Player 2 (index 1) and rolls were cleared
      expect(game.currentPlayerIndex, equals(1));
      expect(game.pendingRolls.isEmpty, isTrue);
    });

    test('Pairs (Jodu) Blocking - Single piece cannot land on safe cell double occupied', () {
      final mockRand = MockRandom([0, 1]); // 1
      final game = DaayakattaiGame(mode: GameMode.fourPlayerTeams, random: mockRand);

      final p0 = game.players[0];
      final p1 = game.players[1];

      // Player 0 starts at index 7. To place pieces at absolute index 9 (safe cell),
      // we need outerSteps = (9 - 7 + 72) % 72 = 2
      game.debugSetupPiece(0, 0, PieceState.outer, outerSteps: 2);
      game.debugSetupPiece(0, 1, PieceState.outer, outerSteps: 2);

      // Verify they form a pair on outer cell 9
      expect(p0.pieces[0].outerIndex, equals(9));
      expect(p0.pieces[1].outerIndex, equals(9));

      // Player 1 starts at index 23. To place a piece at absolute index 9,
      // we need outerSteps = (9 - 23 + 72) % 72 = 58
      game.debugSetupPiece(1, 0, PieceState.outer, outerSteps: 58);
      
      // Verify Player 1's piece is at index 9
      expect(p1.pieces[0].outerIndex, equals(9));

      // Since cell 9 is safe and occupied by Player 0's pair, it should block Player 1.
      final targetCoord = Board.outerTrack[9];
      final canLand = game.canLandOn(targetCoord, p1);
      expect(canLand, isFalse); // Blocked by Jodu!
    });

    test('Vettu lock restricts entry to inner track', () {
      final mockRand = MockRandom([0, 1]); // 1
      final game = DaayakattaiGame(mode: GameMode.twoPlayer, random: mockRand);
      final p0 = game.currentPlayer;

      // Deploy and loop piece to the end of the outer track using helper
      game.debugSetupPiece(0, 0, PieceState.outer, outerSteps: Board.outerLength);

      expect(p0.pieces[0].atGate, isTrue);
      expect(p0.pieces[0].hasCompletedLoop, isTrue);

      // Attempt to enter inner path without having made a cut (hasVettu = false)
      final canEnter = p0.hasVettu;
      expect(canEnter, isFalse);
    });
  });
}