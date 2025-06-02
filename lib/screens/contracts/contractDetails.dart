import 'package:flutter/material.dart';
import 'package:sisgeo/_widgets/background/backgroundCleaner.dart';
import 'package:sisgeo/screens/contracts/apostilamento/apostillesPage.dart';
import 'package:sisgeo/screens/contracts/validity/validityPage.dart';
import '../../_datas/contracts/contracts_data.dart';
import '../../_datas/user/user_data.dart';
import '../../sideMenu.dart';
import '../../sideMenuPage.dart';
import '../commons/upBar/pupUpMenu.dart';
import 'additive/additivePage.dart';
import 'mainInformation/mainInformationPage.dart';
import 'measurement/measurementPage.dart';

class ContractDetailsPage extends StatefulWidget {
  const ContractDetailsPage({super.key, this.userData, this.contractData});
  final UserData? userData;
  final ContractData? contractData;

  @override
  State<ContractDetailsPage> createState() => _ContractDetailsPageState();
}

class _ContractDetailsPageState extends State<ContractDetailsPage> {



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        drawer: SideMenu(onTap: (index) {
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
                    Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                            ),
                            PopUpMenu()
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const TabBar(
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TabBarView(
                          children: [
                            MainInformationPage(contractData: widget.contractData),
                            ValidityPage(contractData: widget.contractData),
                            AdditivePage(contractData: widget.contractData),
                            ApostillesPage(contractData: widget.contractData),
                            MeasurementPage(contractData: widget.contractData),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
            ),
          ],
        ),
      ),
    );
  }
}
