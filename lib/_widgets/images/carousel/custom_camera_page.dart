// lib/_widgets/schedule/square_modal/custom_camera_page.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart' as cam;

import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

/// Câmera full-screen baseada no pacote `camera` (iOS/Android).
/// Retorna bytes (JPEG) via Navigator.pop.
class CustomCameraPage extends StatefulWidget {
  const CustomCameraPage({super.key});

  @override
  State<CustomCameraPage> createState() => _CustomCameraPageState();
}

class _CustomCameraPageState extends State<CustomCameraPage>
    with WidgetsBindingObserver {
  cam.CameraController? _controller;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !(_controller!.value.isInitialized)) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _init(reinitialize: true);
    }
  }

  Future<void> _init({bool reinitialize = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Evita corte de UI no iOS
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      final cams = await cam.availableCameras();
      final back = cams.firstWhere(
            (c) => c.lensDirection == cam.CameraLensDirection.back,
        orElse: () => cams.first,
      );

      final controller = cam.CameraController(
        back,
        cam.ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: cam.ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao iniciar câmera: $e');

      // ❌ erro via NotificationCenter
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Falha ao iniciar a câmera'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Câmera'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _take() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;

    setState(() => _busy = true);
    try {
      final xfile = await c.takePicture(); // JPEG
      final bytes = await xfile.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop<Uint8List>(bytes);
    } catch (e) {
      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Falha ao capturar'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Câmera'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            if (c != null && c.value.isInitialized)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover, // cobre toda a tela
                  child: SizedBox(
                    width: c.value.previewSize!.height, // invertido (camera)
                    height: c.value.previewSize!.width,
                    child: cam.CameraPreview(c),
                  ),
                ),
              )
            else
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),

            // Fechar
            Positioned(
              left: 8,
              top: MediaQuery.of(context).padding.top + 8,
              child: IconButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),

            if (_error != null)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // Disparo
            Positioned(
              bottom: 28 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _busy ? null : _take,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
