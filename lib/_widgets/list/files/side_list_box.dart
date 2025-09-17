import 'package:flutter/material.dart';

class SideListBox extends StatelessWidget {
  final String title;
  final List<String> items;

  /// índice selecionado (destaca a linha)
  final int? selectedIndex;

  /// chamado ao tocar no botão +
  final VoidCallback? onAddPressed;

  /// abre o item ao tocar na linha
  final void Function(int index)? onTap;

  /// remove o item (ícone de lixeira na linha)
  final void Function(int index)? onDelete;

  /// largura fixa do box (default 300)
  final double width;

  const SideListBox({
    super.key,
    required this.title,
    required this.items,
    this.selectedIndex,
    this.onAddPressed,
    this.onTap,
    this.onDelete,
    this.width = 300,
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
          mainAxisSize: MainAxisSize.min, // evita expandir em altura infinita
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12,),
              decoration: BoxDecoration(
                color: Color(0xFF1B2039),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Adicionar arquivo',
                    icon: Icon(Icons.add, color: Colors.white),
                    onPressed: onAddPressed,
                  ),
                ],
              ),
            ),

            // Lista
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Sem arquivos. Toque em + para adicionar.'),
              )
            else
              ConstrainedBox(
                // limita a altura da lista para evitar "unbounded height"
                constraints: const BoxConstraints(maxHeight: 240),
                child: Scrollbar(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: divider),
                    itemBuilder: (context, i) {
                      final selected = selectedIndex != null && selectedIndex == i;
                      return Material(
                        color: selected ? cs.primary.withOpacity(0.08) : Colors.transparent,
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(
                            items[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: onTap != null ? () => onTap!(i) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
