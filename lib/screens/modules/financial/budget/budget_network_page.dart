import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/financial/loa/loa_cubit.dart';

import 'budget_page.dart';

class BudgetNetworkPage extends StatelessWidget {
  final ContractData? contractData;

  const BudgetNetworkPage({
    super.key,
    this.contractData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LOACubit>(
      create: (_) => LOACubit(),
      child: Scaffold(
        body: BudgetPage(contractData: contractData),
      ),
    );
  }
}
