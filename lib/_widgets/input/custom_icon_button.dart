import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  const CustomIconButton(
      {super.key, this.radius, this.iconData, this.onTap, this.icoColor,});

  final double? radius;
  final IconData? iconData;
  final VoidCallback? onTap;
  final Color? icoColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius!),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Icon(iconData, color: icoColor),
        ),
      ),
    );
  }
}
