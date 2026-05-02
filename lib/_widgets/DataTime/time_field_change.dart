import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TimeFieldChange extends StatelessWidget {
  TimeFieldChange({
    super.key,
    this.stream,
    this.hint,
    this.initialValue,
    this.valueColor,
    this.prefix,
    this.suffix,
    this.inputFormat,
    this.obscure = false,
    this.textInputType,
    this.onChanged,
    this.onSaved,
    required this.enabled,
    this.controller,
    this.validator,
    this.labelText,
    this.min,
    this.hour,
  });

  final DateFormat format = DateFormat('HH:mm');

  final Stream<String>? stream;
  final TextEditingController? controller;
  final String? hint;
  final DateTime? initialValue;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? textInputType;
  final List<TextInputFormatter>? inputFormat;
  final String? Function(DateTime?)? validator;
  final Function(DateTime?)? onChanged;
  final Function(DateTime?)? onSaved;
  final bool enabled;
  final Color? valueColor;
  final int? hour;
  final int? min;
  final String? labelText;

  DateTime? _parseTime(String value) {
    if (value.trim().isEmpty) return null;

    try {
      final DateTime parsed = format.parseStrict(value.trim());

      return DateTime(
        0,
        1,
        1,
        parsed.hour,
        parsed.minute,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final DateTime base =
        _parseTime(controller?.text ?? '') ??
            initialValue ??
            DateTime(
              0,
              1,
              1,
              hour ?? 8,
              min ?? 0,
            );

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );

    if (selectedTime == null) return;

    final DateTime selectedDateTime = DateTime(
      0,
      1,
      1,
      selectedTime.hour,
      selectedTime.minute,
    );

    final String text = format.format(selectedDateTime);

    controller?.value = controller!.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );

    onChanged?.call(selectedDateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null &&
        initialValue != null &&
        controller!.text.isEmpty) {
      final String text = format.format(initialValue!);

      controller!.value = controller!.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
        composing: TextRange.empty,
      );
    }

    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snapshot) {
        return TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: textInputType ?? TextInputType.datetime,
          inputFormatters: inputFormat,
          enabled: enabled,
          readOnly: true,
          style: TextStyle(
            color: valueColor ?? Colors.black,
          ),
          onTap: enabled ? () => _selectTime(context) : null,
          validator: (_) {
            return validator?.call(_parseTime(controller?.text ?? ''));
          },
          onSaved: (_) {
            onSaved?.call(_parseTime(controller?.text ?? ''));
          },
          decoration: InputDecoration(
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            labelText: labelText,
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix ??
                const Icon(
                  Icons.access_time_rounded,
                  color: Colors.grey,
                ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.red),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        );
      },
    );
  }
}