
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../_blocs/actives/road_bloc.dart';
import 'geojson_preview_dialog.dart';

class ImportGeoJsonController {
  static Future<void> importarGeoJson({
    required BuildContext context,
    required String path,
    required void Function()? onFinished,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['geojson', 'json'],
      );
      if (result == null) return;

      final file = result.files.first;
      final bytes = file.bytes ?? File(file.path!).readAsBytesSync();
      final Map<String, dynamic> geoJson = json.decode(utf8.decode(bytes));

      final List<dynamic> featuresRaw = geoJson['features'] ?? [];
      final List<Map<String, dynamic>> parsedFeatures =
      featuresRaw.whereType<Map<String, dynamic>>().toList();

      if (parsedFeatures.isEmpty) {
        _showSnackBar(context, 'GeoJSON sem dados válidos.');
        return;
      }

      if (!context.mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) {
          return GeoJsonPreviewDialog(
            features: parsedFeatures,
            onSalvar: (linhas, tipos, subcolecoes) async {
              final roadsBloc = RoadsBloc();
              await roadsBloc.importarRodoviasComCoordenadas(
                linhasPrincipais: linhas,
                subcolecoes: subcolecoes,
              );
              onFinished?.call(); // <- coloque aqui se quiser callback final
            },
          );
        },
      );

    } catch (e) {
      _showSnackBar(context, 'Erro ao importar GeoJSON: $e');
    }
  }

  static void _showSnackBar(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
