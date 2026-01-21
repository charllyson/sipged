import 'package:flutter/material.dart';
import 'package:siged/_services/excel/generic_import_excel_page.dart';
import 'package:siged/_widgets/info/tip_box.dart';
import 'package:siged/_widgets/tiles/tile_widget.dart';

import '../../_widgets/buttons/back_circle_button.dart';
import '../../_widgets/menu/upBar/up_bar.dart';

class SettingsTopicConversoresPage extends StatelessWidget {
  const SettingsTopicConversoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    const barHeight = 72.0;
    final topPadding = topSafe + barHeight + 12;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          bottom: false,
          child: UpBar(
            leading: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: BackCircleButton(),
            ),
          ),
        ),
        toolbarHeight: barHeight,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxW = constraints.maxWidth;
          if (constraints.maxWidth >= 1600) maxW = 1100;
          if (constraints.maxWidth >= 1200 && constraints.maxWidth < 1600) maxW = 1000;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                children: [
                  TileWidget(
                    title: 'Excel → JSON (Genérico)',
                    subtitle: 'Converter Excel para JSON (pré-visualizar e salvar local)',
                    leading: Icons.code_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GenericImportExcelPage()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const TipBox(
                    text:
                    'Se quiser, crie aqui também um conversor GeoJSON ↔ Firestore, CSV ↔ JSON, etc.',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}