import 'package:flutter/material.dart';
import 'interativeMap/interative_map.dart';

class NetworkOfRoadsPage extends StatelessWidget {
  const NetworkOfRoadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Stack(
          children: [
            InteractiveMapPage(),
          ],
        )
      ),
    );
  }
}