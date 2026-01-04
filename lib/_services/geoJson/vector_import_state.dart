// lib/_services/geoJson/vector_import_state.dart
import 'package:equatable/equatable.dart';
import 'vector_import_data.dart';

enum VectorImportStatus {
  idle,
  pickingFile,
  previewReady,
  saving,
  success,
  failure,
}

class VectorImportState extends Equatable {
  final VectorImportStatus status;
  final String? error;

  /// Nome da coleção de destino (ex.: "actives_roads" ou "actives_oaes")
  final String? collectionPath;

  /// Lista de features carregadas do arquivo
  final List<ImportedFeatureData> features;

  /// Metadados das colunas (nome, tipo, selecionada...)
  final List<ImportColumnMeta> columns;

  /// Progresso de salvamento [0..1]
  final double progress;

  /// Mapeamento "campo de destino" (SIGED/Firestore) -> "coluna do arquivo"
  ///
  /// Ex.: { "state": "UF", "road": "RODOVIA", "region": "REGIAO" }
  /// ou { "coordinates": kGeometrySourceLabel } para usar a geometria.
  final Map<String, String> fieldMapping;

  const VectorImportState({
    required this.status,
    required this.features,
    required this.columns,
    this.collectionPath,
    this.error,
    this.progress = 0.0,
    this.fieldMapping = const {},
  });

  factory VectorImportState.initial() => const VectorImportState(
    status: VectorImportStatus.idle,
    features: [],
    columns: [],
    collectionPath: null,
    error: null,
    progress: 0.0,
    fieldMapping: {},
  );

  VectorImportState copyWith({
    VectorImportStatus? status,
    String? error,
    String? collectionPath,
    List<ImportedFeatureData>? features,
    List<ImportColumnMeta>? columns,
    double? progress,
    Map<String, String>? fieldMapping,
  }) {
    return VectorImportState(
      status: status ?? this.status,
      error: error,
      collectionPath: collectionPath ?? this.collectionPath,
      features: features ?? this.features,
      columns: columns ?? this.columns,
      progress: progress ?? this.progress,
      fieldMapping: fieldMapping ?? this.fieldMapping,
    );
  }

  @override
  List<Object?> get props => [
    status,
    error,
    collectionPath,
    features,
    columns,
    progress,
    fieldMapping,
  ];
}
