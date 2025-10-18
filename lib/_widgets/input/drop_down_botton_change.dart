import 'package:flutter/material.dart';

class DropDownButtonChange extends StatefulWidget {
  const DropDownButtonChange({
    super.key,
    required this.items,
    this.labelText,
    required this.controller,
    this.onChanged,
    this.enabled,
    this.validator,
    this.width,
  });

  final void Function(String?)? onChanged;
  final List<String> items;
  final String? labelText;
  final TextEditingController controller;
  final bool? enabled;
  final String? Function(String?)? validator;
  final double? width;

  @override
  State<DropDownButtonChange> createState() => _DropDownButtonChangeState();
}

class _DropDownButtonChangeState extends State<DropDownButtonChange> {
  String? selectedTypes;

  @override
  void initState() {
    super.initState();
    selectedTypes = widget.items.contains(widget.controller.text)
        ? widget.controller.text
        : null;
  }

  @override
  void didUpdateWidget(covariant DropDownButtonChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.text != selectedTypes) {
      setState(() {
        selectedTypes = widget.items.contains(widget.controller.text)
            ? widget.controller.text
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled ?? true;

    return SizedBox(
      width: widget.width ?? 160, // um pouco maior evita apertos desnecessários
      child: DropdownButtonFormField<String>(
        isDense: true,
        isExpanded: true, // ✅ evita overflow horizontal
        menuMaxHeight: 200,
        validator: widget.validator,
        dropdownColor: Colors.white,
        value: selectedTypes,
        // ✅ garante truncamento do item selecionado
        selectedItemBuilder: (ctx) => widget.items
            .map((v) => Align(
          alignment: Alignment.centerLeft,
          child: Text(
            v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ))
            .toList(),

        items: widget.items.map((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          );
        }).toList(),

        onChanged: isEnabled
            ? (selected) {
          setState(() {
            selectedTypes = selected;
            widget.controller.text = selected ?? '';
          });
          widget.onChanged?.call(selected);
        }
            : null,

        iconSize: 20, // (opcional) diminui o espaço do ícone
        decoration: InputDecoration(
          fillColor: isEnabled ? Colors.white : Colors.grey.shade200,
          filled: true,
          labelText: widget.labelText,
          labelStyle: TextStyle(
              color: isEnabled ? Colors.grey : Colors.grey.shade500),
          hintStyle:
          TextStyle(color: isEnabled ? Colors.grey : Colors.grey.shade400),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 14), // ↓
          enabledBorder: OutlineInputBorder(
            borderSide:
            BorderSide(color: isEnabled ? Colors.grey : Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
            BorderSide(color: isEnabled ? Colors.blue : Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade700),
            borderRadius: BorderRadius.circular(10),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
