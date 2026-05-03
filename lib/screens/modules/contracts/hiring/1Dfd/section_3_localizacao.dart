import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/screens/modules/contracts/hiring/1Dfd/setup_region_map.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

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
  late final TextEditingController _ufCtrl;
  late final TextEditingController _municipioCtrl;
  late final TextEditingController _regionalCtrl;
  late final TextEditingController _kmInicialCtrl;
  late final TextEditingController _kmFinalCtrl;

  List<String> _ufs = const [];
  List<String> _munisDaUf = const [];
  String? _ufSelecionada;

  String? _tenantId;
  String? _regionDocId;

  int _regionsNonce = 0;

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

    _tenantId = _normalizeId(d.companyId);
    _regionDocId = _normalizeId(d.regionId);

    _initIbgeUfMunicipios();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tenantCubit = context.read<TenantCubit>();

      tenantCubit.ensureTenantProfileLoaded();
      tenantCubit.ensureTenantItemsLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant SectionLocalizacao oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data == widget.data) return;

    final d = widget.data;

    _syncControllerText(_ufCtrl, d.uf ?? '');
    _syncControllerText(_municipioCtrl, d.municipio ?? '');
    _syncControllerText(_regionalCtrl, d.regional ?? '');
    _syncControllerText(_kmInicialCtrl, d.kmInicial ?? '');
    _syncControllerText(_kmFinalCtrl, d.kmFinal ?? '');

    final newTenantId = _normalizeId(d.companyId);

    if (_tenantId != newTenantId) {
      _tenantId = newTenantId;
      _regionsNonce++;
    }

    if (oldWidget.data.regionId != widget.data.regionId) {
      _regionDocId = _normalizeId(widget.data.regionId);
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

  String? _normalizeId(String? value) {
    final normalized = (value ?? '').trim();

    return normalized.isEmpty ? null : normalized;
  }

  void _syncControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;

    controller.text = value;
  }

  void _syncTenantFromProfile(TenantData? tenant) {
    if (tenant == null) return;

    final newTenantId = _normalizeId(tenant.tenantId ?? tenant.id);

    if (newTenantId == null) return;
    if (_tenantId == newTenantId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _tenantId = newTenantId;
        _regionsNonce++;
      });

      _emitChange();
    });
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      uf: _ufCtrl.text,
      municipio: _municipioCtrl.text,
      regional: _regionalCtrl.text.isEmpty ? null : _regionalCtrl.text,
      kmInicial: _kmInicialCtrl.text,
      kmFinal: _kmFinalCtrl.text,
      regionId: _regionDocId ?? widget.data.regionId,

      // Mantém compatibilidade com DfdData atual.
      // O campo ainda se chama companyId, mas agora recebe o tenantId.
      companyId: _tenantId ?? widget.data.companyId,
    );

    widget.onChanged(updated);
  }

  Future<void> _initIbgeUfMunicipios() async {
    try {
      await _ibgeService.ensureStatesLoaded();

      final ufs = _ibgeService.ufsSigla;

      final currentUf = (widget.data.uf ?? '').trim().toUpperCase();

      final selectedUf = ufs.contains(currentUf)
          ? currentUf
          : (ufs.isNotEmpty ? ufs.first : null);

      final munis = selectedUf != null
          ? await _ibgeService.getMunicipiosByUfSigla(selectedUf)
          : const <String>[];

      if (!mounted) return;

      setState(() {
        _ufs = ufs;
        _ufSelecionada = selectedUf;
        _ufCtrl.text = selectedUf ?? '';
        _munisDaUf = munis;

        final currentMunicipio = (widget.data.municipio ?? '').trim();

        if (!_munisDaUf.contains(currentMunicipio)) {
          _municipioCtrl.text = '';
        }
      });
    } catch (_) {}
  }

  Future<void> _updateUfSelectionFromController() async {
    final ufNow = _ufCtrl.text.trim().toUpperCase();

    if (ufNow.isEmpty || !_ufs.contains(ufNow)) return;

    final munis = await _ibgeService.getMunicipiosByUfSigla(ufNow);

    if (!mounted) return;

    setState(() {
      _ufSelecionada = ufNow;
      _munisDaUf = munis;

      final currentMunicipio = _municipioCtrl.text.trim();

      if (!_munisDaUf.contains(currentMunicipio)) {
        _municipioCtrl.text = '';
      }
    });
  }

  Future<String?> _askNewRegionLabel(
      BuildContext dialogContext, {
        required String initialValue,
      }) async {
    final controller = TextEditingController(text: initialValue);

    final newLabel = await showDialog<String>(
      context: dialogContext,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Editar região'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Novo nome da região',
            ),
            onSubmitted: (value) {
              Navigator.of(dialogCtx).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop(controller.text.trim());
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    final trimmed = newLabel?.trim() ?? '';

    if (trimmed.isEmpty || trimmed == initialValue.trim()) {
      return null;
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final tenantState = context.watch<TenantCubit>().state;
    final tenantCubit = context.read<TenantCubit>();

    final TenantData? tenant = tenantState.tenantProfile;

    _syncTenantFromProfile(tenant);

    final bool hasTenantConfigured = tenant != null;
    final List<TenantItemData> regions = tenantState.regions;

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
                    onChanged: (value) {
                      final uf = (value ?? '').trim().toUpperCase();

                      if (_ufCtrl.text != uf) {
                        _ufCtrl.text = uf;
                      }

                      _updateUfSelectionFromController();
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: DropDownChange(
                    key: ValueKey(
                      'mun-${d.municipio}-${_ufSelecionada ?? ""}',
                    ),
                    width: w5,
                    labelText: 'Município (principal)',
                    controller: _municipioCtrl,
                    enabled: widget.isEditable && _ufSelecionada != null,
                    validator: null,
                    items: _munisDaUf,
                    onChanged: (value) {
                      _municipioCtrl.text = value ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: DropDownChange(
                    key: ValueKey(
                      'tenant-regions-$_regionsNonce-${_tenantId ?? "none"}',
                    ),
                    width: w5,
                    labelText: 'Região/Área',
                    tooltipMessage: !hasTenantConfigured
                        ? 'Configure o contratante no tenant'
                        : 'Clique no ícone de info para gerenciar municípios da região',
                    controller: _regionalCtrl,
                    items: regions.map((e) => e.label).toList(),
                    enabled: widget.isEditable && hasTenantConfigured,
                    validator: null,
                    specialItemLabel: 'Adicionar região/área',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      if (!widget.isEditable) return;

                      final label = value ?? '';

                      _regionalCtrl.text = label;

                      final selected = regions.firstWhere(
                            (region) => region.label == label,
                        orElse: () => const TenantItemData(
                          id: '',
                          label: '',
                        ),
                      );

                      _regionDocId = selected.id.isEmpty ? null : selected.id;

                      _emitChange();
                      setState(() {});
                    },
                    onDetailsTap: (ctx, label) async {
                      if (!hasTenantConfigured) return;

                      final region = tenantCubit.state.regions.firstWhere(
                            (item) => item.label == label,
                        orElse: () => const TenantItemData(
                          id: '',
                          label: '',
                        ),
                      );

                      if (region.id.isEmpty) return;

                      final initialSelected = List<String>.from(
                        region.municipios,
                      );

                      final lockedMunicipios = tenantCubit.state.regions
                          .where((item) => item.id != region.id)
                          .expand((item) => item.municipios)
                          .toSet()
                          .toList();

                      int initialUfCode = 27;

                      final ufSigla = _ufCtrl.text.trim().toUpperCase();

                      if (ufSigla.isNotEmpty) {
                        final maybeId = _ibgeService.getUfIdBySigla(ufSigla);

                        if (maybeId != null) {
                          initialUfCode = maybeId;
                        }
                      }

                      final selectedMunicipios = await setupRegionMap(
                        ctx,
                        title: 'Municípios da região "$label"',
                        initialSelected: initialSelected,
                        lockedMunicipios: lockedMunicipios,
                        initialUfCode: initialUfCode,
                      );

                      if (!mounted || selectedMunicipios == null) return;

                      final updated = await tenantCubit.updateRegionMunicipios(
                        region.id,
                        selectedMunicipios,
                      );

                      if (!mounted || updated == null) return;

                      if (_regionalCtrl.text == region.label) {
                        _emitChange();
                      }

                      setState(() {});
                    },
                    onCreateNewItem: !widget.isEditable || !hasTenantConfigured
                        ? null
                        : (label) async {
                      final created = await tenantCubit.createRegion(
                        label,
                      );

                      if (!mounted || created == null) return;

                      setState(() {
                        _regionDocId = created.id;
                        _regionalCtrl.text = created.label;
                      });

                      _emitChange();
                    },
                    onEditItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, oldLabel) async {
                      final listBeforeDialog =
                      List<TenantItemData>.from(
                        tenantCubit.state.regions,
                      );

                      if (listBeforeDialog.isEmpty) return;

                      final target = listBeforeDialog.firstWhere(
                            (region) => region.label == oldLabel,
                        orElse: () => const TenantItemData(
                          id: '',
                          label: '',
                        ),
                      );

                      if (target.id.isEmpty) return;

                      final newLabel = await _askNewRegionLabel(
                        ctx,
                        initialValue: oldLabel,
                      );

                      if (!mounted || newLabel == null) return;

                      final updated = await tenantCubit.updateRegionName(
                        target.id,
                        newLabel,
                      );

                      if (!mounted || updated == null) return;

                      setState(() {
                        if (_regionDocId == target.id) {
                          _regionalCtrl.text = updated.label;
                        }
                      });

                      _emitChange();
                    }
                        : null,
                    onDeleteItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, label) async {
                      final listBeforeDelete =
                      List<TenantItemData>.from(
                        tenantCubit.state.regions,
                      );

                      if (listBeforeDelete.isEmpty) return;

                      final target = listBeforeDelete.firstWhere(
                            (region) => region.label == label,
                        orElse: () => const TenantItemData(
                          id: '',
                          label: '',
                        ),
                      );

                      if (target.id.isEmpty) return;

                      await tenantCubit.deleteRegion(target.id);

                      if (!mounted) return;

                      if (_regionDocId == target.id ||
                          _regionalCtrl.text == label) {
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