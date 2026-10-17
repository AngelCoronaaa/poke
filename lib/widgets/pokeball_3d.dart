import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../models/pokeball_style.dart';
import 'glass.dart';

/// Carga (una sola vez) el shader de la pokébola 3D.
class PokeballShader {
  static Future<ui.FragmentProgram?>? _carga;
  static ui.FragmentProgram? programa;

  static Future<ui.FragmentProgram?> cargar() => _carga ??= _cargar();

  static Future<ui.FragmentProgram?> _cargar() async {
    try {
      return programa = await ui.FragmentProgram.fromAsset(
        'shaders/pokeball.frag',
      );
    } catch (_) {
      return null; // Se usa el dibujo 2D de respaldo.
    }
  }
}

/// Pokébola 3D que gira sola, se puede girar arrastrando (con inercia)
/// y se agita al tocarla, como al capturar un Pokémon.
class Pokeball3D extends StatefulWidget {
  const Pokeball3D({
    super.key,
    required this.style,
    this.size = 200,
    this.autoRotate = true,
    this.speed = 0.7,
    this.interactive = true,
    this.arrastreLibre = true,
    this.giroInicial = false,
    this.sombra = true,
  });

  final PokeballStyle style;
  final double size;
  final bool autoRotate;

  /// Velocidad del giro automático, en radianes por segundo.
  final double speed;
  final bool interactive;

  /// `true`: se gira en cualquier dirección. `false`: solo horizontal,
  /// para no bloquear el scroll vertical de la pantalla.
  final bool arrastreLibre;
  final bool giroInicial;
  final bool sombra;

  @override
  State<Pokeball3D> createState() => _Pokeball3DState();
}

class _Pokeball3DState extends State<Pokeball3D> with TickerProviderStateMixin {
  static const _inclinacion = 0.38;

  late final Ticker _ticker = createTicker(_tick);
  late final AnimationController _agitar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  final _angulos = ValueNotifier(const Offset(-0.5, _inclinacion));
  Duration _anterior = Duration.zero;
  Offset _velocidad = Offset.zero;
  bool _arrastrando = false;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    if (widget.giroInicial) _velocidad = const Offset(16, 0);
    _ticker.start();

    final programa = PokeballShader.programa;
    if (programa != null) {
      _shader = programa.fragmentShader();
    } else {
      PokeballShader.cargar().then((p) {
        if (p != null && mounted) setState(() => _shader = p.fragmentShader());
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _agitar.dispose();
    _angulos.dispose();
    _shader?.dispose();
    super.dispose();
  }

  void _tick(Duration transcurrido) {
    final dt = ((transcurrido - _anterior).inMicroseconds / 1e6).clamp(
      0.0,
      0.05,
    );
    _anterior = transcurrido;
    if (_arrastrando) return;

    var yaw = _angulos.value.dx + _velocidad.dx * dt;
    var pitch = _angulos.value.dy + _velocidad.dy * dt;
    _velocidad *= math.pow(0.05, dt).toDouble();

    if (widget.autoRotate) yaw += widget.speed * dt;
    // La inclinación regresa suavemente a su posición natural.
    if (_velocidad.dy.abs() < 0.3) {
      pitch += (_inclinacion - pitch) * math.min(1, dt * 1.8);
    }
    _angulos.value = Offset(yaw, pitch.clamp(-1.3, 1.3));
  }

  double get _sensibilidad => 2.6 / widget.size;

  void _inicioArrastre() {
    _arrastrando = true;
    _velocidad = Offset.zero;
  }

  void _arrastre(Offset delta) {
    final a = _angulos.value;
    _angulos.value = Offset(
      a.dx + delta.dx * _sensibilidad,
      (a.dy + delta.dy * _sensibilidad).clamp(-1.3, 1.3),
    );
  }

  void _finArrastre(Offset velocidadPx) {
    _arrastrando = false;
    _velocidad = velocidadPx * _sensibilidad;
  }

  void _tocar() {
    HapticFeedback.lightImpact();
    _agitar.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final shader = _shader;

    Widget bola = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: shader != null
            ? _PokeballShaderPainter(shader, _angulos, widget.style)
            : _PokeballPlanaPainter(widget.style),
      ),
    );

    // Agitación tipo "captura": se balancea sobre su base.
    bola = AnimatedBuilder(
      animation: _agitar,
      child: bola,
      builder: (context, child) {
        final t = _agitar.value;
        final angulo = math.sin(t * math.pi * 6) * 0.32 * (1 - t);
        return Transform.rotate(
          angle: angulo,
          alignment: const Alignment(0, 0.9),
          child: child,
        );
      },
    );

    if (widget.interactive) {
      bola = GestureDetector(
        onTap: _tocar,
        onPanStart: widget.arrastreLibre ? (_) => _inicioArrastre() : null,
        onPanUpdate: widget.arrastreLibre ? (d) => _arrastre(d.delta) : null,
        onPanEnd: widget.arrastreLibre
            ? (d) => _finArrastre(d.velocity.pixelsPerSecond)
            : null,
        onHorizontalDragStart: widget.arrastreLibre
            ? null
            : (_) => _inicioArrastre(),
        onHorizontalDragUpdate: widget.arrastreLibre
            ? null
            : (d) => _arrastre(Offset(d.delta.dx, 0)),
        onHorizontalDragEnd: widget.arrastreLibre
            ? null
            : (d) => _finArrastre(Offset(d.velocity.pixelsPerSecond.dx, 0)),
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: bola),
      );
    }

    if (!widget.sombra) return bola;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bola,
        SizedBox(height: size * 0.06),
        SombraPiso(ancho: size * 0.6, alto: size * 0.07, opacidad: 0.32),
      ],
    );
  }
}

class _PokeballShaderPainter extends CustomPainter {
  _PokeballShaderPainter(this.shader, this.angulos, this.style)
    : super(repaint: angulos);

  final ui.FragmentShader shader;
  final ValueNotifier<Offset> angulos;
  final PokeballStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    var i = 0;
    void color(Color c) {
      shader
        ..setFloat(i++, c.r)
        ..setFloat(i++, c.g)
        ..setFloat(i++, c.b);
    }

    shader
      ..setFloat(i++, size.width)
      ..setFloat(i++, size.height)
      ..setFloat(i++, angulos.value.dx)
      ..setFloat(i++, angulos.value.dy)
      ..setFloat(i++, style.pattern.index.toDouble());
    color(style.top);
    color(style.bottom);
    color(style.band);
    color(style.accent);
    color(style.accent2);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_PokeballShaderPainter old) =>
      old.shader != shader || old.style != style;
}

/// Respaldo 2D por si el dispositivo no puede cargar el shader.
class _PokeballPlanaPainter extends CustomPainter {
  _PokeballPlanaPainter(this.style);

  final PokeballStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.clipPath(Path()..addOval(rect));

    canvas.drawArc(rect, 0, math.pi, true, Paint()..color = style.bottom);
    canvas.drawArc(rect, math.pi, math.pi, true, Paint()..color = style.top);
    canvas.drawRect(
      Rect.fromCenter(center: c, width: r * 2, height: r * 0.13),
      Paint()..color = style.band,
    );
    canvas.drawCircle(c, r * 0.34, Paint()..color = style.band);
    canvas.drawCircle(c, r * 0.25, Paint()..color = const Color(0xFFF5F5F7));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [
            Colors.white.withValues(alpha: 0.45),
            Colors.black.withValues(alpha: 0.25),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_PokeballPlanaPainter old) => old.style != style;
}
