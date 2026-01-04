// lib/screens/sectors/actives/roads/tab_bar_roads_page.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';

import 'package:siged/_blocs/actives/roads/active_roads_data.dart';
import 'road_details_page.dart';

class TabBarRoadsPage extends StatelessWidget {
  const TabBarRoadsPage({
    super.key,
    this.editing,
  });

  /// Registro sendo editado (null = nova rodovia)
  final ActiveRoadsData? editing;

  @override
  Widget build(BuildContext context) {
    return TabChangedWidget(
      tabs: [
        ContractTabDescriptor(
          label: 'Dados',
          builder: (_) => RoadDetailsPage(editing: editing),
          requireSavedContract: false,
        ),
      ],
      topBarColors: const [Color(0xFF1B2031), Color(0xFF1B2039)],
      tabsIsScrollable: true,
      tabAlignment: TabAlignment.start,
    );
  }
}
