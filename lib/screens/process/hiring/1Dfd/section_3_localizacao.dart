// lib/screens/process/hiring/1Dfd/dfd_sections/section_3_localizacao.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_controller.dart';
import 'package:siged/_services/geoJson/geojson_locations_service.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

class SectionLocalizacao extends StatefulWidget {
  final DfdController controller;
  const SectionLocalizacao({super.key, required this.controller});

  @override
  State<SectionLocalizacao> createState() => _SectionLocalizacaoState();
}

class _SectionLocalizacaoState extends State<SectionLocalizacao>
    with FormValidationMixin {
  List<String> _ufs = const [];
  List<String> _munisDaUf = const [];
  String? _ufSelecionada;

  String? get _companyId => widget.controller.companyId;

  // Para detectar mudanças vindas do controller após carregar do Firestore
  String _lastUfFromController = '';

  @override
  void initState() {
    super.initState();
    _initGeojsonUfMunicipios();

    // Escuta o controller para perceber quando fromSectionMaps() preencher UF/Município
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final ufNow = widget.controller.dfdUFCtrl.text.trim().toUpperCase();
    if (ufNow != _lastUfFromController) {
      _lastUfFromController = ufNow;

      if (ufNow.isNotEmpty && _ufs.contains(ufNow)) {
        setState(() {
          _ufSelecionada = ufNow;
          _munisDaUf = GeoJsonLocationsService.I.getMunicipios(_ufSelecionada);
          final curMun = widget.controller.dfdMunicipioCtrl.text.trim();
          if (!_munisDaUf.contains(curMun)) {
            widget.controller.dfdMunicipioCtrl.text = '';
          }
        });
      }
    }
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

      // Tenta usar a UF que já possa ter vindo do Firestore
      final currentUf = widget.controller.dfdUFCtrl.text.trim().toUpperCase();
      final selectedUf =
      ufs.contains(currentUf) ? currentUf : (ufs.isNotEmpty ? ufs.first : null);

      final munis = selectedUf != null
          ? GeoJsonLocationsService.I.getMunicipios(selectedUf)
          : const <String>[];

      if (!mounted) return;
      setState(() {
        _ufs = ufs;
        _ufSelecionada = selectedUf;
        // Atualiza controller com a UF selecionada (mantém se já válida)
        widget.controller.dfdUFCtrl.text = selectedUf ?? '';
        _lastUfFromController =
            widget.controller.dfdUFCtrl.text.trim().toUpperCase();
        _munisDaUf = munis;

        final curMun = widget.controller.dfdMunicipioCtrl.text.trim();
        if (!_munisDaUf.contains(curMun)) {
          widget.controller.dfdMunicipioCtrl.text = '';
        }
      });
    } catch (e) {
      debugPrint('Falha ao carregar GeoJSON UF/Municípios: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('3) Localização / Escopo rodoviário'),
        LayoutBuilder(
          builder: (context, inner) {
            const double gap = 12;
            const double minItem = 180;
            const int maxCols = 6;

            final isMobile = inner.maxWidth <= 600;

            if (isMobile) {
              final full = inner.maxWidth;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  // UF
                  SizedBox(
                    width: full,
                    child: DropDownButtonChange(
                      key: ValueKey('uf-${c.dfdUFCtrl.text}'), // força rebuild com valor salvo
                      width: full,
                      labelText: 'UF',
                      controller: c.dfdUFCtrl,
                      enabled: c.isEditable,
                      validator: validateRequired,
                      items: _ufs,
                      enableInlineDelete: false,
                      onChanged: (v) {
                        final uf = (v ?? '').trim().toUpperCase();
                        setState(() {
                          _ufSelecionada = uf.isEmpty ? null : uf;
                          _munisDaUf =
                              GeoJsonLocationsService.I.getMunicipios(_ufSelecionada);
                          final curMun = c.dfdMunicipioCtrl.text.trim();
                          if (!_munisDaUf.contains(curMun)) {
                            c.dfdMunicipioCtrl.text = '';
                          }
                        });
                      },
                    ),
                  ),

                  // Município
                  SizedBox(
                    width: full,
                    child: DropDownButtonChange(
                      key: ValueKey(
                          'mun-${c.dfdMunicipioCtrl.text}-${_ufSelecionada ?? ""}'),
                      width: full,
                      labelText: 'Município (principal)',
                      controller: c.dfdMunicipioCtrl,
                      enabled: c.isEditable && (_ufSelecionada != null),
                      validator: validateRequired,
                      items: _munisDaUf,
                      enableInlineDelete: false,
                    ),
                  ),

                  // Rodovia
                  SizedBox(
                    width: full,
                    child: DropDownButtonChange(
                      key: ValueKey('roads-${c.companyNonce}-${_companyId ?? "none"}'),
                      width: full,
                      labelText: 'Rodovia',
                      tooltipMessage: _companyId == null ? 'Selecione o contratante' : null,
                      controller: c.dfdRodoviaCtrl,
                      items: const [],
                      enabled: c.isEditable && _companyId != null,
                      validator: validateRequired,
                      firestore: FirebaseFirestore.instance,
                      collectionPath: _companyId == null ? null : 'companies/${_companyId}/roads',
                      labelField: 'name',
                      idField: 'id',
                      autoLoadWhenEmpty: true,
                      allowDuplicates: false,
                      buildFirestoreDoc: (id, label) => {
                        'id': id,
                        'name': label,
                        'createdAt': FieldValue.serverTimestamp(),
                        'createdBy': FirebaseAuth.instance.currentUser?.uid,
                      },
                      specialItemLabel: 'Adicionar rodovia',
                      showSpecialWhenEmpty: true,
                      showSpecialAlways: true,

                      // 🔁 AQUI TAMBÉM:
                      selectedId: c.roadId,
                      onChangedIdLabel: (id, label) => c.setRoad(id: id, label: label),
                    ),
                  ),
                  // KM inicial
                  SizedBox(
                    width: full,
                    child: CustomTextField(
                      controller: c.dfdKmInicialCtrl,
                      enabled: c.isEditable,
                      labelText: 'KM inicial',
                      keyboardType: TextInputType.number,
                    ),
                  ),

                  // KM final
                  SizedBox(
                    width: full,
                    child: CustomTextField(
                      controller: c.dfdKmFinalCtrl,
                      enabled: c.isEditable,
                      labelText: 'KM final',
                      keyboardType: TextInputType.number,
                    ),
                  ),

                  // Natureza da intervenção
                  SizedBox(
                    width: full,
                    child: DropDownButtonChange(
                      key: ValueKey('natureza-${c.dfdNaturezaIntervencaoValue ?? ""}'),
                      enabled: c.isEditable,
                      labelText: 'Natureza da intervenção',
                      controller: TextEditingController(
                          text: c.dfdNaturezaIntervencaoValue ?? ''),
                      items: DfdData.typeOfService,
                      onChanged: (v) => c.dfdNaturezaIntervencaoValue = v ?? '',
                      validator: validateRequired,
                    ),
                  ),
                ],
              );
            }

            // Desktop layout
            int cols = ((inner.maxWidth + gap) / (minItem + gap)).floor();
            cols = cols.clamp(1, maxCols);
            final double colW = (inner.maxWidth - (cols - 1) * gap) / cols;
            double wSpan(int span) => colW * span + gap * (span - 1);

            final ufSpan = cols >= 2 ? 1 : 1;
            final muniSpan = cols >= 3 ? 2 : 1;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                // UF
                SizedBox(
                  width: wSpan(ufSpan),
                  child: DropDownButtonChange(
                    key: ValueKey('uf-${c.dfdUFCtrl.text}'),
                    width: wSpan(ufSpan),
                    labelText: 'UF',
                    controller: c.dfdUFCtrl,
                    enabled: c.isEditable,
                    validator: validateRequired,
                    items: _ufs,
                    enableInlineDelete: false,
                    onChanged: (v) {
                      final uf = (v ?? '').trim().toUpperCase();
                      setState(() {
                        _ufSelecionada = uf.isEmpty ? null : uf;
                        _munisDaUf =
                            GeoJsonLocationsService.I.getMunicipios(_ufSelecionada);
                        final curMun = c.dfdMunicipioCtrl.text.trim();
                        if (!_munisDaUf.contains(curMun)) {
                          c.dfdMunicipioCtrl.text = '';
                        }
                      });
                    },
                  ),
                ),

                // Município
                SizedBox(
                  width: wSpan(muniSpan),
                  child: DropDownButtonChange(
                    key: ValueKey(
                        'mun-${c.dfdMunicipioCtrl.text}-${_ufSelecionada ?? ""}'),
                    width: wSpan(muniSpan),
                    labelText: 'Município (principal)',
                    controller: c.dfdMunicipioCtrl,
                    enabled: c.isEditable && (_ufSelecionada != null),
                    validator: validateRequired,
                    items: _munisDaUf,
                    enableInlineDelete: false,
                  ),
                ),

                // Rodovia
                SizedBox(
                  width: wSpan(1),
                  child: DropDownButtonChange(
                    key: ValueKey('roads-${c.companyNonce}-${_companyId ?? "none"}'),
                    width: wSpan(1),
                    labelText: 'Rodovia',
                    tooltipMessage: _companyId == null ? 'Selecione o contratante' : null,
                    controller: c.dfdRodoviaCtrl,
                    items: const [],
                    enabled: c.isEditable && _companyId != null,
                    validator: validateRequired,
                    firestore: FirebaseFirestore.instance,
                    collectionPath: _companyId == null ? null : 'companies/${_companyId}/roads',
                    labelField: 'name',
                    idField: 'id',
                    autoLoadWhenEmpty: true,
                    allowDuplicates: false,
                    buildFirestoreDoc: (id, label) => {
                      'id': id,
                      'name': label,
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy': FirebaseAuth.instance.currentUser?.uid,
                    },
                    specialItemLabel: 'Adicionar rodovia',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,

                    // 🔁 AQUI É A TROCA:
                    selectedId: c.roadId,                           // antes: c.dfdRodoviaId
                    onChangedIdLabel: (id, label) => c.setRoad(     // antes: c.setRodovia(...)
                      id: id,
                      label: label,
                    ),
                  ),
                ),

                // KM inicial
                SizedBox(
                  width: wSpan(1),
                  child: CustomTextField(
                    controller: c.dfdKmInicialCtrl,
                    enabled: c.isEditable,
                    labelText: 'KM inicial',
                    keyboardType: TextInputType.number,
                  ),
                ),

                // KM final
                SizedBox(
                  width: wSpan(1),
                  child: CustomTextField(
                    controller: c.dfdKmFinalCtrl,
                    enabled: c.isEditable,
                    labelText: 'KM final',
                    keyboardType: TextInputType.number,
                  ),
                ),

                // Natureza da intervenção
                SizedBox(
                  width: wSpan(1),
                  child: DropDownButtonChange(
                    key: ValueKey('natureza-${c.dfdNaturezaIntervencaoValue ?? ""}'),
                    enabled: c.isEditable,
                    labelText: 'Natureza da intervenção',
                    controller: TextEditingController(
                        text: c.dfdNaturezaIntervencaoValue ?? ''),
                    items: DfdData.typeOfService,
                    onChanged: (v) => c.dfdNaturezaIntervencaoValue = v ?? '',
                    validator: validateRequired,
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
