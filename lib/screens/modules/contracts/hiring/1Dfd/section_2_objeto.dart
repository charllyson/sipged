import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/_utils/formatters/sipged_format_numbers.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

class SectionObjeto extends StatefulWidget {
  final bool isEditable;
  final DfdData data;
  final void Function(DfdData updated) onChanged;

  const SectionObjeto({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionObjeto> createState() => _SectionObjetoState();
}

class _SectionObjetoState extends State<SectionObjeto> with SipGedValidation {
  late final TextEditingController _tipoContratacaoCtrl;
  late final TextEditingController _tipoObraCtrl;
  late final TextEditingController _descricaoObjetoCtrl;
  late final TextEditingController _justificativaCtrl;
  late final TextEditingController _rodoviaCtrl;

  late final TextEditingController _extensaoMetrosCtrl;
  late final TextEditingController _valorDemandaCtrl;

  late final FocusNode _extensaoFocus;
  late final FocusNode _valorFocus;

  String? _tenantId;
  int _roadsNonce = 0;

  bool _syncing = false;

  @override
  void initState() {
    super.initState();

    final d = widget.data;

    _tipoContratacaoCtrl = TextEditingController(
      text: d.tipoContratacao ?? '',
    );

    _tipoObraCtrl = TextEditingController(
      text: d.tipoObra ?? '',
    );

    _descricaoObjetoCtrl = TextEditingController(
      text: d.descricaoObjeto ?? '',
    );

    _justificativaCtrl = TextEditingController(
      text: d.justificativa ?? '',
    );

    _rodoviaCtrl = TextEditingController(
      text: d.rodovia ?? '',
    );

    _extensaoMetrosCtrl = TextEditingController(
      text: d.extensaoKm != null ? _kmToMetersText(d.extensaoKm!) : '',
    );

    _valorDemandaCtrl = TextEditingController(
      text: d.valorDemanda != null
          ? SipGedFormatMoney.brlNoSymbol(d.valorDemanda!)
          : '',
    );

    _extensaoFocus = FocusNode();
    _valorFocus = FocusNode();

    _tenantId = _normalizeId(d.companyId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tenantCubit = context.read<TenantCubit>();

      tenantCubit.ensureTenantProfileLoaded();
      tenantCubit.ensureTenantItemsLoaded();
    });

    _tipoContratacaoCtrl.addListener(_onAnyFieldChanged);
    _tipoObraCtrl.addListener(_onAnyFieldChanged);
    _descricaoObjetoCtrl.addListener(_onAnyFieldChanged);
    _justificativaCtrl.addListener(_onAnyFieldChanged);
    _rodoviaCtrl.addListener(_onAnyFieldChanged);
    _extensaoMetrosCtrl.addListener(_onAnyFieldChanged);
    _valorDemandaCtrl.addListener(_onAnyFieldChanged);

    _extensaoFocus.addListener(() {
      if (!mounted) return;

      if (_extensaoFocus.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          final len = _extensaoMetrosCtrl.text.length;

          _extensaoMetrosCtrl.selection = TextSelection.collapsed(
            offset: len,
          );
        });
      } else {
        final meters = SipGedFormatNumbers.toInt(_extensaoMetrosCtrl.text);

        _syncControllerText(
          _extensaoMetrosCtrl,
          meters == null ? '' : _metersToText(meters),
        );
      }
    });

    _valorFocus.addListener(() {
      if (!mounted) return;

      if (_valorFocus.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          final len = _valorDemandaCtrl.text.length;

          _valorDemandaCtrl.selection = TextSelection.collapsed(
            offset: len,
          );
        });
      } else {
        final parsed = SipGedFormatNumbers.toDouble(
          _valorDemandaCtrl.text,
        );

        _syncControllerText(
          _valorDemandaCtrl,
          parsed == null ? '' : SipGedFormatMoney.brlNoSymbol(parsed),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant SectionObjeto oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newData = widget.data;
    final oldData = oldWidget.data;

    final newTenantId = _normalizeId(newData.companyId);

    if (_tenantId != newTenantId) {
      _tenantId = newTenantId;
      _roadsNonce++;
    }

    if (oldData.tipoContratacao != newData.tipoContratacao) {
      _syncControllerText(
        _tipoContratacaoCtrl,
        newData.tipoContratacao ?? '',
      );
    }

    if (oldData.tipoObra != newData.tipoObra) {
      _syncControllerText(
        _tipoObraCtrl,
        newData.tipoObra ?? '',
      );
    }

    if (oldData.descricaoObjeto != newData.descricaoObjeto) {
      _syncControllerText(
        _descricaoObjetoCtrl,
        newData.descricaoObjeto ?? '',
      );
    }

    if (oldData.justificativa != newData.justificativa) {
      _syncControllerText(
        _justificativaCtrl,
        newData.justificativa ?? '',
      );
    }

    if (oldData.rodovia != newData.rodovia) {
      _syncControllerText(
        _rodoviaCtrl,
        newData.rodovia ?? '',
      );
    }

    final newMetersText = newData.extensaoKm != null
        ? _kmToMetersText(newData.extensaoKm!)
        : '';

    final oldMetersText = oldData.extensaoKm != null
        ? _kmToMetersText(oldData.extensaoKm!)
        : '';

    if (newMetersText != oldMetersText && !_extensaoFocus.hasFocus) {
      _syncControllerText(
        _extensaoMetrosCtrl,
        newMetersText,
      );
    }

    final newValorText = newData.valorDemanda != null
        ? SipGedFormatMoney.brlNoSymbol(newData.valorDemanda!)
        : '';

    final oldValorText = oldData.valorDemanda != null
        ? SipGedFormatMoney.brlNoSymbol(oldData.valorDemanda!)
        : '';

    if (newValorText != oldValorText && !_valorFocus.hasFocus) {
      _syncControllerText(
        _valorDemandaCtrl,
        newValorText,
      );
    }
  }

  @override
  void dispose() {
    _tipoContratacaoCtrl.removeListener(_onAnyFieldChanged);
    _tipoObraCtrl.removeListener(_onAnyFieldChanged);
    _descricaoObjetoCtrl.removeListener(_onAnyFieldChanged);
    _justificativaCtrl.removeListener(_onAnyFieldChanged);
    _rodoviaCtrl.removeListener(_onAnyFieldChanged);
    _extensaoMetrosCtrl.removeListener(_onAnyFieldChanged);
    _valorDemandaCtrl.removeListener(_onAnyFieldChanged);

    _extensaoFocus.dispose();
    _valorFocus.dispose();

    _tipoContratacaoCtrl.dispose();
    _tipoObraCtrl.dispose();
    _descricaoObjetoCtrl.dispose();
    _justificativaCtrl.dispose();
    _rodoviaCtrl.dispose();
    _extensaoMetrosCtrl.dispose();
    _valorDemandaCtrl.dispose();

    super.dispose();
  }

  String? _normalizeId(String? value) {
    final normalized = (value ?? '').trim();

    return normalized.isEmpty ? null : normalized;
  }

  String _s(Object? value) {
    return (value is String ? value : value?.toString() ?? '').trim();
  }

  Future<String?> _askNewLabel(
      BuildContext dialogContext, {
        required String title,
        required String initialValue,
        String labelText = 'Novo nome',
      }) async {
    final ctrl = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: dialogContext,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: labelText,
            ),
            onSubmitted: (value) {
              Navigator.of(ctx).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    ctrl.dispose();

    final trimmed = result?.trim();

    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed == initialValue.trim()) return null;

    return trimmed;
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
        _roadsNonce++;
      });

      _emitChange();
    });
  }

  void _syncControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;

    final oldSel = controller.selection;

    _syncing = true;
    controller.text = value;

    final newLen = controller.text.length;

    int base = oldSel.baseOffset;
    int extent = oldSel.extentOffset;

    if (base < 0 || extent < 0) {
      controller.selection = TextSelection.collapsed(offset: newLen);
    } else {
      base = base.clamp(0, newLen);
      extent = extent.clamp(0, newLen);

      controller.selection = TextSelection(
        baseOffset: base,
        extentOffset: extent,
      );
    }

    _syncing = false;
  }

  void _onAnyFieldChanged() {
    if (_syncing) return;
    if (!widget.isEditable) return;

    _emitChange();
  }

  String _metersToText(int meters) {
    return SipGedFormatNumbers.formatDigitsWithDots(
      meters.toString(),
    );
  }

  String _kmToMetersText(double km) {
    final meters = (km * 1000.0).round();

    return _metersToText(meters);
  }

  void _emitChange() {
    final meters = SipGedFormatNumbers.toInt(
      _extensaoMetrosCtrl.text,
    );

    final km = meters == null ? null : meters / 1000.0;

    final updated = widget.data.copyWith(
      tipoContratacao: _tipoContratacaoCtrl.text.trim().isEmpty
          ? null
          : _tipoContratacaoCtrl.text.trim(),
      tipoObra: _tipoObraCtrl.text.trim().isEmpty
          ? null
          : _tipoObraCtrl.text.trim(),
      descricaoObjeto: _descricaoObjetoCtrl.text,
      justificativa: _justificativaCtrl.text,
      rodovia: _rodoviaCtrl.text,
      extensaoKm: km,
      valorDemanda: SipGedFormatNumbers.toDouble(
        _valorDemandaCtrl.text,
      ),
      companyId: _tenantId,
    );

    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tenantState = context.watch<TenantCubit>().state;
    final tenantCubit = context.read<TenantCubit>();

    final TenantData? tenant = tenantState.tenantProfile;

    _syncTenantFromProfile(tenant);

    final bool hasTenantConfigured = tenant != null;
    final List<String> roads = tenantState.roads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '2) Objeto / Escopo'),
        LayoutBuilder(
          builder: (context, inner) {
            final w3 = inputW3(context, inner);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownChange(
                    enabled: widget.isEditable,
                    labelText: 'Tipo de contratação',
                    controller: _tipoContratacaoCtrl,
                    items: ProgressData.tiposDeContratacao,
                    validator: null,
                    onChanged: (value) {
                      _syncControllerText(
                        _tipoContratacaoCtrl,
                        value ?? '',
                      );

                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownChange(
                    enabled: widget.isEditable,
                    labelText: 'Tipo de obra',
                    controller: _tipoObraCtrl,
                    items: ProgressData.workTypes,
                    validator: null,
                    onChanged: (value) {
                      _syncControllerText(
                        _tipoObraCtrl,
                        value ?? '',
                      );

                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownChange(
                    key: ValueKey(
                      'tenant-roads-$_roadsNonce-${_tenantId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Rodovia',
                    tooltipMessage: !hasTenantConfigured
                        ? 'Configure o contratante no tenant'
                        : null,
                    controller: _rodoviaCtrl,
                    items: roads,
                    enabled: widget.isEditable && hasTenantConfigured,
                    validator: null,
                    specialItemLabel: 'Adicionar rodovia',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      if (!widget.isEditable) return;

                      _syncControllerText(
                        _rodoviaCtrl,
                        value ?? '',
                      );

                      _emitChange();
                      setState(() {});
                    },
                    onCreateNewItem: !widget.isEditable || !hasTenantConfigured
                        ? null
                        : (label) async {
                      final newLabel = _s(label);

                      if (newLabel.isEmpty) return;

                      final created = await tenantCubit.createRoad(
                        newLabel,
                      );

                      if (!mounted || created == null) return;

                      _syncControllerText(
                        _rodoviaCtrl,
                        created,
                      );

                      setState(() => _roadsNonce++);

                      _emitChange();
                    },
                    onEditItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, label) async {
                      final oldLabel = _s(label);

                      if (oldLabel.isEmpty) return;
                      if (!roads.contains(oldLabel)) return;

                      final newLabel = await _askNewLabel(
                        ctx,
                        title: 'Editar rodovia',
                        initialValue: oldLabel,
                        labelText: 'Nome da rodovia',
                      );

                      if (newLabel == null) return;

                      final updated = await tenantCubit.updateRoadName(
                        oldLabel,
                        newLabel,
                      );

                      if (!mounted || updated == null) return;

                      if (_rodoviaCtrl.text == oldLabel) {
                        _syncControllerText(
                          _rodoviaCtrl,
                          updated,
                        );

                        _emitChange();
                      }

                      setState(() => _roadsNonce++);
                    }
                        : null,
                    onDeleteItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, label) async {
                      final oldLabel = _s(label);

                      if (oldLabel.isEmpty) return;

                      await tenantCubit.deleteRoad(oldLabel);

                      if (!mounted) return;

                      if (_rodoviaCtrl.text == oldLabel) {
                        _syncControllerText(
                          _rodoviaCtrl,
                          '',
                        );

                        _emitChange();
                      }

                      setState(() => _roadsNonce++);
                    }
                        : null,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _extensaoMetrosCtrl,
                    focusNode: _extensaoFocus,
                    enabled: widget.isEditable,
                    labelText: 'Extensão (metros)',
                    hintText: 'Ex.: 1.234',
                    inputFormatters: const [
                      SipGedThousandsIntCursorFormatter(),
                    ],
                    keyboardType: TextInputType.number,
                    validator: null,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _descricaoObjetoCtrl,
                    enabled: widget.isEditable,
                    validator: null,
                    labelText: 'Nome da demanda',
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _valorDemandaCtrl,
                    focusNode: _valorFocus,
                    enabled: widget.isEditable,
                    labelText: 'Valor da demanda',
                    hintText: 'Ex.: 1.234,56',
                    prefixText: 'R\$ ',
                    inputFormatters: const [
                      SipGedMoneyFormatter(),
                    ],
                    keyboardType: TextInputType.number,
                    validator: null,
                  ),
                ),
                SizedBox(
                  width: inputW1(context, inner),
                  child: CustomTextField(
                    controller: _justificativaCtrl,
                    enabled: widget.isEditable,
                    validator: null,
                    labelText:
                    'Justificativa da contratação (problema/objetivo)',
                    maxLines: 4,
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