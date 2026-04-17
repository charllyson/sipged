import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_state.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';
import 'package:sipged/_widgets/table/paged/paged_table_metrics.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_page.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_row.dart';

class AttributeContent extends StatelessWidget {
  final AttributeMode mode;
  final FeatureState state;
  final List<String> tableColumns;
  final List<AttributeRow> rows;
  final String? selectedKey;
  final ValueChanged<PagedTableMetrics> onMetricsChanged;
  final ValueChanged<AttributeRow> onTapRow;

  const AttributeContent({
    super.key,
    required this.mode,
    required this.state,
    required this.tableColumns,
    required this.rows,
    required this.selectedKey,
    required this.onMetricsChanged,
    required this.onTapRow,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Nenhum registro para exibir.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final cubit = context.read<FeatureCubit>();

    return PagedTableChanged<AttributeRow>(
      listData: rows,
      getKey: (row) => row.feature.selectionKey,
      selectedKey: selectedKey,
      keepSelectionInternally: false,
      enableRowTapSelection: true,
      headingRowHeight: 38,
      dataRowMinHeight: 34,
      dataRowMaxHeight: 34,
      cardMargin: EdgeInsets.zero,
      elevation: 0,
      colorHeadTable: Colors.grey.shade100,
      colorHeadTableText: Colors.black87,
      minTableWidth: 1200,
      rowsPerPageOptions: const [10, 25, 50, 100],
      initialRowsPerPage: 25,
      enablePagination: true,
      onMetricsChanged: onMetricsChanged,
      onTapItem: onTapRow,
      onDelete: mode == AttributeMode.firestore
          ? (row) {
        final feature = state.importFeatures[row.featureIndex];
        if (!feature.selected) {
          cubit.toggleRowSelection(row.featureIndex, true);
        }
        cubit.deleteSelectedFromFirestore();
      }
          : null,
      columns: tableColumns.map((col) {
        final idx = state.importColumns.indexWhere((c) => c.name == col);
        final columnMeta = idx >= 0 ? state.importColumns[idx] : null;

        return PagedColum<AttributeRow>(
          title: col,
          getter: (row) {
            final value = row.feature.editedProperties[col];
            return _stringifyCell(value);
          },
          headerBuilder: (ctx) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    col,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Renomear coluna',
                  onPressed: idx < 0
                      ? null
                      : () async {
                    final newName = await _askRename(
                      ctx,
                      current: col,
                    );
                    if (newName == null || newName.trim().isEmpty) {
                      return;
                    }
                    cubit.renameColumn(idx, newName.trim());
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<TypeFieldGeoJson>(
                  tooltip: 'Tipo da coluna',
                  onSelected: (t) {
                    if (idx >= 0) {
                      cubit.changeColumnType(idx, t);
                    }
                  },
                  itemBuilder: (_) => TypeFieldGeoJson.values
                      .map(
                        (t) => PopupMenuItem(
                      value: t,
                      child: Text(
                        columnMeta?.type == t
                            ? 'Tipo: ${t.name} ✓'
                            : 'Tipo: ${t.name}',
                      ),
                    ),
                  )
                      .toList(),
                  child: const Icon(Icons.data_object, size: 16),
                ),
              ],
            );
          },
        );
      }).toList(),
    );
  }

  Future<String?> _askRename(
      BuildContext context, {
        required String current,
      }) {
    final ctrl = TextEditingController(text: current);

    return showWindowDialog<String>(
      context: context,
      title: 'Renomear coluna',
      width: 420,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: ctrl,
                  labelText: 'Novo nome',
                  onSubmitted: (value) {
                    Navigator.of(dialogCtx).pop(value.trim());
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(dialogCtx).pop(ctrl.text.trim()),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _stringifyCell(dynamic value) {
    if (value == null) return '';
    if (value is num || value is bool) return value.toString();
    if (value is DateTime) return value.toIso8601String();
    if (value is String) return value;
    if (value is List) return '[${value.length}]';
    if (value is Map) return '{...}';
    return value.toString();
  }
}