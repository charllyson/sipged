import 'package:flutter/material.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

class InfractionsDashboardPage extends StatelessWidget {
  const InfractionsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          BackgroundChange(),
          Column(
            children: [
              UpBar(),
              Expanded(
                child: Center(
                  child: Text(
                    'Dashboard de infrações em desenvolvimento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}