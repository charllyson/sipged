// lib/screens/modules/actives/oaes/records/list_oaes_status.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';

import 'list_oaes_table.dart';

typedef OaeTapCallback = void Function(ActiveOaesData oae);
typedef OaeDeleteCallback = void Function(String oaeId);
typedef OaeSortCallback = void Function(int columnIndex, bool ascending);

class ListOaesStatus extends StatefulWidget {
  const ListOaesStatus({
    super.key,
    required this.title,
    required this.scoreKey,
    required this.expansionKey,
    required this.color,
    required this.items,
    required this.constraints,
    required this.onTapItem,
    required this.onDelete,
    required this.onExpansionChanged,
    required this.onSort,
    this.sortColumnIndex,
    this.isAscending = true,
    this.initiallyExpanded = false,
  });

  final String title;
  final int scoreKey;
  final String expansionKey;
  final Color color;
  final List<ActiveOaesData> items;
  final BoxConstraints constraints;

  final OaeTapCallback onTapItem;
  final OaeDeleteCallback onDelete;
  final ValueChanged<bool> onExpansionChanged;

  final OaeSortCallback onSort;
  final int? sortColumnIndex;
  final bool isAscending;

  final bool initiallyExpanded;

  @override
  State<ListOaesStatus> createState() => _ListOaesStatusState();
}

class _ListOaesStatusState extends State<ListOaesStatus> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();

    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant ListOaesStatus oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  void _handleExpansionChanged(bool open) {
    setState(() {
      _isExpanded = open;
    });

    widget.onExpansionChanged(open);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: PageStorageKey<String>('tile_oae_${widget.expansionKey}'),
          initiallyExpanded: widget.initiallyExpanded,
          maintainState: true,
          onExpansionChanged: _handleExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_tree_rounded,
              color: widget.color,
              size: 22,
            ),
          ),
          title: Text(
            widget.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            '$total OAE${total == 1 ? '' : '\'s'} encontrado${total == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: widget.color.withValues(alpha: 0.12),
                ),
                child: Text(
                  '$total',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: widget.color,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
            ],
          ),
          children: [
            if (_isExpanded)
              ListOaesTable(
                items: widget.items,
                constraints: widget.constraints,
                onTapItem: widget.onTapItem,
                onDelete: widget.onDelete,
                sortColumnIndex: widget.sortColumnIndex,
                isAscending: widget.isAscending,
                onSort: widget.onSort,
              ),
          ],
        ),
      ),
    );
  }
}