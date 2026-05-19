import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

class ContractTabDescriptor {
  final String label;
  final Widget Function(ContractData? contract) builder;
  final bool requireSavedContract;

  /// Mantido por compatibilidade.
  /// Não é usado no banner.
  final String? textBanner;

  const ContractTabDescriptor({
    required this.label,
    required this.builder,
    this.textBanner,
    this.requireSavedContract = false,
  });
}
