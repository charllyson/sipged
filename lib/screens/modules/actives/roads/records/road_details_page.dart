// lib/screens/modules/actives/roads/network/road_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:siged/_blocs/modules/actives/roads/active_roads_state.dart';
import 'package:siged/_blocs/modules/actives/roads/active_roads_cubit.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// Layout dividido (igual OAE)
import 'package:siged/_widgets/layout/split_layout/split_layout.dart';

// Mapa interativo genérico
import 'package:siged/screens/modules/actives/roads/records/road_map_section.dart';

class RoadDetailsPage extends StatefulWidget {
  /// Registro que será editado no formulário (opcional). Se null, o form fica “em branco”.
  final ActiveRoadsData? editing;

  const RoadDetailsPage({super.key, this.editing});

  @override
  State<RoadDetailsPage> createState() => _RoadDetailsPageState();
}

class _RoadDetailsPageState extends State<RoadDetailsPage> {
  // Controllers principais (campos textuais)
  final _acronymCtrl = TextEditingController(); // ex: AL-101
  final _ufCtrl = TextEditingController(); // ex: AL
  final _segmentTypeCtrl = TextEditingController();
  final _descCoinCtrl = TextEditingController();
  final _roadCodeCtrl = TextEditingController();
  final _initialSegmentCtrl = TextEditingController();
  final _finalSegmentCtrl = TextEditingController();

  final _initialKmCtrl = TextEditingController();
  final _finalKmCtrl = TextEditingController();
  final _extensionCtrl = TextEditingController();

  final _stateSurfaceCtrl = TextEditingController(); // ex: PAV / EOP / DUP...
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
  final _stateLongCtrl = TextEditingController(); // campo "state" (ex: ALAGOAS)
  final _directionCtrl = TextEditingController();
  final _managingCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // --- infos de auditoria (somente leitura textual) ---
  String _createdAtStr = '';
  String _updatedAtStr = '';
  String _createdByStr = '';
  String _updatedByStr = '';

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

  @override
  void didUpdateWidget(covariant RoadDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editing?.id != widget.editing?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fillUiFromData(widget.editing);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // primeira carga
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fillUiFromData(widget.editing);
    });
  }

  // ---------------- helpers ----------------
  void _setIfDiff(TextEditingController c, String v) {
    if (c.text != v) c.text = v;
  }

  double? _parseNumberLoose(String s) {
    if (s.trim().isEmpty) return null;
    final t = s.contains(',') && !s.contains('.')
        ? s.replaceAll('.', '').replaceAll(',', '.')
        : s;
    return double.tryParse(t);
  }

  int? _parseIntLoose(String s) {
    if (s.trim().isEmpty) return null;
    return int.tryParse(s.replaceAll(RegExp(r'[^0-9\-]'), ''));
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
      d?.stateSurface ?? (d?.surface ?? (d?.state ?? '')),
    );
    _setIfDiff(_worksCtrl, d?.works ?? '');
    _setIfDiff(_coincidentFederalCtrl, d?.coincidentFederal ?? '');
    _setIfDiff(_administrationCtrl, d?.administration ?? '');
    _setIfDiff(_legalActCtrl, d?.legalAct ?? '');
    _setIfDiff(_coincidentStateCtrl, d?.coincidentState ?? '');
    _setIfDiff(
        _coincidentStateSurfaceCtrl, d?.coincidentStateSurface ?? '');
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
      d?.regional ?? (d?.metadata?['regional']?.toString() ?? ''),
    );
    _setIfDiff(_previousNumberCtrl, d?.previousNumber ?? '');
    _setIfDiff(_revestmentTypeCtrl, d?.revestmentType ?? '');

    _setIfDiff(_tmdCtrl, (d?.tmd ?? '').toString());
    _setIfDiff(_tracksNumberCtrl, (d?.tracksNumber ?? '').toString());
    _setIfDiff(_maxSpeedCtrl, (d?.maximumSpeed ?? '').toString());
    _setIfDiff(
        _conservationConditionCtrl, d?.conservationCondition ?? '');
    _setIfDiff(_drainageCtrl, d?.drainage ?? '');
    _setIfDiff(_vsaCtrl, (d?.vsa ?? '').toString());

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
      acronym: _acronymCtrl.text.trim().isEmpty
          ? null
          : _acronymCtrl.text.trim(),
      uf: _ufCtrl.text.trim().isEmpty ? null : _ufCtrl.text.trim(),
      segmentType: _segmentTypeCtrl.text.trim().isEmpty
          ? null
          : _segmentTypeCtrl.text.trim(),
      descCoin: _descCoinCtrl.text.trim().isEmpty
          ? null
          : _descCoinCtrl.text.trim(),
      roadCode: _roadCodeCtrl.text.trim().isEmpty
          ? null
          : _roadCodeCtrl.text.trim(),
      initialSegment: _initialSegmentCtrl.text.trim().isEmpty
          ? null
          : _initialSegmentCtrl.text.trim(),
      finalSegment: _finalSegmentCtrl.text.trim().isEmpty
          ? null
          : _finalSegmentCtrl.text.trim(),
      initialKm: _parseNumberLoose(_initialKmCtrl.text),
      finalKm: _parseNumberLoose(_finalKmCtrl.text),
      extension: _parseNumberLoose(_extensionCtrl.text),
      stateSurface: _stateSurfaceCtrl.text.trim().isEmpty
          ? null
          : _stateSurfaceCtrl.text.trim(),
      works:
      _worksCtrl.text.trim().isEmpty ? null : _worksCtrl.text.trim(),
      coincidentFederal: _coincidentFederalCtrl.text.trim().isEmpty
          ? null
          : _coincidentFederalCtrl.text.trim(),
      administration: _administrationCtrl.text.trim().isEmpty
          ? null
          : _administrationCtrl.text.trim(),
      legalAct: _legalActCtrl.text.trim().isEmpty
          ? null
          : _legalActCtrl.text.trim(),
      coincidentState: _coincidentStateCtrl.text.trim().isEmpty
          ? null
          : _coincidentStateCtrl.text.trim(),
      coincidentStateSurface:
      _coincidentStateSurfaceCtrl.text.trim().isEmpty
          ? null
          : _coincidentStateSurfaceCtrl.text.trim(),
      jurisdiction: _jurisdictionCtrl.text.trim().isEmpty
          ? null
          : _jurisdictionCtrl.text.trim(),
      surface: _surfaceCtrl.text.trim().isEmpty
          ? null
          : _surfaceCtrl.text.trim(),
      unitLocal: _unitLocalCtrl.text.trim().isEmpty
          ? null
          : _unitLocalCtrl.text.trim(),
      coincident: _coincidentCtrl.text.trim().isEmpty
          ? null
          : _coincidentCtrl.text.trim(),
      initialLatSegment: _initialLatSegmentCtrl.text.trim().isEmpty
          ? null
          : _initialLatSegmentCtrl.text.trim(),
      initialLongSegment: _initialLongSegmentCtrl.text.trim().isEmpty
          ? null
          : _initialLongSegmentCtrl.text.trim(),
      finalLatSegment: _finalLatSegmentCtrl.text.trim().isEmpty
          ? null
          : _finalLatSegmentCtrl.text.trim(),
      finalLongSegment: _finalLongSegmentCtrl.text.trim().isEmpty
          ? null
          : _finalLongSegmentCtrl.text.trim(),
      regional: _regionalCtrl.text.trim().isEmpty
          ? null
          : _regionalCtrl.text.trim(),
      previousNumber: _previousNumberCtrl.text.trim().isEmpty
          ? null
          : _previousNumberCtrl.text.trim(),
      revestmentType: _revestmentTypeCtrl.text.trim().isEmpty
          ? null
          : _revestmentTypeCtrl.text.trim(),
      tmd: _parseIntLoose(_tmdCtrl.text),
      tracksNumber: _parseIntLoose(_tracksNumberCtrl.text),
      maximumSpeed: _parseIntLoose(_maxSpeedCtrl.text),
      conservationCondition:
      _conservationConditionCtrl.text.trim().isEmpty
          ? null
          : _conservationConditionCtrl.text.trim(),
      drainage: _drainageCtrl.text.trim().isEmpty
          ? null
          : _drainageCtrl.text.trim(),
      vsa: _parseIntLoose(_vsaCtrl.text),
      roadName: _roadNameCtrl.text.trim().isEmpty
          ? null
          : _roadNameCtrl.text.trim(),
      state: _stateLongCtrl.text.trim().isEmpty
          ? null
          : _stateLongCtrl.text.trim(),
      direction: _directionCtrl.text.trim().isEmpty
          ? null
          : _directionCtrl.text.trim(),
      managingAgency: _managingCtrl.text.trim().isEmpty
          ? null
          : _managingCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      // points continuam fora do form (edição por mapa / import)
      // metadados de auditoria/metadata continuam sendo controlados pelo repositório
    );
  }

  bool _requiredValid(ActiveRoadsData d) {
    final hasAcr = (d.acronym?.trim().isNotEmpty ?? false);
    final hasUF = (d.uf?.trim().isNotEmpty ?? false);
    final hasExt = (d.extension ?? 0) > 0;
    return hasAcr && hasUF && hasExt;
  }

  // ----- input helper -----
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
        keyboardType: number ? TextInputType.number : null,
        inputFormatters: [
          if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
          if (!digitsOnly && number)
            TextInputMask(mask: '#########9[.99]'),
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

        // Dados “draft” vindos dos controllers
        final draft = _buildData(widget.editing);
        final canSave = !st.savingOrImporting && _requiredValid(draft);

        // Painel ESQUERDO (form)
        Widget buildLeftPanel() {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  double w(int perLine) => width >= 1100
                      ? (width - (perLine - 1) * 12) / perLine
                      : width >= 700
                      ? (width - 12) / 2
                      : width;

                  final fields = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _input(_acronymCtrl, 'RODOVIA (Sigla: AL-101)',
                          tooltip: true, width: w(4)),
                      _input(_roadNameCtrl, 'Nome da rodovia',
                          width: w(4)),
                      _input(_ufCtrl, 'UF', tooltip: true, width: w(4)),
                      _input(_stateLongCtrl, 'Estado (descrição)',
                          width: w(4)),
                      _input(_segmentTypeCtrl, 'Tipo de segmento',
                          width: w(4)),
                      _input(_descCoinCtrl, 'Descrição / Moeda (descCoin)',
                          width: w(4)),
                      _input(_roadCodeCtrl, 'CÓDIGO (opcional)', width: w(4)),
                      _input(_initialSegmentCtrl, 'Segmento inicial',
                          width: w(4)),
                      _input(_finalSegmentCtrl, 'Segmento final',
                          width: w(4)),
                      _input(_initialKmCtrl, 'KM INICIAL',
                          number: true, width: w(4)),
                      _input(_finalKmCtrl, 'KM FINAL',
                          number: true, width: w(4)),
                      _input(_extensionCtrl, 'EXTENSÃO (km)',
                          number: true, width: w(4)),
                      _input(_stateSurfaceCtrl,
                          'STATUS/SUPERFÍCIE (ex: PAV, EOP, DUP)',
                          width: w(4)),
                      _input(_surfaceCtrl, 'SUPERFÍCIE (texto livre)',
                          tooltip: true, width: w(4)),
                      _input(_revestmentTypeCtrl, 'Tipo de revestimento',
                          width: w(4)),
                      _input(_worksCtrl, 'OBRAS (texto livre)',
                          width: w(4)),
                      _input(_coincidentFederalCtrl, 'Coincidente Federal',
                          width: w(4)),
                      _input(_coincidentStateCtrl, 'Coincidente Estadual',
                          width: w(4)),
                      _input(_coincidentStateSurfaceCtrl,
                          'Pavimento Estadual Coincidente',
                          width: w(4)),
                      _input(_coincidentCtrl, 'Coincidente (outros)',
                          width: w(4)),
                      _input(_administrationCtrl, 'Administração',
                          width: w(4)),
                      _input(_jurisdictionCtrl, 'Jurisdição', width: w(4)),
                      _input(_legalActCtrl, 'Ato legal', width: w(4)),
                      _input(_unitLocalCtrl, 'Unidade local',
                          width: w(4)),
                      _input(_regionalCtrl, 'REGIÃO', tooltip: true, width: w(4)),
                      _input(_previousNumberCtrl, 'Número anterior',
                          width: w(4)),
                      _input(_directionCtrl, 'SENTIDO', width: w(4)),
                      _input(_managingCtrl, 'ÓRGÃO GESTOR',
                          width: w(4)),
                      _input(_tmdCtrl, 'TMD',
                          number: true,
                          digitsOnly: true,
                          width: w(4)),
                      _input(_tracksNumberCtrl, 'Número de faixas',
                          number: true,
                          digitsOnly: true,
                          width: w(4)),
                      _input(_maxSpeedCtrl, 'VELOCIDADE MÁXIMA',
                          number: true,
                          digitsOnly: true,
                          width: w(4)),
                      _input(_conservationConditionCtrl,
                          'Condição de conservação',
                          width: w(4)),
                      _input(_drainageCtrl, 'Drenagem', width: w(4)),
                      _input(_vsaCtrl, 'VSA',
                          number: true,
                          digitsOnly: true,
                          width: w(4)),
                      _input(_initialLatSegmentCtrl, 'Lat inicial segmento',
                          width: w(4)),
                      _input(_initialLongSegmentCtrl, 'Long inicial segmento',
                          width: w(4)),
                      _input(_finalLatSegmentCtrl, 'Lat final segmento',
                          width: w(4)),
                      _input(_finalLongSegmentCtrl, 'Long final segmento',
                          width: w(4)),
                      _input(_descCtrl, 'DESCRIÇÃO / OBS',
                          maxLines: 3, width: width),
                    ],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      fields,
                      const SizedBox(height: 12),
                      // Infos de auditoria
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
                              await cubit.upsert(data);
                              NotificationCenter.instance.show(
                                AppNotification(
                                  title: const Text('Salvando rodovia...'),
                                  subtitle: Text(
                                    (widget.editing?.id != null)
                                        ? 'Atualizando registro'
                                        : 'Criando novo registro',
                                  ),
                                  type: AppNotificationType.info,
                                  duration:
                                  const Duration(seconds: 2),
                                ),
                              );
                            }
                                : null,
                            icon: const Icon(Icons.save),
                            label: Text(widget.editing?.id != null
                                ? 'Atualizar'
                                : 'Salvar'),
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

        // Painel DIREITO (mapa da rodovia, usando points)
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
