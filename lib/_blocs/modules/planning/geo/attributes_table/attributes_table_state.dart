// lib/_services/files/geoJson/attributes_table_state.dart
import 'package:equatable/equatable.dart';
import 'attributes_table_data.dart';

enum AttributesTableStatus {
  idle,
  pickingFile,
  loadingFirestore,
  previewReady,
  saving,
  deleting,
  success,
  failure,
}

class VectorImportState extends Equatable {
  final AttributesTableStatus status;
  final String? error;

  final String? collectionPath;

  final List<AttributesTableData> features;
  final List<ImportColumnMeta> columns;

  final double progress;

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
    status: AttributesTableStatus.idle,
    features: [],
    columns: [],
    collectionPath: null,
    error: null,
    progress: 0.0,
    fieldMapping: {},
  );

  VectorImportState copyWith({
    AttributesTableStatus? status,
    String? error,
    String? collectionPath,
    List<AttributesTableData>? features,
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

  bool get isBusy =>
      status == AttributesTableStatus.pickingFile ||
          status == AttributesTableStatus.loadingFirestore ||
          status == AttributesTableStatus.saving ||
          status == AttributesTableStatus.deleting;

  bool get hasAnySelected => features.any((f) => f.selected == true);

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
