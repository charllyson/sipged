import 'package:flutter/material.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_column.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_table_row.dart';

class PagedSubTableHeader<T> extends StatelessWidget {
  const PagedSubTableHeader({super.key,
    required this.columns,
    required this.leadingWidth,
    required this.headerHeight,
    required this.headerColor,
    required this.primaryColor,
    required this.hasLeading,
    required this.cellHorizontalPadding,
  });

  final List<PagedSubColumn<T>> columns;
  final double leadingWidth;
  final double headerHeight;
  final Color headerColor;
  final Color primaryColor;
  final bool hasLeading;
  final double cellHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: headerHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.zero,
        ),
        child: ClipRect(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLeading) SizedBox(width: leadingWidth),
              for (final column in columns)
                SizedBox(
                  width: column.width,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: cellHorizontalPadding,
                    ),
                    child: Align(
                      alignment: pagedSubAlignment(column.textAlign),
                      child: Text(
                        column.title,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        textAlign: column.textAlign,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
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
