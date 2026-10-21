import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../models/pokemon.dart';
import '../models/region.dart';
import '../services/pokemon_service.dart';
import '../widgets/aparecer.dart';
import '../widgets/glass.dart';
import '../widgets/pokeball.dart';
import 'pokemon_screen.dart';

/// Lista de la Pokédex con buscador y filtros por región y tipo.
/// Al tocar un Pokémon se abre su ficha ([PokemonScreen]).
class PokedexListScreen extends StatefulWidget {
  const PokedexListScreen({super.key, this.region});

  /// Región seleccionada al abrir (por ejemplo, desde la pantalla de inicio).
  final Region? region;

  @override
  State<PokedexListScreen> createState() => _PokedexListScreenState();
}

class _PokedexListScreenState extends State<PokedexListScreen> {
  late final PokemonService _service = AppScope.read(context).service;
  late Future<List<PokemonResumen>> _lista = _service.getLista();
  Map<int, List<PokemonType>> _tipos = {};

  final _busqueda = TextEditingController();
  late Region? _region = widget.region;
  PokemonType? _tipo;

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(() => setState(() {}));
    _cargarTipos();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  /// Los tipos son opcionales: si fallan, la lista funciona sin ellos.
  Future<void> _cargarTipos() async {
    try {
      final tipos = await _service.getTipos();
      if (mounted) setState(() => _tipos = tipos);
    } on PokemonException {
      // Sin tipos: no se muestran los chips ni el filtro.
    }
  }

  List<PokemonResumen> _filtrar(List<PokemonResumen> todos) {
    final texto = _busqueda.text.trim().toLowerCase().replaceAll('#', '');
    final numero = int.tryParse(texto);
    final region = _region;
    final tipo = _tipo;

    return todos.where((p) {
      if (region != null && (p.id < region.primero || p.id > region.ultimo)) {
        return false;
      }
      if (tipo != null && !(_tipos[p.id]?.contains(tipo) ?? false)) {
        return false;
      }
      if (texto.isEmpty) return true;
      if (numero != null) return p.id.toString().startsWith(texto);
      return p.name.replaceAll('-', ' ').contains(texto);
    }).toList();
  }

  void _abrir(PokemonResumen p) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(rutaSuave(PokemonScreen(initialId: p.id)));
  }

  @override
  Widget build(BuildContext context) {
    final accent = _tipo?.color ?? _region?.color ?? const Color(0xFFE3350D);

    return LiquidBackground(
      accent: accent,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: FutureBuilder<List<PokemonResumen>>(
                future: _lista,
                builder: (context, snapshot) {
                  final todos = snapshot.data;
                  final visibles = todos == null ? null : _filtrar(todos);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Encabezado(total: visibles?.length, region: _region),
                      _Buscador(controller: _busqueda),
                      const SizedBox(height: 12),
                      _Filtros<Region>(
                        opciones: Region.todas,
                        seleccion: _region,
                        etiqueta: (r) => r.nombre,
                        color: (r) => r.color,
                        todas: 'Todas las regiones',
                        onCambio: (r) => setState(() => _region = r),
                      ),
                      if (_tipos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _Filtros<PokemonType>(
                          opciones: PokemonType.todos,
                          seleccion: _tipo,
                          etiqueta: (t) => t.label,
                          color: (t) => t.color,
                          todas: 'Todos los tipos',
                          onCambio: (t) => setState(() => _tipo = t),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Expanded(child: _cuerpo(snapshot, visibles)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(
    AsyncSnapshot<List<PokemonResumen>> snapshot,
    List<PokemonResumen>? visibles,
  ) {
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 40),
                const SizedBox(height: 12),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                GlassButton(
                  tint: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.9),
                  onPressed: () => setState(() => _lista = _service.getLista()),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (visibles == null) {
      return const Center(
        child: PokeballLoader(size: 56, label: 'Cargando Pokédex…'),
      );
    }
    if (visibles.isEmpty) {
      return Center(
        child: Text(
          'Ningún Pokémon coincide con la búsqueda',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: visibles.length,
      itemExtent: 92,
      itemBuilder: (context, i) {
        final p = visibles[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FilaPokemon(
            pokemon: p,
            tipos: _tipos[p.id] ?? const [],
            // Solo las primeras filas aparecen escalonadas.
            orden: i < 8 ? i : null,
            onTap: () => _abrir(p),
          ),
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.total, required this.region});

  final int? total;
  final Region? region;

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GlassButton(
            circular: true,
            tooltip: 'Regresar',
            onPressed: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pokédex',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    total == null
                        ? 'Cargando…'
                        : '$total Pokémon${region == null ? '' : ' · ${region!.nombre}'}',
                    key: ValueKey('$total${region?.nombre}'),
                    style: TextStyle(color: atenuado, fontSize: 13.5),
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

class _Buscador extends StatelessWidget {
  const _Buscador({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        radius: 20,
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o número',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    onPressed: controller.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Fila horizontal de chips para filtrar; tocar el seleccionado lo quita.
class _Filtros<T> extends StatelessWidget {
  const _Filtros({
    required this.opciones,
    required this.seleccion,
    required this.etiqueta,
    required this.color,
    required this.todas,
    required this.onCambio,
  });

  final List<T> opciones;
  final T? seleccion;
  final String Function(T) etiqueta;
  final Color Function(T) color;
  final String todas;
  final ValueChanged<T?> onCambio;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    Widget chip(String texto, Color? fondo, bool activo, VoidCallback onTap) {
      return Presionable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: activo
                ? (fondo ?? onSurface).withValues(alpha: 0.9)
                : onSurface.withValues(alpha: 0.06),
            border: Border.all(
              color: activo
                  ? (fondo ?? onSurface)
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: activo
                  ? colorSobre(fondo ?? onSurface)
                  : onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(todas, null, seleccion == null, () => onCambio(null)),
          for (final o in opciones) ...[
            const SizedBox(width: 8),
            chip(
              etiqueta(o),
              color(o),
              o == seleccion,
              () => onCambio(o == seleccion ? null : o),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaPokemon extends StatelessWidget {
  const _FilaPokemon({
    required this.pokemon,
    required this.tipos,
    required this.orden,
    required this.onTap,
  });

  final PokemonResumen pokemon;
  final List<PokemonType> tipos;
  final int? orden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tipos.isEmpty ? PokemonType.fallbackColor : tipos.first.color;

    final fila = Presionable(
      onTap: onTap,
      semanticLabel: pokemon.displayName,
      child: GlassContainer(
        radius: 24,
        blur: 0, // Sin desenfoque: hay muchas filas en pantalla.
        shadow: false,
        tint: color.withValues(alpha: 0.13),
        padding: const EdgeInsets.fromLTRB(10, 6, 16, 6),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.35),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Image.network(
                pokemon.imageUrl,
                fit: BoxFit.contain,
                cacheWidth: 200,
                frameBuilder: (context, child, frame, sincrono) =>
                    AnimatedOpacity(
                      opacity: sincrono || frame != null ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: child,
                    ),
                errorBuilder: (_, _, _) => Icon(
                  Icons.catching_pokemon,
                  color: color.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pokemon.number,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    pokemon.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (tipos.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (final t in tipos) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: t.color.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colorSobre(t.color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );

    final o = orden;
    return o == null ? fila : Aparecer(orden: o, child: fila);
  }
}
