import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/actives/roads/active_road_bloc.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/mask_class.dart';

import 'package:siged/_blocs/actives/roads/active_roads_data.dart';
import 'package:siged/_blocs/actives/roads/active_roads_event.dart';
import 'package:siged/_blocs/actives/roads/active_roads_state.dart';


class ActiveRoadsForm extends StatefulWidget {
  /// Registro que será editado no formulário (opcional). Se null, o form fica “em branco”.
  final ActiveRoadsData? editing;

  const ActiveRoadsForm({super.key, this.editing});

  @override
  State<ActiveRoadsForm> createState() => _ActiveRoadsFormState();
}

class _ActiveRoadsFormState extends State<ActiveRoadsForm> {
  // Controllers principais (peguei campos mais práticos para cadastro manual)
  final _acronymCtrl       = TextEditingController(); // ex: AL-101
  final _ufCtrl            = TextEditingController(); // ex: AL
  final _regionalCtrl      = TextEditingController(); // ex: VALE DO MUNDAÚ
  final _roadCodeCtrl      = TextEditingController(); // código interno
  final _stateSurfaceCtrl  = TextEditingController(); // ex: PAV / EOP ...
  final _surfaceCtrl       = TextEditingController(); // descrição livre, se existir
  final _extensionCtrl     = TextEditingController(); // km (double)
  final _initialKmCtrl     = TextEditingController();
  final _finalKmCtrl       = TextEditingController();
  final _directionCtrl     = TextEditingController(); // SENTIDO
  final _managingCtrl      = TextEditingController(); // órgão gestor
  final _worksCtrl         = TextEditingController(); // obras
  final _tmdCtrl           = TextEditingController(); // TMD (int)
  final _maxSpeedCtrl      = TextEditingController(); // máxima (int)
  final _descCtrl          = TextEditingController(); // observações

  @override
  void dispose() {
    _acronymCtrl.dispose();
    _ufCtrl.dispose();
    _regionalCtrl.dispose();
    _roadCodeCtrl.dispose();
    _stateSurfaceCtrl.dispose();
    _surfaceCtrl.dispose();
    _extensionCtrl.dispose();
    _initialKmCtrl.dispose();
    _finalKmCtrl.dispose();
    _directionCtrl.dispose();
    _managingCtrl.dispose();
    _worksCtrl.dispose();
    _tmdCtrl.dispose();
    _maxSpeedCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ActiveRoadsForm oldWidget) {
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
    final t = s.contains(',') && !s.contains('.') ? s.replaceAll('.', '').replaceAll(',', '.') : s;
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

  void _fillUiFromData(ActiveRoadsData? r) {
    final d = r;
    _setIfDiff(_acronymCtrl,      d?.acronym ?? '');
    _setIfDiff(_ufCtrl,           d?.uf ?? '');
    _setIfDiff(_regionalCtrl,     d?.regional ?? (d?.metadata?['regional']?.toString() ?? ''));
    _setIfDiff(_roadCodeCtrl,     d?.roadCode ?? '');
    _setIfDiff(_stateSurfaceCtrl, d?.stateSurface ?? (d?.surface ?? (d?.state ?? '')));
    _setIfDiff(_surfaceCtrl,      d?.surface ?? '');
    _setIfDiff(_extensionCtrl,    _fmtNum(d?.extension));
    _setIfDiff(_initialKmCtrl,    _fmtNum(d?.initialKm));
    _setIfDiff(_finalKmCtrl,      _fmtNum(d?.finalKm));
    _setIfDiff(_directionCtrl,    d?.direction ?? '');
    _setIfDiff(_managingCtrl,     d?.managingAgency ?? '');
    _setIfDiff(_worksCtrl,        d?.works ?? '');
    _setIfDiff(_tmdCtrl,          (d?.tmd ?? '').toString());
    _setIfDiff(_maxSpeedCtrl,     (d?.maximumSpeed ?? '').toString());
    _setIfDiff(_descCtrl,         d?.description ?? '');
  }

  ActiveRoadsData _buildData(ActiveRoadsData? base) {
    return ActiveRoadsData(
      id: base?.id,
      acronym: _acronymCtrl.text.trim().isEmpty ? null : _acronymCtrl.text.trim(),
      uf: _ufCtrl.text.trim().isEmpty ? null : _ufCtrl.text.trim(),
      regional: _regionalCtrl.text.trim().isEmpty ? null : _regionalCtrl.text.trim(),
      roadCode: _roadCodeCtrl.text.trim().isEmpty ? null : _roadCodeCtrl.text.trim(),
      stateSurface: _stateSurfaceCtrl.text.trim().isEmpty ? null : _stateSurfaceCtrl.text.trim(),
      surface: _surfaceCtrl.text.trim().isEmpty ? null : _surfaceCtrl.text.trim(),
      extension: _parseNumberLoose(_extensionCtrl.text),
      initialKm: _parseNumberLoose(_initialKmCtrl.text),
      finalKm: _parseNumberLoose(_finalKmCtrl.text),
      direction: _directionCtrl.text.trim().isEmpty ? null : _directionCtrl.text.trim(),
      managingAgency: _managingCtrl.text.trim().isEmpty ? null : _managingCtrl.text.trim(),
      works: _worksCtrl.text.trim().isEmpty ? null : _worksCtrl.text.trim(),
      tmd: _parseIntLoose(_tmdCtrl.text),
      maximumSpeed: _parseIntLoose(_maxSpeedCtrl.text),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      // points ficam de fora no form (edição por mapa)
    );
  }

  bool _requiredValid(ActiveRoadsData d) {
    final hasAcr = (d.acronym?.trim().isNotEmpty ?? false);
    final hasUF  = (d.uf?.trim().isNotEmpty ?? false);
    final hasExt = (d.extension ?? 0) > 0;
    return hasAcr && hasUF && hasExt;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveRoadsBloc, ActiveRoadsState>(
      buildWhen: (a, b) => a.savingOrImporting != b.savingOrImporting,
      builder: (context, st) {
        final bloc = context.read<ActiveRoadsBloc>();

        final fields = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _input(_acronymCtrl,      'RODOVIA (Sigla: AL-101)', tooltip: true),
            _input(_ufCtrl,           'UF', tooltip: true),
            _input(_regionalCtrl,     'REGIÃO', tooltip: true),
            _input(_roadCodeCtrl,     'CÓDIGO (opcional)'),
            _input(_stateSurfaceCtrl, 'STATUS/SUPERFÍCIE (ex: PAV, EOP, DUP)'),
            _input(_surfaceCtrl,      'SUPERFÍCIE (texto livre)', tooltip: true),
            _input(_extensionCtrl,    'EXTENSÃO (km)', number: true),
            _input(_initialKmCtrl,    'KM INICIAL', number: true),
            _input(_finalKmCtrl,      'KM FINAL', number: true),
            _input(_directionCtrl,    'SENTIDO'),
            _input(_managingCtrl,     'ÓRGÃO GESTOR'),
            _input(_worksCtrl,        'OBRAS (texto livre)'),
            _input(_tmdCtrl,          'TMD', number: true, digitsOnly: true),
            _input(_maxSpeedCtrl,     'VELOCIDADE MÁXIMA', number: true, digitsOnly: true),
            _input(_descCtrl,         'DESCRIÇÃO / OBS', maxLines: 3, width: 652),
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
                        ? () {
                      final data = _buildData(widget.editing);
                      bloc.add(ActiveRoadsUpsertRequested(data));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Salvando rodovia...')),
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
