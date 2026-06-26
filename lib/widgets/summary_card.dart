import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SummaryCard extends StatefulWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isHighlighted;
  final String currencySymbol;

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isHighlighted = false,
    this.currencySymbol = '\$',
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  double _scale = 1.0;

  void _setPressed(bool pressed) =>
      setState(() => _scale = pressed ? AppTheme.pressScale : 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: AppTheme.motionFast,
        curve: AppTheme.motionCurve,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: widget.isHighlighted ? 0.5 : 0.28),
                blurRadius: widget.isHighlighted ? 16 : 10,
                spreadRadius: widget.isHighlighted ? 1 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      widget.color.withValues(alpha: 0.22),
                    ],
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(widget.icon, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: Text(
                            widget.label,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: widget.amount),
                      duration: AppTheme.motionSlow * 3,
                      curve: AppTheme.motionCurve,
                      builder: (_, val, __) {
                        final absVal = val.abs();
                        final display = absVal >= 1000
                            ? '${widget.currencySymbol}${(absVal / 1000).toStringAsFixed(1)}k'
                            : '${widget.currencySymbol}${absVal.toStringAsFixed(0)}';
                        return Text(
                          display,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
