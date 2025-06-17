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
  });

  final void Function(String?)? onChanged;
  final List<String> items;
  final String? labelText;
  final TextEditingController controller;
  final bool? enabled;
  final String? Function(String?)? validator;

  @override
  State<DropDownButtonChange> createState() => _DropDownButtonChangeState();
}

class _DropDownButtonChangeState extends State<DropDownButtonChange> {
  String? selectedTypes;

  @override
  void initState() {
    super.initState();
    selectedTypes = widget.controller.text.isNotEmpty ? widget.controller.text : null;
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled ?? true;

    return DropdownButtonFormField<String>(
      validator: widget.validator,
      dropdownColor: Colors.white,
      value: widget.items.contains(widget.controller.text) ? widget.controller.text : null,
      items: widget.items.map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
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
      decoration: InputDecoration(
        fillColor: isEnabled ? Colors.white : Colors.grey.shade200,
        filled: true,
        labelText: widget.labelText,
        labelStyle: TextStyle(color: isEnabled ? Colors.grey : Colors.grey.shade500),
        hintStyle: TextStyle(color: isEnabled ? Colors.grey : Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isEnabled ? Colors.grey : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isEnabled ? Colors.blue : Colors.grey.shade400),
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
    );
  }

}
