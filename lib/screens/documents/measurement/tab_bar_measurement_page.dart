import 'package:flutter/material.dart';
import 'package:sisged/_widgets/background/background_cleaner.dart';
import 'package:sisged/_widgets/popUpMenu/pup_up_photo_menu.dart';
import 'package:sisged/screens/documents/measurement/report/report_measurement_page.dart';
import 'package:sisged/screens/documents/measurement/revision/revision_measurement_page.dart';
import 'package:sisged/_blocs/system/user/user_data.dart';
import 'package:sisged/_widgets/buttons/back_circle_button.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'adjustment/adjustment_measurement_page.dart';

class TabBarMeasurementPage extends StatefulWidget {

  final UserData? userData;
  final ContractData? contractData;
  final ContractBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarMeasurementPage({
    super.key,
    this.userData,
    this.contractData,
    this.initialTabIndex = 0,
    this.contractsBloc,
  });


  @override
  State<TabBarMeasurementPage> createState() => _TabBarMeasurementPageState();
}

class _TabBarMeasurementPageState extends State<TabBarMeasurementPage> {
  late ContractData? _contractData;

  @override
  void initState() {
    super.initState();
    _contractData = widget.contractData;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            BackgroundClean(),
            Builder(
              builder:
                  (context) => Column(
                    children: [
                      Container(
                        height: 72,
                        color: const Color(0xFF1B2033),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            BackCircleButton(),
                            Expanded(
                              child: const TabBar(
                                isScrollable: true,
                                dividerHeight: 0,
                                physics: NeverScrollableScrollPhysics(),
                                labelColor: Colors.white,
                                indicatorColor: Colors.white,
                                unselectedLabelColor: Colors.grey,
                                tabs: [
                                  Tab(text: 'Boletim'),
                                  Tab(text: 'Reajustamento'),
                                  Tab(text: 'Revisões'),
                                ],
                              ),
                            ),
                            PopUpPhotoMenu(),
                          ],
                        ),
                      ),


                      if ((_contractData?.summarySubjectContract
                              ?.trim()
                              .isNotEmpty ??
                          false))
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade200,
                              border: Border.all(color: Colors.grey),
                            ),
                            width: double.infinity,
                            child: Text(
                              _contractData!.summarySubjectContract!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Expanded(
                        child: TabBarView(
                          physics:
                              const NeverScrollableScrollPhysics(), // impede o swipe
                          children: [
                            ReportMeasurement(
                                contractData: widget.contractData!
                            ),
                            _wrapWithBlocker(
                                AdjustmentMeasurement(
                                contractData: _contractData!
                            )),
                            _wrapWithBlocker(
                                RevisionMeasurement(
                                contractData: _contractData!
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrapWithBlocker(Widget child) {
    if (_contractData?.id == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '⚠️ Para acessar esta aba, salve primeiro as informações principais do contrato.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.red.shade700),
          ),
        ),
      );
    }
    return child;
  }
}
