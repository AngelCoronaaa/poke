import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/aparecer.dart';
import '../widgets/glass.dart';
import '../widgets/pokeball.dart';
import '../widgets/pokemon_figure.dart';
import '../widgets/pokemon_model_view.dart';
import '../widgets/stat_bar.dart';
import 'model_3d_screen.dart';

/// Pokédex: ficha de un Pokémon obtenido de la PokeAPI.
class PokemonScreen extends StatefulWidget {
  const PokemonScreen({super.key, this.initialId = 1});

  final int initialId;

  @override
  State<PokemonScreen> createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  late final AppScope _scope = AppScope.read(context);
  late final PokemonService _service = _scope.service;
  final _random = math.Random();

  Pokemon? _pokemon;
  String? _error;
  bool _cargando = true;
  bool _shiny = false;
  bool _girando = true;
  bool _vista3D = true;
  final Map<int, bool> _tieneModelo = {};
  late int _idActual = widget.initialId;
  int _solicitud = 0;

  bool get _puede3D => _scope.modelos3D && visor3DDisponible;

  @override
  void initState() {
    super.initState();
    _cargar('${widget.initialId}');
  }

  Future<void> _cargar(String consulta) async {
    final solicitud = ++_solicitud;
    if (!_cargando || _error != null) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final pokemon = await _service.getPokemon(consulta);
      // Ignora respuestas viejas si el usuario ya pidió otro Pokémon.
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _pokemon = pokemon;
        _idActual = pokemon.id;
        _cargando = false;
      });
      if (_puede3D) _comprobarModelo(pokemon.id);
    } on PokemonException catch (e) {
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _cargando = false;
        _error = e.message;
      });
      if (_pokemon != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _comprobarModelo(int id) async {
    if (_tieneModelo.containsKey(id)) return;
    final existe = await _service.tieneModelo3D(id);
    if (mounted) setState(() => _tieneModelo[id] = existe);
  }

  void _moverA(int id) {
    HapticFeedback.selectionClick();
    final total = PokemonService.total;
    final ajustado = ((id - 1) % total + total) % total + 1;
    _cargar('$ajustado');
  }

  void _anterior() => _moverA(_idActual - 1);
  void _siguiente() => _moverA(_idActual + 1);
  void _aleatorio() => _moverA(_random.nextInt(PokemonService.total) + 1);

  Future<void> _buscar() async {
    final consulta = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => const _DialogoBusqueda(),
    );
    if (consulta != null && consulta.trim().isNotEmpty) _cargar(consulta);
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = _pokemon;
    final accent = pokemon?.color ?? Theme.of(context).colorScheme.primary;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _anterior,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _siguiente,
      },
      child: Focus(
        autofocus: true,
        child: LiquidBackground(
          accent: accent,
          child: Scaffold(
            body: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _BarraSuperior(
                            cargando: _cargando && pokemon != null,
                            onAleatorio: _aleatorio,
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                    opacity: anim,
                                    child: ScaleTransition(
                                      scale: Tween(
                                        begin: 0.96,
                                        end: 1.0,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                              child: _cuerpo(pokemon),
                            ),
                          ),
                        ],
                      ),
                      if (pokemon != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: SafeArea(
                            top: false,
                            child: _BarraNavegacion(
                              onAnterior: _anterior,
                              onSiguiente: _siguiente,
                              onBuscar: _buscar,
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

  Widget _cuerpo(Pokemon? pokemon) {
    if (pokemon != null) {
      final modelo = _puede3D && (_tieneModelo[pokemon.id] ?? false);
      return GestureDetector(
        key: ValueKey(pokemon.id),
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v > 300) _anterior();
          if (v < -300) _siguiente();
        },
        child: _DetallePokemon(
          pokemon: pokemon,
          shiny: _shiny,
          girando: _girando,
          hayModelo3D: modelo,
          vista3D: modelo && _vista3D,
          onShiny: () => setState(() => _shiny = !_shiny),
          onGiro: () => setState(() => _girando = !_girando),
          onVista3D: () => setState(() => _vista3D = !_vista3D),
          onPantallaCompleta: () =>
              Navigator.of(context)
                  .push(rutaSuave(Model3DScreen(pokemon: pokemon))),
        ),
      );
    }
    if (_error != null) {
      return _VistaError(
        key: const ValueKey('error'),
        mensaje: _error!,
        onReintentar: () => _cargar('$_idActual'),
      );
    }
    return const Center(
      key: ValueKey('cargando'),
      child: PokeballLoader(size: 64, label: 'Cargando Pokédex…'),
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({required this.cargando, required this.onAleatorio});

  final bool cargando;
  final VoidCallback onAleatorio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GlassButton(
            circular: true,
            tooltip: 'Regresar',
            onPressed: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Pokédex',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: cargando
                      ? const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: PokeballLoader(size: 18),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          GlassButton(
            circular: true,
            tooltip: 'Pokémon aleatorio',
            onPressed: onAleatorio,
            child: const Icon(Icons.shuffle_rounded),
          ),
        ],
      ),
    );
  }
}

class _DetallePokemon extends StatelessWidget {
  const _DetallePokemon({
    required this.pokemon,
    required this.shiny,
    required this.girando,
    required this.hayModelo3D,
    required this.vista3D,
    required this.onShiny,
    required this.onGiro,
    required this.onVista3D,
    required this.onPantallaCompleta,
  });

  final Pokemon pokemon;
  final bool shiny;
  final bool girando;
  final bool hayModelo3D;
  final bool vista3D;
  final VoidCallback onShiny;
  final VoidCallback onGiro;
  final VoidCallback onVista3D;
  final VoidCallback onPantallaCompleta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = pokemon.color;
    final imagen = shiny
        ? (pokemon.shinyImageUrl ?? pokemon.imageUrl)
        : pokemon.imageUrl;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        // Nombre, número y tipos
        Aparecer(
          orden: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pokemon.number,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                pokemon.displayName,
                style: const TextStyle(
                  fontSize: 38,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tipo in pokemon.types) _ChipTipo(tipo: tipo),
                ],
              ),
            ],
          ),
        ),

        // Pokémon en 3D
        Aparecer(
          orden: 1,
          child: SizedBox(
            height: 340,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  child: Text(
                    pokemon.id.toString().padLeft(3, '0'),
                    style: TextStyle(
                      fontSize: 140,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -6,
                      color: scheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                RotatingPokeball(
                  size: 290,
                  color: color.withValues(alpha: 0.16),
                ),
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.4),
                        color.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: vista3D
                      ? SizedBox(
                          key: const ValueKey('3d'),
                          width: 300,
                          height: 320,
                          child: PokemonModelView(
                            src: PokemonService.modelo3DUrl(pokemon.id),
                            nombre: pokemon.displayName,
                            poster: pokemon.imageUrl,
                          ),
                        )
                      : PokemonFigure(
                          key: const ValueKey('figura'),
                          imageUrl: imagen,
                          color: color,
                          size: 250,
                          spinning: girando,
                        ),
                ),
                Positioned(
                  right: 0,
                  top: 60,
                  child: Column(
                    children: [
                      if (hayModelo3D) ...[
                        GlassButton(
                          circular: true,
                          tooltip: vista3D
                              ? 'Ver ilustración'
                              : 'Ver modelo 3D',
                          tint: vista3D ? color.withValues(alpha: 0.85) : null,
                          onPressed: onVista3D,
                          child: const Icon(Icons.view_in_ar_rounded),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (vista3D)
                        GlassButton(
                          circular: true,
                          tooltip: 'Pantalla completa',
                          onPressed: onPantallaCompleta,
                          child: const Icon(Icons.open_in_full_rounded),
                        )
                      else ...[
                        GlassButton(
                          circular: true,
                          tooltip: girando ? 'Detener giro' : 'Girar',
                          onPressed: onGiro,
                          child: Icon(
                            girando
                                ? Icons.pause_rounded
                                : Icons.threesixty_rounded,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassButton(
                          circular: true,
                          tooltip: shiny ? 'Versión normal' : 'Versión shiny',
                          tint: shiny ? color.withValues(alpha: 0.85) : null,
                          onPressed: onShiny,
                          child: const Icon(Icons.auto_awesome_rounded),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Datos físicos
        Aparecer(
          orden: 2,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _Dato(
                    icono: Icons.straighten_rounded,
                    valor: '${pokemon.heightMeters.toStringAsFixed(1)} m',
                    etiqueta: 'Altura',
                  ),
                  const _Separador(),
                  _Dato(
                    icono: Icons.fitness_center_rounded,
                    valor: '${pokemon.weightKg.toStringAsFixed(1)} kg',
                    etiqueta: 'Peso',
                  ),
                  const _Separador(),
                  _Dato(
                    icono: Icons.bolt_rounded,
                    valor: '${pokemon.baseExperience ?? '—'}',
                    etiqueta: 'Exp. base',
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Estadísticas
        Aparecer(
          orden: 3,
          child: GlassContainer(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TituloSeccion(
                  'Estadísticas base',
                  extra:
                      'Total ${pokemon.stats.fold<int>(0, (s, e) => s + e.value)}',
                ),
                const SizedBox(height: 8),
                for (final (i, stat) in pokemon.stats.indexed)
                  StatBar(
                    stat: stat,
                    color: color,
                    delay: Duration(milliseconds: 250 + i * 70),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Habilidades
        Aparecer(
          orden: 4,
          child: GlassContainer(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TituloSeccion('Habilidades'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final h in pokemon.abilities)
                      _ChipHabilidad(habilidad: h, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipTipo extends StatelessWidget {
  const _ChipTipo({required this.tipo});

  final PokemonType tipo;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 20,
      blur: 10,
      tint: tipo.color.withValues(alpha: 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Text(
        tipo.label,
        style: TextStyle(
          color: colorSobre(tipo.color),
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ChipHabilidad extends StatelessWidget {
  const _ChipHabilidad({required this.habilidad, required this.color});

  final PokemonAbility habilidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            habilidad.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (habilidad.hidden) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.visibility_off_rounded,
              size: 15,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 3),
            Text(
              'Oculta',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.5);
    return Expanded(
      child: Column(
        children: [
          Icon(icono, size: 20, color: atenuado),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(etiqueta, style: TextStyle(fontSize: 12.5, color: atenuado)),
        ],
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) => VerticalDivider(
    width: 1,
    indent: 6,
    endIndent: 6,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
  );
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.titulo, {this.extra});

  final String titulo;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (extra != null)
          Text(
            extra!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}

class _BarraNavegacion extends StatelessWidget {
  const _BarraNavegacion({
    required this.onAnterior,
    required this.onSiguiente,
    required this.onBuscar,
  });

  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final VoidCallback onBuscar;

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.55);

    return GlassContainer(
      radius: 32,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _BotonRedondo(
            icono: Icons.chevron_left_rounded,
            tooltip: 'Anterior',
            onTap: onAnterior,
          ),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onBuscar,
                borderRadius: BorderRadius.circular(26),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_rounded, size: 20, color: atenuado),
                      const SizedBox(width: 8),
                      Text(
                        'Buscar Pokémon',
                        style: TextStyle(
                          color: atenuado,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _BotonRedondo(
            icono: Icons.chevron_right_rounded,
            tooltip: 'Siguiente',
            onTap: onSiguiente,
          ),
        ],
      ),
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: esOscuro ? 0.08 : 0.7),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icono, size: 26),
          ),
        ),
      ),
    );
  }
}

class _DialogoBusqueda extends StatefulWidget {
  const _DialogoBusqueda();

  @override
  State<_DialogoBusqueda> createState() => _DialogoBusquedaState();
}

class _DialogoBusquedaState extends State<_DialogoBusqueda> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Buscar Pokémon',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _enviar(),
                decoration: const InputDecoration(
                  hintText: 'Nombre o número (1–1025)',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 18),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                overflowSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  GlassButton(
                    tint: scheme.primary.withValues(alpha: 0.9),
                    onPressed: _enviar,
                    child: const Text('Buscar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VistaError extends StatelessWidget {
  const _VistaError({
    super.key,
    required this.mensaje,
    required this.onReintentar,
  });

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassContainer(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 44,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 14),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              GlassButton(
                tint: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.9),
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
