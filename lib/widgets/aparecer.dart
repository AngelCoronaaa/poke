import 'package:flutter/material.dart';

/// Aparición escalonada: el contenido sube y se desvanece hacia dentro.
class Aparecer extends StatelessWidget {
  const Aparecer({super.key, required this.orden, required this.child});

  final int orden;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final retraso = orden * 90;
    final total = 500 + retraso;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(retraso / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// Transición suave entre pantallas: desvanecido con un ligero zoom.
Route<T> rutaSuave<T>(Widget pantalla) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 450),
  reverseTransitionDuration: const Duration(milliseconds: 350),
  pageBuilder: (_, _, _) => pantalla,
  transitionsBuilder: (_, animacion, _, child) {
    final curva = CurvedAnimation(
      parent: animacion,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curva,
      child: ScaleTransition(
        scale: Tween(begin: 1.04, end: 1.0).animate(curva),
        child: child,
      ),
    );
  },
);
