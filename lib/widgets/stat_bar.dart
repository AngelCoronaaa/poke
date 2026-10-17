import 'package:flutter/material.dart';

import '../models/pokemon.dart';

/// Barra de estadística que se llena con animación.
class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.stat,
    required this.color,
    this.delay = Duration.zero,
  });

  final PokemonStat stat;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final objetivo = (stat.value / PokemonStat.maxValue).clamp(0.0, 1.0);
    final total = const Duration(milliseconds: 900) + delay;
    final inicio = delay.inMilliseconds / total.inMilliseconds;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: total,
        curve: Interval(inicio, 1, curve: Curves.easeOutCubic),
        builder: (context, t, _) => Row(
          children: [
            SizedBox(
              width: 86,
              child: Text(
                stat.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${(stat.value * t).round()}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: scheme.onSurface.withValues(
                    alpha: esOscuro ? 0.1 : 0.07,
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: objetivo * t,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.65), color],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
