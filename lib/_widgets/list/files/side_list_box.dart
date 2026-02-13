import 'package:flutter/material.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/list/files/auto_icon.dart';
import 'package:sipged/_widgets/pdf/pdf_preview.dart';

// ✅ dialog mac
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

// ✅ input usado no rename
import 'package:sipged/_widgets/input/custom_text_field.dart';

class SideListBox extends StatefulWidget {
  final String title;

  /// Compat: aceita `String` (antigo) ou `Attachment` (novo)
  final List<dynamic> items;

  final int? selectedIndex;
  final VoidCallback? onAddPressed;

  /// callback do pai (seleção)
  final void Function(int index)? onTap;

  /// delete no backend (pai)
  final void Function(int index)? onDelete;

  /// ✅ controla se ao tocar abre o preview interno (showWindowDialogMac / launchUrl)
  /// - true: abre preview interno
  /// - false: NÃO abre preview interno (pai faz)
  final bool openOnTap;

  /// ✅ opcional: persistir rename (ex: salvar em Firestore/Storage)
  /// Retorne `true` se persistiu ok; `false` se falhou (widget reverte).
  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersist;

  /// ✅ opcional: notifica pai com a lista atual (já renomeada / deletada etc.)
  final void Function(List<dynamic> newItems)? onItemsChanged;

  final double width;

  // overlay
  final bool loading;
  final double? uploadProgress;

  /// ✅ controla se mostra o botão editar rótulo
  final bool enableRename;

  const SideListBox({
    super.key,
    required this.title,
    required this.items,
    this.selectedIndex,
    this.onAddPressed,
    this.onTap,
    this.onDelete,
    this.onRenamePersist,
    this.onItemsChanged,
    this.width = 300,
    this.loading = false,
    this.uploadProgress,
    this.enableRename = true,
    this.openOnTap = true,
  });

  @override
  State<SideListBox> createState() => _SideListBoxState();
}

class _SideListBoxState extends State<SideListBox> {
  late List<dynamic> _items;

  @override
  void initState() {
    super.initState();
    _items = List<dynamic>.from(widget.items);
  }

  bool _sameListShallow(List<dynamic> a, List<dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];

      if (x is Attachment && y is Attachment) {
        if (x.id != y.id || x.label != y.label || x.url != y.url) return false;
      } else {
        if (x.toString() != y.toString()) return false;
      }
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant SideListBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameListShallow(oldWidget.items, widget.items)) {
      _items = List<dynamic>.from(widget.items);
    }
  }

  void _emitItemsChanged() {
    final cb = widget.onItemsChanged;
    if (cb != null) cb(List<dynamic>.from(_items));
  }

  String _normExt(String? e) {
    final s = (e ?? '').trim();
    if (s.isEmpty) return '';
    return (s.startsWith('.') ? s.substring(1) : s).toLowerCase();
  }

  bool _isPdfAttachment(Attachment a) {
    final ext = _normExt(a.ext);
    if (ext == 'pdf') return true;
    final url = a.url.toLowerCase();
    return url.endsWith('.pdf');
  }

  Future<void> _openUrlExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _openPdfInMacDialog(BuildContext context, Attachment a) async {
    await showWindowDialogMac<void>(
      context: context,
      title: a.label.isNotEmpty ? a.label : 'Visualizar PDF',
      width: 980,
      contentPadding: EdgeInsets.zero,
      child: SizedBox(
        height: 740,
        child: PdfPreview(pdfUrl: a.url),
      ),
    );
  }

  Future<String?> _askNewLabel(BuildContext context, String current) async {
    final ctrl = TextEditingController(text: current);

    final newLabel = await showWindowDialogMac<String>(
      context: context,
      title: 'Renomear anexo',
      width: 420,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: ctrl,
                  labelText: 'Novo rótulo',
                  onSubmitted: (_) => Navigator.of(dialogCtx).pop(ctrl.text.trim()),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(null),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(ctrl.text.trim()),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final v = newLabel?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  Future<void> _renameAt(int index) async {
    if (!widget.enableRename) return;
    if (index < 0 || index >= _items.length) return;

    final raw = _items[index];
    if (raw is! Attachment) return;

    final oldItem = raw;
    final current = oldItem.label;

    final newLabel = await _askNewLabel(context, current);
    if (newLabel == null) return;
    if (newLabel == current) return;

    final updated = oldItem.copyWith(label: newLabel);

    setState(() {
      _items = [
        ..._items.sublist(0, index),
        updated,
        ..._items.sublist(index + 1),
      ];
    });
    _emitItemsChanged();

    final persist = widget.onRenamePersist;
    if (persist != null) {
      final ok = await persist(index: index, oldItem: oldItem, newItem: updated);
      if (!mounted) return;

      if (!ok) {
        setState(() {
          _items = [
            ..._items.sublist(0, index),
            oldItem,
            ..._items.sublist(index + 1),
          ];
        });
        _emitItemsChanged();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível renomear o anexo.')),
        );
      }
    }
  }

  void _removeAtLocal(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      _items = [
        ..._items.sublist(0, index),
        ..._items.sublist(index + 1),
      ];
    });
    _emitItemsChanged();
  }

  Widget _progressOverlay(BuildContext context) {
    final divider = Theme.of(context).dividerColor;
    final show = widget.loading || widget.uploadProgress != null;
    if (!show) return const SizedBox.shrink();

    final value = widget.uploadProgress;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: divider)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  value == null ? 'Carregando...' : 'Enviando...',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: SipGedTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (value != null)
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )
              else
                const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;

    return SizedBox(
      width: widget.width,
      child: Card(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: SipGedTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Adicionar arquivo',
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: widget.onAddPressed,
                  ),
                ],
              ),
            ),

            // Body com overlay
            Stack(
              children: [
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Sem arquivos. Toque em + e adicione.'),
                  )
                else
                  Builder(
                    builder: (context) {
                      const maxHeight = 280.0;
                      final needsScroll = _items.length > 6;

                      final list = ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: !needsScroll,
                        physics: needsScroll
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, thickness: 1, color: divider),
                        itemBuilder: (context, i) {
                          final selected =
                              widget.selectedIndex != null && widget.selectedIndex == i;

                          final raw = _items[i];
                          final bool isAttachment = raw is Attachment;

                          final String label = isAttachment ? raw.label : raw.toString();

                          final String iconKey = isAttachment
                              ? (_normExt(raw.ext).isNotEmpty ? _normExt(raw.ext) : raw.url)
                              : label;

                          final String subtitle =
                          isAttachment ? _normExt(raw.ext).toUpperCase() : '';

                          Future<void> handleTap() async {
                            // 1) sempre deixa o pai saber (selecionar índice etc.)
                            if (widget.onTap != null) {
                              widget.onTap!(i);
                            }

                            // 2) se NÃO quer abrir preview interno, para aqui
                            if (!widget.openOnTap) return;

                            // 3) abre preview interno (Mac dialog / external)
                            if (!isAttachment) return;
                            final a = raw;

                            if (_isPdfAttachment(a)) {
                              await _openPdfInMacDialog(context, a);
                            } else {
                              await _openUrlExternal(a.url);
                            }
                          }

                          return Material(
                            color: selected ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
                            child: ListTile(
                              dense: true,
                              visualDensity: const VisualDensity(vertical: -2),
                              minVerticalPadding: 0,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              leading: AutoIcon(nameOrUrl: iconKey),
                              title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: subtitle.isEmpty
                                  ? null
                                  : Text(subtitle, style: const TextStyle(fontSize: 11)),
                              onTap: handleTap,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isAttachment && widget.enableRename)
                                    IconButton(
                                      tooltip: 'Renomear rótulo',
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _renameAt(i),
                                    ),
                                  if (widget.onDelete != null)
                                    IconButton(
                                      tooltip: 'Remover',
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        widget.onDelete!(i);
                                        _removeAtLocal(i);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      final content = needsScroll
                          ? SizedBox(height: maxHeight, child: Scrollbar(child: list))
                          : list;

                      final overlayActive = widget.loading || widget.uploadProgress != null;

                      return Padding(
                        padding: EdgeInsets.only(top: overlayActive ? 44 : 0),
                        child: content,
                      );
                    },
                  ),

                _progressOverlay(context),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
