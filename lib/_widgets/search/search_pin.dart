import 'package:flutter/material.dart';

// NEW: pin simples para o resultado da busca
class SearchPin extends StatelessWidget {
  const SearchPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 4,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black26,
            ),
          ),
        ),
        Icon(Icons.location_on, size: 34, color: Colors.redAccent),
      ],
    );
  }
}
