import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/attributes/geo_attributes_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/attributes/geo_attributes_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/attributes/geo_attributes_state.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';
import 'package:sipged/_widgets/windows/window_dialog.dart';

enum AttributesTableMode { importFile, firestore }

class AttributesDialog extends StatefulWidget {
  final String collectionPath;
  final List<String> targetFields;
  final String? title;
  final String? description;
  final AttributesTableMode mode;

  const AttributesDialog({
    super.key,
    required this.collectionPath,
    required this.targetFields,
    this.title,
    this.description,
    this.mode = AttributesTableMode.importFile,
  });

  @override
  State<AttributesDialog> createState() => _AttributesDialogState();
}

class _AttributesDialogState extends State<AttributesDialog> {
  final TextEditingController _searchCtrl = TextEditingController();

  int _rowsPerPage = 25;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() {
      if (!mounted) return;
      setState(() {
        _pageIndex = 0;
      });
    });

    Future.microtask(() {
      final cubit = context.read<GeoAttributesCubit>();
      if (widget.mode == AttributesTableMode.firestore) {
        cubit.startFromFirestore(widget.collectionPath);
      } else {
        cubit.startImport(widget.collectionPath);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle = widget.title ??
        (widget.mode == AttributesTableMode.firestore
            ? 'Tabela de atributos (${widget.collectionPath})'
            : 'Importar (${widget.collectionPath})');

    return BlocListener<GeoAttributesCubit, GeoAttributesState>(
      listener: (context, state) {
        if (widget.mode == AttributesTableMode.importFile &&
            state.status == GeoAttributesStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      child: WindowDialog(
        title: dialogTitle,
        width: 1400,
        contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        onClose: () => Navigator.of(context).pop(false),
        child: SizedBox(
          height: 760,
          child: BlocBuilder<GeoAttributesCubit, GeoAttributesState>(
            builder: (context, state) {
              final isLoading =
                  state.status == GeoAttributesStatus.pickingFile ||
                      state.status == GeoAttributesStatus.loadingFirestore ||
                      state.status == GeoAttributesStatus.idle;

              if (isLoading) {
                return _center(
                  widget.mode == AttributesTableMode.firestore
                      ? 'Carregando feições do Firebase...'
                      : 'Carregando arquivo para pré-visualização...',
                );
              }

              if (state.status == GeoAttributesStatus.failure) {
                return _error(state.error);
              }

              if (state.features.isEmpty) {
                return _center('Nenhuma feição encontrada.');
              }

              final columns = state.columns;
              final selectedColumnNames = columns
                  .where((c) => c.selected)
                  .map((c) => c.name)
                  .toList(growable: false);

              final hasGeometry = state.features.any((f) => f.hasGeometry);

              final tableColumns = <String>[
                ...selectedColumnNames,
                if (hasGeometry) '_geometry_preview_',
              ];

              final filteredIndexes = _applySearchFilter(
                state: state,
                columnsForSearch: selectedColumnNames.isEmpty
                    ? columns.map((e) => e.name).toList(growable: false)
                    : selectedColumnNames,
                query: _searchCtrl.text,
              );

              final total = state.features.length;
              final filteredTotal = filteredIndexes.length;

              final pageData = _pageSlice(filteredIndexes, filteredTotal);
              final pageIndexes = pageData.$1;
              final currentPage = pageData.$2;
              final totalPages = pageData.$3;

              final geometryTypes = state.features
                  .map((e) => e.geometryType.trim())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

              final tipo = geometryTypes.isEmpty
                  ? 'Desconhecido'
                  : geometryTypes.length == 1
                  ? geometryTypes.first
                  : 'Misto (${geometryTypes.join(', ')})';

              return Stack(
                children: [
                  Column(
                    children: [
                      _topBar(
                        context,
                        state: state,
                        tipo: tipo,
                        total: total,
                        filteredTotal: filteredTotal,
                        selectedColumns: selectedColumnNames.length,
                        hasGeometry: hasGeometry,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _tableQgisLike(
                          context,
                          state: state,
                          tableColumns: tableColumns,
                          rowIndexes: pageIndexes,
                          hasGeometry: hasGeometry,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _bottomBar(
                        context,
                        state: state,
                        filteredTotal: filteredTotal,
                        currentPage: currentPage,
                        totalPages: totalPages,
                      ),
                    ],
                  ),
                  if (state.status == GeoAttributesStatus.saving ||
                      state.status == GeoAttributesStatus.deleting)
                    Positioned.fill(
                      child: _overlaySaving(state),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar(
      BuildContext context, {
        required GeoAttributesState state,
        required String tipo,
        required int total,
        required int filteredTotal,
        required int selectedColumns,
        required bool hasGeometry,
      }) {
    final cubit = context.read<GeoAttributesCubit>();

    final desc = widget.description ??
        (widget.mode == AttributesTableMode.firestore
            ? 'Modo Firebase: cada linha representa uma feição geográfica salva na camada. Você pode selecionar linhas e excluir. Renomear colunas aqui altera apenas a visualização atual.'
            : 'Modo importação: cada linha será salva como uma feição geográfica no Firebase, contendo attributes em editor e a geometria associada.');

    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(desc, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip('Geometria', tipo),
                const SizedBox(width: 8),
                _chip('Linhas', '$filteredTotal de $total'),
                const SizedBox(width: 8),
                _chip('Colunas selecionadas', '$selectedColumns'),
                if (hasGeometry) ...[
                  const SizedBox(width: 8),
                  _chip('Preview', 'geom'),
                ],
                const Spacer(),
                SizedBox(
                  width: 360,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: 'Filtrar (busca em todas as colunas)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _searchCtrl.clear,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  tooltip: 'Ações de colunas/linhas',
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                      value: 'select_all_cols',
                      child: Text('Selecionar todas as colunas'),
                    ),
                    PopupMenuItem(
                      value: 'unselect_all_cols',
                      child: Text('Desmarcar todas as colunas'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'select_all_rows',
                      child: Text('Selecionar todas as linhas'),
                    ),
                    PopupMenuItem(
                      value: 'unselect_all_rows',
                      child: Text('Desmarcar todas as linhas'),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'select_all_cols') {
                      for (int i = 0; i < state.columns.length; i++) {
                        cubit.toggleColumnSelection(i, true);
                      }
                    }

                    if (v == 'unselect_all_cols') {
                      for (int i = 0; i < state.columns.length; i++) {
                        cubit.toggleColumnSelection(i, false);
                      }
                    }

                    if (v == 'select_all_rows') {
                      for (int i = 0; i < state.features.length; i++) {
                        cubit.toggleRowSelection(i, true);
                      }
                    }

                    if (v == 'unselect_all_rows') {
                      for (int i = 0; i < state.features.length; i++) {
                        cubit.toggleRowSelection(i, false);
                      }
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _tableQgisLike(
      BuildContext context, {
        required GeoAttributesState state,
        required List<String> tableColumns,
        required List<int> rowIndexes,
        required bool hasGeometry,
      }) {
    if (rowIndexes.isEmpty) {
      return _center('Nenhum registro para exibir nesta página.');
    }

    final cubit = context.read<GeoAttributesCubit>();

    final dataColumns = <DataColumn>[
      const DataColumn(label: Text('Sel')),
      const DataColumn(label: Text('FID')),
      ...tableColumns.map((col) {
        if (col == '_geometry_preview_') {
          return const DataColumn(label: Text('geom'));
        }

        final idx = state.columns.indexWhere((c) => c.name == col);
        final columnMeta = idx >= 0 ? state.columns[idx] : null;

        return DataColumn(
          label: Row(
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
                  final newName = await _askRename(context, current: col);
                  if (newName == null || newName.trim().isEmpty) return;
                  cubit.renameColumn(idx, newName.trim());
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<TypeFieldGeoJson>(
                tooltip: 'Tipo da coluna',
                onSelected: (t) {
                  if (idx >= 0) cubit.changeColumnType(idx, t);
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
          ),
        );
      }),
    ];

    final rows = <DataRow>[];

    for (final featureIndex in rowIndexes) {
      final f = state.features[featureIndex];
      final props = f.editedProperties;

      final cells = <DataCell>[
        DataCell(
          Checkbox(
            value: f.selected,
            onChanged: (v) => cubit.toggleRowSelection(featureIndex, v ?? false),
            visualDensity: VisualDensity.compact,
          ),
        ),
        DataCell(Text(featureIndex.toString())),
      ];

      for (final col in tableColumns) {
        if (col == '_geometry_preview_') {
          if (!hasGeometry || !f.hasGeometry) {
            cells.add(const DataCell(Text('')));
          } else {
            final partsCount = f.geometryParts.length;
            final ptsCount = f.geometryPoints.length;
            final geometryType = f.geometryType.trim();

            String label;
            if (geometryType.isNotEmpty) {
              label = geometryType;
            } else if (partsCount > 1) {
              label = '$partsCount partes';
            } else if (ptsCount > 0) {
              label = '$ptsCount pts';
            } else {
              label = 'geom';
            }

            if (ptsCount > 0) {
              label += ' [$ptsCount pts]';
            }

            cells.add(DataCell(Text(label)));
          }
          continue;
        }

        final v = props[col];
        cells.add(DataCell(Text(_stringifyCell(v))));
      }

      rows.add(DataRow(cells: cells));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1200),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowHeight: 38,
                  dataRowMinHeight: 34,
                  dataRowMaxHeight: 34,
                  columnSpacing: 18,
                  horizontalMargin: 12,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  dataTextStyle: const TextStyle(color: Colors.black87),
                  columns: dataColumns,
                  rows: rows,
                ),
              ),
            ),
          ),
        ),
      ),
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

  String _stringifyCell(dynamic v) {
    if (v == null) return '';
    if (v is num || v is bool) return v.toString();
    if (v is DateTime) return v.toIso8601String();
    if (v is String) return v;
    if (v is List) return '[${v.length}]';
    if (v is Map) return '{...}';
    return v.toString();
  }

  Widget _bottomBar(
      BuildContext context, {
        required GeoAttributesState state,
        required int filteredTotal,
        required int currentPage,
        required int totalPages,
      }) {
    final cubit = context.read<GeoAttributesCubit>();
    final isBusy = state.status == GeoAttributesStatus.saving ||
        state.status == GeoAttributesStatus.deleting;

    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            const Text('Linhas por página: '),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _rowsPerPage,
              items: const [10, 25, 50, 100]
                  .map(
                    (v) => DropdownMenuItem(
                  value: v,
                  child: Text('$v'),
                ),
              )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _rowsPerPage = v;
                  _pageIndex = 0;
                });
              },
            ),
            const SizedBox(width: 16),
            Text('Página $currentPage de $totalPages'),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Anterior',
              onPressed:
              _pageIndex <= 0 ? null : () => setState(() => _pageIndex--),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Próxima',
              onPressed: _pageIndex >= totalPages - 1
                  ? null
                  : () => setState(() => _pageIndex++),
              icon: const Icon(Icons.chevron_right),
            ),
            const Spacer(),
            if (widget.mode == AttributesTableMode.firestore) ...[
              OutlinedButton.icon(
                onPressed: isBusy
                    ? null
                    : () => cubit.startFromFirestore(widget.collectionPath),
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: (isBusy || !state.hasAnySelected)
                    ? null
                    : cubit.deleteSelectedFromFirestore,
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  isBusy ? 'Processando...' : 'Excluir selecionados',
                ),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: isBusy ? null : cubit.saveAllFields,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Importar para o Firebase'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<int> _applySearchFilter({
    required GeoAttributesState state,
    required List<String> columnsForSearch,
    required String query,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return List<int>.generate(state.features.length, (i) => i);
    }

    final out = <int>[];

    for (int i = 0; i < state.features.length; i++) {
      final f = state.features[i];
      final props = f.editedProperties;

      bool match = false;
      for (final col in columnsForSearch) {
        final v = props[col];
        if (v == null) continue;

        if (v.toString().toLowerCase().contains(q)) {
          match = true;
          break;
        }
      }

      if (match) {
        out.add(i);
      }
    }

    return out;
  }

  (List<int>, int, int) _pageSlice(
      List<int> filteredIndexes,
      int filteredTotal,
      ) {
    final totalPages = (filteredTotal / _rowsPerPage).ceil().clamp(1, 999999);

    if (_pageIndex > totalPages - 1) {
      _pageIndex = totalPages - 1;
    }

    final currentPage = (_pageIndex + 1).clamp(1, totalPages);
    final start = _pageIndex * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filteredTotal);

    final pageIndexes =
    (start < end) ? filteredIndexes.sublist(start, end) : const <int>[];

    return (pageIndexes, currentPage, totalPages);
  }

  Widget _center(String text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _error(String? error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Falha ao carregar.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(error ?? 'Erro desconhecido'),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Fechar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlaySaving(GeoAttributesState state) {
    final progresso = (state.progress.clamp(0.0, 1.0) * 100).toStringAsFixed(1);

    final msg = state.status == GeoAttributesStatus.deleting
        ? 'Excluindo no Firebase...'
        : 'Salvando no Firebase...';

    final isIndeterminate = state.progress <= 0.0;

    return Container(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Card(
            color: Colors.black.withValues(alpha: 0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 260,
                    child: LinearProgressIndicator(
                      value: isIndeterminate ? null : state.progress,
                      backgroundColor: Colors.grey.shade300,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$progresso% concluído',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    msg,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}