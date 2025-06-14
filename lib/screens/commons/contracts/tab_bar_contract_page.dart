import 'package:flutter/material.dart';
import 'package:sisgeo/_widgets/background/background_cleaner.dart';
import 'package:sisgeo/_widgets/buttons/float_button_menu.dart';
import 'package:sisgeo/screens/commons/contracts/validity/validity_page.dart';
import '../../../_datas/contracts/contracts_data.dart';
import '../../../_datas/user/user_data.dart';
import '../../../_widgets/schedule/physical_schedule.dart';
import '../../../drawer_menu.dart';
import '../../../side_menu_page.dart';
import 'additive/additive_page.dart';
import 'apostilles/apostilles_page.dart';
import 'mainInformation/main_information_page.dart';
import 'measurement/measurement_page.dart';

class TabBarContractPage extends StatefulWidget {
  const TabBarContractPage({super.key, this.userData, this.contractData});
  final UserData? userData;
  final ContractData? contractData;

  @override
  State<TabBarContractPage> createState() => _TabBarContractPageState();
}

class _TabBarContractPageState extends State<TabBarContractPage> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        drawer: DrawerMenu(onTap: (index) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => SideMenuPage()),
          );
        }),
        body: Stack(
          children: [
            BackgroundCleaner(),
            Builder(
              builder: (context) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 12),
                      child: const TabBar(
                        isScrollable: true,
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: Colors.blue,
                        tabs: [
                          Tab(text: 'Principais Informações'),
                          Tab(text: 'Vigências'),
                          Tab(text: 'Aditivos'),
                          Tab(text: 'Apostilamentos'),
                          Tab(text: 'Medições'),
                          Tab(text: 'Cronograma Físico'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TabBarView(
                          children: [
                            MainInformationPage(contractData: widget.contractData),
                            _wrapWithBlocker(ValidityPage(contractData: widget.contractData)),
                            _wrapWithBlocker(AdditivePage(contractData: widget.contractData)),
                            _wrapWithBlocker(ApostillesPage(contractData: widget.contractData)),
                            _wrapWithBlocker(MeasurementPage(contractData: widget.contractData)),
                            _wrapWithBlocker(PhysicalSchedule(contractData: widget.contractData)),
                          ],
                        ),

                      ),
                    ),
                  ],
                )
            ),
            FloatButtonMenu()
          ],
        ),
      ),
    );
  }

  Widget _wrapWithBlocker(Widget child) {
    if (widget.contractData?.id == null) {
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
