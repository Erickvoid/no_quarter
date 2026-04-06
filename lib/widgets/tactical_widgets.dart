import 'package:flutter/material.dart';
import '../theme/refugio_theme.dart';

/// Barra de progreso elegante
class RefugioProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color? backgroundColor;
  final double height;
  final String? label;

  const RefugioProgressBar({
    super.key,
    required this.progress,
    this.color = RefugioTheme.primary,
    this.backgroundColor,
    this.height = 8,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label!, style: RefugioTextStyles.label),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: RefugioTextStyles.label.copyWith(color: color),
                ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? RefugioTheme.surfaceLight,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta Refugio reutilizable
class RefugioCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final String? headerLabel;

  const RefugioCard({
    super.key,
    required this.child,
    this.borderColor,
    this.padding,
    this.headerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: RefugioTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? RefugioTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerLabel != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: (borderColor ?? RefugioTheme.primary).withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Text(
                headerLabel!,
                style: RefugioTextStyles.label.copyWith(
                  color: borderColor ?? RefugioTheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Separador con label
class RefugioDivider extends StatelessWidget {
  final String? label;
  const RefugioDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const Divider(color: RefugioTheme.cardBorder, height: 32);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: RefugioTheme.cardBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!,
              style: RefugioTextStyles.label.copyWith(
                color: RefugioTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ),
          const Expanded(child: Divider(color: RefugioTheme.cardBorder)),
        ],
      ),
    );
  }
}

/// Indicador de status elegante
class StatusIndicator extends StatelessWidget {
  final bool active;
  final String label;
  final Color activeColor;

  const StatusIndicator({
    super.key,
    required this.active,
    required this.label,
    this.activeColor = RefugioTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? activeColor : RefugioTheme.textMuted,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: RefugioTextStyles.label.copyWith(
            color: active ? activeColor : RefugioTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Aliases de compatibilidad ──
// Permite migración gradual desde los nombres anteriores.
typedef TacticalProgressBar = RefugioProgressBar;
typedef TacticalCard = RefugioCard;
typedef TacticalDivider = RefugioDivider;
