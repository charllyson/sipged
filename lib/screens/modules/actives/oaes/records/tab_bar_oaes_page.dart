import 'package:flutter/material.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';

import 'oae_details_page.dart';

class TabBarOaesPage extends StatelessWidget {
  const TabBarOaesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabChanged(
      tabs: [
        ContractTabDescriptor(
          label: 'Dados',
          builder: (_) => OaeDetailsPage(),
          requireSavedContract: false,
        ),
      ],
      topBarColors: const [Color(0xFF1B2031), Color(0xFF1B2039)],
      tabsIsScrollable: true,
      tabAlignment: TabAlignment.start,
    );
  }
}
