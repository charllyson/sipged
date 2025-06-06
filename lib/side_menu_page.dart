import 'package:flutter/material.dart';
import 'package:sisgeo/screens/commons/contracts/contract_list_menu_page.dart';
import 'package:sisgeo/screens/commons/upBar/pup_up_menu.dart';
import 'package:sisgeo/screens/general/networkOfRoads/network_of_roads.dart';
import 'package:sisgeo/screens/management/dashboard/dashboard.dart';
import 'package:sisgeo/side_menu.dart';

import '_widgets/schedule/physical_schedule.dart';
import 'adm/bd/bd_page.dart';

class SideMenuPage extends StatefulWidget {
  const SideMenuPage({super.key});

  @override
  State<SideMenuPage> createState() => _SideMenuPageState();
}

class _SideMenuPageState extends State<SideMenuPage> {
  int _selectedIndex = 0;
  bool _scrolled = false;

  final List<String> _pageTitles = [
    'GESTÃO',
    'OPERAÇÕES',
    'ADMINISTRATIVO',
    'FINANCEIRO',
    'PLANEJAMENTO',
    'MALHA RODOVIÁRIA',
  ];

  final List<Widget> _pages = [
    const ContractListMenuPage(),
    const DashboardPage(),
    const DashboardPage(),
    const DashboardPage(),
    const DashboardPage(),
    const NetworkOfRoadsPage(),
    const FirestoreDatabase(),
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_scrolled) {
        setState(() => _scrolled = true);
      } else if (_scrollController.offset <= 50 && _scrolled) {
        setState(() => _scrolled = false);
      }
    });
  }

  void _onSelectPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(onTap: _onSelectPage),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: _scrolled ? Colors.black26 : Colors.white,
            title: Text(_pageTitles[_selectedIndex], style: TextStyle(color: _scrolled ? Colors.white : Colors.black)),
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: _scrolled ? Colors.white : Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: const [PopUpMenu()],
          ),
        ],
        body: _pages[_selectedIndex],
      ),
    );
  }
}
