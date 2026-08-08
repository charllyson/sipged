// ==============================
// lib/screens/contracts/validity/validity_form_section.dart
// ==============================

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_state.dart';
import 'package:sipged/_utils/formatters/sipged_format_dates.dart';

import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/list/files/box_list_files.dart';

class ValidityFormSection extends StatefulWidget {
  final ContractData contractData;
  final ValidityState state;

  final bool isEditable;
  final bool isSaving;

  final void Function(String?) onChangedOrderNumber;
  final void Function(String?) onChangedOrderType;
  final void Function(String?) onChangedOrderDate;

  final VoidCallback onClear;
  final Future<void> Function() onSaveOrUpdate;

  final Future<void> Function()? onAddAttachment;
  final Future<void> Function(int index)? onDeleteAttachment;
  final Future<void> Function(int index)? onTapAttachment;

  final void Function(List<dynamic> newItems)? onAttachmentsChanged;

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
  static const String ordemInicio = 'ORDEM DE INÍCIO';
  static const String ordemParalisacao = 'ORDEM DE PARALISAÇÃO';
  static const String ordemReinicio = 'ORDEM DE REINÍCIO';
  static const String ordemFinalizacao = 'ORDEM DE FINALIZAÇÃO';

  static const List<String> _officialOrderTypes = <String>[
    ordemInicio,
    ordemParalisacao,
    ordemReinicio,
    ordemFinalizacao,
  ];

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

    _applyFromState();
  }

  @override
  void didUpdateWidget(covariant ValidityFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSelected = oldWidget.state.selectedValidity;
    final newSelected = widget.state.selectedValidity;

    final oldNextOrder = oldWidget.state.nextOrderNumber;
    final newNextOrder = widget.state.nextOrderNumber;

    final orderOptionsChanged =
        oldWidget.state.orderNumberOptions != widget.state.orderNumberOptions;

    final greyItemsChanged =
        oldWidget.state.greyOrderItems != widget.state.greyOrderItems;

    final orderTypesChanged =
        oldWidget.state.availableOrderTypes != widget.state.availableOrderTypes;

    final attachmentsChanged =
        oldWidget.state.attachments.length != widget.state.attachments.length;

    if (!identical(oldSelected, newSelected) ||
        oldNextOrder != newNextOrder ||
        orderOptionsChanged ||
        greyItemsChanged ||
        orderTypesChanged) {
      _applyFromState(resetSelectedAttachment: true);
      return;
    }

    if (attachmentsChanged) {
      _ensureSelectedIndexValid(widget.state.attachments.length);
    }
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _orderTypeCtrl.dispose();
    _orderDateCtrl.dispose();

    super.dispose();
  }

  void _applyFromState({bool resetSelectedAttachment = false}) {
    final ValidityData? selected = widget.state.selectedValidity;

    if (selected == null) {
      _orderCtrl.text = widget.state.nextOrderNumber.toString();
      _orderTypeCtrl.clear();
      _orderDateCtrl.clear();
    } else {
      _orderCtrl.text = selected.orderNumber?.toString() ?? '';
      _orderTypeCtrl.text = selected.ordertype?.trim() ?? '';
      _orderDateCtrl.text = selected.orderdate != null
          ? SipGedFormatDates.dateToDdMMyyyy(selected.orderdate!)
          : '';
    }

    if (resetSelectedAttachment) {
      if (mounted) {
        setState(() {
          _selectedSideIndex = null;
        });
      } else {
        _selectedSideIndex = null;
      }
    }
  }

  List<String> get _orderTypeItems {
    final items = <String>[];

    for (final item in widget.state.availableOrderTypes) {
      final clean = item.trim();

      if (clean.isEmpty) continue;
      if (!items.contains(clean)) items.add(clean);
    }

    final selectedType = widget.state.selectedValidity?.ordertype?.trim();

    if (selectedType != null &&
        selectedType.isNotEmpty &&
        !items.contains(selectedType)) {
      items.insert(0, selectedType);
    }

    return List<String>.unmodifiable(items);
  }

  bool get _hasValidOfficialOrderType {
    final type = _orderTypeCtrl.text.trim();

    if (type.isEmpty) return false;

    return _officialOrderTypes.contains(type);
  }

  bool get _hasValidOrderDate {
    final date = SipGedFormatDates.ddMMyyyyToDate(_orderDateCtrl.text);

    return date != null;
  }

  bool get _isFormValid {
    return _hasValidOfficialOrderType && _hasValidOrderDate;
  }

  void _ensureSelectedIndexValid(int len) {
    if (_selectedSideIndex == null) return;

    if (len <= 0) {
      if (mounted) {
        setState(() {
          _selectedSideIndex = null;
        });
      } else {
        _selectedSideIndex = null;
      }

      return;
    }

    if (_selectedSideIndex! >= len) {
      if (mounted) {
        setState(() {
          _selectedSideIndex = len - 1;
        });
      } else {
        _selectedSideIndex = len - 1;
      }
    }
  }

  Future<void> _handleSavePressed() async {
    if (!_isFormValid) return;

    await widget.onSaveOrUpdate();
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
          reservedWidth: isSmall ? 0.0 : sideWidth + 12.0,
          spacing: 12.0,
          margin: 12.0,
          extraPadding: 24.0,
          spaceBetweenReserved: 12.0,
        );

        final orderTypeItems = _orderTypeItems;

        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            DropDownChange(
              width: inputWidth,
              labelText: 'Ordem',
              items: state.orderNumberOptions,
              greyItems: state.greyOrderItems,
              controller: _orderCtrl,
              enabled: widget.isEditable && !widget.isSaving,
              onChanged: (value) {
                _orderCtrl.text = value ?? '';
                widget.onChangedOrderNumber(value);
                setState(() {});
              },
            ),
            DropDownChange(
              width: inputWidth,
              labelText: 'Tipo da ordem',
              items: orderTypeItems,
              controller: _orderTypeCtrl,
              enabled: orderTypeItems.isNotEmpty &&
                  widget.isEditable &&
                  !widget.isSaving,
              onChanged: (value) {
                final clean = value?.trim();

                _orderTypeCtrl.text = clean ?? '';
                widget.onChangedOrderType(clean);

                setState(() {});
              },
            ),
            DateFieldChange(
              width: inputWidth,
              controller: _orderDateCtrl,
              initialValue: selectedValidity?.orderdate,
              labelText: 'Data da ordem',
              enabled: widget.isEditable && !widget.isSaving,
              validator: (_) {
                final date =
                SipGedFormatDates.ddMMyyyyToDate(_orderDateCtrl.text);

                if (date == null) {
                  return 'Data inválida';
                }

                return null;
              },
              onChanged: (date) {
                final text = date != null
                    ? SipGedFormatDates.dateToDdMMyyyy(date)
                    : '';

                _orderDateCtrl.text = text;
                widget.onChangedOrderDate(text);

                setState(() {});
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
                onPressed: widget.isEditable && !widget.isSaving
                    ? widget.onClear
                    : null,
              ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: widget.isEditable && !widget.isSaving && _isFormValid
                  ? _handleSavePressed
                  : null,
              icon: const Icon(Icons.save),
              label: Text(
                selectedValidity?.id != null ? 'Atualizar' : 'Salvar',
              ),
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

        final side = BoxListFiles(
          title: 'Arquivos da ordem',
          items: state.attachments,
          selectedIndex: _selectedSideIndex,
          onAddPressed: selectedValidity != null &&
              widget.isEditable &&
              !widget.isSaving &&
              widget.onAddAttachment != null
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
          onDelete: widget.isEditable &&
              !widget.isSaving &&
              widget.onDeleteAttachment != null
              ? (index) async {
            await widget.onDeleteAttachment!(index);

            if (!mounted) return;

            setState(() {
              _selectedSideIndex = null;
            });
          }
              : null,
          width: sideWidth,
          enableRename: widget.isEditable && !widget.isSaving,
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