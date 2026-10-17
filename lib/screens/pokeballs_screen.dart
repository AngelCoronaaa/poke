import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../models/pokeball_style.dart';
import '../widgets/glass.dart';
import '../widgets/pokeball_3d.dart';

/// Galería de pokébolas 3D: se giran arrastrando y se agitan al tocarlas.
class PokeballsScreen extends StatefulWidget {
  const PokeballsScreen({super.key});

  @override
  State<PokeballsScreen> createState() => _PokeballsScreenState();
}

class _PokeballsScreenState extends State<PokeballsScreen> {
  final _info = <String, Future<PokeballInfo>>{};
  int _indice = 0;

  PokeballStyle get _actual => PokeballStyle.todas[_indice];

  Future<PokeballInfo> _infoDe(PokeballStyle style) =>
      _info[style.slug] ??= AppScope.read(context).service
          .getPokeball(style.slug);

  void _seleccionar(int i) {
    final total = PokeballStyle.todas.length;
    HapticFeedback.selectionClick();
    setState(() => _indice = (i % total + total) % total);
  }

  @override
  Widget build(BuildContext context) {
    final style = _actual;
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.5);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _seleccionar(_indice - 1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _seleccionar(_indice + 1),
      },
      child: Focus(
        autofocus: true,
        child: LiquidBackground(
          accent: style.colorFondo,
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            GlassButton(
                              circular: true,
                              tooltip: 'Regresar',
                              onPressed: () => Navigator.maybePop(context),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Pokéballs 3D',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      Expanded(flex: 5, child: _escenario(style)),
                      Text(
                        'Arrastra para girar · toca para agitarla',
                        style: TextStyle(color: atenuado, fontSize: 12.5),
                      ),
                      const SizedBox(height: 12),
                      _selector(),
                      const SizedBox(height: 12),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween(
                                  begin: const Offset(0, 0.06),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: _Ficha(
                              key: ValueKey(style.slug),
                              style: style,
                              info: _infoDe(style),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _escenario(PokeballStyle style) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(
          280.0,
          math.min(constraints.maxHeight - 40, constraints.maxWidth - 130),
        );
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: size * 1.3,
              height: size * 1.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    style.colorFondo.withValues(alpha: 0.35),
                    style.colorFondo.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Pokeball3D(
                key: ValueKey(style.slug),
                style: style,
                size: math.max(size, 80),
                giroInicial: true,
              ),
            ),
            Positioned(
              left: 16,
              child: GlassButton(
                circular: true,
                tooltip: 'Anterior',
                onPressed: () => _seleccionar(_indice - 1),
                child: const Icon(Icons.chevron_left_rounded),
              ),
            ),
            Positioned(
              right: 16,
              child: GlassButton(
                circular: true,
                tooltip: 'Siguiente',
                onPressed: () => _seleccionar(_indice + 1),
                child: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _selector() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: PokeballStyle.todas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final style = PokeballStyle.todas[i];
          final seleccionada = i == _indice;
          return Tooltip(
            message: style.nombre,
            child: Presionable(
              onTap: () => _seleccionar(i),
              semanticLabel: style.nombre,
              child: AnimatedScale(
                scale: seleccionada ? 1.0 : 0.84,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: seleccionada
                          ? style.colorFondo
                          : Colors.white.withValues(alpha: 0.3),
                      width: seleccionada ? 2.5 : 1,
                    ),
                    color: Colors.white.withValues(alpha: 0.12),
                    boxShadow: seleccionada
                        ? [
                            BoxShadow(
                              color: style.colorFondo.withValues(alpha: 0.4),
                              blurRadius: 16,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Pokeball3D(
                    style: style,
                    size: 44,
                    interactive: false,
                    sombra: false,
                    speed: seleccionada ? 1.6 : 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({super.key, required this.style, required this.info});

  final PokeballStyle style;
  final Future<PokeballInfo> info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final atenuado = scheme.onSurface.withValues(alpha: 0.55);
    final color = style.colorFondo;

    return FutureBuilder<PokeballInfo>(
      future: info,
      builder: (context, snapshot) {
        final datos = snapshot.data;
        final cargando = snapshot.connectionState != ConnectionState.done;

        return GlassContainer(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      datos?.nombre ?? style.nombre,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  if (datos?.spriteUrl != null)
                    Image.network(
                      datos!.spriteUrl!,
                      width: 40,
                      height: 40,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Índice de captura',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: atenuado,
                      ),
                    ),
                  ),
                  Text(
                    style.capturaTexto,
                    style: TextStyle(fontWeight: FontWeight.w800, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: style.captura >= 255
                      ? 1
                      : (style.captura / 4).clamp(0.0, 1.0),
                ),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => Container(
                  height: 8,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: scheme.onSurface.withValues(alpha: 0.08),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: t,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.6), color],
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: atenuado,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (datos?.descripcion != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: color.withValues(alpha: 0.15),
                      ),
                      child: Text(
                        'PokeAPI',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: cargando ? 0.5 : 1,
                child: Text(
                  datos?.descripcion ?? style.descripcion,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      style.dato,
                      style: TextStyle(fontSize: 13.5, color: atenuado),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
