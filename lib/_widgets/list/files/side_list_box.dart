import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/list/files/auto_icon.dart';
// mesmo viewer usado no WebPdfWidgetGeneric
import 'package:siged/_services/pdf/pdf_preview.dart';

class SideListBox extends StatelessWidget {
  final String title;
  /// Compat: aceita `String` (antigo) ou `Attachment` (novo)
  final List<dynamic> items;
  final int? selectedIndex;
  final VoidCallback? onAddPressed;
  final void Function(int index)? onTap;
  final void Function(int index)? onDelete;
  final void Function(int index)? onEditLabel; // só para attachment
  final double width;

  const SideListBox({
    super.key,
    required this.title,
    required this.items,
    this.selectedIndex,
    this.onAddPressed,
    this.onTap,
    this.onDelete,
    this.onEditLabel,
    this.width = 300,
  });

  String _normExt(String? e) {
    final s = (e ?? '').trim();
    if (s.isEmpty) return '';
    return (s.startsWith('.') ? s.substring(1) : s).toLowerCase();
  }

  bool _isPdfAttachment(Attachment a) {
    final ext = _normExt(a.ext);
    if (ext == 'pdf') return true;
    final url = (a.url).toLowerCase();
    return url.endsWith('.pdf');
  }

  Future<void> _openUrlExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
    }
  }

  Future<void> _openPdfDialog(BuildContext context, String url, {String? title}) async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980, maxHeight: 780),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // cabeçalho simples com título e fechar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title ?? 'Visualizar PDF',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(child: PdfPreview(pdfUrl: url)),
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
      width: width,
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
            // Cabeçalho
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1B2039),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Adicionar arquivo',
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: onAddPressed,
                  ),
                ],
              ),
            ),

            // Lista
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Sem arquivos. Toque em + e adicione.'),
              )
            else
              Builder(
                builder: (context) {
                  // Quando tiver muitos itens, ativa rolagem e fixa altura.
                  const maxHeight = 280.0;
                  final needsScroll = items.length > 6;

                  final list = ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: !needsScroll,
                    physics: needsScroll
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: divider),
                    itemBuilder: (context, i) {
                      final selected = selectedIndex != null && selectedIndex == i;
                      final dynamic raw = items[i];
                      final bool isAttachment = raw is Attachment;

                      final String label = isAttachment ? raw.label : raw.toString();

                      // Ícone: tenta usar extensão do attachment; cai para URL/nome
                      final String iconKey = isAttachment
                          ? ((_normExt(raw.ext).isNotEmpty) ? _normExt(raw.ext) : raw.url)
                          : label;

                      final String subtitle = isAttachment
                          ? _normExt(raw.ext).toUpperCase()
                          : '';

                      Future<void> handleTap() async {
                        // prioridade: callback externo
                        if (onTap != null) {
                          onTap!(i);
                          return;
                        }
                        // sem callback: comportamento padrão
                        if (isAttachment) {
                          final a = raw as Attachment;
                          if (_isPdfAttachment(a)) {
                            await _openPdfDialog(context, a.url, title: label);
                          } else {
                            await _openUrlExternal(a.url);
                          }
                        }
                      }

                      return Material(
                        color: selected ? cs.primary.withOpacity(0.08) : Colors.transparent,
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
                              if (isAttachment && onEditLabel != null)
                                IconButton(
                                  tooltip: 'Renomear rótulo',
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => onEditLabel!(i),
                                ),
                              if (onDelete != null)
                                IconButton(
                                  tooltip: 'Remover',
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => onDelete!(i),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  return needsScroll
                      ? SizedBox(height: maxHeight, child: Scrollbar(child: list))
                      : list;
                },
              )
          ],
        ),
      ),
    );
  }
}
