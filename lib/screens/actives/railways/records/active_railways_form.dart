import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/actives/railway/active_railway_data.dart';
import 'package:siged/_blocs/actives/railway/active_railways_cubit.dart';
import 'package:siged/_blocs/actives/railway/active_railways_state.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ActiveRailwaysForm extends StatefulWidget {
  /// Registro que será editado no formulário (opcional). Se null, o form fica “em branco”.
  final ActiveRailwayData? editing;

  const ActiveRailwaysForm({super.key, this.editing});

  @override
  State<ActiveRailwaysForm> createState() => _ActiveRailwaysFormState();
}

class _ActiveRailwaysFormState extends State<ActiveRailwaysForm> {
  // Campos de domínio mais comuns na sua ActiveRailwayData
  final _codigoCtrl      = TextEditingController();   // Código
  final _nomeCtrl        = TextEditingController();   // Nome
  final _statusCtrl      = TextEditingController();   // Status (texto livre)
  final _bitolaCtrl      = TextEditingController();   // Bitola
  final _ufCtrl          = TextEditingController();   // UF
  final _municipioCtrl   = TextEditingController();   // Município
  final _extensaoCtrl    = TextEditingController();   // Extensão (km)
  final _extensaoECtrl   = TextEditingController();   // Extensão E. (opcional)
  final _extensaoCCtrl   = TextEditingController();   // Extensão C. (opcional)
  final _codigoCoincCtrl = TextEditingController();   // Código Coincidente (opcional)
  final _fidCtrl         = TextEditingController();   // fid (opcional)
  final _nativeIdCtrl    = TextEditingController();   // id nativo (opcional)

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

  @override
  void didUpdateWidget(covariant ActiveRailwaysForm oldWidget) {
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

  void _fillUiFromData(ActiveRailwayData? d) {
    _setIfDiff(_codigoCtrl,      d?.codigo ?? '');
    _setIfDiff(_nomeCtrl,        d?.nome ?? '');
    _setIfDiff(_statusCtrl,      d?.status ?? '');
    _setIfDiff(_bitolaCtrl,      d?.bitola ?? '');
    _setIfDiff(_ufCtrl,          d?.uf ?? '');
    _setIfDiff(_municipioCtrl,   d?.municipio ?? '');
    _setIfDiff(_extensaoCtrl,    _fmtNum(d?.extensao));
    _setIfDiff(_extensaoECtrl,   _fmtNum(d?.extensaoE));
    _setIfDiff(_extensaoCCtrl,   _fmtNum(d?.extensaoC));
    _setIfDiff(_codigoCoincCtrl, d?.codigoCoincidente ?? '');
    _setIfDiff(_fidCtrl,         (d?.fid ?? '').toString());
    _setIfDiff(_nativeIdCtrl,    (d?.nativeId ?? '').toString());
  }

  ActiveRailwayData _buildData(ActiveRailwayData? base) {
    return ActiveRailwayData(
      id: base?.id,
      codigo: _codigoCtrl.text.trim().isEmpty ? null : _codigoCtrl.text.trim(),
      nome: _nomeCtrl.text.trim().isEmpty ? null : _nomeCtrl.text.trim(),
      status: _statusCtrl.text.trim().isEmpty ? null : _statusCtrl.text.trim(),
      bitola: _bitolaCtrl.text.trim().isEmpty ? null : _bitolaCtrl.text.trim(),
      uf: _ufCtrl.text.trim().isEmpty ? null : _ufCtrl.text.trim(),
      municipio: _municipioCtrl.text.trim().isEmpty ? null : _municipioCtrl.text.trim(),
      extensao: _parseNumberLoose(_extensaoCtrl.text),
      extensaoE: _parseNumberLoose(_extensaoECtrl.text),
      extensaoC: _parseNumberLoose(_extensaoCCtrl.text),
      codigoCoincidente: _codigoCoincCtrl.text.trim().isEmpty ? null : _codigoCoincCtrl.text.trim(),
      fid: _parseIntLoose(_fidCtrl.text),
      nativeId: double.tryParse(_nativeIdCtrl.text.trim()),
      // geometry fica fora do form; é gerida pela importação/edição no mapa
    );
  }

  bool _requiredValid(ActiveRailwayData d) {
    final hasName = (d.nome?.trim().isNotEmpty ?? false);
    final hasUF   = (d.uf?.trim().isNotEmpty ?? false);
    final hasExt  = (d.extensao ?? 0) > 0;
    return hasName && hasUF && hasExt;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveRailwaysCubit, ActiveRailwaysState>(
      buildWhen: (a, b) => a.savingOrImporting != b.savingOrImporting,
      builder: (context, st) {
        final cubit = context.read<ActiveRailwaysCubit>();

        final fields = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _input(_codigoCtrl,     'CÓDIGO'),
            _input(_nomeCtrl,       'NOME', width: 420),
            _input(_statusCtrl,     'STATUS (ex.: Em Operação, Em Obras, Planejada)'),
            _input(_bitolaCtrl,     'BITOLA'),
            _input(_ufCtrl,         'UF', tooltip: true),
            _input(_municipioCtrl,  'MUNICÍPIO', tooltip: true),
            _input(_extensaoCtrl,   'EXTENSÃO (km)', number: true),
            _input(_extensaoECtrl,  'EXTENSÃO E. (km)', number: true),
            _input(_extensaoCCtrl,  'EXTENSÃO C. (km)', number: true),
            _input(_codigoCoincCtrl,'CÓDIGO COINCIDENTE'),
            _input(_fidCtrl,        'fid', number: true, digitsOnly: true, width: 140),
            _input(_nativeIdCtrl,   'id nativo', number: true, width: 140),
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
                      // chama direto o Cubit
                      await cubit.upsert(data);
                      NotificationCenter.instance.show(
                        AppNotification(
                          title: const Text('Salvando ferrovia...'),
                          subtitle: Text(
                            (widget.editing?.id != null)
                                ? 'Atualizando registro'
                                : 'Criando novo registro',
                          ),
                          type: AppNotificationType.info,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                        : null,
                    icon: const Icon(Icons.save),
                    label: Text(widget.editing?.id != null ? 'Atualizar' : 'Salvar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
          if (!digitsOnly && number) TextInputMask(mask: '#########9[.99]'),
        ],
      ),
    );
  }
}
