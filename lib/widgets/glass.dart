import 'dart:ui';

import 'package:flutter/material.dart';

/// Fondo con manchas de color difuminadas que se tiñen con el color
/// del Pokémon actual y cambian suavemente entre uno y otro.
class LiquidBackground extends StatelessWidget {
  const LiquidBackground({
    super.key,
    required this.accent,
    required this.child,
  });

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: accent),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, color, child) {
        final base = color ?? accent;
        final hsl = HSLColor.fromColor(base);
        final secundario = hsl
            .withHue((hsl.hue + 40) % 360)
            .withLightness(esOscuro ? 0.35 : 0.75)
            .toColor();
        final terciario = hsl
            .withHue((hsl.hue + 320) % 360)
            .withLightness(esOscuro ? 0.3 : 0.8)
            .toColor();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          color: esOscuro ? const Color(0xFF0A0B10) : const Color(0xFFF3F4F8),
          child: Stack(
            children: [
              _Mancha(const Alignment(-1.3, -1.0), 460, base, esOscuro),
              _Mancha(const Alignment(1.4, -0.1), 380, secundario, esOscuro),
              _Mancha(const Alignment(-0.4, 1.3), 420, terciario, esOscuro),
              Positioned.fill(child: child!),
            ],
          ),
        );
      },
      child: child,
    );
  }
}

class _Mancha extends StatelessWidget {
  const _Mancha(this.alignment, this.size, this.color, this.esOscuro);

  final Alignment alignment;
  final double size;
  final Color color;
  final bool esOscuro;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: esOscuro ? 0.5 : 0.6),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Texto legible sobre un color: oscuro sobre colores claros y blanco
/// sobre colores oscuros.
Color colorSobre(Color fondo) =>
    fondo.computeLuminance() > 0.5 ? const Color(0xFF1B1C22) : Colors.white;

/// Superficie de vidrio: desenfoque del fondo, relleno translúcido,
/// borde luminoso y un brillo en la parte superior.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.blur = 22,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final double blur;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);
    final relleno =
        tint ?? Colors.white.withValues(alpha: esOscuro ? 0.07 : 0.42);

    // El relleno va en su propia capa: BoxDecoration ignora `color`
    // cuando también recibe `gradient`.
    final superficie = DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, color: relleno),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: esOscuro ? 0.13 : 0.8),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, 0.45, 1],
            colors: [
              Colors.white.withValues(alpha: esOscuro ? 0.12 : 0.45),
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: esOscuro ? 0.04 : 0.12),
            ],
          ),
        ),
        child: child,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: esOscuro ? 0.35 : 0.07),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        // Con blur 0 se omite el desenfoque (más ligero en listas largas).
        child: blur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: superficie,
              )
            : superficie,
      ),
    );
  }
}

/// Sombra elíptica suave para "apoyar" objetos en el piso.
class SombraPiso extends StatelessWidget {
  const SombraPiso({
    super.key,
    required this.ancho,
    required this.alto,
    this.opacidad = 0.3,
  });

  final double ancho;
  final double alto;
  final double opacidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.elliptical(ancho / 2, alto / 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: opacidad),
            blurRadius: alto * 1.4,
            spreadRadius: -alto * 0.1,
          ),
        ],
      ),
    );
  }
}

/// Botón de vidrio que se "hunde" ligeramente al presionarlo.
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.circular = false,
    this.tint,
    this.tooltip,
    this.padding,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool circular;
  final Color? tint;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _presionado = false;

  void _presionar(bool valor) {
    if (widget.onPressed == null) return;
    setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radio = widget.circular ? 24.0 : 26.0;
    final colorContenido = widget.tint != null
        ? colorSobre(widget.tint!)
        : scheme.onSurface;

    Widget boton = AnimatedScale(
      scale: _presionado ? 0.92 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: GlassContainer(
        radius: radio,
        tint: widget.tint,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: (_) => _presionar(true),
            onTapUp: (_) => _presionar(false),
            onTapCancel: () => _presionar(false),
            borderRadius: BorderRadius.circular(radio),
            child: Padding(
              padding:
                  widget.padding ??
                  (widget.circular
                      ? const EdgeInsets.all(12)
                      : const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        )),
              child: IconTheme.merge(
                data: IconThemeData(size: 22, color: colorContenido),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colorContenido,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      boton = Tooltip(message: widget.tooltip, child: boton);
    }
    return boton;
  }
}

/// Hace "presionable" cualquier tarjeta: se encoge un poco al tocarla.
class Presionable extends StatefulWidget {
  const Presionable({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _presionado = true),
          onTapUp: (_) => setState(() => _presionado = false),
          onTapCancel: () => setState(() => _presionado = false),
          child: AnimatedScale(
            scale: _presionado ? 0.97 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
