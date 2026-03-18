// lib/screens/modules/actives/oaes/active_oaes_3d_card.dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/screens/modules/actives/oaes/active_oaes_ifc_viewer_page.dart';

class OaeModel3DCard extends StatefulWidget {
  final ActiveOaesData data;
  final bool isEditable;

  const OaeModel3DCard({
    super.key,
    required this.data,
    this.isEditable = true,
  });

  @override
  State<OaeModel3DCard> createState() => _OaeModel3DCardState();
}

class _OaeModel3DCardState extends State<OaeModel3DCard> {
  bool _busy = false;

  /// Modelo IFC em memória (apenas sessão atual, sem Firebase por enquanto)
  Uint8List? _ifcBytes;
  String? _ifcFileName;

  Future<void> _withBusy(Future<void> Function() task) async {
    if (mounted) setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleImport() async {
    if (!_canEdit) return;

    await _withBusy(() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['ifc'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível ler o arquivo IFC.')),
        );
        return;
      }

      _ifcBytes = bytes;
      _ifcFileName = file.name;

      setState(() {});

      if (!mounted) return;
      // Já abre o viewer logo após importar
      await _openViewerWithCurrentModel();
    });
  }

  bool get _hasModel => _ifcBytes != null && _ifcFileName != null;
  bool get _canEdit => widget.isEditable && !_busy;

  Future<void> _openViewerWithCurrentModel() async {
    if (!_hasModel) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum modelo IFC importado ainda.')),
      );
      return;
    }

    final bytes = _ifcBytes!;
    final fileName = _ifcFileName!;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveOaesIfcViewerPage(
          fileName: fileName,
          bytes: bytes,
          oaeId: widget.data.id,
        ),
      ),
    );
  }

  Future<void> _handleOpenViewer() async {
    if (_busy) return;
    await _openViewerWithCurrentModel();
  }

  Future<void> _handleRemove() async {
    if (!_hasModel || !_canEdit) return;

    await _withBusy(() async {
      final removed = _ifcFileName;
      _ifcBytes = null;
      _ifcFileName = null;
      setState(() {});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modelo IFC "$removed" removido desta sessão.'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasModel = _hasModel;

    return BasicCard(
      isDark: isDark,
      borderRadius: 18,
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _busy ? null : _handleOpenViewer,
        child: Row(
          children: [
            // Thumb / ícone grande
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade400,
                    Colors.indigo.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _busy
                  ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
                  : const Icon(
                Icons.view_in_ar,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 12),
            // Texto + ações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasModel
                        ? 'Modelo IFC vinculado nesta sessão'
                        : 'Nenhum modelo IFC vinculado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasModel
                        ? _ifcFileName ?? ''
                        : 'Importe um arquivo .ifc para visualizar a OAE em 3D.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (widget.isEditable)
                        TextButton.icon(
                          onPressed: _canEdit ? _handleImport : null,
                          icon: const Icon(Icons.upload_file_outlined),
                          label: Text(
                            hasModel
                                ? 'Substituir arquivo IFC'
                                : 'Importar arquivo IFC',
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (hasModel && widget.isEditable)
                        TextButton.icon(
                          onPressed: _canEdit ? _handleRemove : null,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Remover',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      const Spacer(),
                      if (hasModel)
                        TextButton.icon(
                          onPressed: _busy ? null : _handleOpenViewer,
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Abrir viewer'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
