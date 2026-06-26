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
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            // Each card gets its own deep tint of its accent color over the
            // dark soil surface, so the four cards read as distinct shades
            // of green/teal rather than flat white tiles on a green header.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                    widget.color.withValues(alpha: 0.55), AppTheme.surface),
                Color.alphaBlend(
                    widget.color.withValues(alpha: 0.32), AppTheme.background),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: widget.color.withValues(alpha: widget.isHighlighted ? 0.85 : 0.55),
              width: widget.isHighlighted ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: widget.color.withValues(alpha: widget.isHighlighted ? 0.4 : 0.22),
                blurRadius: widget.isHighlighted ? 18 : 12,
                spreadRadius: widget.isHighlighted ? 1 : 0,
              ),
            ],
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
                      color: widget.color,
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
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
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
    );
  }
}
