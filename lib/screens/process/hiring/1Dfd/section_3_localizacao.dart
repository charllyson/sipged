// lib/screens/process/hiring/1Dfd/dfd_sections/section_3_localizacao.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_services/geoJson/geojson_locations_service.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

class SectionLocalizacao extends StatefulWidget {
  final bool isEditable;
  final DfdData data;
  final void Function(DfdData updated) onChanged;

  const SectionLocalizacao({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionLocalizacao> createState() => _SectionLocalizacaoState();
}

class _SectionLocalizacaoState extends State<SectionLocalizacao>
    with FormValidationMixin {
  // controllers
  late final TextEditingController _ufCtrl;
  late final TextEditingController _municipioCtrl;
  late final TextEditingController _regionalCtrl;
  late final TextEditingController _kmInicialCtrl;
  late final TextEditingController _kmFinalCtrl;

  // estado de UF / municípios
  List<String> _ufs = const [];
  List<String> _munisDaUf = const [];
  String? _ufSelecionada;

  // company/region auxiliares
  String? _companyId;
  String? _regionDocId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _ufCtrl        = TextEditingController(text: d.uf);
    _municipioCtrl = TextEditingController(text: d.municipio);
    _regionalCtrl  = TextEditingController(text: d.regional ?? '');
    _kmInicialCtrl = TextEditingController(text: d.kmInicial);
    _kmFinalCtrl   = TextEditingController(text: d.kmFinal);

    _initGeojsonUfMunicipios();
    _resolveCompanyIdFromData();
  }

  @override
  void didUpdateWidget(covariant SectionLocalizacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      _ufCtrl.text        = d.uf;
      _municipioCtrl.text = d.municipio;
      _regionalCtrl.text  = d.regional ?? '';
      _kmInicialCtrl.text = d.kmInicial;
      _kmFinalCtrl.text   = d.kmFinal;

      // se mudou orgaoDemandante, tenta achar novo companyId
      if (oldWidget.data.orgaoDemandante != widget.data.orgaoDemandante) {
        _resolveCompanyIdFromData();
      }

      // se mudou UF, ajusta seleção
      _updateUfSelectionFromController();
    }
  }

  @override
  void dispose() {
    _ufCtrl.dispose();
    _municipioCtrl.dispose();
    _regionalCtrl.dispose();
    _kmInicialCtrl.dispose();
    _kmFinalCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      uf:        _ufCtrl.text,
      municipio: _municipioCtrl.text,
      regional:  _regionalCtrl.text.isEmpty ? null : _regionalCtrl.text,
      kmInicial: _kmInicialCtrl.text,
      kmFinal:   _kmFinalCtrl.text,
    );
    widget.onChanged(updated);
  }

  Future<void> _resolveCompanyIdFromData() async {
    final label = widget.data.orgaoDemandante.trim();
    if (label.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .where('companyName', isEqualTo: label)
          .limit(1)
          .get();

      if (!mounted) return;
      if (snap.docs.isNotEmpty) {
        setState(() {
          _companyId = snap.docs.first.id;
        });
      }
    } catch (_) {}
  }

  Future<void> _initGeojsonUfMunicipios() async {
    try {
      await GeoJsonLocationsService.I.loadFromAsset(
        path: 'assets/geojson/limits/limites_territoriais.geojson',
        ufKeys: const ['SIGLA_UF'],
        munKeys: const ['NM_MUN'],
        upperMun: false,
        stripDiacriticsMun: false,
        force: true,
      );

      final ufs = GeoJsonLocationsService.I.ufs;

      final currentUf = widget.data.uf.trim().toUpperCase();
      final selectedUf =
      ufs.contains(currentUf) ? currentUf : (ufs.isNotEmpty ? ufs.first : null);

      final munis = selectedUf != null
          ? GeoJsonLocationsService.I.getMunicipios(selectedUf)
          : const <String>[];

      if (!mounted) return;

      setState(() {
        _ufs = ufs;
        _ufSelecionada = selectedUf;
        _ufCtrl.text = selectedUf ?? '';
        _munisDaUf = munis;

        final curMun = widget.data.municipio.trim();
        if (!_munisDaUf.contains(curMun)) {
          _municipioCtrl.text = '';
        }
      });
    } catch (_) {}
  }

  void _updateUfSelectionFromController() {
    final ufNow = _ufCtrl.text.trim().toUpperCase();
    if (ufNow.isNotEmpty && _ufs.contains(ufNow)) {
      setState(() {
        _ufSelecionada = ufNow;
        _munisDaUf = GeoJsonLocationsService.I.getMunicipios(_ufSelecionada);
        final curMun = _municipioCtrl.text.trim();
        if (!_munisDaUf.contains(curMun)) {
          _municipioCtrl.text = '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('3) Localização / Escopo rodoviário'),
        LayoutBuilder(
          builder: (context, inner) {
            final w6 = inputW6(context, inner);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // UF
                SizedBox(
                  width: w6,
                  child: DropDownButtonChange(
                    key: ValueKey('uf-${d.uf}'),
                    width: w6,
                    labelText: 'UF',
                    controller: _ufCtrl,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    items: _ufs,
                    enableInlineDelete: false,
                    onChanged: (v) {
                      final uf = (v ?? '').trim().toUpperCase();
                      _ufCtrl.text = uf;
                      _updateUfSelectionFromController();
                      _emitChange();
                    },
                  ),
                ),

                // Município principal
                SizedBox(
                  width: w6,
                  child: DropDownButtonChange(
                    key: ValueKey(
                      'mun-${d.municipio}-${_ufSelecionada ?? ""}',
                    ),
                    width: w6,
                    labelText: 'Município (principal)',
                    controller: _municipioCtrl,
                    enabled: widget.isEditable && (_ufSelecionada != null),
                    validator: validateRequired,
                    items: _munisDaUf,
                    enableInlineDelete: false,
                    onChanged: (v) {
                      _municipioCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),

                // Regional / Área
                SizedBox(
                  width: w6,
                  child: DropDownButtonChange(
                    key: ValueKey(
                      'regions-${widget.data.orgaoDemandante}-${_companyId ?? "none"}',
                    ),
                    width: w6,
                    labelText: 'Regional/Área',
                    tooltipMessage: _companyId == null
                        ? 'Selecione o contratante na identificação'
                        : null,
                    controller: _regionalCtrl,
                    items: const [],
                    enabled: widget.isEditable && _companyId != null,
                    validator: validateRequired,
                    firestore: FirebaseFirestore.instance,
                    collectionPath: _companyId == null
                        ? null
                        : 'companies/${_companyId}/regions',
                    labelField: 'regionName',
                    idField: 'regionId',
                    autoLoadWhenEmpty: true,
                    allowDuplicates: false,
                    buildFirestoreDoc: (id, label) => {
                      'regionId': id,
                      'regionName': label,
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy':
                      FirebaseAuth.instance.currentUser?.uid,
                    },
                    specialItemLabel: 'Adicionar regional/área',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    selectedId: _regionDocId,
                    onChangedIdLabel: (id, label) {
                      _regionDocId = id;
                      _regionalCtrl.text = label;
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),

                // KM inicial
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _kmInicialCtrl,
                    enabled: widget.isEditable,
                    labelText: 'KM inicial',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // KM final
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _kmFinalCtrl,
                    enabled: widget.isEditable,
                    labelText: 'KM final',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
