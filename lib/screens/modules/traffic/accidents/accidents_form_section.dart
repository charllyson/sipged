// lib/screens/modules/traffic/accidents/accidents_form_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';

import '../../../../_widgets/layout/responsive_utils.dart';
import '../../../../_widgets/input/custom_date_field.dart';
import '../../../../_widgets/input/custom_text_field.dart';
import '../../../../_widgets/input/drop_down_botton_change.dart';
import '../../../../_blocs/modules/transit/accidents/accidents_data.dart';

class AccidentsFormSection extends StatefulWidget {
  final bool isEditable;
  final bool formValidated;
  final String? currentAccidentId;
  final int? itemsPerLineOverride; // força número de itens por linha

  /// Modelo atual do formulário
  final AccidentsData data;

  /// Chamado sempre que algum campo é alterado
  final void Function(AccidentsData updated) onChanged;

  final Future<void> Function() onClear;
  final VoidCallback onSave;
  final VoidCallback onGetLocation;

  /// 🔄 Callbacks para sincronizar com o mapa
  final void Function(double lat, double lon)? onUpdateMapFromLatLng;
  final Future<void> Function(String cep)? onUpdateMapFromCep;

  const AccidentsFormSection({
    super.key,
    required this.isEditable,
    required this.formValidated,
    required this.currentAccidentId,
    required this.data,
    required this.onChanged,
    required this.onClear,
    required this.onSave,
    required this.onGetLocation,
    this.itemsPerLineOverride,
    this.onUpdateMapFromLatLng,
    this.onUpdateMapFromCep,
  });

  @override
  State<AccidentsFormSection> createState() => _AccidentsFormSectionState();
}

class _AccidentsFormSectionState extends State<AccidentsFormSection> {
  // Controllers de texto baseados em AccidentsData
  late final TextEditingController _orderCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _highwayCtrl;
  late final TextEditingController _cityDescCtrl; // Cidade (Descrição)
  late final TextEditingController _typeOfAccidentCtrl;
  late final TextEditingController _deathCtrl;
  late final TextEditingController _scoresVictimsCtrl;
  late final TextEditingController _transportInvolvedCtrl;

  late final TextEditingController _latitudeCtrl;
  late final TextEditingController _longitudeCtrl;
  late final TextEditingController _postalCodeCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityAddressCtrl; // Cidade (Endereço)
  late final TextEditingController _subLocalityCtrl;
  late final TextEditingController _administrativeAreaCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _isoCountryCodeCtrl;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _orderCtrl = TextEditingController(
      text: (d.order != null && d.order != 0) ? d.order.toString() : '',
    );

    _selectedDate = d.date;
    _dateCtrl = TextEditingController(text: _formatDate(d.date));

    _highwayCtrl = TextEditingController(text: d.highway ?? '');
    _cityDescCtrl = TextEditingController(text: d.city ?? '');

    _typeOfAccidentCtrl =
        TextEditingController(text: d.typeOfAccident ?? '');

    _deathCtrl =
        TextEditingController(text: d.death != null ? d.death.toString() : '');

    _scoresVictimsCtrl = TextEditingController(
      text: d.scoresVictims != null ? d.scoresVictims.toString() : '',
    );

    _transportInvolvedCtrl =
        TextEditingController(text: d.transportInvolved ?? '');

    _latitudeCtrl = TextEditingController(
      text: d.latLng != null ? d.latLng!.latitude.toStringAsFixed(6) : '',
    );
    _longitudeCtrl = TextEditingController(
      text: d.latLng != null ? d.latLng!.longitude.toStringAsFixed(6) : '',
    );

    _postalCodeCtrl = TextEditingController(text: d.postalCode ?? '');
    _streetCtrl = TextEditingController(text: d.street ?? '');
    _cityAddressCtrl = TextEditingController(text: d.locality ?? '');
    _subLocalityCtrl = TextEditingController(text: d.subLocality ?? '');
    _administrativeAreaCtrl =
        TextEditingController(text: d.administrativeArea ?? '');
    _countryCtrl = TextEditingController(text: d.country ?? '');
    _isoCountryCodeCtrl =
        TextEditingController(text: d.isoCountryCode ?? '');
  }

  @override
  void didUpdateWidget(covariant AccidentsFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final value = v ?? '';
        if (c.text != value) c.text = value;
      }

      sync(_orderCtrl, (d.order != null && d.order != 0) ? d.order.toString() : '');
      _selectedDate = d.date;
      sync(_dateCtrl, _formatDate(d.date));

      sync(_highwayCtrl, d.highway);
      sync(_cityDescCtrl, d.city);
      sync(_typeOfAccidentCtrl, d.typeOfAccident);
      sync(_deathCtrl, d.death != null ? d.death.toString() : '');
      sync(_scoresVictimsCtrl,
          d.scoresVictims != null ? d.scoresVictims.toString() : '');
      sync(_transportInvolvedCtrl, d.transportInvolved);

      sync(
        _latitudeCtrl,
        d.latLng != null ? d.latLng!.latitude.toStringAsFixed(6) : '',
      );
      sync(
        _longitudeCtrl,
        d.latLng != null ? d.latLng!.longitude.toStringAsFixed(6) : '',
      );

      sync(_postalCodeCtrl, d.postalCode);
      sync(_streetCtrl, d.street);
      sync(_cityAddressCtrl, d.locality);
      sync(_subLocalityCtrl, d.subLocality);
      sync(_administrativeAreaCtrl, d.administrativeArea);
      sync(_countryCtrl, d.country);
      sync(_isoCountryCodeCtrl, d.isoCountryCode);
    }
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _dateCtrl.dispose();
    _highwayCtrl.dispose();
    _cityDescCtrl.dispose();
    _typeOfAccidentCtrl.dispose();
    _deathCtrl.dispose();
    _scoresVictimsCtrl.dispose();
    _transportInvolvedCtrl.dispose();

    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _postalCodeCtrl.dispose();
    _streetCtrl.dispose();
    _cityAddressCtrl.dispose();
    _subLocalityCtrl.dispose();
    _administrativeAreaCtrl.dispose();
    _countryCtrl.dispose();
    _isoCountryCodeCtrl.dispose();

    super.dispose();
  }

  // ============================================================
  // Helpers
  // ============================================================

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  bool _isValidLatLng(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  void _tryUpdateMapFromLatLng() {
    final lat = double.tryParse(_latitudeCtrl.text.replaceAll(',', '.'));
    final lng = double.tryParse(_longitudeCtrl.text.replaceAll(',', '.'));
    if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
      widget.onUpdateMapFromLatLng?.call(lat, lng);
    }
  }

  Future<void> _tryUpdateMapFromCep() async {
    final raw = _postalCodeCtrl.text;
    final digits = raw.replaceAll(RegExp(r'\D'), ''); // só números
    if (digits.length == 8) {
      await widget.onUpdateMapFromCep?.call(digits);
    }
  }

  // Campo de texto padrão
  Widget _text(
      BuildContext c,
      TextEditingController ctrl,
      String label, {
        bool enabled = true,
        List<TextInputFormatter>? mask,
        TextInputType? keyboardType,
      }) {
    return CustomTextField(
      enabled: enabled,
      controller: ctrl,
      labelText: label,
      inputFormatters: mask,
      keyboardType: keyboardType,
      onChanged: (_) => _emitChange(),
    );
  }

  // Envolve um campo para respeitar a largura calculada do grid
  Widget _gridItem(double width, Widget child) => ConstrainedBox(
    constraints: BoxConstraints.tightFor(width: width),
    child: child,
  );

  // Cabeçalho de seção (linha inteira)

  // Campo CEP com blur → geocode (sem grid aqui, só o campo)
  Widget _cepField(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) _tryUpdateMapFromCep();
      },
      child: _text(
        context,
        _postalCodeCtrl,
        'CEP',
        keyboardType: TextInputType.number,
        mask: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
  }

  // ============================================================
  // Emitir novo AccidentsData baseado nos controllers
  // ============================================================

  void _emitChange() {
    final base = widget.data;

    int? parseInt(String text) {
      final t = text.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t);
    }

    // Mantém valor de latitude/longitude apenas como texto; o latLng
    // será atualizado normalmente pelo reverse geocode / getLocation
    // via Bloc, mas se quiser, aqui dá pra montar um latLng novo também.

    final updated = AccidentsData(
      // IDs / metadados
      id: base.id,
      createdAt: base.createdAt,
      createdBy: base.createdBy,
      updatedAt: base.updatedAt,
      updatedBy: base.updatedBy,
      deletedAt: base.deletedAt,
      deletedBy: base.deletedBy,
      year: base.year,
      month: base.month,
      yearDocId: base.yearDocId,
      recordPath: base.recordPath,

      // Campos principais
      order: parseInt(_orderCtrl.text) ?? base.order,
      date: _selectedDate ?? base.date,
      highway: _highwayCtrl.text.trim(),
      typeOfAccident: _typeOfAccidentCtrl.text.trim().isEmpty
          ? base.typeOfAccident
          : _typeOfAccidentCtrl.text.trim(),
      death: parseInt(_deathCtrl.text) ?? base.death,
      scoresVictims:
      parseInt(_scoresVictimsCtrl.text) ?? base.scoresVictims,
      transportInvolved: _transportInvolvedCtrl.text.trim(),
      location: base.location,
      referencePoint: base.referencePoint,

      // Cidade usada para mapas / análises
      city: _cityDescCtrl.text.trim(),
      cityNormalized: base.cityNormalized,

      // Endereço detalhado
      street: _streetCtrl.text.trim(),
      subLocality: _subLocalityCtrl.text.trim(),
      locality: _cityAddressCtrl.text.trim(),
      administrativeArea: _administrativeAreaCtrl.text.trim(),
      postalCode: _postalCodeCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      isoCountryCode: _isoCountryCodeCtrl.text.trim(),
      subAdministrativeArea: base.subAdministrativeArea,
      thoroughfare: base.thoroughfare,
      subThoroughfare: base.subThoroughfare,
      nameArea: base.nameArea,

      // LatLng mantido (pode ser atualizado pelo Bloc/Map)
      latLng: base.latLng,

      // Novos (sexo/idade), mantidos do base por enquanto
      victimSex: base.victimSex,
      victimAge: base.victimAge,
    );

    widget.onChanged(updated);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const double containerPadding = 12;

    return LayoutBuilder(
      builder: (context, inner) {
        final maxW = inner.maxWidth;
        final isNarrow = maxW < 720;

        // base: 2 por linha em desktop, 1 em telas pequenas
        final basePerLine = widget.itemsPerLineOverride ?? 2;
        final effectivePerLine = isNarrow ? 1 : basePerLine;

        double fieldW(int perLine) => responsiveInputWidth(
          context: context,
          itemsPerLine: perLine,
          containerWidth: maxW,
          spacing: 14,
          margin: 24,
          extraPadding: containerPadding * 2,
          minItemWidth: 260,
          minWidthSmallScreen: 280,
          forceItemsPerLineOnSmall: false,
        );

        final w2 = fieldW(effectivePerLine);

        // ------- PRIMEIRA LINHA: botão + latitude + longitude -------
        final firstRow = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              message: 'Usar localização atual do usuário',
              child: InkWell(
                onTap: widget.onGetLocation,
                child: const Column(
                  children: [
                    Icon(Icons.my_location, color: Colors.blueAccent),
                    SizedBox(height: 2),
                    Text(
                      'Obter\nlocalização',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueAccent, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _tryUpdateMapFromLatLng();
                      },
                      child: _text(
                        context,
                        _latitudeCtrl,
                        'Latitude',
                        enabled: widget.isEditable,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) _tryUpdateMapFromLatLng();
                      },
                      child: _text(
                        context,
                        _longitudeCtrl,
                        'Longitude',
                        enabled: widget.isEditable,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        // ------- DEMAIS CAMPOS (2 por linha → 1 em telas pequenas) -------
        final gridWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            firstRow,

            _gridItem(w2, _cepField(context)),
            _gridItem(
                w2,
                _text(
                  context,
                  _streetCtrl,
                  'Rua',
                  enabled: widget.isEditable,
                )),
            _gridItem(
              w2,
              _text(
                context,
                _cityAddressCtrl,
                'Cidade (Endereço)',
                enabled: widget.isEditable,
              ),
            ),
            _gridItem(
              w2,
              _text(
                context,
                _subLocalityCtrl,
                'Bairro',
                enabled: widget.isEditable,
              ),
            ),
            _gridItem(
              w2,
              _text(
                context,
                _administrativeAreaCtrl,
                'Estado',
                enabled: widget.isEditable,
              ),
            ),
            SectionTitle(text: 'Descrições do acidente'),
            _gridItem(
              w2,
              Tooltip(
                message: 'Este campo é calculado automaticamente.',
                child: CustomTextField(
                  enabled: false,
                  controller: _orderCtrl,
                  labelText: 'Ordem do acidente',
                ),
              ),
            ),
            _gridItem(
              w2,
              CustomDateField(
                enabled: widget.isEditable,
                controller: _dateCtrl,
                labelText: 'Data do acidente',
                onChanged: (date) {
                  _selectedDate = date ?? _selectedDate;
                  _emitChange();
                },
              ),
            ),
            _gridItem(
              w2,
              DropDownButtonChange(
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                enabled: widget.isEditable,
                labelText: 'Tipo de acidente',
                items: AccidentsData.accidentTypes,
                controller: _typeOfAccidentCtrl,
                onChanged: (v) {
                  _typeOfAccidentCtrl.text = v ?? '';
                  _emitChange();
                },
              ),
            ),
            _gridItem(
              w2,
              _text(
                context,
                _deathCtrl,
                'Mortes',
                enabled: widget.isEditable,
                keyboardType: TextInputType.number,
                mask: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            _gridItem(
              w2,
              _text(
                context,
                _scoresVictimsCtrl,
                'Vítimas com escoriações',
                enabled: widget.isEditable,
                keyboardType: TextInputType.number,
                mask: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            _gridItem(
              w2,
              _text(
                context,
                _transportInvolvedCtrl,
                'Automóveis envolvidos',
                enabled: widget.isEditable,
              ),
            ),
            _gridItem(
              w2,
              _text(
                context,
                _highwayCtrl,
                'Rodovia',
                enabled: widget.isEditable,
              ),
            ),
            _gridItem(
              w2,
              _text(
                context,
                _cityDescCtrl,
                'Cidade (Descrição)',
                enabled: widget.isEditable,
              ),
            ),
          ],
        );

        final actions = Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.save),
                label: Text(
                    widget.currentAccidentId != null ? 'Atualizar' : 'Salvar'),
                onPressed:
                widget.formValidated && widget.isEditable ? widget.onSave : null,
              ),
              if (widget.currentAccidentId != null)
                TextButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text('Limpar'),
                  onPressed: () async => widget.onClear(),
                ),
            ],
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(containerPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              gridWrap,
              const SizedBox(height: 16),
              actions,
            ],
          ),
        );
      },
    );
  }
}
