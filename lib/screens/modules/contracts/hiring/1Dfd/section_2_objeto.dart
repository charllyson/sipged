import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/system/setup/setup_cubit.dart';
import 'package:siged/_blocs/system/setup/setup_data.dart';

import 'package:siged/_utils/formats/money_formatter.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

class PtBrThousandsIntFormatter extends TextInputFormatter {
  const PtBrThousandsIntFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final formatted = _formatDigitsWithDots(digits);
    final digitsBeforeCursor = _countDigitsBefore(newValue.text, newValue.selection.extentOffset);
    final newCursorPos = _cursorPosForDigitsCount(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
      composing: TextRange.empty,
    );
  }

  static String _formatDigitsWithDots(String digits) {
    final normalized = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final s = normalized.isEmpty ? '0' : normalized;

    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write('.');
        count = 0;
      }
    }
    return buf.toString().split('').reversed.join();
  }

  static int _countDigitsBefore(String text, int cursor) {
    final safeCursor = cursor.clamp(0, text.length);
    int count = 0;
    for (int i = 0; i < safeCursor; i++) {
      final ch = text[i];
      if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) count++;
    }
    return count;
  }

  static int _cursorPosForDigitsCount(String formatted, int digitsCount) {
    if (digitsCount <= 0) return 0;
    int seen = 0;
    for (int i = 0; i < formatted.length; i++) {
      final ch = formatted[i];
      if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
        seen++;
        if (seen == digitsCount) return i + 1;
      }
    }
    return formatted.length;
  }
}

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

class _SectionObjetoState extends State<SectionObjeto> with FormValidationMixin {
  late final TextEditingController _tipoContratacaoCtrl;
  late final TextEditingController _tipoObraCtrl;
  late final TextEditingController _descricaoObjetoCtrl;
  late final TextEditingController _justificativaCtrl;
  late final TextEditingController _rodoviaCtrl;

  // Extensão em METROS (inteiro com milhar)
  late final TextEditingController _extensaoMetrosCtrl;

  // Valor: controller NÃO tem "R$" (prefixo só visual)
  late final TextEditingController _valorDemandaCtrl;

  late final FocusNode _extensaoFocus;
  late final FocusNode _valorFocus;

  String? _companyId;
  int _roadsNonce = 0;

  bool _syncing = false;

  @override
  void initState() {
    super.initState();

    final d = widget.data;

    _tipoContratacaoCtrl = TextEditingController(text: d.tipoContratacao ?? '');
    _tipoObraCtrl = TextEditingController(text: d.tipoObra ?? '');
    _descricaoObjetoCtrl = TextEditingController(text: d.descricaoObjeto ?? '');
    _justificativaCtrl = TextEditingController(text: d.justificativa ?? '');
    _rodoviaCtrl = TextEditingController(text: d.rodovia ?? '');

    _extensaoMetrosCtrl = TextEditingController(
      text: d.extensaoKm != null ? _formatMetersFromKm(d.extensaoKm!) : '',
    );

    _valorDemandaCtrl = TextEditingController(
      text: d.valorDemanda != null ? _formatMoneyPtBr(d.valorDemanda!) : '',
    );

    _extensaoFocus = FocusNode();
    _valorFocus = FocusNode();

    _companyId = _normalizeId(d.companyId);
    _ensureCompanySetupLoaded();

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
          _extensaoMetrosCtrl.selection = TextSelection.collapsed(offset: len);
        });
      } else {
        final meters = _parseMetersInt(_extensaoMetrosCtrl.text);
        _syncControllerText(_extensaoMetrosCtrl, meters == null ? '' : _formatMetersInt(meters));
      }
    });

    _valorFocus.addListener(() {
      if (!mounted) return;

      if (_valorFocus.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final len = _valorDemandaCtrl.text.length;
          _valorDemandaCtrl.selection = TextSelection.collapsed(offset: len);
        });
      } else {
        final parsed = _parsePtBrNumber(_valorDemandaCtrl.text);
        _syncControllerText(_valorDemandaCtrl, parsed == null ? '' : _formatMoneyPtBr(parsed));
      }
    });
  }

  @override
  void didUpdateWidget(covariant SectionObjeto oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newData = widget.data;
    final oldData = oldWidget.data;

    final newCompanyId = _normalizeId(newData.companyId);
    if (_companyId != newCompanyId) {
      _companyId = newCompanyId;
      _roadsNonce++;
      _ensureCompanySetupLoaded();
    }

    if (oldData.tipoContratacao != newData.tipoContratacao) {
      _syncControllerText(_tipoContratacaoCtrl, newData.tipoContratacao ?? '');
    }
    if (oldData.tipoObra != newData.tipoObra) {
      _syncControllerText(_tipoObraCtrl, newData.tipoObra ?? '');
    }
    if (oldData.descricaoObjeto != newData.descricaoObjeto) {
      _syncControllerText(_descricaoObjetoCtrl, newData.descricaoObjeto ?? '');
    }
    if (oldData.justificativa != newData.justificativa) {
      _syncControllerText(_justificativaCtrl, newData.justificativa ?? '');
    }
    if (oldData.rodovia != newData.rodovia) {
      _syncControllerText(_rodoviaCtrl, newData.rodovia ?? '');
    }

    // ✅ hidratação com milhar (sem atrapalhar se estiver digitando)
    final newMetersText = newData.extensaoKm != null ? _formatMetersFromKm(newData.extensaoKm!) : '';
    final oldMetersText = oldData.extensaoKm != null ? _formatMetersFromKm(oldData.extensaoKm!) : '';
    if (newMetersText != oldMetersText && !_extensaoFocus.hasFocus) {
      _syncControllerText(_extensaoMetrosCtrl, newMetersText);
    }

    final newValorText = newData.valorDemanda != null ? _formatMoneyPtBr(newData.valorDemanda!) : '';
    final oldValorText = oldData.valorDemanda != null ? _formatMoneyPtBr(oldData.valorDemanda!) : '';
    if (newValorText != oldValorText && !_valorFocus.hasFocus) {
      _syncControllerText(_valorDemandaCtrl, newValorText);
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

  String? _normalizeId(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? null : s;
  }

  void _ensureCompanySetupLoaded() {
    if ((_companyId ?? '').isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SetupCubit>().ensureCompanySetupLoaded(_companyId!);
    });
  }

  void _syncControllerText(TextEditingController c, String v) {
    if (c.text == v) return;

    final oldSel = c.selection;
    _syncing = true;
    c.text = v;

    final newLen = c.text.length;
    int base = oldSel.baseOffset;
    int extent = oldSel.extentOffset;

    if (base < 0 || extent < 0) {
      c.selection = TextSelection.collapsed(offset: newLen);
    } else {
      base = base.clamp(0, newLen);
      extent = extent.clamp(0, newLen);
      c.selection = TextSelection(baseOffset: base, extentOffset: extent);
    }

    _syncing = false;
  }

  void _onAnyFieldChanged() {
    if (_syncing) return;
    if (!widget.isEditable) return;
    _emitChange();
  }

  // -------------------------
  // Extensão em METROS
  // -------------------------
  String _formatMetersFromKm(double km) {
    final meters = (km * 1000.0).round();
    return _formatMetersInt(meters);
  }

  String _formatMetersInt(int meters) {
    return PtBrThousandsIntFormatter._formatDigitsWithDots(meters.toString());
  }

  int? _parseMetersInt(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  // -------------------------
  // Dinheiro pt-BR (milhar + vírgula)
  // -------------------------
  String _formatMoneyPtBr(double value) {
    final cents = (value * 100).round();
    final rawDigits = cents.toString().padLeft(3, '0');

    final intPartDigits = rawDigits.substring(0, rawDigits.length - 2);
    final decDigits = rawDigits.substring(rawDigits.length - 2);

    final intWithThousands = PtBrThousandsIntFormatter._formatDigitsWithDots(intPartDigits);
    return '$intWithThousands,$decDigits';
  }

  double? _parsePtBrNumber(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  void _emitChange() {
    final meters = _parseMetersInt(_extensaoMetrosCtrl.text);
    final km = meters == null ? null : (meters / 1000.0);

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
      valorDemanda: _parsePtBrNumber(_valorDemandaCtrl.text),

      companyId: _companyId,
    );

    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SetupCubit>();
    final systemCubit = context.read<SetupCubit>();
    final List<SetupData> roads = systemCubit.getRoadsForCompany(_companyId);

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
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Tipo de contratação',
                    controller: _tipoContratacaoCtrl,
                    items: HiringData.tiposDeContratacao,
                    validator: null,
                    onChanged: (v) {
                      _syncControllerText(_tipoContratacaoCtrl, v ?? '');
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Tipo de obra',
                    controller: _tipoObraCtrl,
                    items: HiringData.workTypes,
                    validator: null,
                    onChanged: (v) {
                      _syncControllerText(_tipoObraCtrl, v ?? '');
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    key: ValueKey('roads-$_roadsNonce-${_companyId ?? "none"}'),
                    width: w3,
                    labelText: 'Rodovia',
                    tooltipMessage: _companyId == null
                        ? 'Selecione o contratante na identificação'
                        : null,
                    controller: _rodoviaCtrl,
                    items: roads.map((e) => e.label).toList(),
                    enabled: widget.isEditable && _companyId != null,
                    validator: null,
                    specialItemLabel: 'Adicionar rodovia',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      _syncControllerText(_rodoviaCtrl, value ?? '');
                      setState(() {});
                    },
                    onCreateNewItem: (!widget.isEditable || _companyId == null)
                        ? null
                        : (label) async {
                      final created = await systemCubit.createRoad(_companyId!, label);
                      if (!mounted || created == null) return;
                      _syncControllerText(_rodoviaCtrl, created.label);
                      setState(() {});
                    },
                    onEditItem: (widget.isEditable && _companyId != null)
                        ? (oldLabel, newLabel) async {
                      final list = systemCubit.getRoadsForCompany(_companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (r) => r.label == oldLabel,
                        orElse: () => list.first,
                      );
                      if (target.id.isEmpty) return;

                      final updated = await systemCubit.updateRoadName(_companyId!, target.id, newLabel);
                      if (!mounted || updated == null) return;

                      if (_rodoviaCtrl.text == oldLabel) {
                        _syncControllerText(_rodoviaCtrl, updated.label);
                        setState(() {});
                      }
                    }
                        : null,
                    onDeleteItem: (widget.isEditable && _companyId != null)
                        ? (ctx, label) async {
                      final list = systemCubit.getRoadsForCompany(_companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (r) => r.label == label,
                        orElse: () => list.first,
                      );
                      if (target.id.isEmpty) return;

                      await systemCubit.deleteRoad(_companyId!, target.id);

                      if (!mounted) return;
                      if (_rodoviaCtrl.text == label) {
                        _syncControllerText(_rodoviaCtrl, '');
                        setState(() {});
                      }
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
                    inputFormatters: const [PtBrThousandsIntFormatter()],
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

                    // ✅ R$ alinhado e sem sobreposição
                    prefixText: 'R\$ ',

                    inputFormatters: const [MoneyFormatter()],
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
                    labelText: 'Justificativa da contratação (problema/objetivo)',
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
