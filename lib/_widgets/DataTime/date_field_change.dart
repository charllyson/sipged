import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DateFieldChange extends StatefulWidget {
  const DateFieldChange({
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

  @override
  State<DateFieldChange> createState() => _DateFieldChangeState();
}

class _DateFieldChangeState extends State<DateFieldChange> {
  final DateFormat _format = DateFormat('dd/MM/yyyy');

  late final TextEditingController _internalController;

  TextEditingController get _effectiveController {
    return widget.controller ?? _internalController;
  }

  @override
  void initState() {
    super.initState();

    _internalController = TextEditingController();

    _applyInitialValueIfNeeded();
  }

  @override
  void didUpdateWidget(covariant DateFieldChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue ||
        oldWidget.controller != widget.controller) {
      _applyInitialValueIfNeeded();
    }
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  void _applyInitialValueIfNeeded() {
    final controller = _effectiveController;

    if (widget.initialValue == null) return;

    if (controller.text.trim().isNotEmpty) return;

    final text = _format.format(widget.initialValue!);

    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  DateTime? _parseDate(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return null;

    try {
      return _format.parseStrict(clean);
    } catch (_) {
      return null;
    }
  }

  DateTime _resolveInitialPickerDate() {
    final parsed = _parseDate(_effectiveController.text);

    final now = DateTime.now();

    final first = widget.firstDate ?? DateTime(now.year - 100);
    final last = widget.lastDate ?? DateTime(now.year + 100);

    var base = parsed ?? widget.initialValue ?? now;

    if (base.isBefore(first)) {
      base = first;
    }

    if (base.isAfter(last)) {
      base = last;
    }

    return base;
  }

  Future<void> _selectDate(BuildContext context) async {
    if (widget.enabled == false) return;

    final theme = Theme.of(context);

    final customTheme = theme.copyWith(
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

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _resolveInitialPickerDate(),
      firstDate: widget.firstDate ?? DateTime(DateTime.now().year - 100),
      lastDate: widget.lastDate ?? DateTime(DateTime.now().year + 100),
      builder: (context, child) {
        return Theme(
          data: customTheme,
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    var finalDate = selectedDate;

    if (widget.hour != null || widget.min != null) {
      finalDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        widget.hour ?? 0,
        widget.min ?? 0,
      );
    }

    final text = _format.format(finalDate);

    _effectiveController.value = _effectiveController.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );

    widget.onChanged?.call(finalDate);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final value = snapshot.data!.trim();

          if (value.isNotEmpty && value != _effectiveController.text) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              _effectiveController.value = _effectiveController.value.copyWith(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
                composing: TextRange.empty,
              );
            });
          }
        }

        return SizedBox(
          width: widget.width,
          child: TextFormField(
            controller: _effectiveController,
            obscureText: widget.obscure,
            keyboardType: widget.textInputType ?? TextInputType.datetime,
            inputFormatters: widget.inputFormatters,
            enabled: widget.enabled ?? true,
            readOnly: true,
            style: TextStyle(
              color: widget.valueColor ?? Colors.black,
            ),
            onTap: widget.enabled == false ? null : () => _selectDate(context),
            validator: (_) {
              return widget.validator?.call(
                _parseDate(_effectiveController.text),
              );
            },
            onSaved: (_) {
              widget.onSaved?.call(
                _parseDate(_effectiveController.text),
              );
            },
            decoration: InputDecoration(
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              labelText: widget.labelText,
              hintText: widget.hint,
              prefixIcon: widget.prefix,
              suffixIcon: widget.suffix ??
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.grey,
                  ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
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