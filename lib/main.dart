import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_controller.dart';
import 'app/app_scope.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/pokemon_service.dart';
import 'theme/app_theme.dart';
import 'widgets/pokeball_3d.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  PokeballShader.cargar(); // Precarga el shader de las pokébolas 3D.

  runApp(
    PokedexApp(controller: AppController(prefs), service: PokemonService()),
  );
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({
    super.key,
    required this.controller,
    required this.service,
    this.modelos3D = true,
  });

  final AppController controller;
  final PokemonService service;
  final bool modelos3D;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      service: service,
      modelos3D: modelos3D,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          title: 'Pokédex',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro,
          darkTheme: AppTheme.oscuro,
          themeMode: controller.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 400),
          home: const _Raiz(),
        ),
      ),
    );
  }
}

/// Sin sesión muestra el login; con sesión, la pantalla de inicio.
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final trainer = AppScope.of(context).controller.trainer;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 1.06, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: trainer == null
          ? const LoginScreen(key: ValueKey('login'))
          : HomeScreen(key: ValueKey('home-${trainer.trainerId}')),
    );
  }
}
