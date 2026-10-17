import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../models/pokeball_style.dart';
import '../models/region.dart';
import '../models/trainer.dart';
import '../widgets/aparecer.dart';
import '../widgets/glass.dart';
import '../widgets/pokeball_3d.dart';
import '../widgets/theme_selector.dart';

/// Inicio de sesión del entrenador: nombre, compañero y región de origen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  Companero _companero = Companero.todos.first;
  Region _region = Region.todas.first;
  bool _entrando = false;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  String? _validarNombre(String? valor) {
    final nombre = valor?.trim() ?? '';
    if (nombre.length < 3) return 'Escribe al menos 3 caracteres';
    if (!RegExp(r"^[\p{L}\p{N} .'-]+$", unicode: true).hasMatch(nombre)) {
      return 'Usa solo letras, números y espacios';
    }
    return null;
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _entrando = true);
    // La pokébola acelera su giro antes de entrar.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await AppScope.read(context).controller.iniciarSesion(
      nombre: _nombre.text,
      companero: _companero,
      region: _region,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final atenuado = scheme.onSurface.withValues(alpha: 0.55);

    return LiquidBackground(
      accent: _companero.color,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Aparecer(
                            orden: 0,
                            child: Center(
                              child: Pokeball3D(
                                style: PokeballStyle.pokeBall,
                                size: 150,
                                speed: _entrando ? 14 : 0.8,
                                arrastreLibre: false,
                                giroInicial: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Aparecer(
                            orden: 1,
                            child: Column(
                              children: [
                                const Text(
                                  'Pokédex',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Inicia sesión como entrenador Pokémon',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: atenuado,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          Aparecer(orden: 2, child: _formulario(atenuado)),
                          const SizedBox(height: 16),
                          Aparecer(
                            orden: 3,
                            child: Text(
                              'Tus datos se guardan solo en este dispositivo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: atenuado, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(top: 12, right: 16, child: ThemeButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formulario(Color atenuado) {
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Etiqueta('Nombre de entrenador'),
          TextFormField(
            controller: _nombre,
            maxLength: 12,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _entrar(),
            validator: _validarNombre,
            decoration: const InputDecoration(
              hintText: 'Ej. Ash',
              counterText: '',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 22),
          const _Etiqueta('Elige a tu compañero'),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: Companero.todos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final c = Companero.todos[i];
                return _OpcionCompanero(
                  companero: c,
                  seleccionado: c == _companero,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _companero = c);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const _Etiqueta('Región de origen'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in Region.todas)
                _ChipRegion(
                  region: r,
                  seleccionada: r == _region,
                  onTap: () => setState(() => _region = r),
                ),
            ],
          ),
          const SizedBox(height: 26),
          GlassButton(
            tint: _companero.color.withValues(alpha: 0.9),
            onPressed: _entrando ? null : _entrar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.catching_pokemon),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _entrando ? 'Abriendo Pokédex…' : 'Comenzar aventura',
                    key: ValueKey(_entrando),
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

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OpcionCompanero extends StatelessWidget {
  const _OpcionCompanero({
    required this.companero,
    required this.seleccionado,
    required this.onTap,
  });

  final Companero companero;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = companero.color;
    const duracion = Duration(milliseconds: 300);

    return Presionable(
      onTap: onTap,
      semanticLabel: companero.nombre,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            AnimatedScale(
              scale: seleccionado ? 1.0 : 0.86,
              duration: duracion,
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: duracion,
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: seleccionado ? 0.28 : 0.1),
                  border: Border.all(
                    color: seleccionado
                        ? color
                        : Colors.white.withValues(alpha: 0.35),
                    width: seleccionado ? 2.5 : 1,
                  ),
                  boxShadow: seleccionado
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.45),
                            blurRadius: 18,
                          ),
                        ]
                      : null,
                ),
                child: Image.network(
                  companero.imagenUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.catching_pokemon, color: color),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: duracion,
              style: DefaultTextStyle.of(context).style.merge(
                TextStyle(
                  fontSize: 12.5,
                  fontWeight: seleccionado ? FontWeight.w800 : FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: seleccionado ? 1 : 0.6),
                ),
              ),
              child: Text(
                companero.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRegion extends StatelessWidget {
  const _ChipRegion({
    required this.region,
    required this.seleccionada,
    required this.onTap,
  });

  final Region region;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Presionable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: seleccionada
              ? region.color.withValues(alpha: 0.9)
              : onSurface.withValues(alpha: 0.06),
          border: Border.all(
            color: seleccionada
                ? region.color
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          region.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: seleccionada ? Colors.white : onSurface,
          ),
        ),
      ),
    );
  }
}
