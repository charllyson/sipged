import 'package:flutter/material.dart';

class DropDownButtonChange extends StatefulWidget {
  const DropDownButtonChange({
    super.key,
    required this.items,
    this.labelText,
    required this.controller,
    this.onChanged,
  });

  final void Function(String?)? onChanged;
  final List<String> items;
  final String? labelText;
  final TextEditingController controller;

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
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.white,
      value: widget.items.contains(widget.controller.text) ? widget.controller.text : null,
      items: widget.items.map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (selected) {
        setState(() {
          selectedTypes = selected;
          widget.controller.text = selected ?? '';
        });
        if (widget.onChanged != null) {
          widget.onChanged!(selected);
        }
      },
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        labelText: widget.labelText,
        hintStyle: const TextStyle(color: Colors.grey), // ← aqui está o ajuste
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey), // cor da borda normal
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue), // cor ao focar
          borderRadius: BorderRadius.circular(10),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red), // cor se houver erro
          borderRadius: BorderRadius.circular(10),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade700),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
