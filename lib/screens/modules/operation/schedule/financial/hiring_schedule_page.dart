import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/schedule/physical_financial/schedule_physical_financial_widget.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

class HiringSchedulePage extends StatelessWidget {
  final ProcessData contract;

  const HiringSchedulePage({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UpBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: const BackCircleButton(),
        ),
      ),
      body: SchedulePhysicalFinancialWidget(
        contractData: contract,
        chronogramMode: false,
      ),
    );
  }
}
