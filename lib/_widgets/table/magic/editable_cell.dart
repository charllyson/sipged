import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableCell extends StatelessWidget {
  const EditableCell({
    super.key,
    required this.isEditing,
    required this.controller,
    required this.focusNode,
    required this.text,
    required this.textStyle,
    required this.textAlign,
    this.keyboardType,
    this.inputFormatters,
    this.onSubmitted,
    this.onTapOutside,
  });

  final bool isEditing;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String text;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<PointerDownEvent>? onTapOutside;

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      return Text(text, style: textStyle, textAlign: textAlign);
    }
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      enableInteractiveSelection: true,
      mouseCursor: SystemMouseCursors.text,
      decoration: const InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      textAlign: textAlign,
      maxLines: 1,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      onEditingComplete: () => onSubmitted?.call(controller.text),
      onTapOutside: onTapOutside,
      style: textStyle,
      scrollPadding: EdgeInsets.zero,
    );
  }
}
