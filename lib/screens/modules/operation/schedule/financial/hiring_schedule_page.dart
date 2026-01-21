import 'package:flutter/material.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/schedule/physical_financial/schedule_physical_financial_widget.dart';
import 'package:siged/_widgets/menu/upBar/up_bar.dart';

class HiringSchedulePage extends StatelessWidget {
  final ProcessData contract;

  const HiringSchedulePage({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: UpBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: const BackCircleButton(),
            ),
          )),
      body: SchedulePhysicalFinancialWidget(
        contractData: contract,
        chronogramMode: false,
      ),
    );
  }
}
