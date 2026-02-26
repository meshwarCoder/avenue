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
    // Positive dy (dragging down) should increase zoom.
    final delta = details.primaryDelta!;

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
            // 3D Outer Bezel/Shadow container
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Outer deep shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                    blurRadius: 15,
                    offset: const Offset(5, 8),
                    spreadRadius: 1,
                  ),
                  // Top light highlight for 3D effect
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.9),
                    blurRadius: 10,
                    offset: const Offset(-4, -4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF3A3A3C),
                            const Color(0xFF2C2C2E),
                            const Color(0xFF1C1C1E),
                          ]
                        : [
                            Colors.white,
                            const Color(0xFFF2F2F7),
                            const Color(0xFFE5E5EA),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Center(
                  // 3D Inner Core Cap
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          activeRingColor.withOpacity(0.4),
                          activeRingColor.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.45 : 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.06),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glowing indicator dot
                        Positioned(
                          top: 5,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.65,
                                  ),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Progress Ring & Dial Ticks
            Positioned.fill(
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: progress,
                  ringColor: activeRingColor,
                  bgColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  isDark: isDark,
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
  final bool isDark;

  _ProgressRingPainter({
    required this.progress,
    required this.ringColor,
    required this.bgColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 1.8;
    final radius = (math.min(size.width, size.height) / 2) - 4.0;

    // Draw Decorative Dial Ticks (The "Lines")
    final tickCount = 60;
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0;

    for (int i = 0; i < tickCount; i++) {
      final angle = (i * 2 * math.pi / tickCount) - math.pi / 2;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 6.0 : 3.0;

      final innerRadius = radius - 8.0;
      final outerRadius = innerRadius - tickLength;

      tickPaint.color = (isDark ? Colors.white : Colors.black).withOpacity(
        isMajor ? 0.15 : 0.08,
      );

      canvas.drawLine(
        Offset(
          center.dx + innerRadius * math.cos(angle),
          center.dy + innerRadius * math.sin(angle),
        ),
        Offset(
          center.dx + outerRadius * math.cos(angle),
          center.dy + outerRadius * math.sin(angle),
        ),
        tickPaint,
      );
    }

    // Draw Background Track
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * math.pi * progress;
    final startAngle = -math.pi / 2;

    if (progress > 0) {
      // Glow/Neon layer
      final glowPaint = Paint()
        ..color = ringColor.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      // Main active arc
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

      // 3D Terminal dot (Light reflection on dot)
      final endAngle = startAngle + sweepAngle;
      final dotOffset = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      final dotShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(dotOffset + const Offset(1, 1), 3.5, dotShadowPaint);

      final dotPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotOffset, 3.0, dotPaint);

      final dotHighlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotOffset - const Offset(1, 1), 1.0, dotHighlightPaint);
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.isDark != isDark;
  }
}
