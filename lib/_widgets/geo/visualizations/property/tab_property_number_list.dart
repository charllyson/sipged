import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_property.dart';


class TabPropertyNumberList extends StatefulWidget {
  const TabPropertyNumberList({
    super.key,
    required this.property,
    required this.onChanged,
  });

  final GeoWorkspaceDataProperty property;
  final ValueChanged<List<double>> onChanged;

  @override
  State<TabPropertyNumberList> createState() =>
      _TabPropertyNumberListState();
}

class _TabPropertyNumberListState extends State<TabPropertyNumberList> {
  late final TextEditingController _controller;

  String get _externalValue =>
      (widget.property.numberListValue ?? const []).join(', ');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _externalValue);
  }

  @override
  void didUpdateWidget(covariant TabPropertyNumberList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newValue = _externalValue;
    if (_controller.text != newValue) {
      _controller.value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(offset: newValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      minLines: 1,
      maxLines: 3,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        final parts = value.split(',');
        final next = <double>[];

        for (final part in parts) {
          final normalized = part.trim().replaceAll(',', '.');
          final parsed = double.tryParse(normalized);
          if (parsed != null) {
            next.add(parsed);
          }
        }

        widget.onChanged(next);
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.property.hint ?? 'Separar por vírgula',
        border: const OutlineInputBorder(),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}
