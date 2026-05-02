import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DateFieldChange extends StatelessWidget {
  DateFieldChange({
    super.key,
    this.stream,
    this.hint,
    this.initialValue,
    this.valueColor,
    this.prefix,
    this.suffix,
    this.inputFormatters,
    this.obscure = false,
    this.textInputType,
    this.onChanged,
    this.onSaved,
    this.enabled,
    this.controller,
    this.validator,
    this.labelText,
    this.firstDate,
    this.lastDate,
    this.hour,
    this.min,
    this.width,
  });

  final DateFormat format = DateFormat('dd/MM/yyyy');

  final Stream<String>? stream;
  final TextEditingController? controller;
  final String? hint;
  final DateTime? initialValue;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? textInputType;
  final List<TextInputFormatter>? inputFormatters;
  final Function(DateTime?)? onChanged;
  final Function(DateTime?)? onSaved;
  final String? Function(DateTime?)? validator;
  final bool? enabled;
  final Color? valueColor;
  final int? hour;
  final int? min;
  final String? labelText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final double? width;

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;

    try {
      return format.parseStrict(value.trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final TextEditingController? activeController = controller;

    final DateTime base =
        _parseDate(activeController?.text ?? '') ??
            initialValue ??
            DateTime.now();

    final ThemeData theme = Theme.of(context);

    final ThemeData customTheme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        surface: Colors.white,
        primary: Colors.deepPurple,
        onPrimary: Colors.white,
        onSurface: Colors.black,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
      ),
    );

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: firstDate ?? DateTime(DateTime.now().year - 100),
      lastDate: lastDate ?? DateTime(DateTime.now().year + 100),
      builder: (context, child) {
        return Theme(
          data: customTheme,
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    final String text = format.format(selectedDate);

    activeController?.value = activeController.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );

    onChanged?.call(selectedDate);
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
        return SizedBox(
          width: width ?? 100,
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: textInputType ?? TextInputType.datetime,
            inputFormatters: inputFormatters,
            enabled: enabled ?? true,
            readOnly: true,
            style: TextStyle(
              color: valueColor ?? Colors.black,
            ),
            onTap: enabled == false ? null : () => _selectDate(context),
            validator: (_) {
              return validator?.call(_parseDate(controller?.text ?? ''));
            },
            onSaved: (_) {
              onSaved?.call(_parseDate(controller?.text ?? ''));
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
                    Icons.calendar_month_rounded,
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
          ),
        );
      },
    );
  }
}