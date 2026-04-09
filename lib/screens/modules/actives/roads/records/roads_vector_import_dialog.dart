// lib/_widgets/vector_import/roads_vector_import_dialog.dart
import 'package:flutter/material.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/attribute_table.dart';

/// Dialog específico para importar RODOVIAS em `actives_roads`,
/// usando o VectorPreviewDialog genérico.
class RoadsVectorImportDialog extends StatelessWidget {
  const RoadsVectorImportDialog({super.key});

  /// Campos de destino do modelo ActiveRoadsData / coleção `actives_roads`.
  static const List<String> roadTargetFields = [
    'acronym',
    'uf',
    'segmentType',
    'descCoin',
    'roadCode',
    'initialSegment',
    'finalSegment',
    'initialKm',
    'finalKm',
    'extension',
    'stateSurface',
    'works',
    'coincidentFederal',
    'administration',
    'legalAct',
    'coincidentState',
    'coincidentStateSurface',
    'jurisdiction',
    'surface',
    'unitLocal',
    'coincident',
    'initialLatSegment',
    'initialLongSegment',
    'finalLatSegment',
    'finalLongSegment',
    'regional',
    'previousNumber',
    'revestmentType',
    'tmd',
    'tracksNumber',
    'maximumSpeed',
    'conservationCondition',
    'drainage',
    'vsa',
    'roadName',
    'state',
    'direction',
    'managingAgency',
    'description',
    // campo onde a geometria será salva (lista de GeoPoint)
    'points',
  ];

  @override
  Widget build(BuildContext context) {
    return AttributeTable(
      collectionPath: 'actives_roads',
      targetFields: roadTargetFields,
      title: 'Importar rodovias (actives_roads)',
      description:
      'Defina quais colunas do arquivo (ou a GEOMETRIA) irão preencher '
          'cada campo da rodovia no SIGED / Firestore, o filtro (se desejado) '
          'e o tipo de dado que será salvo.',
    );
  }
}
