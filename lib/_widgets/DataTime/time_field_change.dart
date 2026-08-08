// lib/_widgets/DataTime/time_field_change.dart

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
    if (!enabled) return;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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

    final customTheme = theme.copyWith(
      colorScheme: scheme.copyWith(
        primary: scheme.secondary,
        onPrimary: scheme.onSecondary,
        secondary: scheme.secondary,
        onSecondary: scheme.onSecondary,
        surface: scheme.surface,
        onSurface: scheme.onSurface,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surface,
        hourMinuteColor: WidgetStateColor.resolveWith(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.secondary;
            }

            return const Color(0xFFF1F5F9);
          },
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onSecondary;
            }

            return scheme.onSurface;
          },
        ),
        dialHandColor: scheme.secondary,
        dialBackgroundColor: const Color(0xFFF1F5F9),
        entryModeIconColor: scheme.secondary,
        dayPeriodColor: WidgetStateColor.resolveWith(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.secondary;
            }

            return const Color(0xFFF1F5F9);
          },
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onSecondary;
            }

            return scheme.onSurface;
          },
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
      ),
    );

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      builder: (context, child) {
        return Theme(
          data: customTheme,
          child: child!,
        );
      },
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
    final scheme = Theme.of(context).colorScheme;

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
            color: valueColor ?? scheme.onSurface,
          ),
          onTap: enabled ? () => _selectTime(context) : null,
          validator: (_) {
            return validator?.call(_parseTime(controller?.text ?? ''));
          },
          onSaved: (_) {
            onSaved?.call(_parseTime(controller?.text ?? ''));
          },
          decoration: InputDecoration(
            labelStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: Colors.white,
            labelText: labelText,
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix ??
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF64748B),
                ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: scheme.secondary,
                width: 1.4,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: scheme.error,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: scheme.error,
              ),
            ),
          ),
        );
      },
    );
  }
}