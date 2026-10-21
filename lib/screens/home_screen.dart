import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/pokeball_style.dart';
import '../models/pokemon.dart';
import '../models/region.dart';
import '../models/resumen.dart';
import '../models/trainer.dart';
import '../services/pokemon_service.dart';
import '../widgets/aparecer.dart';
import '../widgets/glass.dart';
import '../widgets/pokeball.dart';
import '../widgets/pokeball_3d.dart';
import '../widgets/theme_selector.dart';
import 'pokedex_list_screen.dart';
import 'pokeballs_screen.dart';
import 'pokemon_screen.dart';

/// Pantalla de inicio: licencia del entrenador y datos generales.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PokemonService _service = AppScope.read(context).service;
  late Future<ResumenPokedex> _resumen = _service.getResumen();
  late Future<Pokemon> _delDia = _service.getPokemon('$_idDelDia');

  /// Cambia cada día, igual para todos los entrenadores.
  static int get _idDelDia {
    final dias = DateTime.now().difference(DateTime(2024)).inDays;
    return (dias * 37) % PokemonService.total + 1;
  }

  /// Se conserva para que la pantalla no quede en blanco al cerrar sesión
  /// mientras se desvanece.
  Trainer? _ultimo;

  void _abrirPokedex(int id) =>
      Navigator.of(context).push(rutaSuave(PokemonScreen(initialId: id)));

  void _abrirLista([Region? region]) =>
      Navigator.of(context).push(rutaSuave(PokedexListScreen(region: region)));

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (context) => const _DialogoCerrarSesion(),
    );
    if (confirmar == true && mounted) {
      await AppScope.read(context).controller.cerrarSesion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainer = AppScope.of(context).controller.trainer ?? _ultimo;
    if (trainer == null) return const SizedBox.shrink();
    _ultimo = trainer;

    return LiquidBackground(
      accent: trainer.companero.color,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  Aparecer(
                    orden: 0,
                    child: _Encabezado(
                      trainer: trainer,
                      onCerrarSesion: _cerrarSesion,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Aparecer(orden: 1, child: _Licencia(trainer: trainer)),
                  const _Titulo(
                    'Datos generales',
                    subtitulo: 'En vivo desde la PokeAPI',
                  ),
                  Aparecer(
                    orden: 2,
                    child: _DatosGenerales(
                      futuro: _resumen,
                      onReintentar: () =>
                          setState(() => _resumen = _service.getResumen()),
                    ),
                  ),
                  const _Titulo('Explorar'),
                  Aparecer(
                    orden: 3,
                    child: Row(
                      children: [
                        Expanded(
                          child: _TarjetaExplorar(
                            titulo: 'Pokédex',
                            subtitulo: 'Lista de los 1025 Pokémon con fichas y modelos 3D',
                            color: const Color(0xFFE3350D),
                            onTap: _abrirLista,
                            vista: Image.network(
                              Pokemon.artworkUrl(trainer.companero.id),
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.catching_pokemon, size: 48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _TarjetaExplorar(
                            titulo: 'Pokéballs 3D',
                            subtitulo:
                                '${PokeballStyle.todas.length} tipos con rotación',
                            color: const Color(0xFF7A3FC0),
                            onTap: () =>
                                Navigator.of(context)
                                    .push(rutaSuave(const PokeballsScreen())),
                            vista: const Pokeball3D(
                              style: PokeballStyle.pokeBall,
                              size: 78,
                              interactive: false,
                              sombra: false,
                              speed: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _Titulo('Pokémon del día'),
                  Aparecer(
                    orden: 4,
                    child: _PokemonDelDia(
                      futuro: _delDia,
                      onTap: _abrirPokedex,
                      onReintentar: () => setState(
                        () => _delDia = _service.getPokemon('$_idDelDia'),
                      ),
                    ),
                  ),
                  const _Titulo(
                    'Regiones',
                    subtitulo: 'Explora los Pokémon de cada generación',
                  ),
                  Aparecer(
                    orden: 5,
                    child: SizedBox(
                      height: 148,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: Region.todas.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final region = Region.todas[i];
                          return _TarjetaRegion(
                            region: region,
                            onTap: () => _abrirLista(region),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.trainer, required this.onCerrarSesion});

  final Trainer trainer;
  final VoidCallback onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.55);
    final color = trainer.companero.color;

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
          ),
          child: Image.network(
            trainer.companero.imagenUrl,
            errorBuilder: (_, _, _) => Icon(Icons.person, color: color),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, ${trainer.nombre}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              Text(
                'Entrenador de ${trainer.region.nombre}',
                style: TextStyle(color: atenuado, fontSize: 14),
              ),
            ],
          ),
        ),
        const ThemeButton(),
        const SizedBox(width: 8),
        GlassButton(
          circular: true,
          tooltip: 'Cerrar sesión',
          onPressed: onCerrarSesion,
          child: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

/// Licencia de entrenador con el compañero flotando.
class _Licencia extends StatelessWidget {
  const _Licencia({required this.trainer});

  final Trainer trainer;

  @override
  Widget build(BuildContext context) {
    final color = trainer.companero.color;
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.55);
    final desde = trainer.desde;
    final fecha =
        '${desde.day.toString().padLeft(2, '0')}/${desde.month.toString().padLeft(2, '0')}/${desde.year}';

    return GlassContainer(
      tint: color.withValues(alpha: 0.16),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -50,
            child: RotatingPokeball(
              size: 200,
              color: color.withValues(alpha: 0.18),
              duration: const Duration(seconds: 30),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LICENCIA DE ENTRENADOR',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trainer.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 18,
                        runSpacing: 10,
                        children: [
                          _Campo('ID No.', trainer.trainerId, atenuado),
                          _Campo('Región', trainer.region.nombre, atenuado),
                          _Campo('Desde', fecha, atenuado),
                          _Campo(
                            'Compañero',
                            trainer.companero.nombre,
                            atenuado,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Flotando(
                  child: SizedBox.square(
                    dimension: 110,
                    child: Image.network(
                      trainer.companero.imagenUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.catching_pokemon, size: 56, color: color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo(this.etiqueta, this.valor, this.atenuado);

  final String etiqueta;
  final String valor;
  final Color atenuado;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: TextStyle(fontSize: 11.5, color: atenuado)),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Flotando extends StatefulWidget {
  const _Flotando({required this.child});

  final Widget child;

  @override
  State<_Flotando> createState() => _FlotandoState();
}

class _FlotandoState extends State<_Flotando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -8 * Curves.easeInOut.transform(_controller.value)),
        child: child,
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.titulo, {this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          if (subtitulo != null)
            Text(
              subtitulo!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _DatosGenerales extends StatelessWidget {
  const _DatosGenerales({required this.futuro, required this.onReintentar});

  final Future<ResumenPokedex> futuro;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResumenPokedex>(
      future: futuro,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorCompacto(
            mensaje: '${snapshot.error}',
            onReintentar: onReintentar,
          );
        }
        final r = snapshot.data;
        final datos = [
          (Icons.catching_pokemon, 'Pokémon', r?.pokemon, 'electric'),
          (Icons.flash_on_rounded, 'Movimientos', r?.movimientos, 'fire'),
          (
            Icons.auto_fix_high_rounded,
            'Habilidades',
            r?.habilidades,
            'psychic',
          ),
          (Icons.backpack_rounded, 'Objetos', r?.objetos, 'grass'),
          (Icons.layers_rounded, 'Generaciones', r?.generaciones, 'water'),
          (Icons.public_rounded, 'Regiones', r?.regiones, 'dragon'),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth > 480 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columnas,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              padding: EdgeInsets.zero,
              children: [
                for (final (icono, etiqueta, valor, tipo) in datos)
                  _TarjetaDato(
                    icono: icono,
                    etiqueta: etiqueta,
                    valor: valor,
                    color: PokemonType.fromName(tipo).color,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TarjetaDato extends StatelessWidget {
  const _TarjetaDato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final IconData icono;
  final String etiqueta;
  final int? valor;
  final Color color;

  static String _formato(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.55);

    return GlassContainer(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, size: 20, color: color),
          ),
          const Spacer(),
          valor == null
              ? const _Pulso()
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: valor!.toDouble()),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formato(v.round()),
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
          Text(etiqueta, style: TextStyle(fontSize: 13, color: atenuado)),
        ],
      ),
    );
  }
}

/// Marcador de carga que late suavemente.
class _Pulso extends StatefulWidget {
  const _Pulso();

  @override
  State<_Pulso> createState() => _PulsoState();
}

class _PulsoState extends State<_Pulso> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 70,
        height: 24,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _TarjetaExplorar extends StatelessWidget {
  const _TarjetaExplorar({
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.vista,
    required this.onTap,
  });

  final String titulo;
  final String subtitulo;
  final Color color;
  final Widget vista;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.55);

    return Presionable(
      onTap: onTap,
      semanticLabel: titulo,
      child: GlassContainer(
        tint: color.withValues(alpha: 0.14),
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 176,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: vista),
              ),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: atenuado),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Abrir',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokemonDelDia extends StatelessWidget {
  const _PokemonDelDia({
    required this.futuro,
    required this.onTap,
    required this.onReintentar,
  });

  final Future<Pokemon> futuro;
  final ValueChanged<int> onTap;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pokemon>(
      future: futuro,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorCompacto(
            mensaje: '${snapshot.error}',
            onReintentar: onReintentar,
          );
        }
        final p = snapshot.data;
        if (p == null) {
          return const GlassContainer(
            child: SizedBox(
              height: 150,
              child: Center(child: PokeballLoader(size: 36)),
            ),
          );
        }

        final atenuado = Theme.of(context).colorScheme.onSurface
            .withValues(alpha: 0.5);

        return Presionable(
          onTap: () => onTap(p.id),
          semanticLabel: 'Ver ${p.displayName}',
          child: GlassContainer(
            tint: p.color.withValues(alpha: 0.16),
            padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        p.color.withValues(alpha: 0.45),
                        p.color.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: _Flotando(
                    child: Image.network(
                      p.imageUrl ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.catching_pokemon,
                        size: 56,
                        color: p.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.number,
                        style: TextStyle(
                          color: atenuado,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        p.displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in p.types)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: t.color.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                t.label,
                                style: TextStyle(
                                  color: colorSobre(t.color),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Ver en la Pokédex',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: p.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: p.color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TarjetaRegion extends StatelessWidget {
  const _TarjetaRegion({required this.region, required this.onTap});

  final Region region;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.55);

    return Presionable(
      onTap: onTap,
      semanticLabel: 'Región ${region.nombre}',
      child: GlassContainer(
        radius: 24,
        tint: region.color.withValues(alpha: 0.14),
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 128,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GEN ${region.generacion}',
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: region.color,
                ),
              ),
              const Spacer(),
              Text(
                region.nombre,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${region.total} Pokémon',
                style: TextStyle(fontSize: 12.5, color: atenuado),
              ),
              Text(
                region.rango,
                style: TextStyle(
                  fontSize: 11.5,
                  color: atenuado,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCompacto extends StatelessWidget {
  const _ErrorCompacto({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _DialogoCerrarSesion extends StatelessWidget {
  const _DialogoCerrarSesion();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: GlassContainer(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Cerrar sesión?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Podrás volver a entrar con tu nombre y contraseña.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                overflowSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  GlassButton(
                    tint: scheme.error.withValues(alpha: 0.9),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Cerrar sesión'),
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
