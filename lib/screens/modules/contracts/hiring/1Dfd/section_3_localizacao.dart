import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/system/setup/setup_region_map.dart';
import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

// Service novo de localidades IBGE
import 'package:sipged/_blocs/system/location/ibge_location_service.dart';

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
    with SipGedValidation {
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

  // Service IBGE (novo)
  late final IBGELocationService _ibgeService;

  @override
  void initState() {
    super.initState();
    _ibgeService = IBGELocationService();

    final d = widget.data;

    _ufCtrl = TextEditingController(text: d.uf ?? '');
    _municipioCtrl = TextEditingController(text: d.municipio ?? '');
    _regionalCtrl = TextEditingController(text: d.regional ?? '');
    _kmInicialCtrl = TextEditingController(text: d.kmInicial ?? '');
    _kmFinalCtrl = TextEditingController(text: d.kmFinal ?? '');

    _companyId = d.companyId;
    _regionDocId = d.regionId;

    _initIbgeUfMunicipios();

    // ✅ NÃO chame ensureCompanySetupLoaded no build.
    // Chame aqui/updates.
    if ((_companyId ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SetupCubit>().ensureCompanySetupLoaded(_companyId!);
      });
    } else {
      _resolveCompanyIdFromData();
    }
  }

  @override
  void didUpdateWidget(covariant SectionLocalizacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data) return;

    final d = widget.data;

    void sync(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    sync(_ufCtrl, d.uf ?? '');
    sync(_municipioCtrl, d.municipio ?? '');
    sync(_regionalCtrl, d.regional ?? '');
    sync(_kmInicialCtrl, d.kmInicial ?? '');
    sync(_kmFinalCtrl, d.kmFinal ?? '');

    // company mudou?
    final oldCompany = _companyId;
    final newCompany = d.companyId;

    if (oldCompany != newCompany) {
      _companyId = newCompany;

      if ((_companyId ?? '').isNotEmpty) {
        // ✅ agenda pro pós-frame para não mexer em estado durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<SetupCubit>().ensureCompanySetupLoaded(_companyId!);
        });
      }
    }

    // region mudou?
    if (oldWidget.data.regionId != widget.data.regionId) {
      _regionDocId = widget.data.regionId;
    }

    // se label mudou e ainda não temos companyId
    if (oldWidget.data.orgaoDemandante != widget.data.orgaoDemandante) {
      if ((_companyId ?? '').isEmpty) {
        _resolveCompanyIdFromData();
      }
    }

    _updateUfSelectionFromController();
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
      uf: _ufCtrl.text,
      municipio: _municipioCtrl.text,
      regional: _regionalCtrl.text.isEmpty ? null : _regionalCtrl.text,
      kmInicial: _kmInicialCtrl.text,
      kmFinal: _kmFinalCtrl.text,
      regionId: _regionDocId ?? widget.data.regionId,
      companyId: _companyId ?? widget.data.companyId,
    );
    widget.onChanged(updated);
  }

  Future<void> _resolveCompanyIdFromData() async {
    if (!mounted) return;
    final label = (widget.data.orgaoDemandante ?? '').trim();
    if (label.isEmpty) return;

    final systemCubit = context.read<SetupCubit>();
    if (systemCubit.state.companies.isEmpty) {
      await systemCubit.loadCompanies();
    }

    final id = systemCubit.findCompanyIdByLabel(label);
    if (!mounted || id == null) return;

    setState(() {
      _companyId = id;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SetupCubit>().ensureCompanySetupLoaded(id);
    });
  }

  Future<void> _initIbgeUfMunicipios() async {
    try {
      await _ibgeService.ensureStatesLoaded();

      final ufs = _ibgeService.ufsSigla;

      final currentUf = (widget.data.uf ?? '').trim().toUpperCase();
      final selectedUf =
      ufs.contains(currentUf) ? currentUf : (ufs.isNotEmpty ? ufs.first : null);

      final munis = selectedUf != null
          ? await _ibgeService.getMunicipiosByUfSigla(selectedUf)
          : const <String>[];

      if (!mounted) return;

      setState(() {
        _ufs = ufs;
        _ufSelecionada = selectedUf;
        _ufCtrl.text = selectedUf ?? '';
        _munisDaUf = munis;

        final curMun = (widget.data.municipio ?? '').trim();
        if (!_munisDaUf.contains(curMun)) {
          _municipioCtrl.text = '';
        }
      });
    } catch (_) {
      // se quiser logar
    }
  }

  void _updateUfSelectionFromController() async {
    final ufNow = _ufCtrl.text.trim().toUpperCase();
    if (ufNow.isEmpty || !_ufs.contains(ufNow)) return;

    final munis = await _ibgeService.getMunicipiosByUfSigla(ufNow);
    if (!mounted) return;

    setState(() {
      _ufSelecionada = ufNow;
      _munisDaUf = munis;
      final curMun = _municipioCtrl.text.trim();
      if (!_munisDaUf.contains(curMun)) {
        _municipioCtrl.text = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final systemCubit = context.read<SetupCubit>();
    context.watch<SetupCubit>(); // somente para rebuild

    final List<SetupData> regions = systemCubit.getRegionsForCompany(_companyId);
    final d = widget.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '3) Localização / Escopo rodoviário'),
        LayoutBuilder(
          builder: (context, inner) {
            final w5 = inputW5(context, inner);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w5,
                  child: DropDownChange(
                    key: ValueKey('uf-${d.uf}'),
                    width: w5,
                    labelText: 'UF',
                    controller: _ufCtrl,
                    enabled: widget.isEditable,
                    validator: null,
                    items: _ufs,
                    onChanged: (v) {
                      final uf = (v ?? '').trim().toUpperCase();
                      if (_ufCtrl.text != uf) _ufCtrl.text = uf;
                      _updateUfSelectionFromController();
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: DropDownChange(
                    key: ValueKey('mun-${d.municipio}-${_ufSelecionada ?? ""}'),
                    width: w5,
                    labelText: 'Município (principal)',
                    controller: _municipioCtrl,
                    enabled: widget.isEditable && (_ufSelecionada != null),
                    validator: null,
                    items: _munisDaUf,
                    onChanged: (v) {
                      _municipioCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: DropDownChange(
                    key: ValueKey('regions-${widget.data.orgaoDemandante}-${_companyId ?? "none"}'),
                    width: w5,
                    labelText: 'Região/Área',
                    tooltipMessage: _companyId == null
                        ? 'Selecione o contratante na identificação'
                        : 'Clique no ícone de info para gerenciar municípios da região',
                    controller: _regionalCtrl,
                    items: regions.map((e) => e.label).toList(),
                    enabled: widget.isEditable && _companyId != null,
                    validator: null,
                    specialItemLabel: 'Adicionar região/área',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      final label = value ?? '';
                      _regionalCtrl.text = label;

                      final selected = regions.firstWhere(
                            (e) => e.label == label,
                        orElse: () => const SetupData(id: '', label: ''),
                      );

                      _regionDocId = selected.id.isEmpty ? null : selected.id;

                      _emitChange();
                      setState(() {});
                    },
                    onDetailsTap: (ctx, label) async {
                      if (_companyId == null) return;

                      final regionsList = systemCubit.getRegionsForCompany(_companyId);

                      final region = regionsList.firstWhere(
                            (r) => r.label == label,
                        orElse: () => const SetupData(id: '', label: ''),
                      );
                      if (region.id.isEmpty) return;

                      final initialSelected = region.municipios ?? const <String>[];

                      final lockedMunicipios = regionsList
                          .where((r) => r.id != region.id)
                          .expand((r) => r.municipios ?? const <String>[])
                          .toSet()
                          .toList();

                      int initialUfCode = 27; // fallback AL
                      final ufSigla = _ufCtrl.text.trim().toUpperCase();
                      if (ufSigla.isNotEmpty) {
                        final maybeId = _ibgeService.getUfIdBySigla(ufSigla);
                        if (maybeId != null) initialUfCode = maybeId;
                      }

                      final selectedMunicipios = await setupRegionMap(
                        context,
                        title: 'Municípios da região "$label"',
                        initialSelected: initialSelected,
                        lockedMunicipios: lockedMunicipios,
                        initialUfCode: initialUfCode,
                      );

                      if (selectedMunicipios == null) return;

                      await systemCubit.updateRegionMunicipios(
                        _companyId!,
                        region.id,
                        selectedMunicipios,
                      );

                      if (_regionalCtrl.text == region.label) {
                        _emitChange();
                      }
                    },
                    onCreateNewItem: (!widget.isEditable || _companyId == null)
                        ? null
                        : (label) async {
                      final created = await systemCubit.createRegion(_companyId!, label);
                      if (created != null) {
                        _regionDocId = created.id;
                        _regionalCtrl.text = created.label;
                        _emitChange();
                        setState(() {});
                      }
                    },
                    onEditItem: (widget.isEditable && _companyId != null)
                        ? (ctx, oldLabel) async {
                      final controller = TextEditingController(text: oldLabel);

                      final newLabel = await showDialog<String>(
                        context: ctx,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('Editar região'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Novo nome da região',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(dialogCtx).pop(controller.text.trim()),
                              child: const Text('Salvar'),
                            ),
                          ],
                        ),
                      );

                      if (newLabel == null || newLabel.trim().isEmpty) return;

                      final list = systemCubit.getRegionsForCompany(_companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (r) => r.label == oldLabel,
                        orElse: () => const SetupData(id: '', label: ''),
                      );

                      if (target.id.isEmpty) return;

                      final updated = await systemCubit.updateRegionName(
                        _companyId!,
                        target.id,
                        newLabel.trim(),
                      );

                      if (updated != null && mounted) {
                        setState(() {
                          if (_regionDocId == target.id) {
                            _regionalCtrl.text = updated.label;
                          }
                        });
                        _emitChange();
                      }
                    }
                        : null,
                    onDeleteItem: (widget.isEditable && _companyId != null)
                        ? (ctx, label) async {
                      final list = systemCubit.getRegionsForCompany(_companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (r) => r.label == label,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      await systemCubit.deleteRegion(_companyId!, target.id);

                      if (_regionDocId == target.id || _regionalCtrl.text == label) {
                        setState(() {
                          _regionDocId = null;
                          _regionalCtrl.clear();
                        });
                        _emitChange();
                      }
                    }
                        : null,
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: CustomTextField(
                    controller: _kmInicialCtrl,
                    enabled: widget.isEditable,
                    labelText: 'KM inicial',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w5,
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
