import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';

import 'package:sipged/_widgets/input/custom_text_field.dart';

// ✅ novo (substitui mask_class.dart)
import 'package:sipged/_utils/mask/sipged_masks.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';

// 🔔 Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class ActiveOaesForm extends StatefulWidget {
  const ActiveOaesForm({super.key});

  @override
  State<ActiveOaesForm> createState() => _ActiveOaesFormState();
}

class _ActiveOaesFormState extends State<ActiveOaesForm> {
  // Controllers
  final _orderCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _roadCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _extensionCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _structureCtrl = TextEditingController();
  final _contractsCtrl = TextEditingController();
  final _linearCostCtrl = TextEditingController();
  final _estimateCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _altitudeCtrl = TextEditingController();

  bool _syncingUi = false;

  @override
  void dispose() {
    _orderCtrl.dispose();
    _scoreCtrl.dispose();
    _stateCtrl.dispose();
    _roadCtrl.dispose();
    _regionCtrl.dispose();
    _nameCtrl.dispose();
    _extensionCtrl.dispose();
    _widthCtrl.dispose();
    _areaCtrl.dispose();
    _structureCtrl.dispose();
    _contractsCtrl.dispose();
    _linearCostCtrl.dispose();
    _estimateCtrl.dispose();
    _companyCtrl.dispose();
    _dateCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _altitudeCtrl.dispose();
    super.dispose();
  }

  // --- UI hydration ---
  void _fillUiFromForm(ActiveOaesData f) {
    _syncingUi = true;

    _setIfDiff(_orderCtrl, (f.order ?? '').toString());
    _setIfDiff(_nameCtrl, f.identificationName ?? '');
    _setIfDiff(_latitudeCtrl, _fmtNumberLoose(f.latitude));
    _setIfDiff(_longitudeCtrl, _fmtNumberLoose(f.longitude));

    _setIfDiff(_scoreCtrl, _fmtNumberLoose(f.score));
    _setIfDiff(_stateCtrl, f.state ?? '');
    _setIfDiff(_roadCtrl, f.road ?? '');
    _setIfDiff(_regionCtrl, f.region ?? '');
    _setIfDiff(_extensionCtrl, _fmtNumberLoose(f.extension));
    _setIfDiff(_widthCtrl, _fmtNumberLoose(f.width));
    _setIfDiff(_areaCtrl, _fmtNumberLoose(f.area));
    _setIfDiff(_structureCtrl, f.estructureType ?? f.estructureType ?? '');
    _setIfDiff(_contractsCtrl, f.relatedContracts ?? '');
    _setIfDiff(_linearCostCtrl, _fmtMoneyBR(f.linearCostMedia));
    _setIfDiff(_estimateCtrl, _fmtMoneyBR(f.costEstimate));
    _setIfDiff(_companyCtrl, f.companyBuild ?? '');
    _setIfDiff(_dateCtrl, f.lastDateIntervention != null ? _fmtDDMMYYYY(f.lastDateIntervention!) : '');
    _setIfDiff(_altitudeCtrl, _fmtNumberLoose(f.altitude));

    _syncingUi = false;
  }

  void _setIfDiff(TextEditingController ctrl, String value) {
    if (ctrl.text != value) ctrl.text = value;
  }

  // --- parsers / formatters (ideal mover pro _utils depois) ---
  DateTime? _parseDDMMYYYY(String s) {
    if (s.trim().isEmpty) return null;
    final p = s.split('/');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  String _fmtDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yy';
  }

  String _fmtNumberLoose(num? v) {
    if (v == null) return '';
    // mantém ponto (.) para decimal no armazenamento do controller, usuário pode digitar com vírgula também
    return v.toString();
  }

  double? _parseCurrencyBR(String s) {
    if (s.trim().isEmpty) return null;
    var t = s.replaceAll('R\$', '').trim();
    t = t.replaceAll('.', '');
    t = t.replaceAll(',', '.');
    return double.tryParse(t);
  }

  double? _parseNumberLoose(String s) {
    if (s.trim().isEmpty) return null;
    final cleaned = s
        .trim()
        .replaceAll(RegExp(r'[^\d,.\-]'), '')
        .replaceAll('.', '') // remove milhar
        .replaceAll(',', '.'); // decimal BR -> US
    return double.tryParse(cleaned);
  }

  String _fmtMoneyBR(double? v) {
    if (v == null) return '';
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final dec = parts[1];

    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      buf.write(intPart[i]);
      final left = intPart.length - i - 1;
      if (left > 0 && left % 3 == 0) buf.write('.');
    }
    return 'R\$ ${buf.toString()},$dec';
  }

  ActiveOaesData _patchFromUi(ActiveOaesData base) {
    return base.copyWith(
      order: int.tryParse(_orderCtrl.text),
      identificationName: _nameCtrl.text.trim(),
      latitude: _parseNumberLoose(_latitudeCtrl.text),
      longitude: _parseNumberLoose(_longitudeCtrl.text),
      score: _parseNumberLoose(_scoreCtrl.text),
      state: _stateCtrl.text.trim(),
      road: _roadCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
      extension: _parseNumberLoose(_extensionCtrl.text),
      width: _parseNumberLoose(_widthCtrl.text),
      area: _parseNumberLoose(_areaCtrl.text),
      structureType: _structureCtrl.text.trim(),
      relatedContracts: _contractsCtrl.text.trim(),
      linearCostMedia: _parseCurrencyBR(_linearCostCtrl.text),
      costEstimate: _parseCurrencyBR(_estimateCtrl.text),
      companyBuild: _companyCtrl.text.trim(),
      lastDateIntervention: _parseDDMMYYYY(_dateCtrl.text),
      altitude: _parseNumberLoose(_altitudeCtrl.text),
    );
  }

  bool _requiredValid(ActiveOaesData f) {
    final hasOrder = (f.order ?? 0) > 0;
    final hasName = (f.identificationName?.trim().isNotEmpty ?? false);
    final hasLat = f.latitude != null;
    final hasLng = f.longitude != null;
    return hasOrder && hasName && hasLat && hasLng;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
      buildWhen: (a, b) => a.form != b.form || a.saving != b.saving || a.selectedIndex != b.selectedIndex,
      builder: (context, st) {
        final cubit = context.read<ActiveOaesCubit>();

        // refletir State -> UI (sem loop)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _fillUiFromForm(st.form);
        });

        void onAnyFieldChanged(String _) {
          if (_syncingUi) return;
          final patched = _patchFromUi(st.form);
          cubit.patchForm(patched);
        }

        final campos = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _input(_orderCtrl, 'ORDEM', enabled: false, onChanged: onAnyFieldChanged),
            _input(_nameCtrl, 'IDENTIFICAÇÃO', tooltip: true, onChanged: onAnyFieldChanged),
            _input(_latitudeCtrl, 'LATITUDE', tooltip: true, onChanged: onAnyFieldChanged, number: true),
            _input(_longitudeCtrl, 'LONGITUDE', tooltip: true, onChanged: onAnyFieldChanged, number: true),
            _input(_scoreCtrl, 'SCORE (0..5)', tooltip: true, onChanged: onAnyFieldChanged, number: true),
            _input(_stateCtrl, 'STATUS/UF', tooltip: true, onChanged: onAnyFieldChanged),
            _input(_roadCtrl, 'RODOVIA', tooltip: true, onChanged: onAnyFieldChanged),
            _input(_regionCtrl, 'REGIÃO', tooltip: true, onChanged: onAnyFieldChanged),
            _input(_extensionCtrl, 'EXTENSÃO', tooltip: true, onChanged: onAnyFieldChanged, number: true),
            _input(_widthCtrl, 'LARGURA', tooltip: true, onChanged: onAnyFieldChanged, number: true),
            _input(_areaCtrl, 'ÁREA', tooltip: true, onChanged: onAnyFieldChanged, number: true),
            _input(_structureCtrl, 'TIPO DE ESTRUTURA', tooltip: true, onChanged: onAnyFieldChanged),
            _input(_contractsCtrl, 'CONTRATOS RELACIONADOS', tooltip: true, onChanged: onAnyFieldChanged),
            _input(_linearCostCtrl, 'CUSTO MÉDIO', tooltip: true, money: true, onChanged: onAnyFieldChanged),
            _input(_estimateCtrl, 'CUSTO ESTIMADO', tooltip: true, money: true, onChanged: onAnyFieldChanged),
            _input(_companyCtrl, 'EMPRESA QUE CONSTRUIU', tooltip: true, onChanged: onAnyFieldChanged),
            _input(_dateCtrl, 'ÚLTIMA DATA DE INTERVENÇÃO', tooltip: true, date: true, onChanged: onAnyFieldChanged),
            _input(_altitudeCtrl, 'ALTITUDE', tooltip: true, onChanged: onAnyFieldChanged, number: true),
          ],
        );

        final canSave = !st.saving && _requiredValid(_patchFromUi(st.form));

        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: canSave
                  ? () {
                final patched = _patchFromUi(st.form);
                cubit.upsert(patched);

                NotificationCenter.instance.show(
                  AppNotification(
                    title: const Text('Enviando...'),
                    subtitle: Text(
                      (st.selectedIndex != null) ? 'Atualizando registro' : 'Criando registro',
                    ),
                    type: AppNotificationType.info,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
                  : null,
              icon: const Icon(Icons.save),
              label: Text(st.selectedIndex != null ? 'Atualizar' : 'Salvar'),
            ),
            const SizedBox(width: 12),
            if (st.selectedIndex != null)
              TextButton.icon(
                icon: const Icon(Icons.cleaning_services_outlined),
                label: const Text('Limpar'),
                onPressed: cubit.clearSelection,
              ),
          ],
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              campos,
              const SizedBox(height: 12),
              botoes,
            ],
          ),
        );
      },
    );
  }

  // ---------- input helper ----------
  Widget _input(
      TextEditingController ctrl,
      String label, {
        bool enabled = true,
        bool date = false,
        bool money = false,
        bool number = false,
        bool tooltip = false,
        TextInputFormatter? mask,
        void Function(String)? onChanged,
      }) {
    return Tooltip(
      message: tooltip ? 'Campo livre para preenchimento.' : '',
      child: CustomTextField(
        width: 320,
        controller: ctrl,
        enabled: enabled,
        labelText: label,
        onChanged: onChanged,
        keyboardType: date
            ? TextInputType.datetime
            : (money ? TextInputType.number : (number ? const TextInputType.numberWithOptions(decimal: true, signed: true) : null)),
        inputFormatters: [
          if (date) FilteringTextInputFormatter.digitsOnly,
          if (date) SipGedMasks.dateDDMMYYYY,
          if (money)
            CurrencyInputFormatter(
              leadingSymbol: 'R\$ ',
              useSymbolPadding: true,
              thousandSeparator: ThousandSeparator.Period,
              mantissaLength: 2,
            ),
          if (number) FilteringTextInputFormatter.allow(RegExp(r'[0-9\-\.,]')),
          ?mask,
        ],
      ),
    );
  }
}
