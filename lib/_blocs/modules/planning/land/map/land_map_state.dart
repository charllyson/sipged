import 'package:flutter/foundation.dart';
import 'land_map_data.dart';

@immutable
class LandMapState {
  final bool initialized;
  final bool loading;
  final String? error;
  final String contractId;
  final String? selectedPropertyId;
  final List<LandMapData> items;

  const LandMapState({
    required this.initialized,
    required this.loading,
    required this.error,
    required this.contractId,
    required this.selectedPropertyId,
    required this.items,
  });

  factory LandMapState.initial() {
    return const LandMapState(
      initialized: false,
      loading: false,
      error: null,
      contractId: '',
      selectedPropertyId: null,
      items: [],
    );
  }

  LandMapState copyWith({
    bool? initialized,
    bool? loading,
    String? error,
    String? contractId,
    String? selectedPropertyId,
    List<LandMapData>? items,
    bool clearError = false,
  }) {
    return LandMapState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      contractId: contractId ?? this.contractId,
      selectedPropertyId: selectedPropertyId ?? this.selectedPropertyId,
      items: items ?? this.items,
    );
  }
}