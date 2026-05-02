// lib/_blocs/modules/operation/phys_fin/physics_finance_state.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'physics_finance_data.dart';

class PhysicsFinanceState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final bool termsLoaded;
  final String? errorMessage;

  final List<AdditivesData> additives;

  /// additiveOrder -> additiveId
  final Map<int, String> termAdditiveId;

  /// termOrder -> PhysicsFinanceData
  final Map<int, PhysicsFinanceData> schedulesByTerm;

  /// termOrder -> itemId/serviceKey -> percentuais
  final Map<int, Map<String, List<double>>> gridByTerm;

  const PhysicsFinanceState({
    this.isLoading = false,
    this.isSaving = false,
    this.termsLoaded = false,
    this.errorMessage,
    this.additives = const <AdditivesData>[],
    this.termAdditiveId = const <int, String>{},
    this.schedulesByTerm = const <int, PhysicsFinanceData>{},
    this.gridByTerm = const <int, Map<String, List<double>>>{},
  });

  factory PhysicsFinanceState.initial() {
    return const PhysicsFinanceState();
  }

  PhysicsFinanceState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? termsLoaded,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<AdditivesData>? additives,
    Map<int, String>? termAdditiveId,
    Map<int, PhysicsFinanceData>? schedulesByTerm,
    Map<int, Map<String, List<double>>>? gridByTerm,
  }) {
    return PhysicsFinanceState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      termsLoaded: termsLoaded ?? this.termsLoaded,
      errorMessage:
      clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      additives: additives ?? this.additives,
      termAdditiveId: termAdditiveId ?? this.termAdditiveId,
      schedulesByTerm: schedulesByTerm ?? this.schedulesByTerm,
      gridByTerm: gridByTerm ?? this.gridByTerm,
    );
  }

  @override
  List<Object?> get props {
    return [
      isLoading,
      isSaving,
      termsLoaded,
      errorMessage,
      additives,
      termAdditiveId,
      schedulesByTerm,
      gridByTerm,
    ];
  }
}