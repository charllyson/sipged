import 'package:equatable/equatable.dart';

class LayerDbStatusState extends Equatable {
  final Map<String, bool> hasDbByLayer;
  final bool isLoading;
  final String? error;

  const LayerDbStatusState({
    this.hasDbByLayer = const {},
    this.isLoading = false,
    this.error,
  });

  LayerDbStatusState copyWith({
    Map<String, bool>? hasDbByLayer,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LayerDbStatusState(
      hasDbByLayer: hasDbByLayer ?? this.hasDbByLayer,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [hasDbByLayer, isLoading, error];
}