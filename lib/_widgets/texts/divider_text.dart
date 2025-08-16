import 'package:flutter/material.dart';

class DividerText extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSend;
  final Color colorTitle;
  final Color subTitle;

  const DividerText({
    super.key,
    required this.title,
    this.isSend = false,
    this.subtitle,
    this.colorTitle = Colors.black,
    this.subTitle = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Colors.grey, thickness: 1, endIndent: 12),
          ),
          Column(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, color: colorTitle),
              ),
              if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: subTitle),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Divider(color: Colors.grey, thickness: 1, endIndent: 12),
          ),

        ],
      ),
    );
  }
}
