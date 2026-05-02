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
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null) {
        debugPrint('[ImportExcelController] Importação cancelada pelo usuário.');
        return;
      }

      final file = result.files.first;

      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());

      if (bytes == null) {
        debugPrint(
          '[ImportExcelController] Não foi possível ler o arquivo selecionado.',
        );
        return;
      }

      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        debugPrint(
          '[ImportExcelController] Planilha vazia ou inválida.',
        );
        return;
      }

      final sheet = excel.tables[excel.tables.keys.first];

      if (sheet == null || sheet.rows.isEmpty) {
        debugPrint(
          '[ImportExcelController] Planilha vazia ou inválida.',
        );
        return;
      }

      final headers = <String>[];

      for (int i = 0; i < sheet.rows.first.length; i++) {
        final cell = sheet.rows.first[i];
        final raw = cell?.value?.toString() ?? '';
        final norm = raw.trim().replaceAll(RegExp(r'\s+'), '_');

        headers.add(norm.isEmpty ? 'col_$i' : norm);
      }

      final List<Map<String, dynamic>> jsonData = sheet.rows.skip(1).map((row) {
        final json = <String, dynamic>{};

        for (int i = 0; i < headers.length; i++) {
          final key = headers[i];
          final cell = row.length > i ? row[i] : null;

          json[key] = _converterValor(cell?.value);
        }

        return json;
      }).toList();

      if (jsonData.isEmpty) {
        debugPrint(
          '[ImportExcelController] Nenhum dado encontrado na planilha.',
        );
        return;
      }

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) {
          return ExcelPreviewDialog(
            jsonData: jsonData,
            path: path,
            onFinished: onFinished,
          );
        },
      );
    } catch (e, s) {
      debugPrint('[ImportExcelController] Erro ao importar: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  static dynamic _converterValor(dynamic valor) {
    if (valor == null) return null;

    if (valor is String) {
      final str = valor.trim();

      if (str.isEmpty) return '';

      final dateTimeBrMatch = RegExp(
        r'^(\d{2})/(\d{2})/(\d{4})[ T](\d{2}):(\d{2}):(\d{2})$',
      ).firstMatch(str);

      if (dateTimeBrMatch != null) {
        try {
          final day = int.parse(dateTimeBrMatch.group(1)!);
          final month = int.parse(dateTimeBrMatch.group(2)!);
          final year = int.parse(dateTimeBrMatch.group(3)!);
          final hour = int.parse(dateTimeBrMatch.group(4)!);
          final minute = int.parse(dateTimeBrMatch.group(5)!);
          final second = int.parse(dateTimeBrMatch.group(6)!);

          return DateTime(year, month, day, hour, minute, second);
        } catch (_) {
          return str;
        }
      }

      final dateBrMatch = RegExp(
        r'^(\d{2})/(\d{2})/(\d{4})$',
      ).firstMatch(str);

      if (dateBrMatch != null) {
        try {
          final day = int.parse(dateBrMatch.group(1)!);
          final month = int.parse(dateBrMatch.group(2)!);
          final year = int.parse(dateBrMatch.group(3)!);

          return DateTime(year, month, day);
        } catch (_) {
          return str;
        }
      }

      final dateISO = DateTime.tryParse(str);
      if (dateISO != null) return dateISO;

      final strNum = str.replaceAll('.', '').replaceAll(',', '.');
      final parsed = double.tryParse(strNum);

      if (parsed != null) return parsed;

      return str;
    }

    return valor;
  }
}