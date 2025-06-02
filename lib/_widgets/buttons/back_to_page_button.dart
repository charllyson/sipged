import 'package:flutter/material.dart';

class BackToPageButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final MaterialPageRoute pageRoute;

  const BackToPageButton({
    super.key,
    this.onPressed,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.iconColor = Colors.black,
    required this.pageRoute,
    required
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 20,
      child: CircleAvatar(
        backgroundColor: backgroundColor,
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: onPressed ?? () => Navigator.pushReplacement(context, pageRoute),
        ),
      ),
    );
  }
}
