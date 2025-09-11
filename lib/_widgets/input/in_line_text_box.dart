import 'package:flutter/material.dart';

/// ==================== Editor inline ====================
class InlineTextBox extends StatefulWidget {
  const InlineTextBox({super.key,
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  State<InlineTextBox> createState() => InlineTextBoxState();
}

class InlineTextBoxState extends State<InlineTextBox> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 24, maxWidth: 420),
      child: IntrinsicWidth(
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          style: widget.style,
          autofocus: true,
          minLines: 1,
          maxLines: 6,
          cursorColor: widget.style.color,
          decoration: const InputDecoration(
            isDense: true,
            isCollapsed: true,
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            hintText: '',
          ),
          onSubmitted: (_) => widget.onSubmit(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (!widget.focusNode.hasFocus) {
      final txt = widget.controller.text.trim();
      if (txt.isEmpty) {
        widget.onCancel();
      } else {
        widget.onSubmit();
      }
    }
  }
}
