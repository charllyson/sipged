import 'package:flutter/material.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_column.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_connector_painter.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_table_header.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_table_row.dart';

class PagedSubTable<T> extends StatelessWidget {
  const PagedSubTable({
    super.key,
    required this.items,
    required this.columns,
    this.leadingIcon,
    this.leadingWidth = 34,
    this.backgroundColor = const Color(0xFFF7F9FF),
    this.headerColor = const Color(0x0F091D68),
    this.borderColor = const Color(0x1F091D68),
    this.primaryColor = const Color(0xFF091D68),
    this.padding = const EdgeInsets.fromLTRB(0, 0, 0, 18),
    this.rowMinHeight = 42,
    this.headerHeight = 36,
    this.bottomRadius = 8,
    this.cellHorizontalPadding = 10,
    this.connectorWidth = 42,
    this.connectorColor = const Color(0x66091D68),
    this.connectorThickness = 1.4,
  });

  final List<T> items;
  final List<PagedSubColumn<T>> columns;

  final IconData? leadingIcon;
  final double leadingWidth;

  final Color backgroundColor;
  final Color headerColor;
  final Color borderColor;
  final Color primaryColor;

  final EdgeInsetsGeometry padding;
  final double rowMinHeight;
  final double headerHeight;
  final double bottomRadius;
  final double cellHorizontalPadding;

  /// Espaço visual à esquerda da subtabela.
  final double connectorWidth;

  /// Cor da linha que liga a linha principal aos subitens.
  final Color connectorColor;

  /// Espessura da linha conectora.
  final double connectorThickness;

  static const double _layoutSafetyWidth = 6.0;

  double get _columnsWidth {
    return columns.fold<double>(
      0.0,
          (totalWidth, column) => totalWidth + column.width,
    );
  }

  double get _contentWidth {
    return _columnsWidth +
        (leadingIcon != null ? leadingWidth : 0.0) +
        _layoutSafetyWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: connectorWidth,
            child: CustomPaint(
              painter: PagedSubConnectorPainter(
                color: connectorColor,
                thickness: connectorThickness,
              ),
              child: SizedBox(
                height: _resolvedConnectorHeight,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : _contentWidth;

                final tableWidth =
                _contentWidth > availableWidth ? _contentWidth : availableWidth;

                final needsHorizontalScroll = _contentWidth > availableWidth;

                final tableContent = SizedBox(
                  width: tableWidth,
                  child: items.isEmpty
                      ? _buildEmpty(context)
                      : _buildTable(context, tableWidth),
                );

                if (needsHorizontalScroll) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: tableContent,
                  );
                }

                return tableContent;
              },
            ),
          ),
        ],
      ),
    );
  }

  double get _resolvedConnectorHeight {
    if (items.isEmpty) {
      return 48;
    }

    return headerHeight + (items.length * rowMinHeight);
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(bottomRadius),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        'Nenhum item vinculado.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, double tableWidth) {
    return Container(
      width: tableWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(bottomRadius),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PagedSubTableHeader<T>(
            columns: columns,
            leadingWidth: leadingWidth,
            headerHeight: headerHeight,
            headerColor: headerColor,
            primaryColor: primaryColor,
            hasLeading: leadingIcon != null,
            cellHorizontalPadding: cellHorizontalPadding,
          ),
          for (int index = 0; index < items.length; index++) ...[
            PagedSubTableRow<T>(
              item: items[index],
              columns: columns,
              leadingIcon: leadingIcon,
              leadingWidth: leadingWidth,
              primaryColor: primaryColor,
              rowMinHeight: rowMinHeight,
              cellHorizontalPadding: cellHorizontalPadding,
            ),
            if (index < items.length - 1)
              Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
          ],
        ],
      ),
    );
  }
}
