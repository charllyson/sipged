import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
        Color.fromARGB(255, 27, 32, 51),
        Color.fromARGB(255, 144, 202, 249)
      ], begin: Alignment.topLeft, end: Alignment.bottomRight,),),
    );
  }
}
