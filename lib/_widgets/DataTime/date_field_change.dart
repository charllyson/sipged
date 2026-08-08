import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_painter.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

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
    this.useBalloonPicker = true,
    this.balloonWidth = 330,
    this.balloonMaxHeight = 390,
    this.closeBalloonOnScroll = true,
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

  final bool useBalloonPicker;
  final double balloonWidth;
  final double balloonMaxHeight;

  /// Fecha o balão automaticamente quando o scroll pai começar.
  final bool closeBalloonOnScroll;

  @override
  State<DateFieldChange> createState() => _DateFieldChangeState();
}

class _DateFieldChangeState extends State<DateFieldChange> {
  final DateFormat _format = DateFormat('dd/MM/yyyy');
  final GlobalKey _fieldKey = GlobalKey();

  late final TextEditingController _internalController;

  OverlayEntry? _overlayEntry;
  DateTime? _previewDate;

  ScrollPosition? _scrollPosition;

  TextEditingController get _effectiveController {
    return widget.controller ?? _internalController;
  }

  bool get _balloonOpen {
    return _overlayEntry != null;
  }

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();
    _applyInitialValueIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindNearestScrollPosition();
  }

  @override
  void didUpdateWidget(covariant DateFieldChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue ||
        oldWidget.controller != widget.controller) {
      _applyInitialValueIfNeeded();
    }

    if (oldWidget.closeBalloonOnScroll != widget.closeBalloonOnScroll) {
      _bindNearestScrollPosition();
    }
  }

  @override
  void dispose() {
    _removeBalloon();
    _unbindScrollPosition();
    _internalController.dispose();
    super.dispose();
  }

  void _bindNearestScrollPosition() {
    _unbindScrollPosition();

    if (!widget.closeBalloonOnScroll) return;

    final scrollable = Scrollable.maybeOf(context);
    final position = scrollable?.position;

    if (position == null) return;

    _scrollPosition = position;
    _scrollPosition!.isScrollingNotifier.addListener(_handleScrollActivity);
  }

  void _unbindScrollPosition() {
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScrollActivity);
    _scrollPosition = null;
  }

  void _handleScrollActivity() {
    if (!widget.closeBalloonOnScroll) return;

    final position = _scrollPosition;
    if (position == null) return;

    if (position.isScrollingNotifier.value) {
      _removeBalloon();
    }
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

  DateTime get _firstDate {
    return widget.firstDate ?? DateTime(DateTime.now().year - 100);
  }

  DateTime get _lastDate {
    return widget.lastDate ?? DateTime(DateTime.now().year + 100);
  }

  DateTime _resolveInitialPickerDate() {
    final parsed = _parseDate(_effectiveController.text);
    final now = DateTime.now();

    var base = parsed ?? widget.initialValue ?? now;

    if (base.isBefore(_firstDate)) {
      base = _firstDate;
    }

    if (base.isAfter(_lastDate)) {
      base = _lastDate;
    }

    return DateTime(
      base.year,
      base.month,
      base.day,
      widget.hour ?? base.hour,
      widget.min ?? base.minute,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    if (widget.enabled == false) return;

    if (widget.useBalloonPicker) {
      _toggleBalloon();
      return;
    }

    await _selectDateWithDialog(context);
  }

  Future<void> _selectDateWithDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final customTheme = theme.copyWith(
      colorScheme: scheme.copyWith(
        primary: scheme.secondary,
        onPrimary: scheme.onSecondary,
        secondary: scheme.secondary,
        onSecondary: scheme.onSecondary,
        surface: scheme.surface,
        onSurface: scheme.onSurface,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        headerBackgroundColor: scheme.primary,
        headerForegroundColor: scheme.onPrimary,
        todayBorder: BorderSide(
          color: scheme.secondary,
          width: 1.4,
        ),
        todayForegroundColor: WidgetStatePropertyAll<Color>(
          scheme.secondary,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onSecondary;
            }

            return scheme.onSurface;
          },
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.secondary;
            }

            return null;
          },
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
      ),
    );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _resolveInitialPickerDate(),
      firstDate: _firstDate,
      lastDate: _lastDate,
      builder: (context, child) {
        return Theme(
          data: customTheme,
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    _applySelectedDate(selectedDate);
  }

  void _toggleBalloon() {
    if (_overlayEntry != null) {
      _removeBalloon();
      return;
    }

    _showBalloon();
  }

  void _showBalloon() {
    if (!mounted) return;

    final fieldContext = _fieldKey.currentContext;
    final overlayState = Overlay.of(context);

    if (fieldContext == null) return;

    final targetObject = fieldContext.findRenderObject();
    final overlayObject = overlayState.context.findRenderObject();

    if (targetObject is! RenderBox || !targetObject.attached) return;
    if (overlayObject is! RenderBox || !overlayObject.attached) return;

    _previewDate = _resolveInitialPickerDate();

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        if (!targetObject.attached || !overlayObject.attached) {
          return const SizedBox.shrink();
        }

        final position = BalloonPopup.calculatePosition(
          targetBox: targetObject,
          overlayBox: overlayObject,
          balloonWidth: widget.balloonWidth,
          maxHeight: widget.balloonMaxHeight,
          tipSide: BalloonTipSide.top,
          autoFlip: true,
          topGap: 6,
          screenMargin: 8,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeBalloon,
                onPanDown: (_) {
                  if (widget.closeBalloonOnScroll) {
                    _removeBalloon();
                  }
                },
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: position.left,
              top: position.top,
              width: position.popupWidth,
              child: Material(
                type: MaterialType.transparency,
                child: BalloonPopup(
                  width: widget.balloonWidth,
                  maxHeight: position.popupMaxHeight,
                  tipSide: position.tipSide,
                  tipCenterX: position.tipCenterX,
                  tipCenterY: position.tipCenterY,
                  child: _DateBalloonCalendar(
                    selectedDate: _previewDate ?? _resolveInitialPickerDate(),
                    firstDate: _firstDate,
                    lastDate: _lastDate,
                    onDateChanged: (date) {
                      _previewDate = date;
                      _applySelectedDate(date);
                      _removeBalloon();
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_overlayEntry!);

    if (mounted) {
      setState(() {});
    }
  }

  void _removeBalloon() {
    final entry = _overlayEntry;

    if (entry == null) return;

    entry.remove();
    _overlayEntry = null;

    if (mounted) {
      setState(() {});
    }
  }

  void _applySelectedDate(DateTime selectedDate) {
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

  OutlineInputBorder _border({
    required Color color,
    required double width,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor =
        widget.valueColor ?? DefaultTextStyle.of(context).style.color;

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
          key: _fieldKey,
          width: widget.width,
          child: TextFormField(
            controller: _effectiveController,
            obscureText: widget.obscure,
            keyboardType: widget.textInputType ?? TextInputType.datetime,
            inputFormatters: widget.inputFormatters,
            enabled: widget.enabled ?? true,
            readOnly: true,
            style: TextStyle(
              color: effectiveTextColor,
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
              labelStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              labelText: widget.labelText,
              hintText: widget.hint,
              prefixIcon: widget.prefix,
              suffixIcon: widget.suffix ??
                  Icon(
                    _balloonOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.calendar_month_rounded,
                    color: Colors.grey.shade700,
                  ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              disabledBorder: _border(
                color: Colors.grey.shade400,
                width: 1.0,
              ),
              enabledBorder: _border(
                color: Colors.grey.shade500,
                width: 1.0,
              ),
              focusedBorder: _border(
                color: Colors.blue,
                width: 1.0,
              ),
              focusedErrorBorder: _border(
                color: Colors.red,
                width: 1.0,
              ),
              errorBorder: _border(
                color: Colors.red,
                width: 1.0,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateBalloonCalendar extends StatelessWidget {
  const _DateBalloonCalendar({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final calendarTheme = theme.copyWith(
      colorScheme: scheme.copyWith(
        primary: scheme.secondary,
        onPrimary: scheme.onSecondary,
        secondary: scheme.secondary,
        onSecondary: scheme.onSecondary,
        surface: Colors.white,
        onSurface: scheme.onSurface,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        todayBorder: BorderSide(
          color: scheme.secondary,
          width: 1.4,
        ),
        todayForegroundColor: WidgetStatePropertyAll<Color>(
          scheme.secondary,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onSecondary;
            }

            return scheme.onSurface;
          },
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.secondary;
            }

            return null;
          },
        ),
      ),
    );

    return Theme(
      data: calendarTheme,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: CalendarDatePicker(
          initialDate: selectedDate,
          firstDate: firstDate,
          lastDate: lastDate,
          currentDate: DateTime.now(),
          onDateChanged: onDateChanged,
        ),
      ),
    );
  }
}