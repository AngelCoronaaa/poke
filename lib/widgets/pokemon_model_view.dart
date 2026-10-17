import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// El visor de modelos 3D (model-viewer) funciona en Android, iOS y Web.
bool get visor3DDisponible =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Modelo 3D real (.glb) del Pokémon, animado y girando.
///
/// Con [interactivo] en `false` solo se muestra (sin capturar gestos), para
/// poder hacer scroll sobre él; en `true` se gira, acerca y abre en RA.
class PokemonModelView extends StatelessWidget {
  const PokemonModelView({
    super.key,
    required this.src,
    required this.nombre,
    this.poster,
    this.interactivo = false,
  });

  final String src;
  final String nombre;
  final String? poster;
  final bool interactivo;

  @override
  Widget build(BuildContext context) {
    final visor = ModelViewer(
      key: ValueKey('$src-$interactivo'),
      src: src,
      alt: 'Modelo 3D de $nombre',
      poster: poster,
      loading: Loading.eager,
      autoRotate: true,
      autoRotateDelay: 0,
      rotationPerSecond: '40deg',
      autoPlay: true,
      cameraControls: interactivo,
      disableZoom: !interactivo,
      disablePan: true,
      touchAction: TouchAction.panY,
      interactionPrompt: InteractionPrompt.none,
      cameraOrbit: '0deg 80deg auto',
      shadowIntensity: 1,
      shadowSoftness: 0.9,
      exposure: 1.05,
      ar: interactivo,
      backgroundColor: Colors.transparent,
      debugLogging: false,
    );

    return interactivo ? visor : IgnorePointer(child: visor);
  }
}
