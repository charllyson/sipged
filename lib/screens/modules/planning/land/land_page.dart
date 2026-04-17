import 'package:flutter/material.dart';

import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/screens/modules/planning/land/map/land_map.dart';
import 'package:sipged/screens/modules/planning/land/land_panel.dart';

class LandPage extends StatefulWidget {
  final ProcessData contractData;

  const LandPage({
    super.key,
    required this.contractData,
  });

  @override
  State<LandPage> createState() => _LandPageState();
}

class _LandPageState extends State<LandPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: UpBar(
        leading: BackCircleButton(),
        actions: [
          IconButton(
            tooltip: 'Mostrar painel',
            icon: const Icon(
              Icons.view_sidebar_outlined,
              color: Colors.white,
            ),
            onPressed: _openDrawer,
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: LandPanel(
            contractData: widget.contractData,
          ),
        ),
      ),
      body: LandMap(
        contractData: widget.contractData,
      ),
    );
  }
}