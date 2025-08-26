import 'package:flutter/material.dart';
import 'package:sisged/_widgets/background/background_cleaner.dart';
import 'package:sisged/_widgets/popUpMenu/pup_up_photo_menu.dart';
import 'package:sisged/screens/sectors/financial/payments/adjustment/payments_adjustment_page.dart';
import 'package:sisged/screens/sectors/financial/payments/report/payment_report_page.dart';
import 'package:sisged/screens/sectors/financial/payments/revision/payments_revision_page.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_blocs/system/user/user_data.dart';

class TabBarFinancialPage extends StatefulWidget {

  final UserData? userData;
  final ContractData? contractData;
  final ContractBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarFinancialPage({
    super.key,
    this.userData,
    this.contractData,
    this.initialTabIndex = 0,
    this.contractsBloc,
  });


  @override
  State<TabBarFinancialPage> createState() => _TabBarFinancialPageState();
}

class _TabBarFinancialPageState extends State<TabBarFinancialPage> {
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
                            Builder(
                              builder: (context) => Material(
                                elevation: 6,
                                shape: const CircleBorder(),
                                color: Colors.transparent,
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade900
                                      : Colors.white,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back, size: 22),
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: const TabBar(
                                isScrollable: true,
                                dividerHeight: 0,
                                physics: NeverScrollableScrollPhysics(),
                                labelColor: Colors.white,
                                indicatorColor: Colors.white,
                                unselectedLabelColor: Colors.grey,
                                tabs: [
                                  Tab(text: 'Pagamentos de Medições'),
                                  Tab(text: 'Pagamentos de Apostilamentos'),
                                  Tab(text: 'Pagamentos de Revisões'),
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
                            PaymentsReportPage(contractData: _contractData),
                            _wrapWithBlocker(PaymentsAdjustmentPage(contractData: _contractData)),
                            _wrapWithBlocker(PaymentsRevisionPage(contractData: _contractData)),
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
