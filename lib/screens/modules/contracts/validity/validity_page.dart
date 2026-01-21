// ==============================
// lib/screens/contracts/validity/validity_page.dart
// ==============================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_cubit.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_repository.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_state.dart';

import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/timeline/timeline_class.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';
import 'package:siged/_widgets/pdf/pdf_preview.dart';

import 'validity_form_section.dart';
import 'validity_table_section.dart';

class ValidityPage extends StatelessWidget {
  const ValidityPage({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  String _suggestLabelFromName(ValidityData v, String original) {
    final base = original
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = v.orderNumber ?? 0;
    return 'Ordem $ord - $base';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ValidityCubit>(
      create: (_) {
        final cubit = ValidityCubit(
          repository: ValidityRepository(),
        );

        if (contractData.id != null && contractData.id!.isNotEmpty) {
          cubit.loadForContract(contractData.id!);
        }

        return cubit;
      },
      child: BlocBuilder<ValidityCubit, ValidityState>(
        builder: (context, state) {
          final cubit = context.read<ValidityCubit>();
          final isBusy = state.isLoading || state.isSaving;

          // TODO: integrar permissões reais (UserBloc, roles/perms).
          const bool isEditable = true;

          Future<void> handleAddAttachment() async {
            final v = state.selectedValidity;
            if (v == null) return;

            try {
              // Usamos um repo temporário apenas para pegar os bytes
              final tempRepo = ValidityRepository();
              final (bytes, originalName) =
              await tempRepo.pickFileBytes();

              final suggestion = _suggestLabelFromName(v, originalName);
              final label =
              await askLabelDialog(context, suggestion);
              if (label == null) return;

              await cubit.addAttachmentFromBytes(
                bytes: bytes,
                originalName: originalName,
                customLabel: label,
              );
            } catch (e) {
              // Aqui você pode exibir uma notificação de erro se quiser
              debugPrint('Erro ao adicionar anexo: $e');
            }
          }

          Future<void> handleOpenAttachment(int index) async {
            if (index < 0 || index >= state.attachments.length) return;
            final att = state.attachments[index];
            final url = att.url;
            if (url.isEmpty) return;

            await showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.white,
                insetPadding: const EdgeInsets.all(16),
                child: PdfPreview(pdfUrl: url),
              ),
            );
          }

          Future<void> handleDeleteAttachment(int index) async {
            await cubit.deleteAttachmentAt(index);
          }

          Future<void> handleRenameAttachment(
              int index,
              ) async {
            if (index < 0 || index >= state.attachments.length) return;
            final att = state.attachments[index];

            final currentLabel = att.label.isNotEmpty
                ? att.label
                : _suggestLabelFromName(
              state.selectedValidity ??
                  ValidityData(orderNumber: 0),
              att.id,
            );

            final newLabel =
            await askLabelDialog(context, currentLabel);
            if (newLabel == null) return;

            await cubit.renameAttachment(index, newLabel);
          }

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // =========================
                          // TIMELINE (usa Cubit internamente)
                          // =========================
                          SizedBox(height: 12),
                          const TimelineClass(),
                          const SectionTitle(
                            text: 'Cadastrar validades no sistema',
                          ),
                          ValidityFormSection(
                            contractData: contractData,
                            state: state,
                            isEditable: isEditable,
                            isSaving: state.isSaving,
                            onChangedOrderNumber:
                                (value) => cubit.selectOrderNumber(value),
                            onChangedOrderType:
                                (value) => cubit.updateOrderType(value),
                            onChangedOrderDate:
                                (value) => cubit.updateOrderDate(value),
                            onClear: () => cubit.createNewValidity(),
                            onSaveOrUpdate: () async {
                              final ok = await confirmDialog(
                                context,
                                'Deseja salvar esta validade?',
                              );
                              if (ok) {
                                await cubit.saveSelected();
                              }
                            },
                            onAddAttachment: handleAddAttachment,
                            onDeleteAttachment: handleDeleteAttachment,
                            onRenameAttachment: (index) =>
                                handleRenameAttachment(index),
                            onTapAttachment: handleOpenAttachment,
                          ),

                          const SectionTitle(
                            text:
                            'Validades cadastradas no sistema',
                          ),

                          ValidityTableSection(
                            validities: state.validities,
                            selectedItem: state.selectedValidity,
                            onTapItem: (v) =>
                                cubit.selectValidity(v),
                            onDelete: (id) async {
                              final ok = await confirmDialog(
                                context,
                                'Deseja apagar esta validade?',
                              );
                              if (ok) {
                                await cubit.deleteValidity(id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const FootBar(),
                ],
              ),

              if (isBusy)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}
