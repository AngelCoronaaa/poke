import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_controller.dart';
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
  late final _nombre = TextEditingController(text: _ultimo);
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  late final String? _ultimo = AppScope.read(context)
      .controller
      .ultimoEntrenador;
  // Si ya se entró antes en este dispositivo, abre en "Iniciar sesión".
  late bool _registro = _ultimo == null;
  Companero _companero = Companero.todos.first;
  Region _region = Region.todas.first;
  bool _verPassword = false;
  bool _entrando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  void _cambiarModo(bool registro) {
    if (registro == _registro) return;
    HapticFeedback.selectionClick();
    _formKey.currentState?.reset();
    _password.clear();
    _confirmar.clear();
    setState(() {
      _registro = registro;
      _error = null;
    });
  }

  String? _validarNombre(String? valor) {
    final nombre = valor?.trim() ?? '';
    if (nombre.length < 3) return 'Escribe al menos 3 caracteres';
    if (!RegExp(r"^[\p{L}\p{N} .'-]+$", unicode: true).hasMatch(nombre)) {
      return 'Usa solo letras, números y espacios';
    }
    return null;
  }

  String? _validarPassword(String? valor) {
    final password = valor ?? '';
    if (password.isEmpty) return 'Escribe tu contraseña';
    if (_registro && password.length < 6) {
      return 'Usa al menos 6 caracteres';
    }
    return null;
  }

  String? _validarConfirmacion(String? valor) =>
      valor != _password.text ? 'Las contraseñas no coinciden' : null;

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final controller = AppScope.read(context).controller;
    setState(() => _entrando = true);
    try {
      if (_registro) {
        await controller.registrar(
          nombre: _nombre.text,
          password: _password.text,
          companero: _companero,
          region: _region,
        );
      } else {
        await controller.iniciarSesion(
          nombre: _nombre.text,
          password: _password.text,
        );
      }
      HapticFeedback.mediumImpact();
    } on CuentaException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _entrando = false;
          _error = e.message;
        });
      }
    }
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
                                  _registro
                                      ? 'Crea tu cuenta de entrenador Pokémon'
                                      : 'Inicia sesión como entrenador Pokémon',
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
                          Aparecer(orden: 2, child: _formulario()),
                          const SizedBox(height: 16),
                          Aparecer(
                            orden: 3,
                            child: Text(
                              'Tu cuenta se guarda en el servidor de la Pokédex.',
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

  Widget _formulario() {
    final scheme = Theme.of(context).colorScheme;
    const duracion = Duration(milliseconds: 350);

    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SelectorModo(registro: _registro, onCambio: _cambiarModo),
          const SizedBox(height: 22),
          const _Etiqueta('Nombre de entrenador'),
          TextFormField(
            controller: _nombre,
            maxLength: 12,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            validator: _validarNombre,
            decoration: const InputDecoration(
              hintText: 'Ej. Ash',
              counterText: '',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 16),
          const _Etiqueta('Contraseña'),
          TextFormField(
            controller: _password,
            obscureText: !_verPassword,
            textInputAction: _registro
                ? TextInputAction.next
                : TextInputAction.done,
            autofillHints: [
              _registro ? AutofillHints.newPassword : AutofillHints.password,
            ],
            onFieldSubmitted: _registro ? null : (_) => _entrar(),
            validator: _validarPassword,
            decoration: InputDecoration(
              hintText: _registro ? 'Mínimo 6 caracteres' : 'Tu contraseña',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                tooltip: _verPassword
                    ? 'Ocultar contraseña'
                    : 'Mostrar contraseña',
                onPressed: () => setState(() => _verPassword = !_verPassword),
                icon: Icon(
                  _verPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
          ),
          // Campos que solo aparecen al crear la cuenta.
          AnimatedSize(
            duration: duracion,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _registro
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const _Etiqueta('Confirmar contraseña'),
                      TextFormField(
                        controller: _confirmar,
                        obscureText: !_verPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: _validarConfirmacion,
                        decoration: const InputDecoration(
                          hintText: 'Repite la contraseña',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
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
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _error == null
                ? const SizedBox(width: double.infinity, height: 0)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: scheme.error.withValues(alpha: 0.12),
                        border: Border.all(
                          color: scheme.error.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 20,
                            color: scheme.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: scheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            tint: _companero.color.withValues(alpha: 0.9),
            onPressed: _entrando ? null : _entrar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_registro ? Icons.catching_pokemon : Icons.login_rounded),
                const SizedBox(width: 10),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _entrando
                          ? 'Abriendo Pokédex…'
                          : _registro
                          ? 'Crear cuenta y comenzar'
                          : 'Iniciar sesión',
                      key: ValueKey('$_entrando$_registro'),
                      overflow: TextOverflow.ellipsis,
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

/// Control segmentado de vidrio: "Iniciar sesión" / "Crear cuenta".
class _SelectorModo extends StatelessWidget {
  const _SelectorModo({required this.registro, required this.onCambio});

  final bool registro;
  final ValueChanged<bool> onCambio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.onSurface.withValues(alpha: esOscuro ? 0.08 : 0.05),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: registro ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: GlassContainer(
                radius: 14,
                blur: 8,
                tint: Colors.white.withValues(alpha: esOscuro ? 0.14 : 0.9),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Row(
            children: [
              for (final (valor, texto) in [
                (false, 'Iniciar sesión'),
                (true, 'Crear cuenta'),
              ])
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onCambio(valor),
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: valor == registro ? 1 : 0.55,
                        child: Text(
                          texto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
