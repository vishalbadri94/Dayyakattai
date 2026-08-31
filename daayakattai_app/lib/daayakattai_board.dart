import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'daayakattai_engine.dart';
import 'services/daayakattai_storage_service.dart';
import 'services/daayakattai_audio_service.dart';
import 'widgets/dice_animation_widget.dart';
import 'services/daayakattai_share_service.dart';

const int _gridSize = 15;

const Color _kCellIvory = Color(0xFFF0E3C4);
const Color _kAccentRed = Color(0xFFB5472D);
const Color _kAccentGreen = Color(0xFF3E7C4F);
const Color _kAccentBlue = Color(0xFF3B6FA0);
const Color _kAccentOrange = Color(0xFFC56A2D);
const Color _kSafeRed = Color(0xFFA93226);
const Color _kSafeGreen = Color(0xFF1E8449);
const Color _kSafeBlue = Color(0xFF2471A3);
const Color _kSafeOrange = Color(0xFFD35400);

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
  /// Check if a cell is one of the four unused 6x6 corners (home areas).
  static bool isUnusedCorner(int row, int col) {
    return (row < 6 && col < 6) || // Top-Left
        (row < 6 && col > 8) ||    // Top-Right
        (row > 8 && col < 6) ||    // Bottom-Left
        (row > 8 && col > 8);       // Bottom-Right
  }

  /// Safe cross cells: tips, gates, and inner path cells.
  static bool isSafeCrossCell(int row, int col) {
    // Tips
    if ((row == 7 && col == 0) || (row == 7 && col == 14) ||
        (row == 0 && col == 7) || (row == 14 && col == 7)) {
      return true;
    }
    // Gates
    if ((row == 7 && col == 5) || (row == 7 && col == 9) ||
        (row == 5 && col == 7) || (row == 9 && col == 7)) {
      return true;
    }
    // Inner path cells (from gates to tips)
    if (row == 7 && col >= 1 && col <= 5) return true;
    if (row == 7 && col >= 9 && col <= 13) return true;
    if (col == 7 && row >= 1 && row <= 5) return true;
    if (col == 7 && row >= 9 && row <= 13) return true;
    return false;
  }

  static Rect boardRect(Size size) {
    final double side = math.min(size.width, size.height) - 6.0;
    if (side <= 0) return Rect.zero;
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

  /// Calculates visual offset for home base pieces in the 6x6 corner areas.
  static Offset homePieceOffset(Rect boardRect, int playerId, int pieceId) {
    int startRow = 0;
    int startCol = 0;

    final int teamId = playerId % 4;
    switch (teamId) {
      case 0: // Red: Top-Left (2,2)
        startRow = 2;
        startCol = 2;
        break;
      case 1: // Blue: Top-Right (2,11)
        startRow = 2;
        startCol = 11;
        break;
      case 2: // Green: Bottom-Right (11,11)
        startRow = 11;
        startCol = 11;
        break;
      case 3: // Yellow: Bottom-Left (11,2)
        startRow = 11;
        startCol = 2;
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
      final double dx = (col - 0.5) * cellW * 0.9;
      final double dy = (row - 0.5) * cellH * 0.9;
      return cornerCenter + Offset(dx, dy);
    } else {
      // 6, 8, 12 players: compact 3x4 grid to fit up to 12 pieces in the corner
      final int playerRank = playerId ~/ 4;
      final int totalRank = playerRank * 4 + pieceId;
      final int row = totalRank ~/ 4;
      final int col = totalRank % 4;
      final double dx = (col - 1.5) * cellW * 0.6;
      final double dy = (row - 1.0) * cellH * 0.6;
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
    _drawGridCells(canvas, boardRect);
    _drawPieces(canvas, boardRect);
    _drawBrassOuterFrame(canvas, boardRect);
  }

  @override
  bool shouldRepaint(covariant DaayakattaiBoardPainter oldDelegate) => true;

  void _drawRawSilkBackground(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint woodPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6E4324), Color(0xFF3E2212), Color(0xFF241006)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, woodPaint);

    // Fine dark horizontal grain lines.
    final Paint grainPaint = Paint()
      ..color = const Color(0xFF1A0A03).withValues(alpha: 0.22)
      ..strokeWidth = 1.0;

    final math.Random random = math.Random(19);
    for (int i = 0; i < 90; i++) {
      final double y = random.nextDouble() * size.height;
      final double amplitude = 1.0 + random.nextDouble() * 3.0;
      final Path path = Path()..moveTo(0, y);
      final int steps = 32;
      final double stepW = size.width / steps;
      for (int s = 1; s <= steps; s++) {
        final double x = s * stepW;
        final double wave = math.sin(s * 0.55 + i * 1.3) * amplitude;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, grainPaint);
    }

    // Soft vignette.
    final Paint vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0x00000000), const Color(0x55000000)],
        center: Alignment.center,
        radius: 1.3,
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);
  }

  void _drawBrassCornerBracket(Canvas canvas, Offset corner, Alignment alignment) {
    final Paint brassPaint = Paint()
      ..color = const Color(0xFFD9A843)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double size = 30;
    final Path bracketPath = Path();

    if (alignment == Alignment.topLeft) {
      bracketPath.moveTo(corner.dx + size, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy + size);
      bracketPath.moveTo(corner.dx + size * 0.7, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy + size * 0.7);
    } else if (alignment == Alignment.topRight) {
      bracketPath.moveTo(corner.dx - size, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy + size);
      bracketPath.moveTo(corner.dx - size * 0.7, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy + size * 0.7);
    } else if (alignment == Alignment.bottomLeft) {
      bracketPath.moveTo(corner.dx + size, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy - size);
      bracketPath.moveTo(corner.dx + size * 0.7, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy - size * 0.7);
    } else {
      bracketPath.moveTo(corner.dx - size, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy - size);
      bracketPath.moveTo(corner.dx - size * 0.7, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy);
      bracketPath.lineTo(corner.dx, corner.dy - size * 0.7);
    }

    canvas.drawPath(bracketPath, brassPaint);
  }

  void _drawBrassOuterFrame(Canvas canvas, Rect boardRect) {
    final RRect rrect = RRect.fromRectAndRadius(boardRect, const Radius.circular(10));

    final Paint shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect.shift(const Offset(2, 3)), shadowPaint);

    final Paint goldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = const Color(0xFFD9A843);
    canvas.drawRRect(rrect, goldPaint);

    final Paint darkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF2A1508);
    canvas.drawRRect(rrect.deflate(3.0), darkPaint);

    _drawBrassCornerBracket(canvas, boardRect.topLeft, Alignment.topLeft);
    _drawBrassCornerBracket(canvas, boardRect.topRight, Alignment.topRight);
    _drawBrassCornerBracket(canvas, boardRect.bottomLeft, Alignment.bottomLeft);
    _drawBrassCornerBracket(canvas, boardRect.bottomRight, Alignment.bottomRight);
  }

  void _drawWoodenEmblem(Canvas canvas, Offset center, double size) {
    final Paint emblemPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFD9A843),
          Color(0xFF8B5A2B),
          Color(0xFF5C3317),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size));

    canvas.drawCircle(center, size, emblemPaint);

    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFD9A843);
    canvas.drawCircle(center, size * 0.7, ringPaint);

    canvas.drawCircle(center, size * 0.2, Paint()..color = const Color(0xFFD9A843));
  }

  void _drawGridCells(Canvas canvas, Rect boardRect) {
    final double cellW = boardRect.width / _gridSize;
    final double cellH = boardRect.height / _gridSize;

    _drawCornerPlatforms(canvas, boardRect, cellW, cellH);

    // Center HOME square.
    final Rect centerRect = Rect.fromLTWH(
      boardRect.left + 6 * cellW,
      boardRect.top + 6 * cellH,
      cellW * 3,
      cellH * 3,
    );
    _drawHomeCenter(canvas, centerRect, cellW, cellH);

    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        // Skip corner spaces; they are now raised platforms.
        if (DaayakattaiBoardGeometry.isUnusedCorner(row, col)) {
          continue;
        }

        // Central HOME area is drawn above, so skip center cells.
        if (row >= 6 && row <= 8 && col >= 6 && col <= 8) {
          continue;
        }

        final Rect cellRect = Rect.fromLTWH(
          boardRect.left + col * cellW,
          boardRect.top + row * cellH,
          cellW,
          cellH,
        );
        final Rect fillRect = cellRect.deflate(1.4);

        Color cellColor = _kCellIvory;
        if (row == 7 && col <= 5) {
          cellColor = const Color(0xFFE1E9F2);
        } else if (row == 7 && col >= 9) {
          cellColor = const Color(0xFFDDE9DB);
        } else if (col == 7 && row <= 5) {
          cellColor = const Color(0xFFF3DEDA);
        } else if (col == 7 && row >= 9) {
          cellColor = const Color(0xFFF3E2CF);
        }

        final Paint fillPaint = Paint()..color = cellColor;
        canvas.drawRRect(
          RRect.fromRectAndRadius(fillRect, const Radius.circular(2.5)),
          fillPaint,
        );

        final Paint borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF3F0E0E);

        canvas.drawRRect(
          RRect.fromRectAndRadius(fillRect, const Radius.circular(2.5)),
          borderPaint,
        );

        final Color? xColor = _safeXColor(row, col);
        if (xColor != null) {
          _drawSafeX(canvas, fillRect, xColor);
        }
      }
    }

    _drawJunctionMarks(canvas, boardRect, cellW, cellH);
    _drawDiceSticks(canvas, boardRect, cellW, cellH);
  }

  Color? _safeXColor(int row, int col) {
    if (row == 7 && col <= 5) return _kSafeBlue;
    if (row == 7 && col >= 9) return _kSafeGreen;
    if (col == 7 && row <= 5) return _kSafeRed;
    if (col == 7 && row >= 9) return _kSafeOrange;
    return null;
  }

  void _drawSafeX(Canvas canvas, Rect rect, Color color) {
    final double strokeWidth = math.max(2.0, rect.width * 0.13);
    final Paint shadowPaint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = strokeWidth + 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      rect.topLeft + const Offset(0.8, 0.8),
      rect.bottomRight + const Offset(0.8, 0.8),
      shadowPaint,
    );
    canvas.drawLine(
      rect.topRight + const Offset(-0.8, 0.8),
      rect.bottomLeft + const Offset(-0.8, 0.8),
      shadowPaint,
    );

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
    canvas.drawLine(rect.topRight, rect.bottomLeft, paint);
  }

  void _drawJunctionMarks(Canvas canvas, Rect boardRect, double cellW, double cellH) {
    // North-West junction
    final Rect nw = Rect.fromLTWH(
      boardRect.left + 5 * cellW,
      boardRect.top + 5 * cellH,
      cellW,
      cellH,
    );
    _drawSafeX(canvas, nw.deflate(1.4), _kSafeRed);

    // North-East junction
    final Rect ne = Rect.fromLTWH(
      boardRect.left + 9 * cellW,
      boardRect.top + 5 * cellH,
      cellW,
      cellH,
    );
    _drawSafeX(canvas, ne.deflate(1.4), _kSafeBlue);

    // South-West junction
    final Rect sw = Rect.fromLTWH(
      boardRect.left + 5 * cellW,
      boardRect.top + 9 * cellH,
      cellW,
      cellH,
    );
    _drawSafeX(canvas, sw.deflate(1.4), _kSafeOrange);

    // South-East junction
    final Rect se = Rect.fromLTWH(
      boardRect.left + 9 * cellW,
      boardRect.top + 9 * cellH,
      cellW,
      cellH,
    );
    _drawSafeX(canvas, se.deflate(1.4), _kSafeGreen);
  }

  void _drawCornerPlatforms(Canvas canvas, Rect boardRect, double cellW, double cellH) {
    void build(Rect cornerRect, Alignment corner) {
      final Rect rect = cornerRect.deflate(1.5);
      final RRect rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: corner == Alignment.topLeft ? const Radius.circular(14) : Radius.zero,
        topRight: corner == Alignment.topRight ? const Radius.circular(14) : Radius.zero,
        bottomLeft: corner == Alignment.bottomLeft ? const Radius.circular(14) : Radius.zero,
        bottomRight: corner == Alignment.bottomRight ? const Radius.circular(14) : Radius.zero,
      );

      final Paint platformPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6D4A2B), Color(0xFF3E2212), Color(0xFF241006)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);
      canvas.drawRRect(rrect, platformPaint);

      final Paint darkPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF1F0C04);
      canvas.drawRRect(rrect, darkPaint);

      final Paint goldPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFD9A843);
      canvas.drawRRect(rrect.deflate(4.5), goldPaint);

      _drawCornerPockets(canvas, boardRect, cellW, cellH, corner);
    }

    build(
      Rect.fromLTWH(boardRect.left, boardRect.top, cellW * 6, cellH * 6),
      Alignment.topLeft,
    );
    build(
      Rect.fromLTWH(boardRect.right - cellW * 6, boardRect.top, cellW * 6, cellH * 6),
      Alignment.topRight,
    );
    build(
      Rect.fromLTWH(boardRect.left, boardRect.bottom - cellH * 6, cellW * 6, cellH * 6),
      Alignment.bottomLeft,
    );
    build(
      Rect.fromLTWH(
        boardRect.right - cellW * 6,
        boardRect.bottom - cellH * 6,
        cellW * 6,
        cellH * 6,
      ),
      Alignment.bottomRight,
    );
  }

  void _drawCornerPockets(
    Canvas canvas,
    Rect boardRect,
    double cellW,
    double cellH,
    Alignment corner,
  ) {
    int teamId;
    if (corner == Alignment.topLeft) {
      teamId = 0;
    } else if (corner == Alignment.topRight) {
      teamId = 1;
    } else if (corner == Alignment.bottomRight) {
      teamId = 2;
    } else {
      teamId = 3;
    }

    final double radius = math.min(cellW, cellH) * 0.30;
    for (int i = 0; i < 4; i++) {
      final Offset center = DaayakattaiBoardGeometry.homePieceOffset(boardRect, teamId, i);
      _drawRecessedPocket(canvas, center, radius);
    }
  }

  void _drawRecessedPocket(Canvas canvas, Offset center, double radius) {
    final Paint shadowPaint = Paint()..color = const Color(0x44000000);
    canvas.drawCircle(center + const Offset(1.2, 1.6), radius, shadowPaint);

    final Paint basePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF2A1508), Color(0xFF4A2A12), Color(0xFF5C3317)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, basePaint);

    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF1F0C04);
    canvas.drawCircle(center, radius, rimPaint);

    final Paint innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF8B5A2B).withValues(alpha: 0.5);
    canvas.drawCircle(center, radius - 1.5, innerPaint);
  }

  void _drawHomeCenter(Canvas canvas, Rect rect, double cellW, double cellH) {
    final Offset center = rect.center;

    final Path top = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(center.dx, center.dy)
      ..close();
    final Path right = Path()
      ..moveTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(center.dx, center.dy)
      ..close();
    final Path bottom = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(center.dx, center.dy)
      ..close();
    final Path left = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(center.dx, center.dy)
      ..close();

    final Paint paintA = Paint()..color = const Color(0xFFEAD9B2);
    final Paint paintB = Paint()..color = const Color(0xFFF4E7C8);

    canvas.drawPath(top, paintA);
    canvas.drawPath(right, paintB);
    canvas.drawPath(bottom, paintA);
    canvas.drawPath(left, paintB);

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF3F0E0E);

    canvas.drawLine(rect.topLeft, rect.bottomRight, linePaint);
    canvas.drawLine(rect.topRight, rect.bottomLeft, linePaint);
    canvas.drawRect(rect, linePaint);

    _drawWoodenEmblem(canvas, center, math.min(cellW, cellH) * 0.62);
  }

  void _drawDiceSticks(Canvas canvas, Rect boardRect, double cellW, double cellH) {
    final Offset center = boardRect.center;
    final double length = cellW * 3.9;
    final double thickness = cellW * 0.62;

    _drawDiceStick(
      canvas,
      center.translate(-cellW * 0.35, cellH * 0.2),
      length,
      thickness,
      -0.38,
      3,
    );
    _drawDiceStick(
      canvas,
      center.translate(cellW * 0.35, -cellH * 0.2),
      length,
      thickness,
      0.30,
      2,
    );
  }

  void _drawDiceStick(
    Canvas canvas,
    Offset center,
    double length,
    double thickness,
    double angle,
    int pipCount,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final Rect stickRect = Rect.fromCenter(
      center: Offset.zero,
      width: length,
      height: thickness,
    );
    final RRect rrect = RRect.fromRectAndRadius(
      stickRect,
      Radius.circular(thickness * 0.4),
    );

    final Paint shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawRRect(rrect.shift(const Offset(1.5, 2.0)), shadowPaint);

    final Paint woodPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFC89B63), Color(0xFF8B5A2B), Color(0xFF4A2A12)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(stickRect);
    canvas.drawRRect(rrect, woodPaint);

    final Paint bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFD9A843).withValues(alpha: 0.45);
    canvas.drawRRect(rrect.deflate(1.0), bevelPaint);

    final Paint edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF2A1508);
    canvas.drawRRect(rrect, edgePaint);

    final double pipRadius = thickness * 0.13;
    final double span = length * 0.66;
    for (int i = 0; i < pipCount; i++) {
      final double t = pipCount == 1 ? 0.0 : -0.5 + (i / (pipCount - 1));
      _drawPip(canvas, Offset(span * t, 0), pipRadius);
    }

    canvas.restore();
  }

  void _drawPip(Canvas canvas, Offset center, double radius) {
    final Paint shadowPaint = Paint()..color = const Color(0x66000000);
    canvas.drawCircle(center + const Offset(0, 0.8), radius, shadowPaint);

    final Paint darkPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1F0C04), Color(0xFF4A2A12)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, darkPaint);

    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF2A1508);
    canvas.drawCircle(center, radius, rimPaint);
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
              ? DaayakattaiBoardGeometry.cellCenter(boardRect, 7, 7)
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
          _drawMarble(canvas, center, radius, _teamColor(player.teamId), selected);
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
        _drawMarble(canvas, stackCenter, radius, _teamColor(piece.owner.teamId), selected);
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

  void _drawMarble(
    Canvas canvas,
    Offset center,
    double r,
    Color marbleColor,
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

    // Draw marble with radial gradient
    final Paint marblePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _lightenColor(marbleColor, 0.4),
          marbleColor,
          _darkenColor(marbleColor, 0.3),
        ],
        stops: const [0.0, 0.6, 1.0],
        center: const Alignment(-0.3, -0.3),
        radius: 1.2,
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r, marblePaint);

    // Glossy broad highlight
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(
      center + Offset(-r * 0.3, -r * 0.3),
      r * 0.4,
      highlightPaint,
    );

    // Small bright specular highlight
    final Paint specularPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawCircle(
      center + Offset(-r * 0.22, -r * 0.28),
      r * 0.14,
      specularPaint,
    );

    // Add subtle rim
    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(center, r, rimPaint);
  }

  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
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
  Language _selectedLanguage = Language.tamil;
  final DaayakattaiAudioService _audio = DaayakattaiAudioService();

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

    // Init audio service and restore saved language preference
    _audio.init();
    DaayakattaiStorageService.getLanguage().then((lang) {
      final language = lang == 'english' ? Language.english : Language.tamil;
      DaayakattaiAudioService.setLanguage(language);
      if (mounted) setState(() => _selectedLanguage = language);
    });
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
              IconButton(icon: const Icon(Icons.share, color: Color(0xFFD9A843)), onPressed: () => DaayakattaiShareService.shareGameInvite(channelName: DaayakattaiShareService.generateChannelName(), gameMode: _modeLabel(_currentMode), hostName: 'Host', language: _selectedLanguage == Language.tamil ? 'tamil' : 'english')),
              const SizedBox(width: 4),
              // Language toggle: TML ↔ ENG
              GestureDetector(
                onTap: () async {
                  final next = _selectedLanguage == Language.tamil
                      ? Language.english
                      : Language.tamil;
                  await DaayakattaiAudioService.setLanguage(next);
                  await DaayakattaiStorageService.saveLanguage(
                      next == Language.tamil ? 'tamil' : 'english');
                  if (mounted) setState(() => _selectedLanguage = next);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD9A843)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _selectedLanguage == Language.tamil ? 'TML' : 'ENG',
                    style: const TextStyle(
                      color: Color(0xFFD9A843),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Animated dice display
              DiceAnimationWidget(
                rollValue: _game.currentRoll?.value ?? 0,
                isRolling: false,
              ),
              const SizedBox(height: 8),
              SizedBox(
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
            ],
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
      final result = _game.applyMove(_pendingMove!);
      _movingPieceKey = null;
      _moveFromCell = null;
      _moveToCell = null;
      _pendingMove = null;
      _validPieceKeys.clear();
      _pulseController.stop();
      _pulseController.value = 0;

      // Audio feedback after move
      if (result.cutPieces.isNotEmpty) {
        _audio.speakCut();
      } else if (_game.isGameOver) {
        _audio.speakVictory(_game.winningTeamId ?? 0);
      } else {
        _audio.speakTurn('Player ${_game.currentPlayer.id + 1}');
      }

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

      // Speak the rolled value
      _audio.speakRoll(roll.value);

      if (_game.consecutiveBonusCount == 0 && roll.grantsExtra) {
        // Three consecutive bonus rolls = forfeit
        _audio.speakForfeit();
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
            ((player.teamId == 0 && row >= 2 && row < 4 && col >= 2 && col < 4) ||
             (player.teamId == 1 && row >= 2 && row < 4 && col >= 11 && col < 13) ||
             (player.teamId == 2 && row >= 11 && row < 13 && col >= 11 && col < 13) ||
             (player.teamId == 3 && row >= 11 && row < 13 && col >= 2 && col < 4));
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