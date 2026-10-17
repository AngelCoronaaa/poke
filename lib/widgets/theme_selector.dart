import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import 'glass.dart';

const _opciones = [
  (ThemeMode.system, Icons.brightness_auto_rounded, 'Sistema'),
  (ThemeMode.light, Icons.light_mode_rounded, 'Claro'),
  (ThemeMode.dark, Icons.dark_mode_rounded, 'Oscuro'),
];

IconData iconoTema(ThemeMode modo) =>
    _opciones.firstWhere((o) => o.$1 == modo).$2;

/// Botón circular que muestra el aspecto actual y abre el selector.
class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final modo = AppScope.of(context).controller.themeMode;
    return GlassButton(
      circular: true,
      tooltip: 'Aspecto',
      onPressed: () => mostrarSelectorTema(context),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween(begin: 0.5, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(iconoTema(modo), key: ValueKey(modo)),
      ),
    );
  }
}

/// Hoja inferior de vidrio para elegir el aspecto de la app.
Future<void> mostrarSelectorTema(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    elevation: 0,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassContainer(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aspecto',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              const ThemeSegmentedControl(),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Control segmentado con un indicador que se desliza entre opciones.
class ThemeSegmentedControl extends StatelessWidget {
  const ThemeSegmentedControl({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final controller = AppScope.of(context).controller;
    final modo = controller.themeMode;
    final indice = _opciones.indexWhere((o) => o.$1 == modo);

    return Container(
      height: 76,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: scheme.onSurface.withValues(alpha: esOscuro ? 0.08 : 0.05),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(-1 + indice * 1.0, 0),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            child: FractionallySizedBox(
              widthFactor: 1 / _opciones.length,
              heightFactor: 1,
              child: GlassContainer(
                radius: 18,
                blur: 8,
                tint: Colors.white.withValues(alpha: esOscuro ? 0.14 : 0.9),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Row(
            children: [
              for (final (valor, icono, etiqueta) in _opciones)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.setThemeMode(valor),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: valor == modo ? 1 : 0.55,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icono, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            etiqueta,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
