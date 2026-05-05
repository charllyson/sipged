// lib/_blocs/modules/contracts/validity/validity_state.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

class ValidityState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  final ProcessData? contract;
  final List<ValidityData> validities;
  final List<AdditivesData> additives;

  final ValidityData? selectedValidity;

  final int nextOrderNumber;
  final List<String> orderNumberOptions;
  final Set<String> greyOrderItems;
  final List<String> availableOrderTypes;

  final List<Attachment> attachments;

  const ValidityState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.contract,
    this.validities = const <ValidityData>[],
    this.additives = const <AdditivesData>[],
    this.selectedValidity,
    this.nextOrderNumber = 1,
    this.orderNumberOptions = const <String>[],
    this.greyOrderItems = const <String>{},
    this.availableOrderTypes = const <String>[],
    this.attachments = const <Attachment>[],
  });

  factory ValidityState.initial() {
    return const ValidityState(
      isLoading: false,
      isSaving: false,
      errorMessage: null,
      contract: null,
      validities: <ValidityData>[],
      additives: <AdditivesData>[],
      selectedValidity: null,
      nextOrderNumber: 1,
      orderNumberOptions: <String>['1'],
      greyOrderItems: <String>{},
      availableOrderTypes: <String>[],
      attachments: <Attachment>[],
    );
  }

  ValidityState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    ProcessData? contract,
    List<ValidityData>? validities,
    List<AdditivesData>? additives,
    ValidityData? selectedValidity,
    int? nextOrderNumber,
    List<String>? orderNumberOptions,
    Set<String>? greyOrderItems,
    List<String>? availableOrderTypes,
    List<Attachment>? attachments,
    bool clearError = false,
    bool clearContract = false,
    bool clearSelectedValidity = false,
    bool clearAttachments = false,
  }) {
    return ValidityState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      contract: clearContract ? null : (contract ?? this.contract),
      validities: validities ?? this.validities,
      additives: additives ?? this.additives,
      selectedValidity: clearSelectedValidity
          ? null
          : (selectedValidity ?? this.selectedValidity),
      nextOrderNumber: nextOrderNumber ?? this.nextOrderNumber,
      orderNumberOptions: orderNumberOptions ?? this.orderNumberOptions,
      greyOrderItems: greyOrderItems ?? this.greyOrderItems,
      availableOrderTypes: availableOrderTypes ?? this.availableOrderTypes,
      attachments: clearAttachments
          ? const <Attachment>[]
          : (attachments ?? this.attachments),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isLoading,
    isSaving,
    errorMessage,
    contract,
    validities,
    additives,
    selectedValidity,
    nextOrderNumber,
    orderNumberOptions,
    greyOrderItems,
    availableOrderTypes,
    attachments,
  ];
}