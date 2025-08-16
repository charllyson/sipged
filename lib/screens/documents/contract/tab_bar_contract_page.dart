import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_widgets/background/background_cleaner.dart';
import 'package:sisged/screens/documents/contract/validity/validity_page.dart';

import '../../../../_datas/system/user_data.dart';
import '../../../../_widgets/buttons/back_circle_button.dart';
import '../../../_blocs/documents/contracts/contracts/contracts_bloc.dart';
import '../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../commons/popUpMenu/pup_up_menu.dart';
import 'additive/additive_page.dart';
import 'apostilles/apostilles_page.dart';
import 'budget/budget_controller.dart';
import 'budget/budget_page.dart';
import 'mainInformation/main_information_page.dart';

class TabBarContractPage extends StatefulWidget {
  final UserData? userData;
  final ContractData? contractData;
  final ContractsBloc? contractsBloc;
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
    return DefaultTabController(
      length: 5,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const BackgroundCleaner(),
            Builder(
              builder: (context) => Column(
                children: [
                  Container(
                    height: 72,
                    color: const Color(0xFF1B2033),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const BackCircleButton(),
                        const Expanded(
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
                        const PopUpMenu(),
                      ],
                    ),
                  ),

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

                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // 1) Processo licitatório (informações principais)
                        MainInformationPage(
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
                          ValidityPage(
                            key: ValueKey(_contractData?.id),
                            contractData: _contractData!,
                          ),
                        ),

                        // 3) Aditivos
                        _wrapWithBlocker(
                          AdditivePage(
                            key: ValueKey(_contractData?.id),
                            contractData: _contractData!,
                          ),
                        ),

                        // 4) Apostilamentos
                        _wrapWithBlocker(
                          ApostillesPage(
                            key: ValueKey(_contractData?.id),
                            contractData: _contractData!,
                          ),
                        ),

                        // 5) Planilha orçamentária (Provider local ao tab)
                        _wrapWithBlocker(
                          ChangeNotifierProvider(
                            create: (_) => BudgetController(cellPadHorizontal: 24),
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
