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
    _regionDocId = _normalizeId(d.regionId) ?? _normalizeId(d.regional);

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

    if (oldWidget.data.regionId != widget.data.regionId ||
        oldWidget.data.regional != widget.data.regional) {
      _regionDocId = _normalizeId(widget.data.regionId) ??
          _normalizeId(widget.data.regional);
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

  String _s(Object? value) {
    return (value is String ? value : value?.toString() ?? '').trim();
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
    final regionLabel = _regionalCtrl.text.trim();

    final updated = widget.data.copyWith(
      uf: _ufCtrl.text,
      municipio: _municipioCtrl.text,
      regional: regionLabel.isEmpty ? null : regionLabel,
      kmInicial: _kmInicialCtrl.text,
      kmFinal: _kmFinalCtrl.text,
      regionId: _regionDocId ?? regionLabel,
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
    final List<String> regions = tenantState.regions;

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
                    items: regions,
                    enabled: widget.isEditable && hasTenantConfigured,
                    validator: null,
                    specialItemLabel: 'Adicionar região/área',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      if (!widget.isEditable) return;

                      final label = _s(value);

                      _regionalCtrl.text = label;
                      _regionDocId = label.isEmpty ? null : label;

                      _emitChange();
                      setState(() {});
                    },
                    onDetailsTap: (ctx, label) async {
                      if (!hasTenantConfigured) return;

                      final regionLabel = _s(label);

                      if (regionLabel.isEmpty) return;
                      if (!regions.contains(regionLabel)) return;

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
                        title: 'Municípios da região "$regionLabel"',
                        initialSelected: const <String>[],
                        lockedMunicipios: const <String>[],
                        initialUfCode: initialUfCode,
                      );

                      if (!mounted || selectedMunicipios == null) return;

                      await tenantCubit.updateRegionMunicipios(
                        regionLabel,
                        selectedMunicipios,
                      );

                      if (!mounted) return;

                      if (_regionalCtrl.text == regionLabel) {
                        _emitChange();
                      }

                      setState(() {});
                    },
                    onCreateNewItem: !widget.isEditable || !hasTenantConfigured
                        ? null
                        : (label) async {
                      final newLabel = _s(label);

                      if (newLabel.isEmpty) return;

                      final created = await tenantCubit.createRegion(
                        newLabel,
                      );

                      if (!mounted || created == null) return;

                      setState(() {
                        _regionDocId = created;
                        _regionalCtrl.text = created;
                        _regionsNonce++;
                      });

                      _emitChange();
                    },
                    onEditItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, oldLabelRaw) async {
                      final oldLabel = _s(oldLabelRaw);

                      if (oldLabel.isEmpty) return;
                      if (!regions.contains(oldLabel)) return;

                      final newLabel = await _askNewRegionLabel(
                        ctx,
                        initialValue: oldLabel,
                      );

                      if (!mounted || newLabel == null) return;

                      final updated = await tenantCubit.updateRegionName(
                        oldLabel,
                        newLabel,
                      );

                      if (!mounted || updated == null) return;

                      setState(() {
                        if (_regionDocId == oldLabel ||
                            _regionalCtrl.text == oldLabel) {
                          _regionDocId = updated;
                          _regionalCtrl.text = updated;
                        }

                        _regionsNonce++;
                      });

                      _emitChange();
                    }
                        : null,
                    onDeleteItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, labelRaw) async {
                      final label = _s(labelRaw);

                      if (label.isEmpty) return;

                      await tenantCubit.deleteRegion(label);

                      if (!mounted) return;

                      if (_regionDocId == label ||
                          _regionalCtrl.text == label) {
                        setState(() {
                          _regionDocId = null;
                          _regionalCtrl.clear();
                          _regionsNonce++;
                        });

                        _emitChange();
                      } else {
                        setState(() => _regionsNonce++);
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