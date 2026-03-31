import 'package:flutter/material.dart';

class AttributeLayer extends StatelessWidget {
  final String headerTitle;
  final Color headerColor;
  final String emptyText;
  final List<Widget>? children;
  final Widget? headerTrailing;
  final Widget? body;

  const AttributeLayer({
    super.key,
    required this.headerTitle,
    required this.headerColor,
    required this.emptyText,
    this.children,
    this.headerTrailing,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final listChildren = children ?? const <Widget>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    headerTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (headerTrailing != null) ...[
                  const SizedBox(width: 8),
                  headerTrailing!,
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: body ??
              (listChildren.isEmpty
                  ? Center(child: Text(emptyText))
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 5),
                itemCount: listChildren.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) => listChildren[index],
              )),
        ),
      ],
    );
  }
}