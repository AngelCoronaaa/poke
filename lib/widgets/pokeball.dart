import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Silueta de pokébola dibujada a mano.
class PokeballPainter extends CustomPainter {
  PokeballPainter({required this.color, this.fillTop = false});

  final Color color;
  final bool fillTop;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final grosor = r * 0.1;
    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor;
    final relleno = Paint()..color = color;

    final centro = r * 0.32;
    final rect = Rect.fromCircle(center: c, radius: r - grosor / 2);
    // Capa propia para poder "vaciar" el botón central con BlendMode.clear.
    canvas.saveLayer(Offset.zero & size, Paint());
    if (fillTop) {
      canvas.drawArc(rect, math.pi, math.pi, true, relleno);
      canvas.drawCircle(c, centro, Paint()..blendMode = BlendMode.clear);
    }
    canvas.drawCircle(c, r - grosor / 2, trazo);
    canvas.drawLine(
      Offset(c.dx - r + grosor / 2, c.dy),
      Offset(c.dx - centro, c.dy),
      trazo,
    );
    canvas.drawLine(
      Offset(c.dx + centro, c.dy),
      Offset(c.dx + r - grosor / 2, c.dy),
      trazo,
    );
    canvas.drawCircle(c, centro, trazo);
    canvas.drawCircle(c, r * 0.14, relleno);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PokeballPainter old) =>
      old.color != color || old.fillTop != fillTop;
}

/// Pokébola que gira sin detenerse.
class RotatingPokeball extends StatefulWidget {
  const RotatingPokeball({
    super.key,
    required this.size,
    required this.color,
    this.duration = const Duration(seconds: 20),
    this.fillTop = false,
  });

  final double size;
  final Color color;
  final Duration duration;
  final bool fillTop;

  @override
  State<RotatingPokeball> createState() => _RotatingPokeballState();
}

class _RotatingPokeballState extends State<RotatingPokeball>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: PokeballPainter(color: widget.color, fillTop: widget.fillTop),
      ),
    );
  }
}

/// Indicador de carga con una pokébola girando y "rebotando".
class PokeballLoader extends StatelessWidget {
  const PokeballLoader({super.key, this.size = 56, this.label});

  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotatingPokeball(
          size: size,
          color: scheme.primary,
          fillTop: true,
          duration: const Duration(milliseconds: 900),
        ),
        if (label != null) ...[
          const SizedBox(height: 16),
          Text(
            label!,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
