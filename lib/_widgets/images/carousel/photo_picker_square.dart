import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sipged/_widgets/images/carousel/photo_preview_page.dart';
import 'package:sipged/_widgets/images/carousel/custom_camera_page.dart';
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

// Só usado fora do Web
import 'dart:io' show Platform;

class PhotoPickerSquare extends StatefulWidget {
  final bool enabled;

  /// Fluxo legado
  final VoidCallback? onTap;

  /// Callbacks finais
  final Future<void> Function(Uint8List bytes)? onPickFromCamera;
  final Future<void> Function(Uint8List bytes)? onPickFromGallery;

  final int? imageQuality;
  final double? maxWidth;
  final double? maxHeight;

  final double editorMaxScale;
  final int editorExportQuality;
  final bool editorCircleCrop;
  final List<double>? editorAspectRatios;

  const PhotoPickerSquare({
    super.key,
    required this.enabled,
    this.onTap,
    this.onPickFromCamera,
    this.onPickFromGallery,
    this.imageQuality = 90,
    this.maxWidth,
    this.maxHeight,
    this.editorMaxScale = 5.0,
    this.editorExportQuality = 90,
    this.editorCircleCrop = false,
    this.editorAspectRatios,
  });

  @override
  State<PhotoPickerSquare> createState() => _PhotoPickerSquareState();
}

class _PhotoPickerSquareState extends State<PhotoPickerSquare> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  bool get _hasNewCallbacks =>
      widget.onPickFromCamera != null || widget.onPickFromGallery != null;

  Future<void> _runLocked(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<T?> _withBlockingDialog<T>(
      BuildContext context, {
        required String message,
        required Future<T> Function() task,
      }) async {
    bool dialogOpen = false;

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: const Color(0x80000000),
      builder: (_) {
        dialogOpen = true;
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6E6E6E)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
                const SizedBox(width: 12),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      return await task();
    } finally {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _openChooser(BuildContext context) async {
    if (!widget.enabled || _busy) return;

    if (!_hasNewCallbacks) {
      widget.onTap?.call();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar foto'),
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  await Future<void>.delayed(const Duration(milliseconds: 120));
                  if (!mounted) return;
                  await _runLocked(() => _pickFromCamera(context));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  await Future<void>.delayed(const Duration(milliseconds: 120));
                  if (!mounted) return;
                  await _runLocked(() => _pickFromGallery(context));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    try {
      Uint8List? bytes;

      if (kIsWeb) {
        final XFile? file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: null,
          maxWidth: null,
          maxHeight: null,
        );

        if (file != null) {
          bytes = await _withBlockingDialog<Uint8List?>(
            context,
            message: 'Carregando foto…',
            task: file.readAsBytes,
          );
        }
      } else if (Platform.isIOS) {
        bytes = await Navigator.of(context, rootNavigator: true).push<Uint8List?>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const CustomCameraPage(),
          ),
        );
      } else {
        final XFile? file = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: null,
          maxWidth: null,
          maxHeight: null,
        );

        if (file != null) {
          bytes = await _withBlockingDialog<Uint8List?>(
            context,
            message: 'Carregando foto…',
            task: file.readAsBytes,
          );
        }
      }

      if (bytes == null || !mounted) return;

      final Uint8List? edited =
      await Navigator.of(context, rootNavigator: true).push<Uint8List?>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PhotoPreviewPage(
            originalBytes: bytes!,
            outputJpegQuality: 100,
            previewFit: BoxFit.contain,
            showOverlayInPreview: true,
            debugLog: false,
          ),
        ),
      );

      if (edited == null) return;
      await widget.onPickFromCamera?.call(edited);
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Falha ao obter imagem da câmera'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Fotos'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }

      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: null,
        maxWidth: null,
        maxHeight: null,
      );
      if (file == null) return;

      final bytes = await _withBlockingDialog<Uint8List?>(
        context,
        message: 'Carregando foto…',
        task: file.readAsBytes,
      );
      if (bytes == null || !mounted) return;

      final Uint8List? edited =
      await Navigator.of(context, rootNavigator: true).push<Uint8List?>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PhotoPreviewPage(
            originalBytes: bytes,
            outputJpegQuality: 100,
            previewFit: BoxFit.contain,
            showOverlayInPreview: true,
            debugLog: false,
          ),
        ),
      );

      if (edited == null) return;
      await widget.onPickFromGallery?.call(edited);
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Falha ao obter/editar imagem'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Fotos'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_busy;

    return SizedBox(
      width: 96,
      height: 96,
      child: InkWell(
        onTap: enabled ? () => _openChooser(context) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled ? Colors.blueGrey.shade300 : Colors.grey,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_a_photo,
                color: enabled ? Colors.blueGrey : Colors.grey,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                _busy ? 'Abrindo…' : 'Adicionar foto',
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? Colors.blueGrey : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}