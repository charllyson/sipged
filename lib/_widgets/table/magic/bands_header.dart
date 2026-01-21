// lib/_widgets/table/magic/bands_header.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;

class BandsHeader extends StatelessWidget {
  const BandsHeader({
    super.key,
    required this.ctrl,
    required this.bandHeight,
    this.addTopBorder = false,
  });

  final bc.MagicTableController ctrl;
  final double bandHeight;
  final bool addTopBorder;

  @override
  Widget build(BuildContext context) {
    // Agrupa colunas consecutivas por 'group'
    final groups = <_BandInfo>[];
    if (ctrl.hasSchema && ctrl.columns.isNotEmpty) {
      String? curGroup;
      double accWidth = 0;
      for (int c = 0; c < ctrl.colCount; c++) {
        final meta = ctrl.columns[c];
        final g = meta.group ?? '';
        final w = (c < ctrl.colWidths.length) ? ctrl.colWidths[c] : 120.0;

        if (curGroup == null) {
          curGroup = g;
          accWidth = w;
        } else if (g == curGroup) {
          accWidth += w;
        } else {
          groups.add(_BandInfo(curGroup.isEmpty ? null : curGroup, accWidth));
          curGroup = g;
          accWidth = w;
        }
      }
      if (curGroup != null) {
        groups.add(_BandInfo(curGroup.isEmpty ? null : curGroup, accWidth));
      }
    } else {
      // Sem schema: uma única banda cobrindo todas colunas
      final total = ctrl.colWidths.fold<double>(0.0, (s, w) => s + w);
      groups.add(_BandInfo(null, total));
    }

    return Row(
      children: groups.map((b) => _bandBox(b.label ?? '', b.width)).toList(),
    );
  }

  Widget _bandBox(String label, double width) {
    if (width <= 0) return const SizedBox.shrink();
    final borderColor = Colors.grey.shade300;
    return Container(
      width: width,
      height: bandHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: addTopBorder ? BorderSide(color: borderColor, width: 1) : BorderSide.none,
          left: BorderSide(color: borderColor, width: 1),
          right: BorderSide(color: borderColor, width: 1),
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Text(
        label.isEmpty ? ' ' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BandInfo {
  final String? label;
  final double width;
  _BandInfo(this.label, this.width);
}
