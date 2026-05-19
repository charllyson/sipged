import 'package:flutter/material.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';

class ChipCard extends StatelessWidget {
  const ChipCard(
      this.title,
      this.value,
      this.icon, {
        super.key,
        this.textValue,
        this.formatAsMoney = true,
        this.showTitle = true,
        this.separator = ': ',
        this.tooltip,
        this.onTap,
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
        this.maxLines = 1,
        this.overflow = TextOverflow.ellipsis,
      });

  final String title;
  final double? value;
  final IconData? icon;

  /// Valor textual customizado.
  ///
  /// Use quando o conteúdo não for dinheiro/número simples.
  /// Exemplo: "3 faixa(s)", "12 serviço(s)", "Ativo".
  final String? textValue;

  /// Quando true, formata [value] como dinheiro.
  final bool formatAsMoney;

  /// Quando false, mostra apenas o valor resolvido, sem "title: ".
  ///
  /// Útil para substituir chips pequenos como:
  /// "3 faixa(s)" ou "2 serviço(s)".
  final bool showTitle;

  /// Separador entre título e valor.
  ///
  /// Padrão: ": ".
  final String separator;

  final String? tooltip;
  final VoidCallback? onTap;

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
  final int maxLines;
  final TextOverflow overflow;

  String get _resolvedValue {
    if (textValue != null) return textValue!;

    if (value == null) return '-';

    if (formatAsMoney) {
      return SipGedFormatMoney.doubleToText(value!);
    }

    final isInteger = value! % 1 == 0;

    if (isInteger) {
      return value!.toInt().toString();
    }

    return value!.toString();
  }

  String get _resolvedLabel {
    final cleanTitle = title.trim();
    final cleanValue = _resolvedValue.trim();

    if (!showTitle || cleanTitle.isEmpty) {
      return cleanValue;
    }

    return '$cleanTitle$separator$cleanValue';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final resolvedBackgroundColor = backgroundColor ?? Colors.grey.shade100;

    final resolvedForegroundColor =
        foregroundColor ?? theme.colorScheme.onSurface;

    final resolvedBorderColor = borderColor ?? Colors.grey.shade400;

    final chip = Chip(
      avatar: icon != null
          ? Icon(
        icon,
        size: iconSize,
        color: resolvedForegroundColor,
      )
          : null,
      label: Text(
        _resolvedLabel,
        maxLines: maxLines,
        overflow: overflow,
        style: textStyle ??
            theme.textTheme.bodyMedium?.copyWith(
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

    final result = onTap == null
        ? chip
        : InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onTap,
      child: chip,
    );

    if (tooltip == null || tooltip!.trim().isEmpty) {
      return result;
    }

    return Tooltip(
      message: tooltip!,
      child: result,
    );
  }
}