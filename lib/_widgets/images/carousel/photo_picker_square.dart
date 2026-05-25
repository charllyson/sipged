// lib/_widgets/images/carousel/photo_picker_square.dart

import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

 import 'package:sipged/_services/my_location/nominatim_cubit.dart';
import 'package:sipged/_widgets/images/carousel/custom_camera_page.dart';
import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/images/carousel/services/photo_utils.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

class PhotoPickerSquare extends StatefulWidget {
  const PhotoPickerSquare({
    super.key,
    required this.enabled,
    this.onTap,
    this.onPickFromCamera,
    this.onPickFromGallery,
    this.onPickMultipleFromGallery,
    this.imageQuality = 90,
    this.maxWidth,
    this.maxHeight,
    this.editorMaxScale = 5.0,
    this.editorExportQuality = 90,
    this.editorCircleCrop = false,
    this.editorAspectRatios,
    this.uploadedBy,
    this.resolveAddressFromPhotoGps = true,
    this.captureLocationWhenCameraHasNoGps = true,
  });

  final bool enabled;
  final VoidCallback? onTap;

  final Future<void> Function(PhotoData photo)? onPickFromCamera;
  final Future<void> Function(PhotoData photo)? onPickFromGallery;
  final Future<void> Function(List<PhotoData> photos)? onPickMultipleFromGallery;

  final int? imageQuality;
  final double? maxWidth;
  final double? maxHeight;

  final double editorMaxScale;
  final int editorExportQuality;
  final bool editorCircleCrop;
  final List<double>? editorAspectRatios;

  final String? uploadedBy;

  /// Resolve endereço a partir da latitude/longitude da foto.
  final bool resolveAddressFromPhotoGps;

  /// Para foto tirada pela câmera interna.
  ///
  /// O pacote camera geralmente não grava GPS no EXIF. Nesse caso,
  /// capturamos a localização atual no momento da foto e associamos ao PhotoData.
  final bool captureLocationWhenCameraHasNoGps;

  @override
  State<PhotoPickerSquare> createState() => _PhotoPickerSquareState();
}

class _PhotoPickerSquareState extends State<PhotoPickerSquare> {
  final ImagePicker _picker = ImagePicker();

  bool _busy = false;

  bool get _hasNewCallbacks {
    return widget.onPickFromCamera != null ||
        widget.onPickFromGallery != null ||
        widget.onPickMultipleFromGallery != null;
  }

  Future<void> _runLocked(Future<void> Function() task) async {
    if (_busy) return;

    if (mounted) {
      setState(() => _busy = true);
    }

    try {
      await task();
    } catch (e, s) {
      debugPrint('[PhotoPickerSquare] Falha na operação: $e');
      debugPrintStack(stackTrace: s);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<T?> _withBlockingDialog<T>({
    required String message,
    required Future<T> Function() task,
  }) async {
    if (!mounted) {
      return task();
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    bool dialogPushed = false;

    showDialog<void>(
      context: navigator.context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: const Color(0x99000000),
      builder: (_) {
        dialogPushed = true;

        return _PhotoPickerBlockingDialog(
          message: message,
        );
      },
    );

    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return await task();
    } finally {
      if (navigator.mounted && dialogPushed && navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  Future<void> _openChooser() async {
    if (!widget.enabled || _busy) return;

    if (!_hasNewCallbacks) {
      widget.onTap?.call();
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);

    await showModalBottomSheet<void>(
      context: navigator.context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tirar foto'),
                  subtitle: const Text(
                    'Capturar uma foto e adicionar ao carrossel',
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();

                    await Future<void>.delayed(
                      const Duration(milliseconds: 120),
                    );

                    if (!mounted) return;

                    await _runLocked(_pickFromCamera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Escolher da galeria'),
                  subtitle: const Text('Selecionar uma ou várias fotos'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();

                    await Future<void>.delayed(
                      const Duration(milliseconds: 120),
                    );

                    if (!mounted) return;

                    await _runLocked(_pickMultipleFromGallery);
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List?> _readFileBytesWithLoading(XFile file) async {
    return _withBlockingDialog<Uint8List?>(
      message: 'Carregando foto...',
      task: file.readAsBytes,
    );
  }

  Future<PhotoData?> _buildOriginalPhotoMetadata({
    required Uint8List bytes,
    required String originalName,
    required DateTime fallbackDate,
  }) async {
    return _withBlockingDialog<PhotoData>(
      message: 'Lendo dados da foto...',
      task: () {
        return PhotoUtils.buildPhotoDataFromBytes(
          original: bytes,
          originalName: originalName,
          fallbackTakenAt: fallbackDate,
          uploadedAtMs: DateTime.now().millisecondsSinceEpoch,
          uploadedBy: widget.uploadedBy,
        );
      },
    );
  }

  Future<LatLng?> _captureCurrentLocationForCameraPhoto() async {
    if (!widget.captureLocationWhenCameraHasNoGps) return null;

    return _withBlockingDialog<LatLng?>(
      message: 'Capturando coordenada da foto...',
      task: () async {
        try {
          final cubit = context.read<NominatimCubit>();

          return await cubit.getUserCurrentLocation();
        } catch (e, s) {
          debugPrint(
            '[PhotoPickerSquare] Não foi possível capturar localização atual: $e',
          );
          debugPrintStack(stackTrace: s);

          return null;
        }
      },
    );
  }

  Future<PhotoData> _ensureCameraPhotoHasCoordinates(PhotoData photo) async {
    if (photo.lat != null && photo.lng != null) {
      return photo;
    }

    final coords = await _captureCurrentLocationForCameraPhoto();

    if (coords == null) {
      return photo;
    }

    return photo.copyWith(
      lat: coords.latitude,
      lng: coords.longitude,
    );
  }

  Future<PhotoData> _resolveAddressIntoPhotoMeta(PhotoData photo) async {
    if (!widget.resolveAddressFromPhotoGps) return photo;

    final lat = photo.lat;
    final lng = photo.lng;

    if (lat == null || lng == null) return photo;

    try {
      final cubit = context.read<NominatimCubit>();

      final placemark = await cubit.getPlaceMarkAdapted(
        LatLng(lat, lng),
      );

      if (placemark == null) return photo;

      final address = _ResolvedPhotoAddress.fromPlacemark(placemark);

      return photo.copyWith(
        address: address.address,
        city: address.city,
        state: address.state,
      );
    } catch (e, s) {
      debugPrint(
        '[PhotoPickerSquare] Não foi possível resolver endereço da foto: $e',
      );
      debugPrintStack(stackTrace: s);

      return photo;
    }
  }

  Future<PhotoData?> _preparePhotoFromBytes({
    required Uint8List bytes,
    required String originalName,
    required DateTime fallbackDate,
    required bool fromCamera,
  }) async {
    final rawPhoto = await _buildOriginalPhotoMetadata(
      bytes: bytes,
      originalName: originalName,
      fallbackDate: fallbackDate,
    );

    if (rawPhoto == null) return null;

    final withCoords = fromCamera
        ? await _ensureCameraPhotoHasCoordinates(rawPhoto)
        : rawPhoto;

    final withAddress = await _resolveAddressIntoPhotoMeta(withCoords);

    /// Importante:
    /// Aqui NÃO carimbamos os bytes.
    /// O carimbo visual aparece no preview/galeria.
    /// O carimbo definitivo é gerado somente no salvamento/upload.
    return withAddress;
  }

  Future<void> _pickFromCamera() async {
    try {
      Uint8List? bytes;
      String originalName =
          'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb) {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: null,
          maxWidth: null,
          maxHeight: null,
        );

        if (file == null) return;

        originalName = file.name;
        bytes = await _readFileBytesWithLoading(file);
      } else if (Platform.isIOS) {
        if (!mounted) return;

        final navigator = Navigator.of(context, rootNavigator: true);

        bytes = await navigator.push<Uint8List?>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const CustomCameraPage(),
          ),
        );
      } else {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: null,
          maxWidth: null,
          maxHeight: null,
        );

        if (file == null) return;

        originalName = file.name;
        bytes = await _readFileBytesWithLoading(file);
      }

      if (bytes == null || bytes.isEmpty || !mounted) return;

      final photo = await _preparePhotoFromBytes(
        bytes: bytes,
        originalName: originalName,
        fallbackDate: DateTime.now(),
        fromCamera: true,
      );

      if (photo == null || !mounted) return;

      await widget.onPickFromCamera?.call(photo);
    } catch (e, s) {
      debugPrint('[PhotoPickerSquare] Falha ao obter imagem da câmera: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> _pickMultipleFromGallery() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }

      final files = await _picker.pickMultiImage(
        imageQuality: null,
        maxWidth: null,
        maxHeight: null,
      );

      if (files.isEmpty) return;

      final photos = <PhotoData>[];

      for (final file in files) {
        if (!mounted) return;

        final bytes = await _readFileBytesWithLoading(file);

        if (bytes == null || bytes.isEmpty) continue;

        final photo = await _preparePhotoFromBytes(
          bytes: bytes,
          originalName: file.name,
          fallbackDate: DateTime.now(),
          fromCamera: false,
        );

        if (photo != null) {
          photos.add(photo);
        }
      }

      if (photos.isEmpty || !mounted) return;

      if (widget.onPickMultipleFromGallery != null) {
        await widget.onPickMultipleFromGallery!(photos);
        return;
      }

      if (widget.onPickFromGallery != null) {
        for (final photo in photos) {
          await widget.onPickFromGallery!(photo);
        }
      }
    } catch (e, s) {
      debugPrint('[PhotoPickerSquare] Falha ao obter imagens da galeria: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_busy;

    return SizedBox(
      width: 96,
      height: 96,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled ? _openChooser : null,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: enabled ? Colors.blueGrey.shade300 : Colors.grey,
                width: 1.2,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _busy
                    ? const _PhotoPickerBusyContent()
                    : _PhotoPickerIdleContent(enabled: enabled),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolvedPhotoAddress {
  const _ResolvedPhotoAddress({
    this.address,
    this.city,
    this.state,
  });

  final String? address;
  final String? city;
  final String? state;

  factory _ResolvedPhotoAddress.fromPlacemark(Placemark placemark) {
    String clean(String? value) {
      return value?.trim() ?? '';
    }

    String? emptyToNull(String value) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }

    final street = clean(placemark.street);
    final thoroughfare = clean(placemark.thoroughfare);
    final subThoroughfare = clean(placemark.subThoroughfare);
    final subLocality = clean(placemark.subLocality);
    final postalCode = clean(placemark.postalCode);

    final addressParts = <String>[
      if (street.isNotEmpty) street,
      if (street.isEmpty && thoroughfare.isNotEmpty) thoroughfare,
      if (subThoroughfare.isNotEmpty) subThoroughfare,
      if (subLocality.isNotEmpty) subLocality,
      if (postalCode.isNotEmpty) postalCode,
    ];

    final locality = clean(placemark.locality);
    final subAdministrativeArea = clean(placemark.subAdministrativeArea);
    final administrativeArea = clean(placemark.administrativeArea);

    return _ResolvedPhotoAddress(
      address: emptyToNull(addressParts.join(', ')),
      city: emptyToNull(
        locality.isNotEmpty ? locality : subAdministrativeArea,
      ),
      state: emptyToNull(administrativeArea),
    );
  }
}

class _PhotoPickerBlockingDialog extends StatelessWidget {
  const _PhotoPickerBlockingDialog({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 220,
              maxWidth: 360,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6E6E6E),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingTreeDots(
                    size: 24,
                    strokeWidth: 2.6,
                    color: Colors.white,
                    centered: false,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPickerIdleContent extends StatelessWidget {
  const _PhotoPickerIdleContent({
    required this.enabled,
  });

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('idle'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.add_a_photo,
          color: enabled ? Colors.blueGrey : Colors.grey,
          size: 22,
        ),
        const SizedBox(height: 6),
        Text(
          'Adicionar foto',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: enabled ? Colors.blueGrey : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PhotoPickerBusyContent extends StatelessWidget {
  const _PhotoPickerBusyContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey<String>('busy'),
      mainAxisSize: MainAxisSize.min,
      children: [
        LoadingTreeDots(
          size: 24,
          strokeWidth: 2.4,
          centered: false,
        ),
        SizedBox(height: 8),
        Text(
          'Abrindo...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}