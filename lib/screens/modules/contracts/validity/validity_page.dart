import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_repository.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_state.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_contract.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

import 'package:sipged/_services/pdf/pdf_preview.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/timeline/timeline_class.dart';

import 'validity_form_section.dart';
import 'validity_table_section.dart';

class ValidityPage extends StatelessWidget {
  const ValidityPage({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  String get _contractId => contractData.id?.trim() ?? '';

  String get _contractTitle {
    final summary = contractData.summarySubjectContract?.trim() ?? '';
    if (summary.isNotEmpty) return summary;

    final number = contractData.contractNumber?.trim() ?? '';
    if (number.isNotEmpty) return 'Contrato $number';

    final process = contractData.processNumber?.trim() ?? '';
    if (process.isNotEmpty) return 'Processo $process';

    final id = _contractId;
    if (id.isNotEmpty) return 'Contrato $id';

    return 'Contrato sem identificação';
  }

  String _suggestLabelFromName(ValidityData v, String original) {
    final base = original
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    final ord = v.orderNumber ?? 0;
    return 'Ordem $ord - $base';
  }

  String _resolveActorName(String? uid) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final cleanUid = uid?.trim();

    if (cleanUid != null && cleanUid.isNotEmpty) {
      final meta = contractData.participantsInfo[cleanUid];

      if (meta != null) {
        final fullName = (meta['fullName'] ??
            meta['displayName'] ??
            meta['nameComplete'] ??
            '')
            .toString()
            .trim();

        if (fullName.isNotEmpty) return fullName;

        final name = (meta['name'] ?? '').toString().trim();
        final surname = (meta['surname'] ?? '').toString().trim();

        final composed = [name, surname]
            .where((e) => e.trim().isNotEmpty)
            .join(' ')
            .trim();

        if (composed.isNotEmpty) return composed;

        final email = (meta['email'] ?? '').toString().trim();
        if (email.isNotEmpty) return email;
      }
    }

    final displayName = currentUser?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = currentUser?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  List<String> _contractNotificationRecipients({
    required String? currentUserId,
  }) {
    final current = currentUserId?.trim();
    final ids = <String>{};

    for (final entry in contractData.permissionContractId.entries) {
      final userId = entry.key.trim();
      if (userId.isEmpty) continue;

      final perms = entry.value;

      final canRead = perms['read'] == true ||
          perms['view'] == true ||
          perms['create'] == true ||
          perms['edit'] == true ||
          perms['update'] == true ||
          perms['delete'] == true ||
          perms['admin'] == true ||
          perms['owner'] == true;

      if (!canRead) continue;
      if (current != null && current.isNotEmpty && userId == current) continue;

      ids.add(userId);
    }

    for (final userId in contractData.participantsInfo.keys) {
      final clean = userId.trim();
      if (clean.isEmpty) continue;
      if (current != null && current.isNotEmpty && clean == current) continue;

      ids.add(clean);
    }

    return ids.toList();
  }

  Future<void> _notify({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? details,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!context.mounted) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid.trim();
    final actorName = _resolveActorName(currentUserId);

    final recipients = _contractNotificationRecipients(
      currentUserId: currentUserId,
    );

    await NotificationContract.show(
      context: context,
      contract: contractData,
      title: title,
      subtitle: subtitle,
      details: details ?? _contractTitle,
      leadingLabel: 'Validade',
      module: 'contracts_validity',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: currentUserId,
      actorName: actorName,
      targetUserIds: recipients,
      extra: <String, dynamic>{
        'route': 'contracts_validity',
        'contractId': _contractId,
        'contractTitle': _contractTitle,
        'contractSummary': _contractTitle,
        ...extra,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ValidityCubit>(
      create: (_) {
        final cubit = ValidityCubit(
          repository: ValidityRepository(),
        );

        if (_contractId.isNotEmpty) {
          cubit.loadForContract(_contractId);
        }

        return cubit;
      },
      child: BlocBuilder<ValidityCubit, ValidityState>(
        builder: (context, state) {
          final cubit = context.read<ValidityCubit>();

          final isBusy = state.isLoading || state.isSaving;
          const bool isEditable = true;

          Future<void> handleAddAttachment() async {
            final v = state.selectedValidity;

            if (v == null) {
              await _notify(
                context: context,
                title: 'Salve a validade primeiro',
                subtitle: 'Depois você poderá anexar arquivos.',
                type: NotificationType.info,
              );
              return;
            }

            try {
              final tempRepo = ValidityRepository();
              final (bytes, originalName) = await tempRepo.pickFileBytes();

              if (!context.mounted) return;

              final suggestion = _suggestLabelFromName(v, originalName);
              final label = await askLabelDialog(context, suggestion);

              if (!context.mounted) return;
              if (label == null) return;

              await cubit.addAttachmentFromBytes(
                bytes: bytes,
                originalName: originalName,
                customLabel: label,
              );

              if (!context.mounted) return;

              await _notify(
                context: context,
                title: 'Arquivo anexado',
                subtitle: label,
                type: NotificationType.success,
                saveInBell: true,
                sendPush: true,
                extra: <String, dynamic>{
                  'action': 'validity_attachment_created',
                  'validityId': v.id,
                  'orderNumber': v.orderNumber,
                  'attachmentLabel': label,
                },
              );
            } catch (e) {
              if (!context.mounted) return;

              await _notify(
                context: context,
                title: 'Erro ao anexar arquivo',
                subtitle: '$e',
                type: NotificationType.error,
                duration: const Duration(seconds: 6),
              );
            }
          }

          Future<void> handleOpenAttachment(int index) async {
            if (index < 0 || index >= state.attachments.length) return;

            final att = state.attachments[index];
            final url = att.url;

            if (url.isEmpty) return;
            if (!context.mounted) return;

            await showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.white,
                insetPadding: const EdgeInsets.all(16),
                child: PdfPreview(pdfUrl: url),
              ),
            );
          }

          Future<void> handleDeleteAttachment(int index) async {
            if (index < 0 || index >= state.attachments.length) return;

            final selected = state.selectedValidity;
            final attachment = state.attachments[index];

            final ok = await confirmDialog(
              context,
              'Deseja remover este arquivo?',
            );

            if (!context.mounted) return;
            if (!ok) return;

            try {
              await cubit.deleteAttachmentAt(index);

              if (!context.mounted) return;

              await _notify(
                context: context,
                title: 'Arquivo removido',
                subtitle: attachment.label,
                type: NotificationType.warning,
                saveInBell: true,
                sendPush: true,
                extra: <String, dynamic>{
                  'action': 'validity_attachment_deleted',
                  'validityId': selected?.id,
                  'orderNumber': selected?.orderNumber,
                  'attachmentLabel': attachment.label,
                },
              );
            } catch (e) {
              if (!context.mounted) return;

              await _notify(
                context: context,
                title: 'Erro ao remover arquivo',
                subtitle: '$e',
                type: NotificationType.error,
                duration: const Duration(seconds: 6),
              );
            }
          }

          Future<void> handleSaveOrUpdate() async {
            final selectedBeforeSave = state.selectedValidity;
            final isNew = selectedBeforeSave?.id == null;

            final ok = await confirmDialog(
              context,
              'Deseja salvar esta validade?',
            );

            if (!context.mounted) return;
            if (!ok) return;

            try {
              await cubit.saveSelected();

              if (!context.mounted) return;

              final actorName = _resolveActorName(
                FirebaseAuth.instance.currentUser?.uid,
              );

              await _notify(
                context: context,
                title: isNew ? 'Validade criada' : 'Validade atualizada',
                subtitle: isNew
                    ? 'Ordem salva por $actorName.'
                    : 'Ordem atualizada por $actorName.',
                type: NotificationType.success,
                saveInBell: true,
                sendPush: true,
                extra: <String, dynamic>{
                  'action': isNew ? 'validity_created' : 'validity_updated',
                  'validityId': selectedBeforeSave?.id,
                  'orderNumber': selectedBeforeSave?.orderNumber,
                  'orderType': selectedBeforeSave?.ordertype,
                  'orderDate': selectedBeforeSave?.orderdate?.toIso8601String(),
                },
              );
            } catch (e) {
              if (!context.mounted) return;

              await _notify(
                context: context,
                title: 'Erro ao salvar validade',
                subtitle: '$e',
                type: NotificationType.error,
                duration: const Duration(seconds: 6),
              );
            }
          }

          Future<bool> handleRenamePersistAttachment({
            required int index,
            required Attachment oldItem,
            required Attachment newItem,
          }) async {
            final selected = state.selectedValidity;

            try {
              await cubit.renameAttachment(
                index,
                newItem.label,
              );

              if (!context.mounted) return false;

              await _notify(
                context: context,
                title: 'Anexo renomeado',
                subtitle: newItem.label,
                type: NotificationType.success,
                saveInBell: true,
                sendPush: true,
                extra: <String, dynamic>{
                  'action': 'validity_attachment_renamed',
                  'validityId': selected?.id,
                  'orderNumber': selected?.orderNumber,
                  'oldAttachmentLabel': oldItem.label,
                  'newAttachmentLabel': newItem.label,
                },
              );

              return true;
            } catch (e) {
              if (!context.mounted) return false;

              await _notify(
                context: context,
                title: 'Falha ao renomear anexo',
                subtitle: '$e',
                type: NotificationType.error,
                duration: const Duration(seconds: 6),
              );

              return false;
            }
          }

          Future<void> handleDeleteValidity(String id) async {
            final ok = await confirmDialog(
              context,
              'Deseja apagar esta validade?',
            );

            if (!context.mounted) return;
            if (!ok) return;

            final deleted = state.validities.firstWhere(
                  (item) => item.id == id,
              orElse: () => ValidityData(id: id),
            );

            try {
              await cubit.deleteValidity(id);

              if (!context.mounted) return;

              final actorName = _resolveActorName(
                FirebaseAuth.instance.currentUser?.uid,
              );

              await _notify(
                context: context,
                title: 'Validade apagada',
                subtitle:
                'Ordem ${deleted.orderNumber ?? '-'} removida por $actorName.',
                type: NotificationType.warning,
                saveInBell: true,
                sendPush: true,
                extra: <String, dynamic>{
                  'action': 'validity_deleted',
                  'validityId': id,
                  'orderNumber': deleted.orderNumber,
                  'orderType': deleted.ordertype,
                  'orderDate': deleted.orderdate?.toIso8601String(),
                },
              );
            } catch (e) {
              if (!context.mounted) return;

              await _notify(
                context: context,
                title: 'Erro ao apagar validade',
                subtitle: '$e',
                type: NotificationType.error,
                duration: const Duration(seconds: 6),
              );
            }
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
                          const SizedBox(height: 12),
                          const TimelineClass(),
                          const SectionTitle(
                            text: 'Cadastrar validades no sistema',
                          ),
                          ValidityFormSection(
                            contractData: contractData,
                            state: state,
                            isEditable: isEditable,
                            isSaving: state.isSaving,
                            onChangedOrderNumber: cubit.selectOrderNumber,
                            onChangedOrderType: cubit.updateOrderType,
                            onChangedOrderDate: cubit.updateOrderDate,
                            onClear: cubit.createNewValidity,
                            onSaveOrUpdate: handleSaveOrUpdate,
                            onAddAttachment: handleAddAttachment,
                            onDeleteAttachment: handleDeleteAttachment,
                            onTapAttachment: handleOpenAttachment,
                            onRenamePersistAttachment:
                            handleRenamePersistAttachment,
                          ),
                          const SectionTitle(
                            text: 'Validades cadastradas no sistema',
                          ),
                          ValidityTableSection(
                            validities: state.validities,
                            selectedItem: state.selectedValidity,
                            onTapItem: cubit.selectValidity,
                            onDelete: handleDeleteValidity,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const FootBar(),
                ],
              ),
              if (isBusy)
                Stack(
                  children: [
                    ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                    const Center(
                      child: LoadingTreeDots(size: 110),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}