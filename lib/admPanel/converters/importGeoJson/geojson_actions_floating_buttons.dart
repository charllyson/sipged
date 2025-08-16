import 'package:flutter/material.dart';

class GeoJsonActionsFloatingButtons extends StatelessWidget {
  final void Function(BuildContext context) onImportGeoJson;
  final VoidCallback onDeleteCollection;

  const GeoJsonActionsFloatingButtons({
    super.key,
    required this.onImportGeoJson,
    required this.onDeleteCollection,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      right: 30,
      child: Column(
        children: [
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
                    Text('Enviar Polylines (GeoJson)',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                    Text('Deletar Polylines (GeoJson)',
                        style: TextStyle(color: Colors.white)),
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
