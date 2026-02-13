import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_cubit.dart';

import 'empenho_page.dart';

class EmpenhoNetworkPage extends StatelessWidget {
  final ProcessData? contractData;

  const EmpenhoNetworkPage({
    super.key,
    this.contractData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmpenhoCubit>(
      create: (_) => EmpenhoCubit(),
      child: Scaffold(
        body: EmpenhoPage(contractData: contractData),
      ),
    );
  }
}
