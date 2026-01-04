// lib/screens/sectors/actives/oaes/active_oaes_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_data.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_cubit.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

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

  // --- helpers ---
  void _fillUiFromForm(ActiveOaesData f) {
    _setIfDiff(_orderCtrl, (f.order ?? '').toString());
    _setIfDiff(_nameCtrl, f.identificationName ?? '');
    _setIfDiff(_latitudeCtrl, (f.latitude ?? '').toString());
    _setIfDiff(_longitudeCtrl, (f.longitude ?? '').toString());

    _setIfDiff(_scoreCtrl, (f.score ?? '').toString());
    _setIfDiff(_stateCtrl, f.state ?? '');
    _setIfDiff(_roadCtrl, f.road ?? '');
    _setIfDiff(_regionCtrl, f.region ?? '');
    _setIfDiff(_extensionCtrl, (f.extension ?? '').toString());
    _setIfDiff(_widthCtrl, (f.width ?? '').toString());
    _setIfDiff(_areaCtrl, (f.area ?? '').toString());
    _setIfDiff(_structureCtrl, f.estructureType ?? '');
    _setIfDiff(_contractsCtrl, f.relatedContracts ?? '');
    _setIfDiff(_linearCostCtrl, _fmtMoneyBR(f.linearCostMedia));
    _setIfDiff(_estimateCtrl, _fmtMoneyBR(f.costEstimate));
    _setIfDiff(_companyCtrl, f.companyBuild ?? '');
    _setIfDiff(
      _dateCtrl,
      f.lastDateIntervention != null ? _fmtDDMMYYYY(f.lastDateIntervention!) : '',
    );
    _setIfDiff(_altitudeCtrl, (f.altitude ?? '').toString());
  }

  void _setIfDiff(TextEditingController ctrl, String value) {
    if (ctrl.text != value) ctrl.text = value;
  }

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

  double? _parseCurrencyBR(String s) {
    if (s.trim().isEmpty) return null;
    s = s.replaceAll('R\$', '').trim();
    s = s.replaceAll('.', '');
    s = s.replaceAll(',', '.');
    return double.tryParse(s);
  }

  double? _parseNumberLoose(String s) {
    if (s.trim().isEmpty) return null;
    final t = s.contains(',') && !s.contains('.')
        ? s.replaceAll('.', '').replaceAll(',', '.')
        : s;
    return double.tryParse(t);
  }

  String _fmtMoneyBR(double? v) {
    if (v == null) return '';
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    String intPart = parts[0];
    final dec = parts[1];

    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      buf.write(intPart[i]);
      final left = intPart.length - i - 1;
      if (left > 0 && left % 3 == 0) buf.write('.');
    }
    final withThousands = buf.toString();
    return 'R\$ $withThousands,$dec';
  }

  ActiveOaesData _patchFromUi(ActiveOaesData base) {
    return base.copyWith(
      order: int.tryParse(_orderCtrl.text),
      identificationName: _nameCtrl.text,
      latitude: _parseNumberLoose(_latitudeCtrl.text),
      longitude: _parseNumberLoose(_longitudeCtrl.text),
      score: _parseNumberLoose(_scoreCtrl.text),
      state: _stateCtrl.text,
      road: _roadCtrl.text,
      region: _regionCtrl.text,
      extension: _parseNumberLoose(_extensionCtrl.text),
      width: _parseNumberLoose(_widthCtrl.text),
      area: _parseNumberLoose(_areaCtrl.text),
      structureType: _structureCtrl.text,
      relatedContracts: _contractsCtrl.text,
      linearCostMedia: _parseCurrencyBR(_linearCostCtrl.text),
      costEstimate: _parseCurrencyBR(_estimateCtrl.text),
      companyBuild: _companyCtrl.text,
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
      // rebuilda quando form/saving mudarem
      buildWhen: (a, b) =>
      a.form != b.form || a.saving != b.saving || a.selectedIndex != b.selectedIndex,
      builder: (context, st) {
        final cubit = context.read<ActiveOaesCubit>();

        // refletir State -> UI (sem loop, pois _setIfDiff evita set redundante)
        WidgetsBinding.instance.addPostFrameCallback((_) => _fillUiFromForm(st.form));

        void _onFieldChanged(String _) {
          final patched = _patchFromUi(st.form);
          cubit.patchForm(patched);
        }

        final campos = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _input(
              _orderCtrl,
              'ORDEM',
              enabled: false,
              onChanged: _onFieldChanged,
            ),
            _input(
              _nameCtrl,
              'IDENTIFICAÇÃO',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _latitudeCtrl,
              'LATITUDE',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _longitudeCtrl,
              'LONGITUDE',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _scoreCtrl,
              'SCORE (0..5)',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _stateCtrl,
              'STATUS/UF',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _roadCtrl,
              'RODOVIA',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _regionCtrl,
              'REGIÃO',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _extensionCtrl,
              'EXTENSÃO',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _widthCtrl,
              'LARGURA',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _areaCtrl,
              'ÁREA',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _structureCtrl,
              'TIPO DE ESTRUTURA',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _contractsCtrl,
              'CONTRATOS RELACIONADOS',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _linearCostCtrl,
              'CUSTO MÉDIO',
              tooltip: true,
              money: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _estimateCtrl,
              'CUSTO ESTIMADO',
              tooltip: true,
              money: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _companyCtrl,
              'EMPRESA QUE CONSTRUIU',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _dateCtrl,
              'ÚLTIMA DATA DE INTERVENÇÃO',
              tooltip: true,
              date: true,
              onChanged: _onFieldChanged,
            ),
            _input(
              _altitudeCtrl,
              'ALTITUDE',
              tooltip: true,
              onChanged: _onFieldChanged,
            ),
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
                      (st.selectedIndex != null)
                          ? 'Atualizando registro'
                          : 'Criando registro',
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
                onPressed: () {
                  cubit.clearSelection();
                },
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
        keyboardType:
        date ? TextInputType.datetime : (money ? TextInputType.number : null),
        inputFormatters: [
          if (date) FilteringTextInputFormatter.digitsOnly,
          if (date) TextInputMask(mask: '99/99/9999'),
          if (money)
            CurrencyInputFormatter(
              leadingSymbol: 'R\$',
              useSymbolPadding: true,
              thousandSeparator: ThousandSeparator.Period,
              mantissaLength: 2,
            ),
          if (mask != null) mask,
        ],
      ),
    );
  }
}
