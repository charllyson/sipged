import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';

class LayerGeneralEditor extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onSubmit;

  const LayerGeneralEditor({
    super.key,
    required this.nameController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A aba Geral foi propositalmente reduzida para conter
              // apenas os dados básicos da camada.
              CustomTextField(
                controller: nameController,
                labelText: 'Nome da camada',
                onSubmitted: (_) => onSubmit(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}