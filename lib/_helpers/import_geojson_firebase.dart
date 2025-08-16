import 'package:flutter/material.dart';

import '../admPanel/converters/importGeoJson/import_geojson_controller.dart';


Future<void> handleImportGeoJson(BuildContext context) async {
  final TextEditingController _pathController = TextEditingController();

  final path = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Informe o caminho da coleção'),
      content: TextField(
        controller: _pathController,
        decoration: const InputDecoration(
          labelText: 'Ex: actives_roads ou actives_roads/.../segments',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final path = _pathController.text.trim();
            if (path.isNotEmpty) {
              Navigator.pop(context, path);
            }
          },
          child: const Text('Importar GeoJSON'),
        ),
      ],
    ),
  );

  if (!context.mounted || path == null || path.isEmpty) return;

  await ImportGeoJsonController.importarGeoJson(
    context: context,
    path: path,
    onFinished: () async {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Importação do GeoJSON finalizada!')),
        );
        //await _carregarDadosIniciais();
      }
    },
  );
}