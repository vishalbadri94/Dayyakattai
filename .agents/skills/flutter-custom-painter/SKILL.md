---
name: flutter-custom-painter
description: "Best practices for writing highly optimized CustomPainters in Flutter, preventing frame drops during animations."
---

# Flutter CustomPainter Optimization Guidelines

Use this skill when editing or creating custom board game animations or painters (like `DaayakattaiBoardPainter`).

## 1. Repaint Isolation
* Always wrap the `CustomPaint` widget inside a `RepaintBoundary` widget. This prevents the canvas from rebuilding when parent widgets (like status bars, chat overlays, or timers) trigger rebuilds.
* Avoid passing complex data calculations inside the `paint()` method; perform pre-calculations in the widget or state and pass flat values.

## 2. Implement `shouldRepaint` Correctly
* Do not unconditionally return `true` unless the canvas changes on every single tick.
* Compare key variables:
  ```dart
  @override
  bool shouldRepaint(covariant DaayakattaiBoardPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.moveProgress != moveProgress ||
        oldDelegate.movingPieceKey != movingPieceKey ||
        oldDelegate.validPieceKeys.length != validPieceKeys.length;
  }
  ```

## 3. Painting Efficiency
* **Avoid unnecessary Path creations**: Instantiating a `Path` inside the `paint()` loop is expensive. Cache paths or reuse static points where possible.
* **Canvas Clipping**: Clip operations are resource-heavy. Use simple mathematics or custom geometry mapping instead of clipping when drawing rings or overlays.
* **Use drawPicture**: For static components (like the raw silk cloth thread lines background), consider caching the drawing as a `Picture` using a `PictureRecorder` once, and then simply calling `canvas.drawPicture()` on subsequent frames.
