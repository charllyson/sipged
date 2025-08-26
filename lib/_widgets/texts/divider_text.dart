import 'package:flutter/material.dart';

class DividerText extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSend;
  final Color colorTitle;
  final Color subTitle;
  final EdgeInsetsGeometry padding;
  final Color dividerColor;
  final double thickness;

  const DividerText({
    super.key,
    required this.title,
    this.subtitle,
    this.isSend = false,
    this.colorTitle = Colors.black,
    this.subTitle = Colors.black54,
    this.padding = const EdgeInsets.all(12),
    this.dividerColor = Colors.grey,
    this.thickness = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasWidth = constraints.hasBoundedWidth;

          final left = hasWidth
              ? Expanded(child: Divider(color: dividerColor, thickness: thickness, endIndent: 12))
              : Flexible(fit: FlexFit.loose, child: Divider(color: dividerColor, thickness: thickness, endIndent: 12));

          final right = hasWidth
              ? Expanded(child: Divider(color: dividerColor, thickness: thickness, endIndent: 12))
              : Flexible(fit: FlexFit.loose, child: Divider(color: dividerColor, thickness: thickness, endIndent: 12));

          return Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              left,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: colorTitle)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(fontSize: 12, color: subTitle)),
                ],
              ),
              const SizedBox(width: 12),
              right,
            ],
          );
        },
      ),
    );
  }
}
