import 'package:equatable/equatable.dart';
import 'geo_attributes_data.dart';

enum GeoAttributesStatus {
  idle,
  pickingFile,
  loadingFirestore,
  previewReady,
  saving,
  deleting,
  success,
  failure,
}

class GeoAttributesState extends Equatable {
  final GeoAttributesStatus status;
  final String? error;
  final String? collectionPath;
  final List<GeoAttributesData> features;
  final List<ImportColumnMeta> columns;
  final double progress;
  final Map<String, String> fieldMapping;

  const GeoAttributesState({
    required this.status,
    required this.features,
    required this.columns,
    this.collectionPath,
    this.error,
    this.progress = 0.0,
    this.fieldMapping = const {},
  });

  factory GeoAttributesState.initial() => const GeoAttributesState(
    status: GeoAttributesStatus.idle,
    features: [],
    columns: [],
    collectionPath: null,
    error: null,
    progress: 0.0,
    fieldMapping: {},
  );

  GeoAttributesState copyWith({
    GeoAttributesStatus? status,
    String? error,
    String? collectionPath,
    List<GeoAttributesData>? features,
    List<ImportColumnMeta>? columns,
    double? progress,
    Map<String, String>? fieldMapping,
    bool clearError = false,
  }) {
    return GeoAttributesState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      collectionPath: collectionPath ?? this.collectionPath,
      features: features ?? this.features,
      columns: columns ?? this.columns,
      progress: progress ?? this.progress,
      fieldMapping: fieldMapping ?? this.fieldMapping,
    );
  }

  bool get isBusy =>
      status == GeoAttributesStatus.pickingFile ||
          status == GeoAttributesStatus.loadingFirestore ||
          status == GeoAttributesStatus.saving ||
          status == GeoAttributesStatus.deleting;

  bool get hasAnySelected => features.any((f) => f.selected);

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