// ==============================
// lib/screens/contracts/validity/validity_form_section.dart
// ==============================
import 'package:flutter/material.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_state.dart';
import 'package:siged/_utils/formats/sipged_format_dates.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

class ValidityFormSection extends StatefulWidget {
  final ProcessData contractData;
  final ValidityState state;

  /// Se o usuário pode editar (permissão)
  final bool isEditable;

  /// Se está salvando no momento (para desabilitar botões)
  final bool isSaving;

  // ====== Callbacks de campos ======
  final void Function(String?) onChangedOrderNumber;
  final void Function(String?) onChangedOrderType;
  final void Function(String?) onChangedOrderDate;

  final VoidCallback onClear;
  final Future<void> Function() onSaveOrUpdate;

  // ====== Callbacks de anexos ======
  final Future<void> Function()? onAddAttachment;
  final Future<void> Function(int index)? onDeleteAttachment;
  final Future<void> Function(int index)? onTapAttachment;

  /// ✅ NOVO: se quiser manter pai sincronizado / reagir a mudanças
  final void Function(List<dynamic> newItems)? onAttachmentsChanged;

  /// ✅ NOVO: persistência do rename (se quiser)
  /// Retorne true se persistiu; false para o SideListBox reverter o rótulo.
  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersistAttachment;

  const ValidityFormSection({
    super.key,
    required this.contractData,
    required this.state,
    required this.isEditable,
    required this.isSaving,
    required this.onChangedOrderNumber,
    required this.onChangedOrderType,
    required this.onChangedOrderDate,
    required this.onClear,
    required this.onSaveOrUpdate,
    this.onAddAttachment,
    this.onDeleteAttachment,
    this.onTapAttachment,
    this.onAttachmentsChanged,
    this.onRenamePersistAttachment,
  });

  @override
  State<ValidityFormSection> createState() => _ValidityFormSectionState();
}

class _ValidityFormSectionState extends State<ValidityFormSection> {
  late final TextEditingController _orderCtrl;
  late final TextEditingController _orderTypeCtrl;
  late final TextEditingController _orderDateCtrl;

  int? _selectedSideIndex;

  @override
  void initState() {
    super.initState();
    _orderCtrl = TextEditingController();
    _orderTypeCtrl = TextEditingController();
    _orderDateCtrl = TextEditingController();
    _applyFromState(force: true);
  }

  @override
  void didUpdateWidget(covariant ValidityFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSel = oldWidget.state.selectedValidity;
    final newSel = widget.state.selectedValidity;

    if (!identical(oldSel, newSel)) {
      _applyFromState(force: true);
    }
  }

  void _applyFromState({bool force = false}) {
    final ValidityData? v = widget.state.selectedValidity;

    if (v == null) {
      _orderCtrl.text = widget.state.nextOrderNumber.toString();
      _orderTypeCtrl.text = '';
      _orderDateCtrl.text = '';
    } else {
      _orderCtrl.text = v.orderNumber?.toString() ?? '';
      _orderTypeCtrl.text = v.ordertype ?? '';
      _orderDateCtrl.text =
      v.orderdate != null ? SipGedFormatDates.dateToDdMMyyyy(v.orderdate!) : '';
    }

    setState(() {
      _selectedSideIndex = null;
    });
  }

  bool get _isFormValid {
    final hasType = _orderTypeCtrl.text.trim().isNotEmpty;
    final dt = SipGedFormatDates.ddMMyyyyToDate(_orderDateCtrl.text);
    return hasType && dt != null;
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _orderTypeCtrl.dispose();
    _orderDateCtrl.dispose();
    super.dispose();
  }

  void _ensureSelectedIndexValid(int len) {
    if (_selectedSideIndex == null) return;
    if (len <= 0) {
      setState(() => _selectedSideIndex = null);
      return;
    }
    if (_selectedSideIndex! >= len) {
      setState(() => _selectedSideIndex = len - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final selectedValidity = state.selectedValidity;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;
        final sideWidth = isSmall ? constraints.maxWidth : 300.0;

        final inputWidth = responsiveInputWidth(
          context: context,
          itemsPerLine: 3,
          reservedWidth: isSmall ? 0.0 : (sideWidth + 12.0),
          spacing: 12.0,
          margin: 12.0,
          extraPadding: 24.0,
          spaceBetweenReserved: 12.0,
        );

        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            DropDownButtonChange(
              width: inputWidth,
              labelText: 'Ordem',
              items: state.orderNumberOptions,
              greyItems: state.greyOrderItems,
              controller: _orderCtrl,
              enabled: widget.isEditable,
              onChanged: (value) {
                widget.onChangedOrderNumber(value);
              },
            ),
            DropDownButtonChange(
              width: inputWidth,
              labelText: 'Tipo da ordem',
              items: state.availableOrderTypes,
              controller: _orderTypeCtrl,
              enabled: state.availableOrderTypes.isNotEmpty && widget.isEditable,
              onChanged: (value) {
                _orderTypeCtrl.text = value ?? '';
                widget.onChangedOrderType(value);
              },
            ),
            CustomDateField(
              width: inputWidth,
              controller: _orderDateCtrl,
              initialValue: selectedValidity?.orderdate,
              labelText: 'Data da ordem',
              enabled: widget.isEditable,
              validator: (_) {
                final d = SipGedFormatDates.ddMMyyyyToDate(_orderDateCtrl.text);
                return d == null ? 'Data inválida' : null;
              },
              onChanged: (date) {
                final text =
                date != null ? SipGedFormatDates.dateToDdMMyyyy(date) : '';
                _orderDateCtrl.text = text;
                widget.onChangedOrderDate(text);
              },
            ),
          ],
        );

        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (selectedValidity?.id != null)
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Limpar'),
                onPressed: widget.isEditable && !widget.isSaving ? widget.onClear : null,
              ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: widget.isEditable && !widget.isSaving && _isFormValid
                  ? () async {
                await widget.onSaveOrUpdate();
              }
                  : null,
              icon: const Icon(Icons.save),
              label: Text(selectedValidity?.id != null ? 'Atualizar' : 'Salvar'),
            ),
          ],
        );

        final corpo = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            camposWrap,
            const SizedBox(height: 12),
            botoes,
          ],
        );

        final side = SideListBox(
          title: 'Arquivos da ordem',
          items: state.attachments,
          selectedIndex: _selectedSideIndex,
          onAddPressed: (selectedValidity != null &&
              widget.isEditable &&
              widget.onAddAttachment != null)
              ? () async {
            await widget.onAddAttachment!.call();
          }
              : null,
          onTap: (index) async {
            setState(() {
              _selectedSideIndex = index;
            });
            if (widget.onTapAttachment != null) {
              await widget.onTapAttachment!(index);
            }
          },
          onDelete: (widget.isEditable && widget.onDeleteAttachment != null)
              ? (index) async {
            await widget.onDeleteAttachment!(index);
            if (!mounted) return;
            setState(() {
              _selectedSideIndex = null;
            });
          }
              : null,
          width: sideWidth,

          // ✅ rename embutido
          enableRename: widget.isEditable,
          onItemsChanged: (newItems) {
            _ensureSelectedIndexValid(newItems.length);
            widget.onAttachmentsChanged?.call(newItems);
          },
          onRenamePersist: widget.onRenamePersistAttachment,
        );

        final content = isSmall
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            side,
            const SizedBox(height: 12),
            corpo,
          ],
        )
            : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            side,
            const SizedBox(width: 12),
            Expanded(child: corpo),
          ],
        );

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(12),
            child: content,
          ),
        );
      },
    );
  }
}
