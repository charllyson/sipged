import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'preview_dialog.dart';
import 'sanitizer_geometry.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ImportGeoJson {
  /// Abre o file picker, mostra o preview e devolve o que foi selecionado.
  ///
  /// - `onSalvar`: recebe (linhasPrincipais, geometrias) já saneadas (LineStrings).
  /// - `onFinished`: callback opcional para pós-processo (refresh etc).
  static Future<void> geoJsonImport({
    required BuildContext context,
    required String path, // mantido por compatibilidade
    required Future<void> Function(
        List<Map<String, dynamic>> linhasPrincipais,
        List<Map<String, dynamic>> geometrias,
        ) onSalvar,
    required void Function()? onFinished,
    double maxJumpKm = 2.0,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['geojson', 'json'],
      );
      if (result == null) {
        _notify('Importação cancelada', type: AppNotificationType.warning);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes ?? File(file.path!).readAsBytesSync();
      final Map<String, dynamic> geoJson = json.decode(utf8.decode(bytes));

      final List<dynamic> featuresRaw = geoJson['features'] ?? [];
      final List<Map<String, dynamic>> parsedFeatures =
      featuresRaw.whereType<Map<String, dynamic>>().toList();

      if (parsedFeatures.isEmpty) {
        _notify('GeoJSON sem dados válidos.', type: AppNotificationType.warning);
        return;
      }

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return GeoJsonPreviewDialog(
            features: parsedFeatures,
            onSalvar: (linhas, tipos, subcolecoes) async {
              // subcolecoes esperado: [{'points': [{latitude, longitude}, ...]}, ...]
              final geometrias = <Map<String, dynamic>>[];
              int totalSaltosConsiderados = 0;

              for (final sub in subcolecoes) {
                final rawPoints = (sub['points'] as List?) ?? const [];
                final pts = rawPoints.map((p) {
                  final lat = (p['latitude'] as num).toDouble();
                  final lng = (p['longitude'] as num).toDouble();
                  return LatLng(lat, lng);
                }).toList();

                final sanitized = sanitizePolyline(raw: pts, maxJumpKm: maxJumpKm);
                totalSaltosConsiderados +=
                sanitized.forwardLongJumps <= sanitized.reverseLongJumps
                    ? sanitized.forwardLongJumps
                    : sanitized.reverseLongJumps;

                for (final seg in sanitized.segments) {
                  final pointsMap = seg
                      .map((p) => {
                    'latitude': p.latitude,
                    'longitude': p.longitude,
                  })
                      .toList();
                  geometrias.add({
                    'geometryType': 'LineString',
                    'points': pointsMap,
                  });
                }
              }

              await onSalvar(linhas, geometrias);
              onFinished?.call();

              _notify(
                'Importação concluída',
                type: AppNotificationType.success,
                subtitle:
                'Saltos detectados (no sentido escolhido): $totalSaltosConsiderados',
              );
            },
          );
        },
      );
    } catch (e) {
      _notify('Erro ao importar GeoJSON', type: AppNotificationType.error, subtitle: '$e');
    }
  }

  // 🔔 helper de notificação
  static void _notify(
      String title, {
        AppNotificationType type = AppNotificationType.info,
        String? subtitle,
      }) {
    NotificationCenter.instance.show(
      AppNotification(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        type: type,
      ),
    );
  }
}
