import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';

import 'package:sipged/screens/modules/actives/roads/records/road_map_section.dart';

class RoadDetailsPage extends StatefulWidget {
  final ActiveRoadsData? editing;

  const RoadDetailsPage({
    super.key,
    this.editing,
  });

  @override
  State<RoadDetailsPage> createState() => _RoadDetailsPageState();
}

class _RoadDetailsPageState extends State<RoadDetailsPage> {
  final _acronymCtrl = TextEditingController();
  final _ufCtrl = TextEditingController();
  final _segmentTypeCtrl = TextEditingController();
  final _descCoinCtrl = TextEditingController();
  final _roadCodeCtrl = TextEditingController();
  final _initialSegmentCtrl = TextEditingController();
  final _finalSegmentCtrl = TextEditingController();

  final _initialKmCtrl = TextEditingController();
  final _finalKmCtrl = TextEditingController();
  final _extensionCtrl = TextEditingController();

  final _stateSurfaceCtrl = TextEditingController();
  final _worksCtrl = TextEditingController();
  final _coincidentFederalCtrl = TextEditingController();
  final _administrationCtrl = TextEditingController();
  final _legalActCtrl = TextEditingController();
  final _coincidentStateCtrl = TextEditingController();
  final _coincidentStateSurfaceCtrl = TextEditingController();
  final _jurisdictionCtrl = TextEditingController();
  final _surfaceCtrl = TextEditingController();
  final _unitLocalCtrl = TextEditingController();
  final _coincidentCtrl = TextEditingController();

  final _initialLatSegmentCtrl = TextEditingController();
  final _initialLongSegmentCtrl = TextEditingController();
  final _finalLatSegmentCtrl = TextEditingController();
  final _finalLongSegmentCtrl = TextEditingController();

  final _regionalCtrl = TextEditingController();
  final _previousNumberCtrl = TextEditingController();
  final _revestmentTypeCtrl = TextEditingController();

  final _tmdCtrl = TextEditingController();
  final _tracksNumberCtrl = TextEditingController();
  final _maxSpeedCtrl = TextEditingController();
  final _conservationConditionCtrl = TextEditingController();
  final _drainageCtrl = TextEditingController();
  final _vsaCtrl = TextEditingController();

  final _roadNameCtrl = TextEditingController();
  final _stateLongCtrl = TextEditingController();
  final _directionCtrl = TextEditingController();
  final _managingCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _createdAtStr = '';
  String _updatedAtStr = '';
  String _createdByStr = '';
  String _updatedByStr = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fillUiFromData(widget.editing);
    });
  }

  @override
  void didUpdateWidget(covariant RoadDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.editing?.id != widget.editing?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fillUiFromData(widget.editing);
      });
    }
  }

  @override
  void dispose() {
    _acronymCtrl.dispose();
    _ufCtrl.dispose();
    _segmentTypeCtrl.dispose();
    _descCoinCtrl.dispose();
    _roadCodeCtrl.dispose();
    _initialSegmentCtrl.dispose();
    _finalSegmentCtrl.dispose();
    _initialKmCtrl.dispose();
    _finalKmCtrl.dispose();
    _extensionCtrl.dispose();
    _stateSurfaceCtrl.dispose();
    _worksCtrl.dispose();
    _coincidentFederalCtrl.dispose();
    _administrationCtrl.dispose();
    _legalActCtrl.dispose();
    _coincidentStateCtrl.dispose();
    _coincidentStateSurfaceCtrl.dispose();
    _jurisdictionCtrl.dispose();
    _surfaceCtrl.dispose();
    _unitLocalCtrl.dispose();
    _coincidentCtrl.dispose();
    _initialLatSegmentCtrl.dispose();
    _initialLongSegmentCtrl.dispose();
    _finalLatSegmentCtrl.dispose();
    _finalLongSegmentCtrl.dispose();
    _regionalCtrl.dispose();
    _previousNumberCtrl.dispose();
    _revestmentTypeCtrl.dispose();
    _tmdCtrl.dispose();
    _tracksNumberCtrl.dispose();
    _maxSpeedCtrl.dispose();
    _conservationConditionCtrl.dispose();
    _drainageCtrl.dispose();
    _vsaCtrl.dispose();
    _roadNameCtrl.dispose();
    _stateLongCtrl.dispose();
    _directionCtrl.dispose();
    _managingCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showNotification({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        details: details,
        leadingLabel: 'Rodovias',
        type: type,
        duration: duration,
      ),
    );
  }

  void _setIfDiff(TextEditingController c, String v) {
    if (c.text == v) return;

    c.value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
  }

  double? _parseNumberLoose(String s) {
    final raw = s.trim();
    if (raw.isEmpty) return null;

    var cleaned = raw.replaceAll(RegExp(r'[^\d,.\-]'), '');

    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');

    if (hasComma && hasDot) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      cleaned = cleaned.replaceAll(',', '.');
    }

    return double.tryParse(cleaned);
  }

  int? _parseIntLoose(String s) {
    final raw = s.trim();
    if (raw.isEmpty) return null;

    return int.tryParse(raw.replaceAll(RegExp(r'[^0-9\-]'), ''));
  }

  String _fmtNum(num? v, {int maxDecimals = 3}) {
    if (v == null) return '';

    var s = v.toStringAsFixed(maxDecimals);

    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }

    return s;
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year.toString()}';
  }

  void _fillUiFromData(ActiveRoadsData? d) {
    _setIfDiff(_acronymCtrl, d?.acronym ?? '');
    _setIfDiff(_ufCtrl, d?.uf ?? '');
    _setIfDiff(_segmentTypeCtrl, d?.segmentType ?? '');
    _setIfDiff(_descCoinCtrl, d?.descCoin ?? '');
    _setIfDiff(_roadCodeCtrl, d?.roadCode ?? '');
    _setIfDiff(_initialSegmentCtrl, d?.initialSegment ?? '');
    _setIfDiff(_finalSegmentCtrl, d?.finalSegment ?? '');
    _setIfDiff(_initialKmCtrl, _fmtNum(d?.initialKm));
    _setIfDiff(_finalKmCtrl, _fmtNum(d?.finalKm));
    _setIfDiff(_extensionCtrl, _fmtNum(d?.extension));

    _setIfDiff(
      _stateSurfaceCtrl,
      d?.stateSurface ?? d?.surface ?? d?.state ?? '',
    );

    _setIfDiff(_worksCtrl, d?.works ?? '');
    _setIfDiff(_coincidentFederalCtrl, d?.coincidentFederal ?? '');
    _setIfDiff(_administrationCtrl, d?.administration ?? '');
    _setIfDiff(_legalActCtrl, d?.legalAct ?? '');
    _setIfDiff(_coincidentStateCtrl, d?.coincidentState ?? '');
    _setIfDiff(_coincidentStateSurfaceCtrl, d?.coincidentStateSurface ?? '');
    _setIfDiff(_jurisdictionCtrl, d?.jurisdiction ?? '');
    _setIfDiff(_surfaceCtrl, d?.surface ?? '');
    _setIfDiff(_unitLocalCtrl, d?.unitLocal ?? '');
    _setIfDiff(_coincidentCtrl, d?.coincident ?? '');

    _setIfDiff(_initialLatSegmentCtrl, d?.initialLatSegment ?? '');
    _setIfDiff(_initialLongSegmentCtrl, d?.initialLongSegment ?? '');
    _setIfDiff(_finalLatSegmentCtrl, d?.finalLatSegment ?? '');
    _setIfDiff(_finalLongSegmentCtrl, d?.finalLongSegment ?? '');

    _setIfDiff(
      _regionalCtrl,
      d?.regional ?? d?.metadata?['regional']?.toString() ?? '',
    );

    _setIfDiff(_previousNumberCtrl, d?.previousNumber ?? '');
    _setIfDiff(_revestmentTypeCtrl, d?.revestmentType ?? '');

    _setIfDiff(_tmdCtrl, d?.tmd?.toString() ?? '');
    _setIfDiff(_tracksNumberCtrl, d?.tracksNumber?.toString() ?? '');
    _setIfDiff(_maxSpeedCtrl, d?.maximumSpeed?.toString() ?? '');
    _setIfDiff(_conservationConditionCtrl, d?.conservationCondition ?? '');
    _setIfDiff(_drainageCtrl, d?.drainage ?? '');
    _setIfDiff(_vsaCtrl, d?.vsa?.toString() ?? '');

    _setIfDiff(_roadNameCtrl, d?.roadName ?? '');
    _setIfDiff(_stateLongCtrl, d?.state ?? '');
    _setIfDiff(_directionCtrl, d?.direction ?? '');
    _setIfDiff(_managingCtrl, d?.managingAgency ?? '');
    _setIfDiff(_descCtrl, d?.description ?? '');

    _createdAtStr = _fmtDate(d?.createdAt);
    _updatedAtStr = _fmtDate(d?.updatedAt);
    _createdByStr = d?.createdBy ?? '';
    _updatedByStr = d?.updatedBy ?? '';

    setState(() {});
  }

  ActiveRoadsData _buildData(ActiveRoadsData? base) {
    return ActiveRoadsData(
      id: base?.id,
      acronym: _emptyToNull(_acronymCtrl.text),
      uf: _emptyToNull(_ufCtrl.text),
      segmentType: _emptyToNull(_segmentTypeCtrl.text),
      descCoin: _emptyToNull(_descCoinCtrl.text),
      roadCode: _emptyToNull(_roadCodeCtrl.text),
      initialSegment: _emptyToNull(_initialSegmentCtrl.text),
      finalSegment: _emptyToNull(_finalSegmentCtrl.text),
      initialKm: _parseNumberLoose(_initialKmCtrl.text),
      finalKm: _parseNumberLoose(_finalKmCtrl.text),
      extension: _parseNumberLoose(_extensionCtrl.text),
      stateSurface: _emptyToNull(_stateSurfaceCtrl.text),
      works: _emptyToNull(_worksCtrl.text),
      coincidentFederal: _emptyToNull(_coincidentFederalCtrl.text),
      administration: _emptyToNull(_administrationCtrl.text),
      legalAct: _emptyToNull(_legalActCtrl.text),
      coincidentState: _emptyToNull(_coincidentStateCtrl.text),
      coincidentStateSurface: _emptyToNull(_coincidentStateSurfaceCtrl.text),
      jurisdiction: _emptyToNull(_jurisdictionCtrl.text),
      surface: _emptyToNull(_surfaceCtrl.text),
      unitLocal: _emptyToNull(_unitLocalCtrl.text),
      coincident: _emptyToNull(_coincidentCtrl.text),
      initialLatSegment: _emptyToNull(_initialLatSegmentCtrl.text),
      initialLongSegment: _emptyToNull(_initialLongSegmentCtrl.text),
      finalLatSegment: _emptyToNull(_finalLatSegmentCtrl.text),
      finalLongSegment: _emptyToNull(_finalLongSegmentCtrl.text),
      regional: _emptyToNull(_regionalCtrl.text),
      previousNumber: _emptyToNull(_previousNumberCtrl.text),
      revestmentType: _emptyToNull(_revestmentTypeCtrl.text),
      tmd: _parseIntLoose(_tmdCtrl.text),
      tracksNumber: _parseIntLoose(_tracksNumberCtrl.text),
      maximumSpeed: _parseIntLoose(_maxSpeedCtrl.text),
      conservationCondition: _emptyToNull(_conservationConditionCtrl.text),
      drainage: _emptyToNull(_drainageCtrl.text),
      vsa: _parseIntLoose(_vsaCtrl.text),
      roadName: _emptyToNull(_roadNameCtrl.text),
      state: _emptyToNull(_stateLongCtrl.text),
      direction: _emptyToNull(_directionCtrl.text),
      managingAgency: _emptyToNull(_managingCtrl.text),
      description: _emptyToNull(_descCtrl.text),
    );
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  bool _requiredValid(ActiveRoadsData d) {
    final hasAcr = d.acronym?.trim().isNotEmpty ?? false;
    final hasUF = d.uf?.trim().isNotEmpty ?? false;
    final hasExt = (d.extension ?? 0) > 0;

    return hasAcr && hasUF && hasExt;
  }

  Widget _input(
      TextEditingController ctrl,
      String label, {
        bool number = false,
        bool digitsOnly = false,
        bool tooltip = false,
        int maxLines = 1,
        double width = 320,
      }) {
    return Tooltip(
      message: tooltip ? 'Campo livre para preenchimento.' : '',
      child: CustomTextField(
        width: width,
        controller: ctrl,
        labelText: label,
        maxLines: maxLines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        )
            : TextInputType.text,
        inputFormatters: [
          if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
          if (!digitsOnly && number)
            FilteringTextInputFormatter.allow(
              RegExp(r'[0-9\-.,]'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveRoadsCubit, ActiveRoadsState>(
      buildWhen: (a, b) => a.savingOrImporting != b.savingOrImporting,
      builder: (context, st) {
        final cubit = context.read<ActiveRoadsCubit>();

        final draft = _buildData(widget.editing);
        final canSave = !st.savingOrImporting && _requiredValid(draft);

        Widget buildLeftPanel() {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  double w(int perLine) {
                    if (width >= 1100) {
                      return (width - (perLine - 1) * 12) / perLine;
                    }

                    if (width >= 700) {
                      return (width - 12) / 2;
                    }

                    return width;
                  }

                  final fields = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _input(
                        _acronymCtrl,
                        'RODOVIA (Sigla: AL-101)',
                        tooltip: true,
                        width: w(4),
                      ),
                      _input(_roadNameCtrl, 'Nome da rodovia', width: w(4)),
                      _input(_ufCtrl, 'UF', tooltip: true, width: w(4)),
                      _input(_stateLongCtrl, 'Estado (descrição)', width: w(4)),
                      _input(_segmentTypeCtrl, 'Tipo de segmento', width: w(4)),
                      _input(
                        _descCoinCtrl,
                        'Descrição / Moeda (descCoin)',
                        width: w(4),
                      ),
                      _input(_roadCodeCtrl, 'CÓDIGO (opcional)', width: w(4)),
                      _input(
                        _initialSegmentCtrl,
                        'Segmento inicial',
                        width: w(4),
                      ),
                      _input(
                        _finalSegmentCtrl,
                        'Segmento final',
                        width: w(4),
                      ),
                      _input(
                        _initialKmCtrl,
                        'KM INICIAL',
                        number: true,
                        width: w(4),
                      ),
                      _input(
                        _finalKmCtrl,
                        'KM FINAL',
                        number: true,
                        width: w(4),
                      ),
                      _input(
                        _extensionCtrl,
                        'EXTENSÃO (km)',
                        number: true,
                        width: w(4),
                      ),
                      _input(
                        _stateSurfaceCtrl,
                        'STATUS/SUPERFÍCIE (ex: PAV, EOP, DUP)',
                        width: w(4),
                      ),
                      _input(
                        _surfaceCtrl,
                        'SUPERFÍCIE (texto livre)',
                        tooltip: true,
                        width: w(4),
                      ),
                      _input(
                        _revestmentTypeCtrl,
                        'Tipo de revestimento',
                        width: w(4),
                      ),
                      _input(_worksCtrl, 'OBRAS (texto livre)', width: w(4)),
                      _input(
                        _coincidentFederalCtrl,
                        'Coincidente Federal',
                        width: w(4),
                      ),
                      _input(
                        _coincidentStateCtrl,
                        'Coincidente Estadual',
                        width: w(4),
                      ),
                      _input(
                        _coincidentStateSurfaceCtrl,
                        'Pavimento Estadual Coincidente',
                        width: w(4),
                      ),
                      _input(
                        _coincidentCtrl,
                        'Coincidente (outros)',
                        width: w(4),
                      ),
                      _input(
                        _administrationCtrl,
                        'Administração',
                        width: w(4),
                      ),
                      _input(_jurisdictionCtrl, 'Jurisdição', width: w(4)),
                      _input(_legalActCtrl, 'Ato legal', width: w(4)),
                      _input(_unitLocalCtrl, 'Unidade local', width: w(4)),
                      _input(
                        _regionalCtrl,
                        'REGIÃO',
                        tooltip: true,
                        width: w(4),
                      ),
                      _input(
                        _previousNumberCtrl,
                        'Número anterior',
                        width: w(4),
                      ),
                      _input(_directionCtrl, 'SENTIDO', width: w(4)),
                      _input(_managingCtrl, 'ÓRGÃO GESTOR', width: w(4)),
                      _input(
                        _tmdCtrl,
                        'TMD',
                        number: true,
                        digitsOnly: true,
                        width: w(4),
                      ),
                      _input(
                        _tracksNumberCtrl,
                        'Número de faixas',
                        number: true,
                        digitsOnly: true,
                        width: w(4),
                      ),
                      _input(
                        _maxSpeedCtrl,
                        'VELOCIDADE MÁXIMA',
                        number: true,
                        digitsOnly: true,
                        width: w(4),
                      ),
                      _input(
                        _conservationConditionCtrl,
                        'Condição de conservação',
                        width: w(4),
                      ),
                      _input(_drainageCtrl, 'Drenagem', width: w(4)),
                      _input(
                        _vsaCtrl,
                        'VSA',
                        number: true,
                        digitsOnly: true,
                        width: w(4),
                      ),
                      _input(
                        _initialLatSegmentCtrl,
                        'Lat inicial segmento',
                        width: w(4),
                      ),
                      _input(
                        _initialLongSegmentCtrl,
                        'Long inicial segmento',
                        width: w(4),
                      ),
                      _input(
                        _finalLatSegmentCtrl,
                        'Lat final segmento',
                        width: w(4),
                      ),
                      _input(
                        _finalLongSegmentCtrl,
                        'Long final segmento',
                        width: w(4),
                      ),
                      _input(
                        _descCtrl,
                        'DESCRIÇÃO / OBS',
                        maxLines: 3,
                        width: width,
                      ),
                    ],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      fields,
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 8,
                          children: [
                            Text('Criado em: $_createdAtStr'),
                            Text('Criado por: $_createdByStr'),
                            Text('Atualizado em: $_updatedAtStr'),
                            Text('Atualizado por: $_updatedByStr'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: canSave
                                ? () async {
                              final data = _buildData(widget.editing);

                              _showNotification(
                                title: 'Salvando rodovia...',
                                subtitle: widget.editing?.id != null
                                    ? 'Atualizando registro'
                                    : 'Criando novo registro',
                                type: NotificationStatus.info,
                                duration: const Duration(seconds: 2),
                              );

                              await cubit.upsert(data);
                            }
                                : null,
                            icon: const Icon(Icons.save),
                            label: Text(
                              widget.editing?.id != null
                                  ? 'Atualizar'
                                  : 'Salvar',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }

        Widget buildRightPanel() {
          return RoadDetailsMapSection(road: widget.editing);
        }

        return SplitLayout(
          left: buildLeftPanel(),
          right: buildRightPanel(),
          showRightPanel: true,
          stackedRightOnTop: true,
        );
      },
    );
  }
}