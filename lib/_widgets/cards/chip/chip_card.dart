import 'package:flutter/material.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';

class ChipCard extends StatelessWidget {
  final String title;
  final double? value;
  final IconData? icon;
  final String? textValue;
  final bool formatAsMoney;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final BoxConstraints? avatarBoxConstraints;
  final VisualDensity? visualDensity;
  final MaterialTapTargetSize? materialTapTargetSize;
  final double iconSize;

  const ChipCard(
      this.title,
      this.value,
      this.icon, {
        super.key,
        this.textValue,
        this.formatAsMoney = true,
        this.backgroundColor,
        this.foregroundColor,
        this.borderColor,
        this.borderWidth = 1,
        this.borderRadius = 999,
        this.elevation,
        this.padding,
        this.textStyle,
        this.avatarBoxConstraints,
        this.visualDensity,
        this.materialTapTargetSize,
        this.iconSize = 18,
      });

  String get _resolvedValue {
    if (textValue != null) return textValue!;
    if (value == null) return '-';
    if (formatAsMoney) {
      return SipGedFormatMoney.doubleToText(value!);
    }
    return value!.toString();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBackgroundColor = backgroundColor ?? Colors.grey.shade100;
    final resolvedForegroundColor =
        foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    final resolvedBorderColor = borderColor ?? Colors.grey.shade400;

    return Chip(
      avatar: icon != null
          ? Icon(
        icon,
        size: iconSize,
        color: resolvedForegroundColor,
      )
          : null,
      label: Text(
        '$title: $_resolvedValue',
        style: textStyle ??
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: resolvedForegroundColor,
              fontWeight: FontWeight.w600,
            ),
      ),
      backgroundColor: resolvedBackgroundColor,
      side: BorderSide(
        color: resolvedBorderColor,
        width: borderWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: elevation,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
      avatarBoxConstraints: avatarBoxConstraints,
      visualDensity: visualDensity ?? VisualDensity.standard,
      materialTapTargetSize:
      materialTapTargetSize ?? MaterialTapTargetSize.shrinkWrap,
    );
  }
}