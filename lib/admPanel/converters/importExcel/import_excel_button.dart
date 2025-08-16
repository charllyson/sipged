import 'package:flutter/material.dart';
import 'excel_import_controller.dart';

class ImportExcelButton extends StatelessWidget {
  final String path;
  final void Function()? onFinished;

  const ImportExcelButton({
    super.key,
    required this.path,
    this.onFinished,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: 'Importar dados da planilha',
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
              child: IconButton(
                icon: const Icon(Icons.file_upload, size: 20),
                color: isDark ? Colors.white : Colors.black87,
                onPressed: () => ImportExcelController.importar(
                  context: context,
                  path: path,
                  onFinished: onFinished,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
