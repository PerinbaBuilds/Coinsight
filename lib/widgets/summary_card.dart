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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: AppTheme.motionFast,
        curve: AppTheme.motionCurve,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.space16, AppTheme.space16, AppTheme.space16, AppTheme.space12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: widget.color.withValues(alpha: isDark ? 0.18 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                widget.label,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
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
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
