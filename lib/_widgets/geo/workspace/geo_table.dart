import 'package:flutter/material.dart';

class GeoTable extends StatelessWidget {
  final String? title;
  final List<String> columns;
  final List<Map<String, String>> rows;

  const GeoTable({super.key,
    required this.title,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          if ((title ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 38,
                  dataRowMinHeight: 34,
                  dataRowMaxHeight: 40,
                  columns: columns
                      .map(
                        (col) => DataColumn(
                      label: Text(
                        col,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                      .toList(growable: false),
                  rows: rows
                      .map(
                        (row) => DataRow(
                      cells: columns
                          .map(
                            (col) => DataCell(
                          Text(
                            row[col] ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                          .toList(growable: false),
                    ),
                  )
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}