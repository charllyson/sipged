// lib/screens/sectors/planning/rightWay/tab_bar_right_way_page.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/menu/pop_up/pup_up_photo_menu.dart';
import 'package:siged/screens/sectors/financial/payments/adjustment/payments_adjustment_page.dart';
import 'package:siged/screens/sectors/financial/payments/revision/payments_revision_page.dart';
import 'package:siged/_blocs/process/contracts/contract_bloc.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';

// >>> NOVOS imports
import 'package:siged/screens/process/landRegularization/lane_regularization_property_form.dart';
import 'package:siged/_blocs/process/laneRegularization/lane_regularization_controller.dart';
import 'package:siged/_blocs/process/laneRegularization/lane_regularization_store.dart';

class TabBarRightWayPage extends StatefulWidget {
  final UserData? userData;
  final ContractData? contractData;
  final ContractBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarRightWayPage({
    super.key,
    this.userData,
    this.contractData,
    this.initialTabIndex = 0,
    this.contractsBloc,
  });

  @override
  State<TabBarRightWayPage> createState() => _TabBarRightWayPageState();
}

class _TabBarRightWayPageState extends State<TabBarRightWayPage> {
  late ContractData? _contractData;

  // >>> NOVO: controller e store do módulo
  late final LaneRegularizationStore _store;
  LaneRegularizationController? _propCtrl;

  @override
  void initState() {
    super.initState();
    _contractData = widget.contractData;

    _store = LaneRegularizationStore();
    if (_contractData != null) {
      _propCtrl = LaneRegularizationController(
        contract: _contractData!,
        store: _store,
      );
    }
  }

  @override
  void dispose() {
    _propCtrl?.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double safeTop = MediaQuery.of(context).padding.top;
    const double barHeight = 72.0;
    final double topBarTotal = safeTop + barHeight;

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const BackgroundClean(),

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
                    ),

                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // ====== ABA 1: IMÓVEL =================================
                        _wrapWithBlocker(
                          child: _propCtrl == null
                              ? const SizedBox.shrink()
                              : Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: LaneRegularizationPropertyForm(
                              controller: _propCtrl!,
                            ),
                          ),
                        ),

                        // ====== ABA 2: Pagamentos de Reajustes =================
                        _wrapWithBlocker(
                          child: PaymentsAdjustmentPage(contractData: _contractData),
                        ),

                        // ====== ABA 3: Pagamentos de Revisões ==================
                        _wrapWithBlocker(
                          child: PaymentsRevisionPage(contractData: _contractData),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ======= Barra azul no topo =======================================
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
                padding: EdgeInsets.only(top: safeTop),
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
                          Tab(text: 'Imóvel'),
                          Tab(text: 'Notificação'),
                          Tab(text: 'Pagamento'),
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

  Widget _wrapWithBlocker({required Widget child}) {
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
