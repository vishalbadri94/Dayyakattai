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

    _flipStates = List.generate(2, (_) => _random.nextBool());

    if (widget.isRolling) {
      _startRolling();
    }
  }

  void _startRolling() {
    _controller.repeat();
    _flipTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        _flipStates = List.generate(2, (_) => _random.nextBool());
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
        return [false, false];
      case 1:
        return [true, false];
      case 2:
        return [true, true];
      case 3:
        return [true, true];
      case 4:
        return [true, true];
      case 5:
        return [false, false];
      case 6:
        return [true, true];
      default:
        return [false, false];
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

    // Brass gradient colors
    final brassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFD9A843),
        const Color(0xFFB8860B),
        const Color(0xFF8B6914),
        const Color(0xFFD9A843),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final brassPaint = Paint()
      ..shader = brassGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    final goldDotPaint = Paint()
      ..color = const Color(0xFFD9A843)
      ..style = PaintingStyle.fill;

    // Draw two elongated rectangular bars side-by-side
    for (int i = 0; i < 2; i++) {
      final left = startX + i * (stickWidth + gap);
      final top = startY;

      // Apply rotation and scale during animation
      final angle = animationValue * 2 * pi;
      final scale = 1.0 + 0.1 * sin(animationValue * 2 * pi);

      canvas.save();
      canvas.translate(left + stickWidth / 2, top + stickHeight / 2);
      canvas.rotate(angle);
      canvas.scale(scale);
      canvas.translate(-(left + stickWidth / 2), -(top + stickHeight / 2));

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, stickWidth, stickHeight),
        Radius.circular(stickWidth * 0.2),
      );

      // Draw the stick body with brass gradient
      canvas.drawRRect(rect, brassPaint);

      // Draw gold border
      final goldPaint = Paint()
        ..color = const Color(0xFFD9A843)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(rect, goldPaint);

      // Draw dots on the faces representing the final roll values
      if (!isSpecialFive) {
        if (faces[i]) {
          // Draw dot in center of the stick
          final center = Offset(left + stickWidth / 2, top + stickHeight / 2);
          canvas.drawCircle(center, stickWidth * 0.15, goldDotPaint);
        }
      } else {
        // Special case for 5: draw gold dot in center of all sticks
        final center = Offset(left + stickWidth / 2, top + stickHeight / 2);
        canvas.drawCircle(center, stickWidth * 0.15, goldDotPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DicePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.isSpecialFive != isSpecialFive ||
        oldDelegate.animationValue != animationValue;
  }
}