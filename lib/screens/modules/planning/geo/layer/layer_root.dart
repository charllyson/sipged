import 'package:flutter/material.dart';

class LayerRootHeader extends StatelessWidget {
  const LayerRootHeader({
    super.key,
    required this.layersCount,
    required this.groupsCount,
    required this.onTap,
    this.onDropItem,
  });

  final int layersCount;
  final int groupsCount;
  final VoidCallback onTap;

  final void Function(
      String draggedId,
      String? targetParentId,
      int targetIndex,
      )? onDropItem;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        return details.data.trim().isNotEmpty;
      },
      onAcceptWithDetails: (details) {
        onDropItem?.call(details.data, null, 0);
      },
      builder: (context, candidateData, rejectedData) {
        final hoveringInside = candidateData.isNotEmpty;

        final Color backgroundColor = hoveringInside
            ? const Color(0xFFF3F4F6)
            : const Color(0xFFF8FAFC);

        final Color borderColor = hoveringInside
            ? const Color(0xFF9CA3AF)
            : const Color(0xFFE5E7EB);

        const Color titleColor = Color(0xFF111827);

        final Color iconBackgroundColor = hoveringInside
            ? const Color(0xFFE5E7EB)
            : const Color(0xFFF1F5F9);

        const Color iconColor = Color(0xFF4B5563);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color: borderColor,
                width: hoveringInside ? 1.2 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    size: 18,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: hoveringInside
                        ? const Column(
                      key: ValueKey('root_hovering'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raiz das camadas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Solte aqui para mover para a raiz',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ],
                    )
                        : const Align(
                      key: ValueKey('root_normal'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Raiz das camadas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}