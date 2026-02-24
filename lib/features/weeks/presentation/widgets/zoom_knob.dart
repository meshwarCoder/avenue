import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DragZoomRing extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final double initialValue;
  final ValueChanged<double> onChanged;
  final Color? ringColor;
  final Color? backgroundColor;

  const DragZoomRing({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.onChanged,
    this.ringColor,
    this.backgroundColor,
  });

  @override
  State<DragZoomRing> createState() => _DragZoomRingState();
}

class _DragZoomRingState extends State<DragZoomRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  double _currentValue = 0.0;
  double _smoothedDelta = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(DragZoomRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_resetController.isAnimating) {
      _currentValue = widget.value;
    }
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _resetToInitial() {
    HapticFeedback.mediumImpact();
    // Stop any current animation
    if (_resetController.isAnimating) {
      _resetController.stop();
    }

    _resetAnimation =
        Tween<double>(begin: _currentValue, end: widget.initialValue).animate(
          CurvedAnimation(parent: _resetController, curve: Curves.elasticOut),
        )..addListener(() {
          if (mounted) {
            setState(() {
              _currentValue = _resetAnimation.value;
            });
            widget.onChanged(_currentValue);
          }
        });

    _resetController.forward(from: 0.0);
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_resetController.isAnimating) {
      _resetController.stop();
    }
    _smoothedDelta = 0.0;

    // Prevent parent Scrollable from scrolling
    final scrollableState = Scrollable.maybeOf(context);
    if (scrollableState != null) {
      scrollableState.position.hold(() {});
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // Negative dy means dragging up. Dragging up should increase zoom.
    final delta = -details.primaryDelta!;

    // Sensitivity: 1 pixel drag = change in value.
    final adjustedDelta = delta * 0.8;

    // Smooth the delta slightly to remove digitizer jitter
    _smoothedDelta = (_smoothedDelta * 0.7) + (adjustedDelta * 0.3);

    final newValue = (_currentValue + _smoothedDelta).clamp(
      widget.minValue,
      widget.maxValue,
    );

    if (newValue != _currentValue) {
      setState(() {
        _currentValue = newValue;
      });
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeRingColor = widget.ringColor ?? theme.colorScheme.primary;
    final bgColor =
        widget.backgroundColor ??
        (isDark ? const Color(0xFF2C2C2E) : Colors.white);

    final range = widget.maxValue - widget.minValue;
    final progress = range == 0
        ? 0.0
        : (_currentValue - widget.minValue) / range;

    return GestureDetector(
      onDoubleTap: _resetToInitial,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circular shape
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),

            // Progress Ring
            Positioned.fill(
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: progress,
                  ringColor: activeRingColor,
                  bgColor: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color bgColor;

  _ProgressRingPainter({
    required this.progress,
    required this.ringColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 1.6; // Extremely thin line as requested
    final radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2);

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * math.pi * progress;
    final startAngle = -math.pi / 2;

    if (progress > 0) {
      final glowPaint = Paint()
        ..color = ringColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      final fgPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.bgColor != bgColor;
  }
}
