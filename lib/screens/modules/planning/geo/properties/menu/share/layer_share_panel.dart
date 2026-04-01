import 'package:flutter/material.dart';

class LayerSharePanel extends StatelessWidget {
  final Widget preview;
  final Widget list;
  final List<Widget> actions;
  final double expandedHeight;
  final double previewWidth;
  final double actionBarWidth;
  final double compactPreviewHeight;
  final double compactListHeight;

  const LayerSharePanel({
    super.key,
    required this.preview,
    required this.list,
    required this.actions,
    this.expandedHeight = 254,
    this.previewWidth = 220,
    this.actionBarWidth = 60,
    this.compactPreviewHeight = 120,
    this.compactListHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;

        if (isCompact) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: compactPreviewHeight,
                  child: preview,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                SizedBox(
                  height: compactListHeight,
                  child: list,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: expandedHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: previewWidth,
                  child: preview,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(child: list),
                Container(
                  width: actionBarWidth,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        actions[i],
                        if (i != actions.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}