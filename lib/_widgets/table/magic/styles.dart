import 'package:flutter/material.dart';

class RowStyle {
  const RowStyle({required this.bg, required this.textStyle, required this.editBg});
  final Color bg;
  final TextStyle textStyle;
  final Color editBg;
}

bool _isUpperCase(String v) {
  final only = v.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
  return only.isNotEmpty && only == only.toUpperCase();
}

RowStyle computeRowStyle({
  required bool isHeader,
  required String firstCol,
  required String secondCol,
}) {
  if (isHeader) {
    return RowStyle(
      bg: const Color(0xFF091D68),
      textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      editBg: Colors.yellow.shade100,
    );
  }

  final isIntegerRow = int.tryParse(firstCol) != null;
  final isUpperCaseRow = _isUpperCase(secondCol);

  if (isIntegerRow) {
    return RowStyle(
      bg: Colors.grey.shade200,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      editBg: Colors.yellow.shade100,
    );
  }
  if (isUpperCaseRow) {
    return RowStyle(
      bg: Colors.grey.shade100,
      textStyle: const TextStyle(fontStyle: FontStyle.italic),
      editBg: Colors.yellow.shade100,
    );
  }
  return RowStyle(
    bg: Colors.white,
    textStyle: const TextStyle(),
    editBg: Colors.yellow.shade100,
  );
}
