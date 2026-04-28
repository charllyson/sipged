import 'package:flutter/material.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.onClear,
    required this.hintText,
    required this.onClose,
    this.hintColor,
  });

  final TextEditingController controller;
  final void Function(String) onSubmit;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final String hintText;
  final Color? hintColor;

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
          controller: controller,
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor ?? Colors.black38,
            fontSize: 13,
          ),
          textAlignVertical: TextAlignVertical.center,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 0,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: onSubmit,
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Colors.black54,
          ),
          suffix: IconButton(
            tooltip: 'Limpar',
            icon: const Icon(
              Icons.close,
              size: 18,
              color: Colors.black45,
            ),
            onPressed: () {
              onClear();
              onClose();
            },
            splashRadius: 18,
          ),
        ),
      ),
    );
  }
}