import 'package:flutter/material.dart';

class SearchOverlayWidget {
  static OverlayEntry build({
    required BuildContext context,
    required TextEditingController controller,
    required VoidCallback onClose,
    required ValueChanged<String> onSubmitted,
  }) {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        right: 20,
        left: 20,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: onSubmitted,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
