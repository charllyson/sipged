import 'package:flutter/material.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_column.dart';

class PagedSubTableRow<T> extends StatelessWidget {
  const PagedSubTableRow({super.key,
    required this.item,
    required this.columns,
    required this.leadingWidth,
    required this.primaryColor,
    required this.rowMinHeight,
    required this.cellHorizontalPadding,
    this.leadingIcon,
  });

  final T item;
  final List<PagedSubColumn<T>> columns;

  final IconData? leadingIcon;
  final double leadingWidth;
  final Color primaryColor;
  final double rowMinHeight;
  final double cellHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: rowMinHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRect(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null)
                SizedBox(
                  width: leadingWidth,
                  child: Icon(
                    leadingIcon,
                    size: 18,
                    color: primaryColor,
                  ),
                ),
              for (final column in columns)
                SizedBox(
                  width: column.width,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: cellHorizontalPadding,
                    ),
                    child: Align(
                      alignment: pagedSubAlignment(column.textAlign),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: column.maxWidth ?? column.width,
                        ),
                        child: Text(
                          column.valueBuilder(item),
                          maxLines: column.maxLines,
                          overflow: TextOverflow.visible,
                          softWrap: column.maxLines > 1,
                          textAlign: column.textAlign,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: column.fontWeight ?? FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Alignment pagedSubAlignment(TextAlign align) {
  switch (align) {
    case TextAlign.center:
      return Alignment.center;
    case TextAlign.right:
      return Alignment.centerRight;
    case TextAlign.left:
    case TextAlign.start:
    default:
      return Alignment.centerLeft;
  }
}