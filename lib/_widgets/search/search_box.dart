import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:flutter/material.dart';

/// Caixa com sombra/borda
class SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSubmit;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final String hintText;

  const SearchBox({super.key,
    required this.controller,
    required this.onSubmit,
    required this.onClear,
    required this.hintText,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Material(
      elevation: 12,
      shadowColor: Colors.black45,
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: Colors.black12),
        ),
        alignment: Alignment.center,
        child: CustomTextField(
          textAlignVertical: TextAlignVertical.center,
          contentPadding: EdgeInsets.zero,             // remove padding vertical
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: onSubmit,
          prefix: const Icon(Icons.search, size: 20, color: Colors.black54),
          suffix: IconButton(
            tooltip: 'Limpar',
            icon: const Icon(Icons.close, size: 18, color: Colors.black45),
            onPressed: () {
              onClear();          // limpa texto
              onClose();          // fecha overlay
            },
            splashRadius: 18,
          ),
        ),
      ),
    );
  }
}
