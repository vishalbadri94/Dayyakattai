# DeepSeek Logic Test Report

# Daayakattai Game Engine Test Report

## 1. Summary Table

| Scenario | Status | Notes |
|----------|--------|-------|
| SCENARIO 1 — Basic Deployment | **PASS** | Roll of 1 correctly deploys home pawn; non-1 rolls with all pawns home result in skipped turn |
| SCENARIO 2 — Bonus Roll Chain | **PARTIAL** | Bonus rolls granted correctly, but 3-strike forfeit logic has a bug in `rollDice()` |
| SCENARIO 3 — Jodu Blocking | **PASS** | Enemy pawns correctly blocked from landing on Jodu pairs |
| SCENARIO 4 — Vettu (Capture) | **PASS** | Capture logic works correctly; `hasVettu` set properly |
| SCENARIO 5 — Inner Track Gate | **PASS** | Entry blocked without Vettu; allowed with Vettu |
| SCENARIO 6 — Win Condition | **PASS** | Victory correctly detected when all team pawns finish |
| SCENARIO 7 — Match Statistics Storage | **PASS** | History limited to 100; wins only for winning team; batched writes |

---

## 2. Detailed Findings

### SCENARIO 1 — Basic Deployment

**Status: PASS**

**Logic Flow Traced:**
1. In `_legalMovesForPiece()`, when `piece.state == PieceState.home`, the code checks `if (rollValue == 1)` before generating a deploy move.
2. If roll is 1, it checks `_canLandOn(targetCoord, player)` where `targetCoord = Board.coordinateAt(player.startOuterIndex)`.
3. The deploy move is created with `MoveKind.deploy` and `targetIndex = player.startOuterIndex`.
4. In `applyMove()`, `MoveKind.deploy` calls `piece._deploy()` which sets state to `outer` with `_outerSteps = 0`.
5. For non-1 rolls with all pawns home, `getLegalMoves()` returns an empty list.
6. In the UI (`_updateHighlights()`), when there are pending rolls but no legal moves, `skipCurrentRoll()` is called after a 1.5s delay, which advances to the next player.

**Bugs Found:** None

---

### SCENARIO 2 — Bonus Roll Chain

**Status: PARTIAL**

**Logic Flow Traced:**
1. `DiceRoll.grantsExtra` returns `true` for values 1, 5, 6, and 12.
2. In `rollDice()`:
   - If `roll.grantsExtra` is true, `_consecutiveBonusCount` is incremented.
   - If `_consecutiveBonusCount == 3`, the turn is forfeited: pending rolls cleared, count reset to 0, rolling phase set to false, and `_advanceToNextPlayer()` is called.
   - Otherwise, the roll is added to `_pendingRolls` and `_rollingPhase` remains true.
3. For non-bonus rolls, the roll is added to `_pendingRolls`, `_consecutiveBonusCount` is reset to 0, and `_rollingPhase` is set to false.

**Bug Found:**
- **BUG-001**: In `rollDice()`, when the 3-strike forfeit triggers, the roll that caused the forfeit is **not added to `_pendingRolls`**. This means the player who triggered the forfeit doesn't get to use that roll. While this might be intentional (forfeit means losing the turn), the code returns the roll but the UI in `_rollDice()` checks `if (_game.consecutiveBonusCount == 0 && roll.grantsExtra)` to show the forfeit message. However, after `_advanceToNextPlayer()`, the `_consecutiveBonusCount` is reset to 0, so the condition `_game.consecutiveBonusCount == 0` is true, and `roll.grantsExtra` is true, so the message shows correctly. The logic is actually correct for the forfeit behavior, but the roll is lost (not added to pending), which is the intended behavior.

**Additional Issue:**
- **BUG-002**: In the UI `_rollDice()` method, the condition to show the forfeit snackbar is `if (_game.consecutiveBonusCount == 0 && roll.grantsExtra)`. This is fragile because `_consecutiveBonusCount` could be 0 for other reasons (e.g., a non-bonus roll was just made). However, since `roll.grantsExtra` is also checked, this is acceptable. The logic works correctly for the intended scenario.

**Verdict:** The core logic works correctly. The 3-strike forfeit properly clears pending rolls, resets the counter, and advances to the next player. The bonus roll chain works as expected.

---

### SCENARIO 3 — Jodu Blocking

**Status: PASS**

**Logic Flow Traced:**
1. In `_canLandOn()`, the engine counts pieces on the target coordinate:
   - `teammatePiecesCount`: pieces from the same team.
   - `opponentPiecesCount`: pieces from opposing teams.
2. If `teammatePiecesCount > 0`, the move is blocked (return false) — teammates cannot land on each other on unsafe cells.
3. If `opponentPiecesCount >= 2`, the move is blocked (return false) — a single piece cannot capture a pair (Jodu).
4. The Jodu scenario test (`_scenarioJoduBlock`) places two Player 0 pieces at outer index 5 and a Player 1 piece at outer index 3 with a roll of 2. The target would be index 5, which has 2 opponent pieces, so the move is correctly blocked.

**Bugs Found:** None

---

### SCENARIO 4 — Vettu (Capture)

**Status: PASS**

**Logic Flow Traced:**
1. In `applyMove()`, after a `deploy` or `outerMove`, the engine calls `_captureAtOuterIndex(move.targetIndex, player)`.
2. `_captureAtOuterIndex()`:
   - Returns empty list if the coordinate is a Malai (safe) cell.
   - Iterates through all players, skipping same-team players.
   - For each opponent piece in `outer` state at the target index, calls `piece.sendHome()` and adds to captured list.
3. If `cutPieces.isNotEmpty`, sets `player.hasVettu = true`.
4. The capture only happens for `deploy` and `outerMove` kinds, not for `enterInner`, `innerMove`, or `finish`.

**Bugs Found:** None

---

### SCENARIO 5 — Inner Track Gate (Pazham Entry)

**Status: PASS**

**Logic Flow Traced:**
1. In `_legalMovesForPiece()`, for pieces in `outer` state:
   - The code checks `if (piece.atGate && player.hasVettu && rollValue <= player.innerPath.length)`.
   - `piece.atGate` is true when `_outerSteps >= Board.outerLength` and `_outerSteps % Board.outerLength == 0`.
   - Without `hasVettu`, the condition fails, and no inner track entry move is generated.
   - With `hasVettu`, the move is generated if the roll value fits within the inner path length.
2. The Vettu Lock scenario (`_scenarioVettuLock`) places a piece at the gate with `hasVettu = false` and a roll of 3. The legal moves list will be empty for inner entry (though the piece could still move on the outer track if the target is valid).
3. The Vettu Unlock scenario (`_scenarioVettuUnlock`) sets `hasVettu = true` and allows inner entry.

**Bugs Found:** None

---

### SCENARIO 6 — Win Condition

**Status: PASS**

**Logic Flow Traced:**
1. `_checkWinner()` iterates through unique team IDs.
2. For each team, it checks if all players on that team have `allFinished` (all 4 pieces in `finished` state).
3. If a team qualifies, it returns that team ID.
4. In `applyMove()`, after a move is applied, `_winningTeamId = _checkWinner()` is called.
5. If the game is over, pending rolls are cleared, and the turn ends immediately.
6. The UI's `_handleMoveStatus()` detects `_game.isGameOver` and calls `_handleGameFinished()`.

**Bugs Found:** None

---

### SCENARIO 7 — Match Statistics Storage

**Status: PASS**

**Logic Flow Traced:**

**(a) History limit to 100 entries:**
- `_maxMatchHistory = 100` constant is defined.
- In `logMatch()`, after adding the new record, `if (list.length > _maxMatchHistory)` removes the oldest entries with `list.removeRange(0, list.length - _maxMatchHistory)`.

**(b) Only increment gamesWon for winning team:**
- In `logMatch()`, the code checks `if (matchStats.teamId == record.winnerTeamId)` before incrementing `p.gamesWon++`.
- This correctly only increments wins for players on the winning team.

**(c) Batch profile writes:**
- The code collects all profile updates in memory using `profilesChanged` flag.
- Only after processing all `record.statsPerPlayer` entries does it write to storage once: `await _storage.write(key: _keyProfiles, ...)`.
- This avoids N+1 write operations.

**Bugs Found:** None

---

## 3. Bugs and Recommendations

### Bugs Found

| Bug ID | Severity | Description | Location |
|--------|----------|-------------|----------|
| BUG-001 | **Low** | In `rollDice()`, when the 3-strike forfeit triggers, the forfeiting roll is not added to `_pendingRolls`. This is actually correct behavior (the turn is forfeited), but the code could be clearer about this intent. | `daayakattai_engine.dart` — `rollDice()` |
| BUG-002 | **Low** | The UI's forfeit message condition `if (_game.consecutiveBonusCount == 0 && roll.grantsExtra)` is fragile. It relies on the fact that `_advanceToNextPlayer()` resets the counter. If the game logic changes, this could break. | `daayakattai_board.dart` — `_rollDice()` |

### Recommendations

1. **Add explicit documentation** for the 3-strike forfeit behavior in `rollDice()` to clarify that the forfeiting roll is intentionally discarded.

2. **Improve the forfeit message condition** in the UI to use a more explicit check, such as checking if the turn was actually forfeited (e.g., checking if the current player changed after the roll).

3. **Consider adding a `forfeited` flag to `TurnResult`** to make the UI logic more robust and less dependent on internal state.

4. **Add unit tests** for the edge cases:
   - Rolling 3 bonus rolls in a row with no moves in between.
   - Rolling a bonus roll after a non-bonus roll (counter reset).
   - Jodu blocking when the pair is on a Malai (safe) cell (should be allowed since Malai cells are always safe).

5. **Potential issue with `_canLandOn` for Malai cells**: The function returns `true` immediately for Malai cells without checking if there are already pieces there. This means multiple pieces (including from different teams) can stack on Malai cells. This is likely intentional (safe cells), but should be verified against game rules.

6. **The `_captureAtOuterIndex` function** only captures pieces in `outer` state. If a piece is in `inner` state on the same coordinate (which shouldn't happen since inner paths are separate), it wouldn't be captured. This is correct behavior.

7. **In `_handleGameFinished()`**, the stats are hardcoded (`rollsCount: 15, dhavamsRolled: 2, pannirendusRolled: 1, piecesCut: 1`). This should be tracked dynamically during gameplay for accurate statistics.

---

## Conclusion

The Daayakattai game engine correctly implements the core game rules for deployment, bonus rolls, Jodu blocking, Vettu captures, inner track entry, and win conditions. The storage service properly handles match history limits, win attribution, and batched writes. The only issues found are minor UI robustness concerns and a lack of dynamic stat tracking in the game completion handler.