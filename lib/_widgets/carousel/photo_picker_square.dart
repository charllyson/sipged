// lib/_widgets/schedule/square_modal/photo_picker_square.dart
import 'package:flutter/material.dart';

class PhotoPickerSquare extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const PhotoPickerSquare({super.key, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96, height: 96,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled ? Colors.blueGrey.shade300 : Colors.grey,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo, color: enabled ? Colors.blueGrey : Colors.grey, size: 22),
              const SizedBox(height: 6),
              Text(
                'Adicionar foto',
                style: TextStyle(fontSize: 12, color: enabled ? Colors.blueGrey : Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
