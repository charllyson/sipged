import 'package:flutter/material.dart';

class SideListBox extends StatelessWidget {
  final String title;
  final List<String> items;
  final int? selectedIndex;
  final VoidCallback? onAddPressed;
  final void Function(int index)? onTap;
  final void Function(int index)? onDelete;
  final double width;

  /// Opcional: sobrescrever o leading por item (ex.: para o box georreferenciado)
  final Widget Function(String name)? leadingBuilder;

  const SideListBox({
    super.key,
    required this.title,
    required this.items,
    this.selectedIndex,
    this.onAddPressed,
    this.onTap,
    this.onDelete,
    this.width = 300,
    this.leadingBuilder,
  });

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
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: Scrollbar(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: divider),
                    itemBuilder: (context, i) {
                      final selected = selectedIndex != null && selectedIndex == i;
                      final name = items[i];

                      return Material(
                        color: selected ? cs.primary.withOpacity(0.08) : Colors.transparent,
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          leading: leadingBuilder?.call(name) ?? _autoIconFor(name),
                          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: onTap != null ? () => onTap!(i) : null,
                          trailing: onDelete == null
                              ? null
                              : IconButton(
                            tooltip: 'Remover',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onDelete!(i),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- helpers ----------
  Widget _autoIconFor(String nameOrUrl) {
    final ext = _extractExt(nameOrUrl); // ex.: ".kml"

    switch (ext) {
      case '.pdf':
        return const Icon(Icons.picture_as_pdf);
      case '.kml':
        return const Icon(Icons.terrain); // KML
      case '.kmz':
        return const Icon(Icons.layers); // KMZ
      case '.geojson':
      case '.json':
        return const Icon(Icons.public); // GeoJSON
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.webp':
        return const Icon(Icons.image);
      case '.doc':
      case '.docx':
        return const Icon(Icons.description);
      case '.xls':
      case '.xlsx':
      case '.csv':
        return const Icon(Icons.table_chart);
      case '.ppt':
      case '.pptx':
        return const Icon(Icons.slideshow);
      case '.zip':
      case '.rar':
      case '.7z':
        return const Icon(Icons.archive);
      case '.txt':
      case '.md':
        return const Icon(Icons.notes);
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }

  /// Extrai a extensão de forma robusta (minúscula), ignorando query/hash e espaços.
  String _extractExt(String input) {
    var s = input.trim();

    // remove query e hash
    final q = s.indexOf('?');
    if (q != -1) s = s.substring(0, q);
    final h = s.indexOf('#');
    if (h != -1) s = s.substring(0, h);

    // pega só o último segmento do path
    s = s.split('/').last.trim();

    // match da última extensão no fim da string
    final m = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(s);
    if (m == null) return '';
    return '.${m.group(1)!.toLowerCase()}';
  }
}
