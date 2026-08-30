import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class DiceAnimationWidget extends StatefulWidget {
  final int rollValue;
  final bool isRolling;
  final VoidCallback? onAnimationComplete;

  const DiceAnimationWidget({
    super.key,
    required this.rollValue,
    required this.isRolling,
    this.onAnimationComplete,
  });

  @override
  State<DiceAnimationWidget> createState() => _DiceAnimationWidgetState();
}

class _DiceAnimationWidgetState extends State<DiceAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<bool> _flipStates;
  final Random _random = Random();
  Timer? _flipTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete?.call();
        }
      });

    _flipStates = List.generate(4, (_) => _random.nextBool());

    if (widget.isRolling) {
      _startRolling();
    }
  }

  void _startRolling() {
    _controller.repeat();
    _flipTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        _flipStates = List.generate(4, (_) => _random.nextBool());
      });
    });
  }

  void _stopRolling() {
    _flipTimer?.cancel();
    _flipTimer = null;
    _controller.stop();
    _controller.reset();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DiceAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _startRolling();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _stopRolling();
    }
  }

  @override
  void dispose() {
    _flipTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<bool> _getFinalFaces() {
    switch (widget.rollValue) {
      case 12:
        return [false, false, false, false];
      case 1:
        return [true, false, false, false];
      case 2:
        return [true, true, false, false];
      case 3:
        return [true, true, true, false];
      case 4:
        return [true, true, true, true];
      case 5:
        return [false, false, false, false];
      case 6:
        return [true, true, true, true];
      default:
        return [false, false, false, false];
    }
  }

  String _getTamilLabel() {
    switch (widget.rollValue) {
      case 1:
        return '1 - தாயம்';
      case 5:
        return '5 - வைகல்';
      case 6:
        return '6 - ஆறு';
      case 12:
        return '12 - பன்னிரண்டு';
      default:
        return '${widget.rollValue}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final faces = widget.isRolling ? _flipStates : _getFinalFaces();
    final isSpecialFive = !widget.isRolling && widget.rollValue == 5;

    return SizedBox(
      width: 160,
      height: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(120, 120),
                  painter: _DicePainter(
                    faces: faces,
                    isSpecialFive: isSpecialFive,
                    animationValue: _controller.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (widget.isRolling)
            FadeTransition(
              opacity: Tween(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeInOut,
                ),
              ),
              child: const Text(
                'Rolling...',
                style: TextStyle(
                  color: Color(0xFFD9A843),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              _getTamilLabel(),
              style: TextStyle(
                color: widget.rollValue == 1 ||
                        widget.rollValue == 5 ||
                        widget.rollValue == 6 ||
                        widget.rollValue == 12
                    ? const Color(0xFFD9A843)
                    : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  final List<bool> faces;
  final bool isSpecialFive;
  final double animationValue;

  _DicePainter({
    required this.faces,
    required this.isSpecialFive,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stickWidth = size.width * 0.35;
    final stickHeight = size.height * 0.35;
    final gap = size.width * 0.1;
    final startX = (size.width - (stickWidth * 2 + gap)) / 2;
    final startY = (size.height - (stickHeight * 2 + gap)) / 2;

    final goldPaint = Paint()
      ..color = const Color(0xFFD9A843)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final darkPaint = Paint()
      ..color = const Color(0xFF2B0A0A)
      ..style = PaintingStyle.fill;

    final ivoryPaint = Paint()
      ..color = const Color(0xFFF1E4C4)
      ..style = PaintingStyle.fill;

    final goldDotPaint = Paint()
      ..color = const Color(0xFFD9A843)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final row = i ~/ 2;
      final col = i % 2;
      final left = startX + col * (stickWidth + gap);
      final top = startY + row * (stickHeight + gap);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, stickWidth, stickHeight),
        Radius.circular(stickWidth * 0.2),
      );

      // Draw the stick body
      canvas.drawRRect(rect, faces[i] ? ivoryPaint : darkPaint);

      // Draw gold border
      canvas.drawRRect(rect, goldPaint);

      // Special case for 5: draw gold dot in center of all sticks
      if (isSpecialFive) {
        final center = Offset(left + stickWidth / 2, top + stickHeight / 2);
        canvas.drawCircle(center, stickWidth * 0.15, goldDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DicePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.isSpecialFive != isSpecialFive ||
        oldDelegate.animationValue != animationValue;
  }
}