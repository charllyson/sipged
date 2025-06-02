import 'package:flutter/material.dart';
import 'package:sisgeo/_class/theme/darkTheme.dart';
import 'package:sisgeo/screens/adm/bd/bdPage.dart';
import '../../sideMenu.dart';
import '../../sideMenuPage.dart';
import '../commons/upBar/pupUpMenu.dart';

class AdmPage extends StatefulWidget {
  const AdmPage({super.key});

  @override
  State<AdmPage> createState() => _AdmPageState();
}

class _AdmPageState extends State<AdmPage> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DarkAdminTheme.theme,
      child: DefaultTabController(
        length: 1,
        child: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.orange,
                  indicatorColor: Colors.orange,
                  isScrollable: true,
                  tabs: [
                    Tab(
                        text: 'Banco de dados',
                        icon: Icon(Icons.security_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: TabBarView(
                      children: [
                        FirestoreDatabase(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
