import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/screens/modules/contracts/measurement/physics_finance/physfin_widget.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

class HiringSchedulePage extends StatelessWidget {
  final ContractData contract;

  const HiringSchedulePage({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UpBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: const CircleButtonChange(),
        ),
      ),
      body: PhysFinWidget(
        contractData: contract,
        chronogramMode: false,
      ),
    );
  }
}
