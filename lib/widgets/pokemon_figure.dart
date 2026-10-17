import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'glass.dart';
import 'pokeball.dart';

/// Figura del Pokémon con volumen: la imagen se "extruye" en varias capas
/// a distinta profundidad, de modo que al girar en 3D se ven sus costados.
/// Gira sola, se puede girar arrastrando de lado y da un giro al tocarla.
class PokemonFigure extends StatefulWidget {
  const PokemonFigure({
    super.key,
    required this.imageUrl,
    required this.color,
    this.size = 240,
    this.spinning = true,
  });

  final String? imageUrl;
  final Color color;
  final double size;
  final bool spinning;

  @override
  State<PokemonFigure> createState() => _PokemonFigureState();
}

class _PokemonFigureState extends State<PokemonFigure>
    with TickerProviderStateMixin {
  static const _capas = 9;
  static const _velocidadGiro = 1.1; // rad/s

  late final Ticker _ticker = createTicker(_tick);
  late final AnimationController _flotar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);
  final _yaw = ValueNotifier<double>(0);
  Duration _anterior = Duration.zero;
  double _velocidad = 14; // giro de entrada
  bool _arrastrando = false;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void didUpdateWidget(PokemonFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) _velocidad = 14;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _flotar.dispose();
    _yaw.dispose();
    super.dispose();
  }

  void _tick(Duration transcurrido) {
    final dt = ((transcurrido - _anterior).inMicroseconds / 1e6).clamp(
      0.0,
      0.05,
    );
    _anterior = transcurrido;
    if (_arrastrando) return;

    var yaw = _yaw.value + _velocidad * dt;
    _velocidad *= math.pow(0.12, dt).toDouble();

    if (widget.spinning) {
      yaw += _velocidadGiro * dt;
    } else if (_velocidad.abs() < 0.4) {
      // Sin giro automático: vuelve a quedar de frente.
      final frente = (yaw / (2 * math.pi)).roundToDouble() * 2 * math.pi;
      yaw += (frente - yaw) * math.min(1, dt * 4);
    }
    _yaw.value = yaw;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final sensibilidad = 3.2 / size;

    return GestureDetector(
      onTap: () => _velocidad += 16,
      onHorizontalDragStart: (_) {
        _arrastrando = true;
        _velocidad = 0;
      },
      onHorizontalDragUpdate: (d) => _yaw.value += d.delta.dx * sensibilidad,
      onHorizontalDragEnd: (d) {
        _arrastrando = false;
        _velocidad = d.velocity.pixelsPerSecond.dx * sensibilidad;
      },
      child: SizedBox(
        width: size,
        height: size + 36,
        child: AnimatedBuilder(
          animation: Listenable.merge([_yaw, _flotar]),
          builder: (context, _) {
            final flotar = Curves.easeInOut.transform(_flotar.value);
            final yaw = _yaw.value;

            return Stack(
              alignment: Alignment.topCenter,
              children: [
                // Sombra en el "piso" que se encoge al subir.
                Positioned(
                  bottom: 8,
                  child: SombraPiso(
                    ancho: size * (0.5 - flotar * 0.1),
                    alto: 14,
                    opacidad: 0.3 - flotar * 0.1,
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -14 * flotar + 6),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014)
                      ..rotateY(yaw),
                    child: SizedBox.square(
                      dimension: size,
                      child: _volumen(size, yaw),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Apila las capas de atrás hacia adelante según hacia dónde mira.
  Widget _volumen(double size, double yaw) {
    final url = widget.imageUrl;
    if (url == null) return _sinImagen(size);

    final profundidad = size * 0.07;
    final borde = Color.lerp(widget.color, Colors.black, 0.45)!;
    final indices = List.generate(_capas, (i) => i);
    // Con perspectiva, z positivo queda más lejos: se dibuja primero lo lejano.
    final deFrente = math.cos(yaw) >= 0;
    final orden = deFrente ? indices.reversed : indices;

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final i in orden)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(
              0,
              0,
              (i / (_capas - 1) - 0.5) * profundidad,
            ),
            child: i == 0 || i == _capas - 1
                ? _imagen(url, size, conCarga: i == 0)
                : Image.network(
                    url,
                    fit: BoxFit.contain,
                    color: borde,
                    colorBlendMode: BlendMode.srcIn,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
          ),
      ],
    );
  }

  Widget _imagen(String url, double size, {required bool conCarga}) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sincrono) {
        if (sincrono) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 400),
          child: child,
        );
      },
      loadingBuilder: (context, child, progreso) =>
          progreso == null || !conCarga
          ? child
          : Center(child: PokeballLoader(size: size * 0.2)),
      errorBuilder: (_, _, _) =>
          conCarga ? _sinImagen(size) : const SizedBox.shrink(),
    );
  }

  Widget _sinImagen(double size) => Center(
    child: Icon(
      Icons.catching_pokemon,
      size: size * 0.4,
      color: widget.color.withValues(alpha: 0.5),
    ),
  );
}
