import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/screens/adm/bd/bdPage.dart';
import 'package:sisgeo/screens/commons/upBar/pupUpMenu.dart';
import 'package:sisgeo/screens/contracts/contractListMenuPage.dart';
import 'package:sisgeo/screens/dashboard/dashboard.dart';
import 'package:sisgeo/screens/networkOfRoads/networkOfRoads.dart';
import 'package:sisgeo/sideMenu.dart';

class SideMenuPage extends StatefulWidget {
  const SideMenuPage({super.key});

  @override
  State<SideMenuPage> createState() => _SideMenuPageState();
}

class _SideMenuPageState extends State<SideMenuPage> {
  int _selectedIndex = 0;
  bool _scrolled = false;

  final List<String> _pageTitles = [
    'Dashboard',
    'Contratos',
    'Malha Rodoviária',
  ];

  final List<Widget> _pages = const [
    DashboardPage(),
    ContractListMenuPage(),
    NetworkOfRoadsPage(),
    FirestoreDatabase()
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 20 && !_scrolled) {
        setState(() => _scrolled = true);
      } else if (_scrollController.offset <= 20 && _scrolled) {
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
