// ignore_for_file: unused_import

import 'package:flutter/material.dart';

import '../../_datas/user/user_data.dart';
import '../../sideMenu.dart';
import '../commons/upBar/pupUpMenu.dart';
import 'interativeMap/interativeMap.dart';
import '../../sideMenuPage.dart';

class NetworkOfRoadsPage extends StatelessWidget {
  const NetworkOfRoadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Stack(
          children: [
            InterativeMap(),
          ],
        )
      ),
    );
  }
}