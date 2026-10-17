import 'package:flutter/widgets.dart';

import '../services/pokemon_service.dart';
import 'app_controller.dart';

/// Da acceso a la sesión y a los servicios desde cualquier pantalla.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required this.service,
    this.modelos3D = true,
    required super.child,
  }) : super(notifier: controller);

  final PokemonService service;

  /// Permite desactivar el visor 3D (por ejemplo, en las pruebas).
  final bool modelos3D;

  AppController get controller => notifier!;

  /// Se reconstruye cuando cambia la sesión o el tema.
  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  /// Lectura sin suscribirse a cambios (útil en initState y callbacks).
  static AppScope read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!;
}
