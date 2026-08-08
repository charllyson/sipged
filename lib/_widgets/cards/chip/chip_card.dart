import 'package:flutter/material.dart';

typedef ChipCardValueFormatter = String Function(double value);

class ChipCard extends StatelessWidget {
  const ChipCard(
      this.title,
      this.value,
      this.icon, {
        super.key,
        this.textValue,
        this.valueFormatter,
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
  /// Use quando o conteúdo não for número simples.
  /// Exemplo: "3 faixa(s)", "12 serviço(s)", "Ativo".
  final String? textValue;

  /// Formatador externo para o valor numérico.
  ///
  /// Exemplo no SIPGED:
  /// valueFormatter: SipGedFormatMoney.doubleToText
  ///
  /// Assim o ChipCard não depende de regras específicas do projeto.
  final ChipCardValueFormatter? valueFormatter;

  /// Mantido por compatibilidade com usos antigos.
  ///
  /// Quando [valueFormatter] for informado, ele terá prioridade.
  /// Quando [formatAsMoney] for true e [valueFormatter] for null,
  /// o fallback genérico será value.toStringAsFixed(2).
  final bool formatAsMoney;

  /// Quando false, mostra apenas o valor resolvido, sem "title: ".
  final bool showTitle;

  /// Separador entre título e valor.
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
    final customText = textValue?.trim();

    if (customText != null && customText.isNotEmpty) {
      return customText;
    }

    final numericValue = value;

    if (numericValue == null) {
      return '-';
    }

    if (valueFormatter != null) {
      return valueFormatter!(numericValue);
    }

    if (formatAsMoney) {
      return numericValue.toStringAsFixed(2);
    }

    final isInteger = numericValue % 1 == 0;

    if (isInteger) {
      return numericValue.toInt().toString();
    }

    return numericValue.toString();
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
        : Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: chip,
      ),
    );

    final cleanTooltip = tooltip?.trim();

    if (cleanTooltip == null || cleanTooltip.isEmpty) {
      return result;
    }

    return Tooltip(
      message: cleanTooltip,
      child: result,
    );
  }
}