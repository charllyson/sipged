import 'package:flutter/material.dart';

class PushPanelsController extends ChangeNotifier {
  final List<String> _openIds = <String>[];

  List<String> get openIds => List.unmodifiable(_openIds);

  bool isOpen(String id) => _openIds.contains(id);

  void open(String id) {
    if (_openIds.contains(id)) return;
    _openIds.add(id);
    notifyListeners();
  }

  void close(String id) {
    if (!_openIds.contains(id)) return;
    _openIds.remove(id);
    notifyListeners();
  }

  void toggle(String id) {
    if (isOpen(id)) {
      close(id);
    } else {
      open(id);
    }
  }

  void closeAll() {
    if (_openIds.isEmpty) return;
    _openIds.clear();
    notifyListeners();
  }
}