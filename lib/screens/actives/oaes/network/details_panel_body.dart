import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

/// ============================== SUBWIDGETS ==============================
class DetailsPanelBody extends StatelessWidget {
  const DetailsPanelBody({super.key, required this.entries});

  final List<MapEntry<String, String>> entries;

  @override
  Widget build(BuildContext context) {
    return Padding(
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