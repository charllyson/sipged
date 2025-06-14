import 'package:flutter/material.dart';
import 'package:sisgeo/screens/commons/contracts/list_contract_page.dart';
import 'package:sisgeo/screens/directors/operation/execution/list_only_read_contract_page.dart';
import 'package:sisgeo/screens/directors/transportAndTransit/transport_transit_page.dart';
import 'package:sisgeo/screens/general/networkOfRoads/network_of_roads.dart';
import 'package:sisgeo/drawer_menu.dart';
import '_widgets/buttons/float_button_menu.dart';

class SideMenuPage extends StatefulWidget {
  const SideMenuPage({super.key});

  @override
  State<SideMenuPage> createState() => _SideMenuPageState();
}

class _SideMenuPageState extends State<SideMenuPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ListContractPage(), ///01
    const NetworkOfRoadsPage(), ///02
    const ListOnlyReadContractPage(), ///03
    const ListOnlyReadContractPage(), ///04
    const TransportTransitPage(), ///05
    const TransportTransitPage(), ///06
  ];

  void _onSelectPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).pop(); // fecha o Drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerMenu(onTap: _onSelectPage),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          FloatButtonMenu()
        ],
      ),
    );
  }
}
