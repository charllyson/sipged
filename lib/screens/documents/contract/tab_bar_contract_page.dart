import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/popUpMenu/pup_up_photo_menu.dart';
import 'package:siged/screens/documents/contract/validity/validity_page.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_bloc.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'additive/additive_page.dart';
import 'apostilles/apostilles_page.dart';
import '../../../_widgets/table/magic/magic_table_controller.dart';
import 'budget/budget_page.dart';
import 'mainInformation/main_information_page.dart';
import 'mainInformation/main_manager_section.dart';

class TabBarContractPage extends StatefulWidget {
  final UserData? userData;
  final ContractData? contractData;
  final ContractBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarContractPage({
    super.key,
    this.userData,
    this.contractData,
    this.initialTabIndex = 0,
    this.contractsBloc,
  });

  @override
  State<TabBarContractPage> createState() => _TabBarContractPageState();
}

class _TabBarContractPageState extends State<TabBarContractPage> {
  late ContractData? _contractData;

  @override
  void initState() {
    super.initState();
    _contractData = widget.contractData;
  }

  @override
  Widget build(BuildContext context) {
    // ======= lógica da UpBar: safeTop + altura visual da barra =======
    final double safeTop = MediaQuery.of(context).padding.top; // iOS notch/Android status bar (no web = 0)
    const double barHeight = 72.0;                              // sua faixa azul
    final double topBarTotal = safeTop + barHeight;

    return DefaultTabController(
      length: 5,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const BackgroundClean(),

            // Conteúdo deslocado para baixo da barra (safeTop + 72)
            Padding(
              padding: EdgeInsets.only(top: topBarTotal),
              child: Column(
                children: [
                  // Banner com resumo (se houver)
                  if ((_contractData?.summarySubjectContract?.trim().isNotEmpty ?? false))
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade200,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        _contractData!.summarySubjectContract!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),

                  // Conteúdo das abas
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // 1) Processo licitatório
                        MainManagerSection(
                          key: ValueKey(_contractData?.id),
                          contractData: _contractData,
                          onSaved: (updated) {
                            setState(() {
                              _contractData = updated;
                            });
                          },
                        ),

                        // 2) Vigências
                        _wrapWithBlocker(
                              () => ValidityPage(
                            key: ValueKey(_contractData?.id),
                            contractData: _contractData!, // <- seguro: só é avaliado quando há id
                          ),
                        ),

                        // 3) Aditivos
                        _wrapWithBlocker(
                              () => AdditivePage(
                            key: ValueKey(_contractData?.id),
                            contractData: _contractData!,
                          ),
                        ),

                        // 4) Apostilamentos
                        _wrapWithBlocker(
                              () => ApostillesPage(
                            key: ValueKey(_contractData?.id),
                            contractData: _contractData!,
                          ),
                        ),

                        // 5) Planilha orçamentária
                        _wrapWithBlocker(
                              () => ChangeNotifierProvider(
                            create: (_) => MagicTableController(cellPadHorizontal: 24),
                            child: BudgetPage(
                              key: ValueKey(_contractData?.id),
                              contractData: _contractData!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),

            // ======= Barra azul estilo UpBar (reserva safeTop internamente) =======
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
                padding: EdgeInsets.only(top: safeTop), // << UpBar logic aqui
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
                          Tab(text: 'Processo licitatório'),
                          Tab(text: 'Vigências'),
                          Tab(text: 'Aditivos'),
                          Tab(text: 'Apostilamentos'),
                          Tab(text: 'Planilha orçamentária'),
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
  Widget _wrapWithBlocker(Widget Function() childBuilder) {
    final hasId = _contractData?.id != null;
    if (!hasId) {
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
    // Só constrói o conteúdo quando há ID (evita avaliar _contractData!)
    return childBuilder();
  }

}
