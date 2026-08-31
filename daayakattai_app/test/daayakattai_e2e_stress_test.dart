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
  group('Daayakattai E2E Rules Edge Cases & Stress Tests', () {
    test('Frictionless Entry - Deploy requires exactly 1 (Dhayam)', () {
      final mockRand = MockRandom([0, 1]); // rolls 0+1 -> 1
      final game = DaayakattaiGame(mode: GameMode.twoPlayer, random: mockRand);
      
      expect(game.needsRoll, isTrue);
      game.rollDice();
      
      // Get legal moves - should contain a deploy move
      final moves = game.getLegalMoves();
      expect(moves.isNotEmpty, isTrue);
      expect(moves.any((m) => m.kind == MoveKind.deploy), isTrue);
    });

    test('Forfeit Edge Case - 3 consecutive bonus rolls forfeits immediately', () {
      final mockRand = MockRandom([
        0, 0, // 12 (bonus)
        0, 1, // 1 (bonus)
        2, 3, // 5 (3rd bonus -> forfeit)
      ]);
      final game = DaayakattaiGame(mode: GameMode.twoPlayer, random: mockRand);

      game.rollDice(); // 12
      game.rollDice(); // 1
      game.rollDice(); // 5 -> triggers forfeit immediately
      
      expect(game.currentPlayerIndex, equals(1));
      expect(game.pendingRolls.isEmpty, isTrue);
    });

    test('Vettu Lock - Branching to inner path requires at least one cut (Vettu)', () {
      final mockRand = MockRandom([0, 1]); // 1
      final game = DaayakattaiGame(mode: GameMode.twoPlayer, random: mockRand);
      final p0 = game.currentPlayer;

      // Put a piece at absolute outer index 7 (Player 0 startOuterIndex is 7)
      game.debugSetupPiece(0, 0, PieceState.outer, outerSteps: 0);

      // Verify Player 0 has no Vettu yet
      expect(p0.hasVettu, isFalse);

      // Loop piece to gate (outerSteps = 72)
      game.debugSetupPiece(0, 0, PieceState.outer, outerSteps: 72);
      expect(p0.pieces[0].atGate, isTrue);
      
      // Ensure it cannot move to inner without cut
      final moves = game.getLegalMoves();
      expect(moves.any((m) => m.kind == MoveKind.enterInner), isFalse);
    });

    test('Jodu Blocking - Safe double-occupied cells block opponent landings', () {
      final mockRand = MockRandom([0, 1]); // 1
      final game = DaayakattaiGame(mode: GameMode.fourPlayerTeams, random: mockRand);

      final p0 = game.players[0];
      final p1 = game.players[1];

      // Form a Jodu pair on outer index 9 (Player 0 starts at index 7 -> outerSteps: 2)
      game.debugSetupPiece(0, 0, PieceState.outer, outerSteps: 2);
      game.debugSetupPiece(0, 1, PieceState.outer, outerSteps: 2);

      expect(p0.pieces[0].outerIndex, equals(9));
      expect(p0.pieces[1].outerIndex, equals(9));

      // Player 1 starts at index 23. Place opponent right at index 9 (outerSteps: 58)
      game.debugSetupPiece(1, 0, PieceState.outer, outerSteps: 58);

      // Verify landing is blocked
      final targetCoord = Board.outerTrack[9];
      final canLand = game.canLandOn(targetCoord, p1);
      expect(canLand, isFalse);
    });
  });
}