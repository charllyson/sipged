import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';

import '../../../_widgets/input/custom_text_field.dart';
import '../../../_widgets/mask_class.dart';
import 'active_oaes_controller.dart';

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

  // --- helpers de sync ---
  void _fillUiFromForm(ActiveOaesController c) {
    _setIfDiff(_orderCtrl, (c.form.order ?? '').toString());
    _setIfDiff(_nameCtrl, c.form.identificationName ?? '');
    _setIfDiff(_latitudeCtrl, (c.form.latitude ?? '').toString());
    _setIfDiff(_longitudeCtrl, (c.form.longitude ?? '').toString());

    _setIfDiff(_scoreCtrl, (c.form.score ?? '').toString());
    _setIfDiff(_stateCtrl, c.form.state ?? '');
    _setIfDiff(_roadCtrl, c.form.road ?? '');
    _setIfDiff(_regionCtrl, c.form.region ?? '');
    _setIfDiff(_extensionCtrl, (c.form.extension ?? '').toString());
    _setIfDiff(_widthCtrl, (c.form.width ?? '').toString());
    _setIfDiff(_areaCtrl, (c.form.area ?? '').toString());
    _setIfDiff(_structureCtrl, c.form.structureType ?? '');
    _setIfDiff(_contractsCtrl, c.form.relatedContracts ?? '');
    _setIfDiff(_linearCostCtrl, (c.form.linearCostMedia ?? '').toString());
    _setIfDiff(_estimateCtrl, (c.form.costEstimate ?? '').toString());
    _setIfDiff(_companyCtrl, c.form.companyBuild ?? '');
    _setIfDiff(_dateCtrl, c.form.lastDateIntervention != null ? _fmtDDMMYYYY(c.form.lastDateIntervention!) : '');
    _setIfDiff(_altitudeCtrl, (c.form.altitude ?? '').toString());
  }

  void _pushRequiredFieldsToForm(ActiveOaesController c) {
    c.updateField<int>(int.tryParse(_orderCtrl.text), (v) => c.form.order = v);
    c.updateField<String>(_nameCtrl.text, (v) => c.form.identificationName = v);
    c.updateField<double>(double.tryParse(_latitudeCtrl.text), (v) => c.form.latitude = v);
    c.updateField<double>(double.tryParse(_longitudeCtrl.text), (v) => c.form.longitude = v);
  }

  void _pushOptionalFieldsToForm(ActiveOaesController c) {
    c.updateField<double>(double.tryParse(_scoreCtrl.text), (v) => c.form.score = v);
    c.updateField<String>(_stateCtrl.text, (v) => c.form.state = v);
    c.updateField<String>(_roadCtrl.text, (v) => c.form.road = v);
    c.updateField<String>(_regionCtrl.text, (v) => c.form.region = v);
    c.updateField<double>(double.tryParse(_extensionCtrl.text), (v) => c.form.extension = v);
    c.updateField<double>(double.tryParse(_widthCtrl.text), (v) => c.form.width = v);
    c.updateField<double>(double.tryParse(_areaCtrl.text), (v) => c.form.area = v);
    c.updateField<String>(_structureCtrl.text, (v) => c.form.structureType = v);
    c.updateField<String>(_contractsCtrl.text, (v) => c.form.relatedContracts = v);
    c.updateField<double>(double.tryParse(_linearCostCtrl.text), (v) => c.form.linearCostMedia = v);
    c.updateField<double>(double.tryParse(_estimateCtrl.text), (v) => c.form.costEstimate = v);
    c.updateField<String>(_companyCtrl.text, (v) => c.form.companyBuild = v);
    c.updateField<DateTime>(_parseDDMMYYYY(_dateCtrl.text), (v) => c.form.lastDateIntervention = v);
    c.updateField<double>(double.tryParse(_altitudeCtrl.text), (v) => c.form.altitude = v);
  }

  void _setIfDiff(TextEditingController ctrl, String value) {
    if (ctrl.text != value) ctrl.text = value;
  }

  DateTime? _parseDDMMYYYY(String s) {
    if (s.trim().isEmpty) return null;
    try {
      final p = s.split('/');
      if (p.length != 3) return null;
      final d = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      final y = int.tryParse(p[2]);
      if (d == null || m == null || y == null) return null;
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  String _fmtDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yy';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ActiveOaesController>();

    // reflita mudanças do controller.form na UI
    WidgetsBinding.instance.addPostFrameCallback((_) => _fillUiFromForm(c));

    final campos = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _input(_orderCtrl, 'ORDEM', enabled: false, onChanged: (_) {
          _pushRequiredFieldsToForm(c);
        }),
        _input(_nameCtrl, 'IDENTIFICAÇÃO', tooltip: true, onChanged: (_) {
          _pushRequiredFieldsToForm(c);
        }),
        _input(_latitudeCtrl, 'LATITUDE', tooltip: true, onChanged: (_) {
          _pushRequiredFieldsToForm(c);
        }),
        _input(_longitudeCtrl, 'LONGITUDE', tooltip: true, onChanged: (_) {
          _pushRequiredFieldsToForm(c);
        }),

        _input(_scoreCtrl, 'SCORE', tooltip: true),
        _input(_stateCtrl, 'STATUS', tooltip: true),
        _input(_roadCtrl, 'RODOVIA', tooltip: true),
        _input(_regionCtrl, 'REGIÃO', tooltip: true),
        _input(_extensionCtrl, 'EXTENSÃO', tooltip: true),
        _input(_widthCtrl, 'LARGURA', tooltip: true),
        _input(_areaCtrl, 'ÁREA', tooltip: true),
        _input(_structureCtrl, 'TIPO DE ESTRUTURA', tooltip: true),
        _input(_contractsCtrl, 'CONTRATOS RELACIONADOS', tooltip: true),
        _input(_linearCostCtrl, 'CUSTO MÉDIO', tooltip: true, money: true),
        _input(_estimateCtrl, 'CUSTO ESTIMADO', tooltip: true, money: true),
        _input(_companyCtrl, 'EMPRESA QUE CONSTRUIU', tooltip: true),
        _input(_dateCtrl, 'ÚLTIMA DATA DE INTERVENÇÃO', tooltip: true, date: true),
        _input(_altitudeCtrl, 'ALTITUDE', tooltip: true),
      ],
    );

    final botoes = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: c.formValid && c.isEditable ? () async {
            _pushRequiredFieldsToForm(c);
            _pushOptionalFieldsToForm(c);
            final err = await c.saveOrUpdate();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(err == null
                  ? (c.editingMode ? 'OAE atualizado com sucesso!' : 'OAE salvo com sucesso!')
                  : err),
              backgroundColor: err == null ? Colors.green : Colors.orange,
            ));
          } : null,
          icon: const Icon(Icons.save),
          label: Text(c.editingMode ? 'Atualizar' : 'Salvar'),
        ),
        const SizedBox(width: 12),
        if (c.editingMode)
          TextButton.icon(
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Limpar'),
            onPressed: () => c.clearSelectionAndReset(),
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
        keyboardType: date
            ? TextInputType.datetime
            : (money ? TextInputType.number : null),
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
