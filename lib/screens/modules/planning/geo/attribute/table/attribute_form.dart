import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

class AttributeForm extends StatelessWidget {
  final List<String> columns;
  final Map<String, TextEditingController> controllers;
  final bool hasSelection;
  final void Function(String field, String value) onChangedField;

  const AttributeForm({
    super.key,
    required this.columns,
    required this.controllers,
    required this.hasSelection,
    required this.onChangedField,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasSelection
                  ? 'Propriedades da feição selecionada'
                  : 'Selecione uma linha para visualizar e editar os atributos',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (columns.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nenhuma coluna disponível.'),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: columns.map((column) {
                  final controller =
                      controllers[column] ?? TextEditingController();

                  return SizedBox(
                    width: 260,
                    child: CustomTextField(
                      controller: controller,
                      labelText: column,
                      readOnly: !hasSelection,
                      enabled: hasSelection,
                      maxLines: 1,
                      fillCollor:
                      hasSelection ? Colors.white : Colors.grey.shade200,
                      onChanged: (value) => onChangedField(column, value),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}