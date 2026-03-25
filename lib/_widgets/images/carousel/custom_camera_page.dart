import 'dart:typed_data';

import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class CustomCameraPage extends StatefulWidget {
  const CustomCameraPage({super.key});

  @override
  State<CustomCameraPage> createState() => _CustomCameraPageState();
}

class _CustomCameraPageState extends State<CustomCameraPage>
    with WidgetsBindingObserver {
  cam.CameraController? _controller;
  bool _busy = false;
  bool _initializing = false;
  String? _error;
  int _initToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      c.dispose();
      _controller = null;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_initializing) return;

    _initializing = true;
    final int token = ++_initToken;

    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }

    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      final cams = await cam.availableCameras();
      if (cams.isEmpty) {
        throw 'Nenhuma câmera disponível neste dispositivo.';
      }

      final back = cams.firstWhere(
            (c) => c.lensDirection == cam.CameraLensDirection.back,
        orElse: () => cams.first,
      );

      final old = _controller;
      _controller = null;
      await old?.dispose();

      final controller = cam.CameraController(
        back,
        cam.ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: cam.ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      try {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {}

      if (!mounted || token != _initToken) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });
    } on cam.CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro da câmera: ${e.description ?? e.code}';
      });

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Falha ao iniciar a câmera'),
          subtitle: Text('${e.description ?? e.code}'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Câmera'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao iniciar câmera: $e';
      });

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
      _initializing = false;
      if (mounted && token == _initToken) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _take() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;

    setState(() => _busy = true);
    try {
      final xfile = await c.takePicture();
      final bytes = await xfile.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop<Uint8List>(bytes);
    } on cam.CameraException catch (e) {
      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Falha ao capturar'),
          subtitle: Text('${e.description ?? e.code}'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Câmera'),
          duration: const Duration(seconds: 6),
        ),
      );
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

  Widget _buildPreview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final previewSize = c.value.previewSize;
    if (previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: cam.CameraPreview(c),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildPreview(),
          Positioned(
            left: 8,
            top: topInset + 8,
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
                    color: Colors.black.withValues(alpha: 0.6),
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
          Positioned(
            bottom: 28 + bottomInset,
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
    );
  }
}