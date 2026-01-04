// lib/_widgets/vector_import/vector_preview_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_services/geoJson/vector_import_cubit.dart';
import 'package:siged/_services/geoJson/vector_import_data.dart';
import 'package:siged/_services/geoJson/vector_import_state.dart';
import 'package:siged/_widgets/windows/window_dialog.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

/// Classe auxiliar interna para armazenar (coluna, valorFiltro)
class _FilterSpec {
  final String column;
  final String value;

  const _FilterSpec({
    required this.column,
    required this.value,
  });
}

///
/// Dialog GENÉRICO de pré-visualização/mapeamento de import vetorial.
///
class VectorPreviewDialog extends StatefulWidget {
  final String collectionPath;
  final List<String> targetFields;
  final String? title;
  final String? description;

  const VectorPreviewDialog({
    super.key,
    required this.collectionPath,
    required this.targetFields,
    this.title,
    this.description,
  });

  @override
  State<VectorPreviewDialog> createState() => _VectorPreviewDialogState();
}

class _VectorPreviewDialogState extends State<VectorPreviewDialog> {
  /// Tipo escolhido para cada campo destino
  final Map<String, TypeFieldGeoJson> _fieldTypes = {};

  /// Filtro aplicado em cada campo destino (por coluna "De")
  /// Valor especial "*" = nenhum filtro (todos os valores).
  final Map<String, String> _fieldFilters = {};

  @override
  void initState() {
    super.initState();
    // Dispara import assim que o dialog abre
    Future.microtask(() {
      context.read<VectorImportCubit>().startImport(widget.collectionPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle =
        widget.title ?? 'Importar vetores (${widget.collectionPath})';

    return BlocListener<VectorImportCubit, VectorImportState>(
      listener: (context, state) {
        if (state.status == VectorImportStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      child: WindowDialog(
        title: dialogTitle,
        width: 1100,
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        onClose: () => Navigator.of(context).pop(false),
        child: SizedBox(
          height: 640,
          child: BlocBuilder<VectorImportCubit, VectorImportState>(
            builder: (context, state) {
              if (state.status == VectorImportStatus.pickingFile ||
                  state.status == VectorImportStatus.idle) {
                return _buildCenterMessage(
                  'Carregando arquivo para pré-visualização...',
                );
              }

              if (state.status == VectorImportStatus.failure) {
                return _buildErrorContent(state.error);
              }

              if (state.features.isEmpty || state.columns.isEmpty) {
                return _buildCenterMessage(
                  'Nenhuma feature de linha encontrada.',
                );
              }

              if (widget.targetFields.isEmpty) {
                return _buildCenterMessage(
                  'Nenhuma configuração de campos de destino foi informada para '
                      '"${widget.collectionPath}".',
                );
              }

              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding:
                          const EdgeInsets.only(top: 12.0, bottom: 8.0),
                          child: _buildMappingSection(state),
                        ),
                      ),
                      _buildFooterActions(context, state),
                    ],
                  ),
                  if (state.status == VectorImportStatus.saving)
                    Positioned.fill(
                      child: _buildOverlaySalvando(state),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets auxiliares
  // ---------------------------------------------------------------------------

  Widget _buildCenterMessage(String text) {
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

  Widget _buildErrorContent(String? error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Falha ao carregar o arquivo.',
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

  /// Seção De -> Filtro -> Tipo -> Para
  Widget _buildMappingSection(VectorImportState state) {
    final cubit = context.read<VectorImportCubit>();
    final columns = state.columns;
    final mapping = state.fieldMapping;
    final targetFields = widget.targetFields;

    final textStyleLabel = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontWeight: FontWeight.w600);

    final description = widget.description ??
        'Defina quais colunas do arquivo (ou a GEOMETRIA) irão preencher '
            'cada campo de destino no SIGED / Firestore, o filtro (se desejado) '
            'e o tipo de dado que será salvo.';

    // nomes das colunas do arquivo
    final columnNames = columns.map((c) => c.name).toList(growable: false);

    // existe alguma geometria?
    final bool hasGeometryPoints =
    state.features.any((f) => f.geometryPoints.isNotEmpty);

    // opções gerais para "De:"
    final List<String> sourceOptions = [
      ...columnNames,
      if (hasGeometryPoints) kGeometrySourceLabel,
    ];

    final typeNames =
    TypeFieldGeoJson.values.map((t) => t.name).toList(growable: false);

    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('De: (Arquivo / Geometria)',
                    style: textStyleLabel),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text('Filtro', style: textStyleLabel),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text('Tipo', style: textStyleLabel),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text('Para: (SIGED / Firestore)', style: textStyleLabel),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.grey.shade300,
            height: 1,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                itemCount: targetFields.length,
                itemBuilder: (ctx, index) {
                  final target = targetFields[index];

                  // se o destino for "points" e existir geometria, faz
                  // um auto-mapeamento padrão para [GEOMETRIA]
                  final currentSource = mapping[target];
                  if (target == 'points' &&
                      hasGeometryPoints &&
                      currentSource == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      cubit.setFieldMapping(target, kGeometrySourceLabel);
                    });
                  }

                  final selectedSource =
                      mapping[target] ?? (target == 'points' &&
                          hasGeometryPoints
                          ? kGeometrySourceLabel
                          : null);

                  final selectedType =
                      _fieldTypes[target] ?? TypeFieldGeoJson.string;
                  final currentFilter = _fieldFilters[target] ?? '*';

                  final controllerDe =
                  TextEditingController(text: selectedSource ?? '');
                  final controllerTipo =
                  TextEditingController(text: selectedType.name);
                  final controllerFiltro =
                  TextEditingController(text: currentFilter);

                  // valores possíveis de filtro com base na coluna "De"
                  List<String> filterValues = ['*'];
                  bool filterEnabled = false;

                  final hasSource =
                      selectedSource != null && selectedSource.isNotEmpty;

                  if (hasSource &&
                      selectedSource != kGeometrySourceLabel &&
                      columnNames.contains(selectedSource)) {
                    final valuesSet = <String>{};
                    for (final feature in state.features) {
                      final raw =
                      feature.editedProperties[selectedSource];
                      if (raw == null) continue;
                      valuesSet.add(raw.toString());
                    }
                    final sorted = valuesSet.toList()..sort();
                    filterValues = ['*', ...sorted];
                    filterEnabled = true;
                  } else {
                    filterValues = ['*'];
                    filterEnabled = false;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // De
                        Expanded(
                          flex: 4,
                          child: DropDownButtonChange(
                            controller: controllerDe,
                            items: sourceOptions,
                            labelText: 'Coluna / Geometria',
                            specialItemLabel: '',
                            showSpecialAlways: false,
                            showSpecialWhenEmpty: false,
                            onChanged: (value) {
                              final v = (value == null || value.isEmpty)
                                  ? null
                                  : value;
                              cubit.setFieldMapping(target, v);

                              setState(() {
                                _fieldFilters[target] = '*';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Filtro
                        Expanded(
                          flex: 2,
                          child: DropDownButtonChange(
                            controller: controllerFiltro,
                            items: filterValues,
                            enabled: filterEnabled,
                            labelText: 'Filtro',
                            tooltipMessage:
                            'Selecione um valor específico da coluna ou use * para todos.\n'
                                '(Desativado para fonte GEOMETRIA)',
                            specialItemLabel: '',
                            showSpecialAlways: false,
                            showSpecialWhenEmpty: false,
                            onChanged: (value) {
                              if (value == null || value.isEmpty) return;
                              setState(() {
                                _fieldFilters[target] = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Tipo
                        Expanded(
                          flex: 3,
                          child: DropDownButtonChange(
                            controller: controllerTipo,
                            items: typeNames,
                            labelText: 'Tipo',
                            specialItemLabel: '',
                            showSpecialAlways: false,
                            showSpecialWhenEmpty: false,
                            onChanged: (value) {
                              if (value == null || value.isEmpty) return;
                              final tipo =
                              TypeFieldGeoJson.values.firstWhere(
                                    (t) => t.name == value,
                                orElse: () => TypeFieldGeoJson.string,
                              );
                              setState(() {
                                _fieldTypes[target] = tipo;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Para
                        Expanded(
                          flex: 3,
                          child: Text(
                            target,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countFilteredFeatures(VectorImportState state) {
    final List<_FilterSpec> activeFilters = [];

    _fieldFilters.forEach((target, filterValue) {
      if (filterValue.isEmpty || filterValue == '*') return;

      final columnName = state.fieldMapping[target];
      if (columnName == null || columnName.isEmpty) return;
      if (columnName == kGeometrySourceLabel) return;

      activeFilters.add(
        _FilterSpec(column: columnName, value: filterValue),
      );
    });

    if (activeFilters.isEmpty) {
      return state.features.length;
    }

    int count = 0;

    for (final feature in state.features) {
      bool matchesAll = true;

      for (final filter in activeFilters) {
        final raw = feature.editedProperties[filter.column];
        if (raw == null || raw.toString() != filter.value) {
          matchesAll = false;
          break;
        }
      }

      if (matchesAll) {
        count++;
      }
    }

    return count;
  }

  Widget _buildFooterActions(
      BuildContext context,
      VectorImportState state,
      ) {
    final cubit = context.read<VectorImportCubit>();

    final isSaving = state.status == VectorImportStatus.saving;

    final totalLinhas = state.features.length;
    final totalLinhasFiltradas = _countFilteredFeatures(state);
    final totalColunas = state.columns.length;

    final geometryType = state.features.first.geometryType;
    final tipo = geometryType.isNotEmpty ? geometryType : 'Desconhecido';

    return Column(
      children: [
        Container(
          color: Colors.grey.shade300,
          height: 1,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Tipo de geometria: '),
                  Text(
                    tipo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  const Text('Linhas: '),
                  Text(
                    '$totalLinhasFiltradas de $totalLinhas',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  const Text('Colunas: '),
                  Text(
                    '$totalColunas',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isSaving ? null : cubit.save,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverlaySalvando(VectorImportState state) {
    final progresso =
    (state.progress.clamp(0.0, 1.0) * 100).toStringAsFixed(1);

    return Container(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Card(
            color: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 220,
                    child: LinearProgressIndicator(
                      value: state.progress,
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
                  const Text(
                    'Salvando no Firebase...',
                    style: TextStyle(color: Colors.white),
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
