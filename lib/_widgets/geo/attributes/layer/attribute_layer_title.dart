import 'package:flutter/material.dart';

class AttributeLayerTitle extends StatelessWidget {
  final String headerTitle;
  final Color headerColor;
  final String emptyText;
  final List<Widget> children;

  const AttributeLayerTitle({super.key,
    required this.headerTitle,
    required this.headerColor,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: children.isEmpty
              ? Center(child: Text(emptyText))
              : ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 5),
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) => children[index],
          ),
        ),
      ],
    );
  }
}

