import 'package:flutter/material.dart';

class FloatButtonMenu extends StatelessWidget {

  const FloatButtonMenu({
    super.key,
    required
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 16,
      child: Builder(
        builder: (context) => Material(
          elevation: 6,
          shape: const CircleBorder(),
          color: Colors.transparent,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : Colors.white,
            child: IconButton(
              icon: const Icon(Icons.menu, size: 22),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
      ),
    );
  }
}
