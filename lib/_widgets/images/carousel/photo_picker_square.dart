import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import 'package:siged/_widgets/images/carousel/photo_preview_page.dart';

// Só serão usados fora do Web:
import 'dart:io' show Platform;
import 'package:siged/_widgets/images/carousel/custom_camera_page.dart';

import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class PhotoPickerSquare extends StatelessWidget {
  final bool enabled;

  /// Fluxo legado (ex.: FilePicker).
  final VoidCallback? onTap;

  /// Callbacks finais (bytes confirmados no preview).
  final Future<void> Function(Uint8List bytes)? onPickFromCamera;
  final Future<void> Function(Uint8List bytes)? onPickFromGallery;

  /// Parâmetros legados — ignorados quando preservamos original.
  final int? imageQuality; // 0..100
  final double? maxWidth;
  final double? maxHeight;

  /// Opções (podem ser repassadas ao editor, se desejar).
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
  Widget build(BuildContext context) {
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
              Icon(Icons.add_a_photo,
                  color: enabled ? Colors.blueGrey : Colors.grey, size: 22),
              const SizedBox(height: 6),
              Text(
                'Adicionar foto',
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

  Future<void> _openChooser(BuildContext parentContext) async {
    final noNewCallbacks =
        onPickFromCamera == null && onPickFromGallery == null;
    if (noNewCallbacks) {
      onTap?.call();
      return;
    }

    await showModalBottomSheet<void>(
      context: parentContext,
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
                  Navigator.of(parentContext, rootNavigator: true).pop();
                  await Future.delayed(const Duration(milliseconds: 150));
                  await _pickFromCamera(parentContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () async {
                  Navigator.of(parentContext, rootNavigator: true).pop();
                  await Future.delayed(const Duration(milliseconds: 150));
                  await _pickFromGallery(parentContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- helper de bloqueio ----------
  Future<T?> _withBlockingDialog<T>(
      BuildContext context, {
        required String message,
        required Future<T> Function() task,
      }) async {
    // abre overlay
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: const Color(0x80000000),
      builder: (_) => Center(
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      return await task();
    } finally {
      // fecha overlay se ainda aberto
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    try {
      Uint8List? bytes;

      if (kIsWeb) {
        // Web: usa image_picker. Alguns browsers podem abrir apenas o seletor.
        final picker = ImagePicker();
        final XFile? file = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: null,
          maxWidth: null,
          maxHeight: null,
        );
        if (file != null) {
          bytes = await _withBlockingDialog<Uint8List?>(
            context,
            message: 'Carregando foto…',
            task: () => file.readAsBytes(),
          );
        }
      } else if (Platform.isIOS) {
        // iOS nativo: sua câmera custom (tela cheia)
        bytes = await Navigator.of(context, rootNavigator: true).push<Uint8List?>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const CustomCameraPage(),
          ),
        );
      } else {
        // Android (e demais nativos): image_picker
        final picker = ImagePicker();
        final XFile? file = await picker.pickImage(
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
            task: () => file.readAsBytes(),
          );
        }
      }

      if (bytes == null) return;

      // Pré-visualização (ela própria mostra overlay "Preparando pré-visualização…")
      final edited = await Navigator.of(context, rootNavigator: true).push<Uint8List?>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PhotoPreviewPage(
            originalBytes: bytes!,
            outputJpegQuality: 100,
            previewFit: BoxFit.contain, // sem corte
            showOverlayInPreview: true,
            debugLog: false,
          ),
        ),
      );
      if (edited == null) return;

      await onPickFromCamera?.call(edited);
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
      // Evita mexer em SystemChrome no Web
      if (!kIsWeb && Platform.isIOS) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }

      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: null,
        maxWidth: null,
        maxHeight: null,
      );
      if (file == null) return;

      final bytes = await _withBlockingDialog<Uint8List?>(
        context,
        message: 'Carregando foto…',
        task: () => file.readAsBytes(),
      );
      if (bytes == null) return;

      final edited = await Navigator.of(context, rootNavigator: true).push<Uint8List?>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PhotoPreviewPage(
            originalBytes: bytes,
            outputJpegQuality: 100,
            previewFit: BoxFit.contain, // sem corte
            showOverlayInPreview: true,
            debugLog: false,
          ),
        ),
      );
      if (edited == null) return;

      await onPickFromGallery?.call(edited);
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
}
