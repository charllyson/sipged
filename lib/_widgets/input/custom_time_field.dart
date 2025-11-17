import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CustomTimeField extends StatelessWidget {
  CustomTimeField({
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

  final DateFormat? format = DateFormat(
    'HH:mm',
  );
  final Stream<String>? stream;
  final TextEditingController? controller;
  final String? hint;
  final DateTime? initialValue;
  final Widget? prefix;
  final Widget? suffix;
  final bool? obscure;
  final TextInputType? textInputType;
  final List<TextInputFormatter>? inputFormat;
  final String? Function(DateTime?)? validator;
  final Function(DateTime?)? onChanged;
  final Function(DateTime?)? onSaved;
  final bool enabled;
  final Color? valueColor;
  late final int? hour;
  late final int? min;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snapshot) {
        return DateTimeField(
          format: format!,
          onShowPicker: (context, currentValue) async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(
                currentValue ?? DateTime(
                  0,
                  1,
                  1,
                  8,
                  0,
                ),
              ),
            );
            return DateTimeField.convert(time);
          },
          onSaved: onSaved,
          initialValue: initialValue,
          validator: validator,
          controller: controller,
          obscureText: obscure!,
          keyboardType: textInputType,
          inputFormatters: inputFormat,
          onChanged: onChanged,
          enabled: enabled,
          decoration: InputDecoration(
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            labelText: labelText,
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
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
