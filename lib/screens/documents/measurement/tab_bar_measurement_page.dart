import 'package:flutter/material.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/popUpMenu/pup_up_photo_menu.dart';
import 'package:siged/screens/documents/measurement/report/report_measurement_page.dart';
import 'package:siged/screens/documents/measurement/revision/revision_measurement_page.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_bloc.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
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
    // ======= lógica UpBar: status bar (safeTop) + altura da barra =======
    final double safeTop = MediaQuery.of(context).padding.top; // iOS/Android; no web costuma ser 0
    const double barHeight = 72.0;                              // sua faixa azul
    final double topBarTotal = safeTop + barHeight;

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const BackgroundClean(),

            // Conteúdo deslocado para baixo da barra
            Padding(
              padding: EdgeInsets.only(top: topBarTotal),
              child: Column(
                children: [
                  if ((_contractData?.summarySubjectContract?.trim().isNotEmpty ?? false))
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade200,
                          border: Border.all(color: Colors.grey),
                        ),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
                      physics: const NeverScrollableScrollPhysics(), // impede o swipe
                      children: [
                        // 1) Boletim
                        ReportMeasurement(
                          contractData: widget.contractData!,
                        ),

                        // 2) Reajustamento
                        _wrapWithBlocker(
                          AdjustmentMeasurement(
                            contractData: _contractData!,
                          ),
                        ),

                        // 3) Revisões
                        _wrapWithBlocker(
                          RevisionMeasurement(
                            contractData: _contractData!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ======= Barra azul no topo (reserva do safeTop internamente) =======
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: topBarTotal,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B2031), Color(0xFF1B2039)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 1),
                  ),
                ),
                padding: EdgeInsets.only(top: safeTop), // << respeita notch/status bar
                child: Row(
                  children: const [
                    SizedBox(width: 12),
                    BackCircleButton(),
                    Expanded(
                      child: TabBar(
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
                    SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bloqueia a aba quando o contrato ainda não foi salvo (id nulo)
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
