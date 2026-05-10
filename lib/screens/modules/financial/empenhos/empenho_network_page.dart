import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_cubit.dart';

import 'empenho_page.dart';

class EmpenhoNetworkPage extends StatelessWidget {
  const EmpenhoNetworkPage({
    super.key,
    this.contractData,
  });

  final ContractData? contractData;

  @override
  Widget build(BuildContext context) {
    final permissionState = context.read<PermissionCubit>().state;

    return BlocProvider<EmpenhoCubit>(
      create: (_) {
        return EmpenhoCubit(
          initialPermissions: permissionState.current,
          initialTenantId: permissionState.activeTenantId,
        );
      },
      child: Scaffold(
        body: EmpenhoPage(contractData: contractData),
      ),
    );
  }
}