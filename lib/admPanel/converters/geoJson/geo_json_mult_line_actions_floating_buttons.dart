import 'package:flutter/material.dart';

import 'geo_json_mult_line_fix_jumps_in_collection.dart';

class GeoJsonActionsButtons extends StatelessWidget {
  final void Function(BuildContext context) onImportGeoJson;
  final VoidCallback onDeleteCollection;
  final VoidCallback onCheckDistances; // já existia
  final String collectionPath;         // ⇦ passe 'actives_railways'

  const GeoJsonActionsButtons({
    super.key,
    required this.onImportGeoJson,
    required this.onDeleteCollection,
    required this.onCheckDistances,
    required this.collectionPath,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 30,
      child: Column(
        children: [
          // Importar GeoJSON
          InkWell(
            onTap: () => onImportGeoJson(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.upload, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Enviar Polylines', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Deletar coleção
          InkWell(
            onTap: onDeleteCollection,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.restore_from_trash_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Deletar Polylines', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Verificar Saltos (somente checagem)
          InkWell(
            onTap: onCheckDistances,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.alt_route, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Verificar Saltos', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ✅ Verificar & Corrigir (coleção existente)
          InkWell(
            onTap: () async {
              await geoJsonFixJumpsInCollection(
                collectionPath: collectionPath,
                maxJumpKm: 2.0,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verificação & correção concluídas.')),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Verificar & Corrigir', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
