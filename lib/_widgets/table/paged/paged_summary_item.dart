import 'package:flutter/material.dart';

class PagedSummaryItem {
  const PagedSummaryItem({
    required this.label,
    required this.value,
    this.backgroundColor,
    this.fontWeight,
  });

  final String label;
  final String value;
  final Color? backgroundColor;
  final FontWeight? fontWeight;
}

class PagedSummaryBox extends StatelessWidget {
  const PagedSummaryBox({
    super.key,
    required this.items,
  });

  final List<PagedSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: item.backgroundColor ?? Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(fontWeight: item.fontWeight),
                ),
              ),
              Text(
                item.value,
                style: TextStyle(fontWeight: item.fontWeight),
              ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}