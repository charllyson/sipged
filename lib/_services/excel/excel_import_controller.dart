import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'excel_preview_dialog.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ImportExcelController {
  static Future<void> importar({
    required BuildContext context,
    required String path,
    required void Function()? onFinished,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        _notify('Importação cancelada', type: AppNotificationType.warning);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes ?? File(file.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];

      if (sheet == null || sheet.rows.isEmpty) {
        _notify('Planilha vazia ou inválida.', type: AppNotificationType.warning);
        return;
      }

      // Cabeçalhos normalizados
      final headers = <String>[];
      for (var i = 0; i < sheet.rows.first.length; i++) {
        final cell = sheet.rows.first[i];
        final raw = cell?.value?.toString() ?? '';
        final norm = raw.trim().replaceAll(RegExp(r'\s+'), '_');
        headers.add(norm.isEmpty ? 'col_$i' : norm);
      }

      // Linhas
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
        _notify('Nenhum dado encontrado na planilha.', type: AppNotificationType.warning);
        return;
      }

      if (!context.mounted) return;
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
      _notify('Erro ao importar', type: AppNotificationType.error, subtitle: '$e');
    }
  }

  static dynamic _converterValor(dynamic valor) {
    if (valor == null) return null;

    if (valor is String) {
      final str = valor.trim();

      // 14/11/2019 10:30:00
      final match =
      RegExp(r'^(\d{2})/(\d{2})/(\d{4})[ T](\d{2}):(\d{2}):(\d{2})$').firstMatch(str);
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

      // 14/11/2019
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(str)) {
        final parts = str.split('/');
        return DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      }

      // ISO
      final dateISO = DateTime.tryParse(str);
      if (dateISO != null) return dateISO;

      // numérico com vírgula/ponto
      final strNum = str.replaceAll('.', '').replaceAll(',', '.');
      final parsed = double.tryParse(strNum);
      if (parsed != null) return parsed;

      return str;
    }

    return valor;
  }

  // 🔔 helper de notificação
  static void _notify(
      String title, {
        AppNotificationType type = AppNotificationType.info,
        String? subtitle,
      }) {
    NotificationCenter.instance.show(
      AppNotification(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        type: type,
      ),
    );
  }
}
