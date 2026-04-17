import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/land/owner/land_owner_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/owner/land_owner_data.dart';
import 'package:sipged/_blocs/modules/planning/land/owner/land_owner_state.dart';

import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

class LandOwner extends StatefulWidget {
  final String contractId;
  final String propertyId;
  final String? userId;

  const LandOwner({
    super.key,
    required this.contractId,
    required this.propertyId,
    this.userId,
  });

  @override
  State<LandOwner> createState() => _LandOwnerState();
}

class _LandOwnerState extends State<LandOwner> {
  late final ScrollController _scrollCtrl;

  final ownerCtrl = TextEditingController();
  final cpfCnpjCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final documentNumberCtrl = TextEditingController();
  final maritalStatusCtrl = TextEditingController();
  final spouseNameCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  String? _lastSyncKey;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant LandOwner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contractId != widget.contractId ||
        oldWidget.propertyId != widget.propertyId) {
      _lastSyncKey = null;
      _initialize();
    }
  }

  void _initialize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LandOwnerCubit>().initialize(
        contractId: widget.contractId,
        propertyId: widget.propertyId,
      );
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    ownerCtrl.dispose();
    cpfCnpjCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    documentNumberCtrl.dispose();
    maritalStatusCtrl.dispose();
    spouseNameCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  double _responsiveWidth(BuildContext context) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 3,
      reservedWidth: 0,
      spacing: 12,
      margin: 12,
      extraPadding: 24,
      spaceBetweenReserved: 12,
    );
  }

  void _syncFromState(LandOwnerData d) {
    final key = [
      d.id,
      d.updatedAt?.millisecondsSinceEpoch,
      d.ownerName,
      d.cpfCnpj,
      d.phone,
      d.email,
      d.documentNumber,
      d.maritalStatus,
      d.spouseName,
      d.notes,
    ].join('_');

    if (_lastSyncKey == key) return;
    _lastSyncKey = key;

    ownerCtrl.text = d.ownerName;
    cpfCnpjCtrl.text = d.cpfCnpj;
    phoneCtrl.text = d.phone;
    emailCtrl.text = d.email;
    documentNumberCtrl.text = d.documentNumber;
    maritalStatusCtrl.text = d.maritalStatus;
    spouseNameCtrl.text = d.spouseName;
    notesCtrl.text = d.notes;
  }

  LandOwnerData _buildDraft(LandOwnerState state) {
    return state.draft.copyWith(
      ownerName: ownerCtrl.text.trim(),
      cpfCnpj: cpfCnpjCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      documentNumber: documentNumberCtrl.text.trim(),
      maritalStatus: maritalStatusCtrl.text.trim(),
      spouseName: spouseNameCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
    );
  }

  void _clearForm(LandOwnerState state) {
    final empty = LandOwnerData.empty(
      contractId: state.contractId,
      id: state.propertyId,
    );

    ownerCtrl.clear();
    cpfCnpjCtrl.clear();
    phoneCtrl.clear();
    emailCtrl.clear();
    documentNumberCtrl.clear();
    maritalStatusCtrl.clear();
    spouseNameCtrl.clear();
    notesCtrl.clear();

    context.read<LandOwnerCubit>().updateDraft(empty);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LandOwnerCubit, LandOwnerState>(
      listenWhen: (previous, current) =>
      previous.error != current.error ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.error != null && state.error!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }

        if (state.successMessage != null &&
            state.successMessage!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
      },
      builder: (context, state) {
        _syncFromState(state.draft);

        final bloc = context.read<LandOwnerCubit>();

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = _responsiveWidth(context);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Scrollbar(
                controller: _scrollCtrl,
                thumbVisibility: true,
                interactive: true,
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  primary: false,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  child: AbsorbPointer(
                    absorbing: state.loading || state.saving,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (state.loading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: LinearProgressIndicator(),
                          ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            CustomTextField(
                              width: w,
                              controller: ownerCtrl,
                              labelText: 'Proprietário / Posseiro',
                            ),
                            CustomTextField(
                              width: w,
                              controller: cpfCnpjCtrl,
                              labelText: 'CPF / CNPJ',
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d\.\-\/]'),
                                ),
                              ],
                            ),
                            CustomTextField(
                              width: w,
                              controller: phoneCtrl,
                              labelText: 'Telefone',
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d\(\)\s\-\+]'),
                                ),
                              ],
                            ),
                            CustomTextField(
                              width: w,
                              controller: emailCtrl,
                              labelText: 'E-mail',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            CustomTextField(
                              width: w,
                              controller: documentNumberCtrl,
                              labelText: 'Número do Documento',
                            ),
                            DropDownChange(
                              width: w,
                              enabled: true,
                              labelText: 'Estado Civil',
                              controller: maritalStatusCtrl,
                              items: const [
                                'Solteiro(a)',
                                'Casado(a)',
                                'União estável',
                                'Divorciado(a)',
                                'Viúvo(a)',
                                'Outro',
                              ],
                            ),
                            CustomTextField(
                              width: w,
                              controller: spouseNameCtrl,
                              labelText: 'Nome do Cônjuge',
                            ),
                            CustomTextField(
                              width: (w * 2) + 12,
                              controller: notesCtrl,
                              labelText: 'Observações',
                              maxLines: 4,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Recarregar'),
                              onPressed: state.loading
                                  ? null
                                  : () => bloc.initialize(
                                contractId: widget.contractId,
                                propertyId: widget.propertyId,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.cleaning_services_outlined),
                              label: const Text('Limpar'),
                              onPressed:
                              state.saving ? null : () => _clearForm(state),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Excluir'),
                              onPressed: state.saving ? null : () => bloc.delete(),
                            ),
                            ElevatedButton.icon(
                              icon: state.saving
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(Icons.save),
                              label: Text(
                                state.saving ? 'Salvando...' : 'Salvar',
                              ),
                              onPressed: state.saving
                                  ? null
                                  : () {
                                bloc.updateDraft(_buildDraft(state));
                                bloc.save(userId: widget.userId);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}