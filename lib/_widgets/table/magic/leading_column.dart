import 'package:flutter/material.dart';
import 'package:sipged/_widgets/table/magic/magic_table_changed.dart';

class LeadingColumn extends StatelessWidget {
  const LeadingColumn({
    super.key,
    required this.rowCount,
    required this.rowHeight,
    required this.bottomScrollGap,
    required this.leadingHeaderBuilder,
    required this.leadingCellBuilder,
    required this.rowStyleResolver,
  });

  final int rowCount;
  final double rowHeight;
  final double bottomScrollGap;

  final Widget Function(BuildContext context)? leadingHeaderBuilder;
  final Widget Function(BuildContext context, int row)? leadingCellBuilder;

  final RowStyleResolver rowStyleResolver;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(rowCount, (r) {
          if (r == 0) {
            return Container(
              height: rowHeight,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: leadingHeaderBuilder?.call(context),
            );
          }
          final style = rowStyleResolver(r);
          return Container(
            height: rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: style.bg,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: DefaultTextStyle.merge(
              style: style.text,
              child: leadingCellBuilder!.call(context, r),
            ),
          );
        }),
        SizedBox(height: bottomScrollGap),
      ],
    );
  }
}
