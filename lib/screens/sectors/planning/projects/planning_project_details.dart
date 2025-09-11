import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:siged/_blocs/actives/roads/active_roads_data.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

class PlanningProjectDetails extends StatefulWidget {

  final ContractData contractData;
  const PlanningProjectDetails({super.key, required this.contractData});

  @override
  State<PlanningProjectDetails> createState() => _PlanningProjectDetailsState();
}

class _PlanningProjectDetailsState extends State<PlanningProjectDetails> {
  final _pending = <_DxfPendingItem>[]; // arquivos escolhidos (ainda não "enviados")
  final _existing = <_DxfSavedItem>[];  // arquivos "salvos" localmente
  bool _loadingList = true;
  bool _uploading = false;

  String get _contractId => widget.contractData.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  /// Carrega anexos existentes
  /// MODO LOCAL: apenas marca como carregado (não busca nada).
  Future<void> _loadExisting() async {
    setState(() => _loadingList = false);
  }

  Future<void> _pickDxf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['dxf'],
      allowMultiple: false,
      withData: kIsWeb, // no Web precisamos dos bytes
    );
    if (result == null || result.files.isEmpty) return;

    final f = result.files.first;
    setState(() {
      _pending.add(_DxfPendingItem(
        name: f.name,
        bytes: kIsWeb ? f.bytes : null,
        path: kIsWeb ? null : f.path,
        size: (kIsWeb ? f.bytes?.length : f.size), // melhor esforço
      ));
    });
  }

  Future<void> _uploadAll() async {
    if (_pending.isEmpty) return;
    setState(() => _uploading = true);

    try {
      for (final item in List<_DxfPendingItem>.from(_pending)) {
        await _uploadOne(item);
      }
      await _loadExisting();
    } catch (e) {
      debugPrint('Erro no upload local: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// "Envia" um item pendente:
  /// MODO LOCAL: move dos pendentes para existentes com metadados fake.
  Future<void> _uploadOne(_DxfPendingItem item) async {
    final now = DateTime.now();
    final fakeId = '${now.millisecondsSinceEpoch}_${item.name}';
    final fakeUrl = 'local://${item.name}';

    setState(() {
      _pending.remove(item);
      _existing.insert(
        0,
        _DxfSavedItem(
          id: fakeId,
          name: item.name,
          description: item.descriptionCtrl.text,
          size: item.size,
          url: fakeUrl,
          storagePath: '',
          createdAt: now,
        ),
      );
    });
  }

  /// Exclui um anexo existente:
  /// MODO LOCAL: apenas remove da lista em memória.
  Future<void> _deleteExisting(_DxfSavedItem item) async {
    setState(() => _existing.removeWhere((e) => e.id == item.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(
            double.infinity,
            72
        ),
        child: UpBar(
          leading: Row(
            children: [
              SizedBox(width: 12),
              const BackCircleButton(),
            ],
          ),
          titleWidgets: [Text('PROJETOS DE: ${widget.contractData.summarySubjectContract}')],
        ),
      ),
      body: Stack(
        children: [
          BackgroundClean(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DxfPickerSection(
                    pending: _pending,
                    loading: _uploading,
                    onPick: _pickDxf,
                    onRemovePending: (i) => setState(() => _pending.removeAt(i)),
                    onUploadOne: (i) => _uploadOne(_pending[i]),
                  ),
                  const SizedBox(height: 24),
                  _ExistingDxfsSection(
                    loading: _loadingList,
                    items: _existing,
                    onDelete: _deleteExisting,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ======= MODELOS AUXILIARES =======
class _DxfPendingItem {
  final String name;
  final String? path; // mobile/desktop
  final Uint8List? bytes; // web
  final int? size;
  final TextEditingController descriptionCtrl;

  _DxfPendingItem({
    required this.name,
    this.path,
    this.bytes,
    this.size,
    String? initialDescription,
  }) : descriptionCtrl = TextEditingController(text: initialDescription ?? '');
}

class _DxfSavedItem {
  final String id;
  final String name;
  final String description;
  final int? size;
  final String url;
  final String storagePath;
  final DateTime? createdAt;

  _DxfSavedItem({
    required this.id,
    required this.name,
    required this.description,
    required this.size,
    required this.url,
    required this.storagePath,
    required this.createdAt,
  });
}

/// ======= UI: PENDENTES (a escolher + lista) =======
class _DxfPickerSection extends StatelessWidget {
  final List<_DxfPendingItem> pending;
  final bool loading;
  final VoidCallback onPick;
  final void Function(int index) onRemovePending;
  final Future<void> Function(int index) onUploadOne;

  const _DxfPickerSection({
    required this.pending,
    required this.loading,
    required this.onPick,
    required this.onRemovePending,
    required this.onUploadOne,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.layers_outlined),
                const SizedBox(width: 8),
                const Text('Adicione um trecho', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: loading ? null : onPick,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Adicionar outro trecho'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              const Text('Nenhum pendente. Clique em “Adicionar”.')
            else
              Column(
                children: [
                  for (int i = 0; i < pending.length; i++)
                    _PendingDxfTile(
                      item: pending[i],
                      index: i,
                      onRemove: () => onRemovePending(i),
                      onUpload: () => onUploadOne(i),
                      disabled: loading,
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: loading ? null : onPick,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar outro DXF'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingDxfTile extends StatelessWidget {
  final _DxfPendingItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onUpload;
  final bool disabled;

  const _PendingDxfTile({
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onUpload,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insert_drive_file_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: item.descriptionCtrl,
                  enabled: !disabled,
                  labelText: 'Descrição do DXF',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                tooltip: 'Enviar este',
                onPressed: disabled ? null : onUpload,
                icon: const Icon(Icons.cloud_upload_outlined),
              ),
              IconButton(
                tooltip: 'Remover',
                onPressed: disabled ? null : onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ======= UI: EXISTENTES (já enviados) =======
class _ExistingDxfsSection extends StatelessWidget {
  final bool loading;
  final List<_DxfSavedItem> items;
  final Future<void> Function(_DxfSavedItem item) onDelete;

  const _ExistingDxfsSection({
    required this.loading,
    required this.items,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open_outlined),
                const SizedBox(width: 8),
                const Text('DXFs já anexados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (items.isEmpty)
              const Text('Nenhum DXF enviado ainda.')
            else
              Column(
                children: [
                  for (final it in items)
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(it.name),
                      subtitle: Text(it.description.isEmpty ? 'Sem descrição' : it.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Baixar/abrir',
                            onPressed: () => _openUrl(context, it.url),
                            icon: const Icon(Icons.open_in_new),
                          ),
                          IconButton(
                            tooltip: 'Excluir',
                            onPressed: () async {
                              final ok = await _confirm(context, 'Excluir este anexo?');
                              if (ok) await onDelete(it);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String msg) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    ) ??
        false;
  }

  void _openUrl(BuildContext context, String url) {
    // No Web/Mobile/Desktop: implementar com url_launcher.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abrindo URL… (implementar com url_launcher)')),
    );
  }
}
