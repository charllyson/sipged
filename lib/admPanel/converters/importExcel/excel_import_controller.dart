import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'excel_preview_dialog.dart';

class ImportExcelController {
  static Future<void> importar({
    required BuildContext context,
    required String path,
    required void Function()? onFinished,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      final file = result.files.first;
      final bytes = file.bytes ?? File(file.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];

      if (sheet == null || sheet.rows.isEmpty) {
        _showSnackBar(context, 'Planilha vazia ou inválida.');
        return;
      }

      final headers = <String>[];
      for (var i = 0; i < sheet.rows.first.length; i++) {
        final cell = sheet.rows.first[i];
        final raw = cell?.value?.toString() ?? '';
        headers.add(raw.trim().replaceAll(RegExp(r'\s+'), '_').isEmpty
            ? 'col_$i'
            : raw.trim().replaceAll(RegExp(r'\s+'), '_'));
      }

      final List<Map<String, dynamic>> jsonData = sheet.rows.skip(1).map((row) {
        final Map<String, dynamic> json = {};
        for (int i = 0; i < headers.length; i++) {
          final key = headers[i];
          final cell = row.length > i ? row[i] : null;
          json[key] = _converterValor(cell?.value);
        }
        return json;
      }).toList();


      if (jsonData.isEmpty) {
        _showSnackBar(context, 'Nenhum dado encontrado na planilha.');
        return;
      }

      if (!context.mounted) {
        return;
      }
      await showDialog(
        context: context,
        builder: (ctx) {
          return ExcelPreviewDialog(
            jsonData: jsonData,
            path: path,
            onFinished: onFinished,
          );
        },
      );
    } catch (e) {
      _showSnackBar(context, 'Erro ao importar: $e');
    }
  }

  static dynamic _converterValor(dynamic valor) {
    if (valor == null) return null;

    if (valor is String) {
      final str = valor.trim();

      // Detecta padrão: 14/11/2019 10:30:00
      final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})[ T](\d{2}):(\d{2}):(\d{2})$').firstMatch(str);
      if (match != null) {
        try {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final year = int.parse(match.group(3)!);
          final hour = int.parse(match.group(4)!);
          final minute = int.parse(match.group(5)!);
          final second = int.parse(match.group(6)!);
          return DateTime(year, month, day, hour, minute, second);
        } catch (_) {
          return null;
        }
      }

      // Detecta padrão: 14/11/2019
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(str)) {
        final parts = str.split('/');
        return DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      }

      // Detecta padrão: 2019-11-14T10:30:00 ou similar
      final dateISO = DateTime.tryParse(str);
      if (dateISO != null) return dateISO;

      // Detecta valores numéricos com vírgula ou ponto
      final strNum = str.replaceAll('.', '').replaceAll(',', '.');
      final parsed = double.tryParse(strNum);
      if (parsed != null) return parsed;

      return str;
    }

    return valor;
  }

  static void _showSnackBar(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
