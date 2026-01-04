import 'package:flutter/material.dart';

class MiniCircleButton extends StatelessWidget {
  const MiniCircleButton({super.key, required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(90),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
