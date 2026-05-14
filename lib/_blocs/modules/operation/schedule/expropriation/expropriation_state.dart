import 'package:flutter/foundation.dart';

import 'expropriation_data.dart';

@immutable
class ExpropriationState {
  static const Object _unset = Object();

  final bool initialized;
  final bool loading;
  final bool saving;
  final bool deleting;
  final String? error;
  final String? successMessage;
  final String contractId;
  final String? propertyId;
  final List<ExpropriationData> items;
  final ExpropriationData draft;

  const ExpropriationState({
    required this.initialized,
    required this.loading,
    required this.saving,
    required this.deleting,
    required this.error,
    required this.successMessage,
    required this.contractId,
    required this.propertyId,
    required this.items,
    required this.draft,
  });

  factory ExpropriationState.initial() {
    return ExpropriationState(
      initialized: false,
      loading: false,
      saving: false,
      deleting: false,
      error: null,
      successMessage: null,
      contractId: '',
      propertyId: null,
      items: const [],
      draft: ExpropriationData.empty(contractId: ''),
    );
  }

  ExpropriationState copyWith({
    bool? initialized,
    bool? loading,
    bool? saving,
    bool? deleting,
    Object? error = _unset,
    Object? successMessage = _unset,
    String? contractId,
    Object? propertyId = _unset,
    List<ExpropriationData>? items,
    ExpropriationData? draft,
    bool clearError = false,
    bool clearSuccessMessage = false,
  }) {
    return ExpropriationState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
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
      items: items ?? this.items,
      draft: draft ?? this.draft,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExpropriationState &&
            other.initialized == initialized &&
            other.loading == loading &&
            other.saving == saving &&
            other.deleting == deleting &&
            other.error == error &&
            other.successMessage == successMessage &&
            other.contractId == contractId &&
            other.propertyId == propertyId &&
            listEquals(other.items, items) &&
            other.draft == draft);
  }

  @override
  int get hashCode {
    return Object.hash(
      initialized,
      loading,
      saving,
      deleting,
      error,
      successMessage,
      contractId,
      propertyId,
      Object.hashAll(items),
      draft,
    );
  }
}