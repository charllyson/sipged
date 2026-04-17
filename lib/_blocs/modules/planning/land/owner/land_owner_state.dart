import 'package:flutter/foundation.dart';
import 'land_owner_data.dart';

@immutable
class LandOwnerState {
  static const Object _unset = Object();

  final bool initialized;
  final bool loading;
  final bool saving;
  final String? error;
  final String? successMessage;
  final String contractId;
  final String? propertyId;
  final LandOwnerData draft;

  const LandOwnerState({
    required this.initialized,
    required this.loading,
    required this.saving,
    required this.error,
    required this.successMessage,
    required this.contractId,
    required this.propertyId,
    required this.draft,
  });

  factory LandOwnerState.initial() {
    return LandOwnerState(
      initialized: false,
      loading: false,
      saving: false,
      error: null,
      successMessage: null,
      contractId: '',
      propertyId: null,
      draft: LandOwnerData.empty(contractId: ''),
    );
  }

  LandOwnerState copyWith({
    bool? initialized,
    bool? loading,
    bool? saving,
    Object? error = _unset,
    Object? successMessage = _unset,
    String? contractId,
    Object? propertyId = _unset,
    LandOwnerData? draft,
    bool clearError = false,
    bool clearSuccessMessage = false,
  }) {
    return LandOwnerState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError
          ? null
          : identical(error, _unset)
          ? this.error
          : error as String?,
      successMessage: clearSuccessMessage
          ? null
          : identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
      contractId: contractId ?? this.contractId,
      propertyId: identical(propertyId, _unset)
          ? this.propertyId
          : propertyId as String?,
      draft: draft ?? this.draft,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LandOwnerState &&
            other.initialized == initialized &&
            other.loading == loading &&
            other.saving == saving &&
            other.error == error &&
            other.successMessage == successMessage &&
            other.contractId == contractId &&
            other.propertyId == propertyId &&
            other.draft == draft);
  }

  @override
  int get hashCode {
    return Object.hash(
      initialized,
      loading,
      saving,
      error,
      successMessage,
      contractId,
      propertyId,
      draft,
    );
  }
}