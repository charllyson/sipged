// lib/screens/modules/actives/oaes/network/details_panel_body.dart
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

/// Painel de detalhes com campos somente leitura.
class DetailsPanelBody extends StatelessWidget {
  const DetailsPanelBody({
    super.key,
    required this.entries,
  });

  /// Lista de pares (rótulo, valor) exibidos no painel.
  final List<MapEntry<String, String>> entries;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (final kv in entries) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: CustomTextField(
                labelText: kv.key,
                enabled: false,
                initialValue: kv.value,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
