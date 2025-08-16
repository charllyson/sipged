import 'package:flutter/material.dart';

class SearchOverlayManager {
  final BuildContext context;
  final TextEditingController controller;
  final void Function(String)? onSearch;
  OverlayEntry? _overlayEntry;
  bool _isOverlayVisible = false;

  SearchOverlayManager(this.context, this.controller, this.onSearch);

  void toggleOverlay() {
    if (_isOverlayVisible) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 72,
        right: 16,
        left: 16,
        child: Material(
          elevation: 6,
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                border: InputBorder.none,
              ),
              onSubmitted: (text) {
                _removeOverlay();
                onSearch?.call(text);
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
    _isOverlayVisible = true;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _isOverlayVisible = false;
  }
}
