// lib/_blocs/process/contracts/validity/validity_state.dart
import 'package:equatable/equatable.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/additives/additives_data.dart';
import 'package:siged/_blocs/process/validity/validity_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

class ValidityState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  final ProcessData? contract;
  final List<ValidityData> validities;
  final List<AdditivesData> additives;

  final ValidityData? selectedValidity;

  /// Próxima ordem numérica sugerida (menor buraco ou max+1)
  final int nextOrderNumber;

  /// Opções de número de ordem para o dropdown (1..max+1)
  final List<String> orderNumberOptions;

  /// Itens já ocupados (para render cinza)
  final Set<String> greyOrderItems;

  /// Tipos de ordem permitidos para o próximo registro
  final List<String> availableOrderTypes;

  /// Anexos da validade selecionada
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
  }) {
    return ValidityState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      contract: contract ?? this.contract,
      validities: validities ?? this.validities,
      additives: additives ?? this.additives,
      selectedValidity: selectedValidity ?? this.selectedValidity,
      nextOrderNumber: nextOrderNumber ?? this.nextOrderNumber,
      orderNumberOptions:
      orderNumberOptions ?? this.orderNumberOptions,
      greyOrderItems: greyOrderItems ?? this.greyOrderItems,
      availableOrderTypes:
      availableOrderTypes ?? this.availableOrderTypes,
      attachments: attachments ?? this.attachments,
    );
  }

  factory ValidityState.initial() => const ValidityState(
    isLoading: false,
    isSaving: false,
    nextOrderNumber: 1,
  );

  @override
  List<Object?> get props => [
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
