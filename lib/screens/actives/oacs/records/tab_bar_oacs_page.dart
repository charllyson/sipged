import 'package:flutter/material.dart';
import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';

import 'oac_details_page.dart';
import 'oac_inspections_page.dart';
import 'oac_documents_page.dart';

class TabBarOacsPage extends StatelessWidget {
  const TabBarOacsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabChangedWidget(
      tabs: [
        ContractTabDescriptor(
          label: 'Dados',
          builder: (_) => const OacDetailsPage(),
          requireSavedContract: false,
        ),
        ContractTabDescriptor(
          label: 'Inspeções',
          builder: (_) => const OacInspectionsPage(),
          requireSavedContract: false,
        ),
        ContractTabDescriptor(
          label: 'Documentos',
          builder: (_) => const OacDocumentsPage(),
          requireSavedContract: false,
        ),
      ],
      topBarColors: const [Color(0xFF1B2031), Color(0xFF1B2039)],
      tabsIsScrollable: true,
      tabAlignment: TabAlignment.start,
    );
  }
}
