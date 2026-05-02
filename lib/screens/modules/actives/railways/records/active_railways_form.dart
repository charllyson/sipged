import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/railway/active_railway_data.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_cubit.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';

class ActiveRailwaysForm extends StatefulWidget {
  final ActiveRailwayData? editing;

  const ActiveRailwaysForm({
    super.key,
    this.editing,
  });

  @override
  State<ActiveRailwaysForm> createState() => _ActiveRailwaysFormState();
}

class _ActiveRailwaysFormState extends State<ActiveRailwaysForm> {
  final _codigoCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();
  final _bitolaCtrl = TextEditingController();
  final _ufCtrl = TextEditingController();
  final _municipioCtrl = TextEditingController();
  final _extensaoCtrl = TextEditingController();
  final _extensaoECtrl = TextEditingController();
  final _extensaoCCtrl = TextEditingController();
  final _codigoCoincCtrl = TextEditingController();
  final _fidCtrl = TextEditingController();
  final _nativeIdCtrl = TextEditingController();

  bool _syncingUi = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fillUiFromData(widget.editing);
    });
  }

  @override
  void didUpdateWidget(covariant ActiveRailwaysForm oldWidget) {
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
    _codigoCtrl.dispose();
    _nomeCtrl.dispose();
    _statusCtrl.dispose();
    _bitolaCtrl.dispose();
    _ufCtrl.dispose();
    _municipioCtrl.dispose();
    _extensaoCtrl.dispose();
    _extensaoECtrl.dispose();
    _extensaoCCtrl.dispose();
    _codigoCoincCtrl.dispose();
    _fidCtrl.dispose();
    _nativeIdCtrl.dispose();
    super.dispose();
  }

  void _showNotification({
    required String title,
    String? subtitle,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Ferrovias',
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

  void _fillUiFromData(ActiveRailwayData? d) {
    _syncingUi = true;

    _setIfDiff(_codigoCtrl, d?.codigo ?? '');
    _setIfDiff(_nomeCtrl, d?.nome ?? '');
    _setIfDiff(_statusCtrl, d?.status ?? '');
    _setIfDiff(_bitolaCtrl, d?.bitola ?? '');
    _setIfDiff(_ufCtrl, d?.uf ?? '');
    _setIfDiff(_municipioCtrl, d?.municipio ?? '');
    _setIfDiff(_extensaoCtrl, _fmtNum(d?.extensao));
    _setIfDiff(_extensaoECtrl, _fmtNum(d?.extensaoE));
    _setIfDiff(_extensaoCCtrl, _fmtNum(d?.extensaoC));
    _setIfDiff(_codigoCoincCtrl, d?.codigoCoincidente ?? '');
    _setIfDiff(_fidCtrl, d?.fid?.toString() ?? '');
    _setIfDiff(_nativeIdCtrl, d?.nativeId?.toString() ?? '');

    _syncingUi = false;
  }

  ActiveRailwayData _buildData(ActiveRailwayData? base) {
    return ActiveRailwayData(
      id: base?.id,
      codigo: _codigoCtrl.text.trim().isEmpty ? null : _codigoCtrl.text.trim(),
      nome: _nomeCtrl.text.trim().isEmpty ? null : _nomeCtrl.text.trim(),
      status: _statusCtrl.text.trim().isEmpty ? null : _statusCtrl.text.trim(),
      bitola: _bitolaCtrl.text.trim().isEmpty ? null : _bitolaCtrl.text.trim(),
      uf: _ufCtrl.text.trim().isEmpty ? null : _ufCtrl.text.trim(),
      municipio:
      _municipioCtrl.text.trim().isEmpty ? null : _municipioCtrl.text.trim(),
      extensao: _parseNumberLoose(_extensaoCtrl.text),
      extensaoE: _parseNumberLoose(_extensaoECtrl.text),
      extensaoC: _parseNumberLoose(_extensaoCCtrl.text),
      codigoCoincidente: _codigoCoincCtrl.text.trim().isEmpty
          ? null
          : _codigoCoincCtrl.text.trim(),
      fid: _parseIntLoose(_fidCtrl.text),
      nativeId: _parseNumberLoose(_nativeIdCtrl.text),
    );
  }

  bool _requiredValid(ActiveRailwayData d) {
    final hasName = d.nome?.trim().isNotEmpty ?? false;
    final hasUF = d.uf?.trim().isNotEmpty ?? false;
    final hasExt = (d.extensao ?? 0) > 0;

    return hasName && hasUF && hasExt;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveRailwaysCubit, ActiveRailwaysState>(
      buildWhen: (a, b) => a.savingOrImporting != b.savingOrImporting,
      builder: (context, st) {
        final cubit = context.read<ActiveRailwaysCubit>();

        void onAnyChanged(String _) {
          if (_syncingUi) return;
        }

        final fields = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _input(_codigoCtrl, 'CÓDIGO', onChanged: onAnyChanged),
            _input(_nomeCtrl, 'NOME', width: 420, onChanged: onAnyChanged),
            _input(
              _statusCtrl,
              'STATUS (ex.: Em Operação, Em Obras, Planejada)',
              onChanged: onAnyChanged,
            ),
            _input(_bitolaCtrl, 'BITOLA', onChanged: onAnyChanged),
            _input(_ufCtrl, 'UF', tooltip: true, onChanged: onAnyChanged),
            _input(
              _municipioCtrl,
              'MUNICÍPIO',
              tooltip: true,
              onChanged: onAnyChanged,
            ),
            _input(
              _extensaoCtrl,
              'EXTENSÃO (km)',
              number: true,
              onChanged: onAnyChanged,
            ),
            _input(
              _extensaoECtrl,
              'EXTENSÃO E. (km)',
              number: true,
              onChanged: onAnyChanged,
            ),
            _input(
              _extensaoCCtrl,
              'EXTENSÃO C. (km)',
              number: true,
              onChanged: onAnyChanged,
            ),
            _input(
              _codigoCoincCtrl,
              'CÓDIGO COINCIDENTE',
              onChanged: onAnyChanged,
            ),
            _input(
              _fidCtrl,
              'fid',
              digitsOnly: true,
              width: 140,
              onChanged: onAnyChanged,
            ),
            _input(
              _nativeIdCtrl,
              'id nativo',
              number: true,
              width: 140,
              onChanged: onAnyChanged,
            ),
          ],
        );

        final draft = _buildData(widget.editing);
        final canSave = !st.savingOrImporting && _requiredValid(draft);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              fields,
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: canSave
                        ? () async {
                      final data = _buildData(widget.editing);

                      _showNotification(
                        title: 'Salvando ferrovia...',
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
                      widget.editing?.id != null ? 'Atualizar' : 'Salvar',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _input(
      TextEditingController ctrl,
      String label, {
        bool number = false,
        bool digitsOnly = false,
        bool tooltip = false,
        int maxLines = 1,
        double width = 320,
        void Function(String)? onChanged,
      }) {
    return Tooltip(
      message: tooltip ? 'Campo livre para preenchimento.' : '',
      child: CustomTextField(
        width: width,
        controller: ctrl,
        labelText: label,
        maxLines: maxLines,
        onChanged: onChanged,
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
}