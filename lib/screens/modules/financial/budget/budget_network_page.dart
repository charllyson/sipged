import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/financial/budget/budget_cubit.dart';

import 'budget_page.dart';

class BudgetNetworkPage extends StatelessWidget {
  final ProcessData? contractData;

  const BudgetNetworkPage({
    super.key,
    this.contractData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BudgetCubit>(
      create: (_) => BudgetCubit(),
      child: Scaffold(
        body: BudgetPage(contractData: contractData),
      ),
    );
  }
}
