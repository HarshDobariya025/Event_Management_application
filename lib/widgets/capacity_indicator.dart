import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class CapacityIndicator extends StatefulWidget {
  final int current;
  final int max;
  final bool showLabel;
  final double height;

  const CapacityIndicator({
    super.key,
    required this.current,
    required this.max,
    this.showLabel = true,
    this.height = 16,
  });

  @override
  State<CapacityIndicator> createState() => _CapacityIndicatorState();
}

class _CapacityIndicatorState extends State<CapacityIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _targetProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _updateProgress();
  }

  @override
  void didUpdateWidget(CapacityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current || oldWidget.max != widget.max) {
      _updateProgress();
    }
  }

  void _updateProgress() {
    final newProgress = widget.max > 0
        ? (widget.current / widget.max).clamp(0.0, 1.0)
        : 0.0;
    final currentValue = _progressAnimation.value;
    _progressAnimation = Tween<double>(
      begin: currentValue,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _targetProgress = newProgress;
    _controller.forward(from: 0);
  }

  static const double criticalThreshold = 0.90;
  static const double moderateThreshold = 0.70;

  Color get _barColor {
    if (_targetProgress >= criticalThreshold) return AppTheme.error;
    if (_targetProgress >= moderateThreshold) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = widget.max > 0
        ? ((widget.current / widget.max) * 100).toInt()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.current} of ${widget.max} checked in',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white70
                      : const Color(0xFF4A5568),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _barColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percentage%',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            final progress = _progressAnimation.value;
            Color barColor;
            if (progress >= criticalThreshold) barColor = AppTheme.error;
            else if (progress >= moderateThreshold) barColor = AppTheme.warning;
            else barColor = AppTheme.success;

            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(widget.height),
                  child: Stack(
                    children: [
                      Container(
                        height: widget.height,
                        width: double.infinity,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: widget.height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                barColor.withOpacity(0.8),
                                barColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(widget.height),
                            boxShadow: [
                              BoxShadow(
                                color: barColor.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
