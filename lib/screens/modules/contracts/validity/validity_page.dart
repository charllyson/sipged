// lib/screens/modules/contracts/validity/validity_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/validity/validity_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_repository.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_state.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_validity.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_services/pdf/pdf_preview.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/timeline/timeline_class.dart';

import 'validity_form_section.dart';
import 'validity_table_section.dart';

class ValidityPage extends StatefulWidget {
  const ValidityPage({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  State<ValidityPage> createState() => _ValidityPageState();
}

class _ValidityPageState extends State<ValidityPage> {
  final DfdRepository _dfdRepository = DfdRepository();

  DfdData? _dfdData;

  String get _contractId => widget.contractData.id?.trim() ?? '';

  String get _contractTitle {
    final descricaoObjeto = _dfdData?.descricaoObjeto?.trim();

    if (descricaoObjeto != null && descricaoObjeto.isNotEmpty) {
      return descricaoObjeto;
    }

    if (_contractId.isNotEmpty) {
      return 'Contrato $_contractId';
    }

    return 'Contrato sem identificação';
  }

  String get _contractNumber {
    final processoAdministrativo = _dfdData?.processoAdministrativo?.trim();

    if (processoAdministrativo != null && processoAdministrativo.isNotEmpty) {
      return processoAdministrativo;
    }

    return _contractId;
  }

  @override
  void initState() {
    super.initState();
    _loadDfdDisplayData();
  }

  @override
  void didUpdateWidget(covariant ValidityPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.contractData.id?.trim() ?? '';
    final newId = widget.contractData.id?.trim() ?? '';

    if (oldId != newId) {
      _dfdData = null;
      _loadDfdDisplayData();
    }
  }

  Future<void> _loadDfdDisplayData() async {
    final contractId = _contractId;

    if (contractId.isEmpty) return;

    try {
      final dfd = await _dfdRepository.readDataForContract(contractId);

      if (!mounted) return;

      setState(() {
        _dfdData = dfd;
      });
    } catch (e, stack) {
      debugPrint('Falha ao carregar DFD do contrato em validade: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  String _suggestLabelFromName(ValidityData validity, String originalName) {
    final base = originalName
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    final order = validity.orderNumber ?? 0;

    return 'Ordem $order - $base';
  }

  String _resolveActorName(String? uid) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final cleanUid = uid?.trim();

    if (cleanUid != null && cleanUid.isNotEmpty) {
      final meta = widget.contractData.participantsInfo[cleanUid];

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

        final composed = <String>[name, surname]
            .where((item) => item.trim().isNotEmpty)
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

    for (final entry in widget.contractData.permissionContractId.entries) {
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

      if (current != null && current.isNotEmpty && userId == current) {
        continue;
      }

      ids.add(userId);
    }

    for (final userId in widget.contractData.participantsInfo.keys) {
      final clean = userId.trim();

      if (clean.isEmpty) continue;

      if (current != null && current.isNotEmpty && clean == current) {
        continue;
      }

      ids.add(clean);
    }

    return ids.toList();
  }

  DateTime? _parseDateTimeFromExtra(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);

    if (iso != null) {
      return iso;
    }

    final parts = text.split('/');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        final parsed = DateTime(year, month, day);

        if (parsed.day == day &&
            parsed.month == month &&
            parsed.year == year) {
          return parsed;
        }
      }
    }

    return null;
  }

  Future<void> _notify({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus status = NotificationStatus.info,

    /// Compatibilidade temporária com chamadas antigas.
    NotificationStatus? type,

    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!context.mounted) return;

    const route = 'contracts_validity';
    const notificationSource = 'contracts_validity';

    final currentUserId = FirebaseAuth.instance.currentUser?.uid.trim();
    final actorName = _resolveActorName(currentUserId);

    final recipients = _contractNotificationRecipients(
      currentUserId: currentUserId,
    );

    final delivery = saveInBell || sendPush
        ? NotificationDelivery.localBellAndPush
        : NotificationDelivery.localOnly;

    await NotificationValidity.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: subtitle,
      details: details ?? _contractTitle,
      leadingLabel: 'Validade',
      module: route,
      source: 'validity_notification',
      notificationSource: notificationSource,
      status: type ?? status,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      delivery: delivery,
      actorId: currentUserId,
      actorName: actorName,
      targetUserIds: recipients,
      includeCurrentUser: true,
      validityId: extra['validityId']?.toString(),
      validityOrder:
      extra['orderNumber']?.toString() ?? extra['validityOrder']?.toString(),
      validityStartDate: _parseDateTimeFromExtra(
        extra['validityStartDate'] ??
            extra['orderDate'] ??
            extra['validityDate'],
      ),
      validityEndDate: _parseDateTimeFromExtra(
        extra['validityEndDate'],
      ),
      extra: <String, dynamic>{
        'route': route,
        'module': route,
        'source': 'validity_notification',
        'sourceKey': notificationSource,
        'subSource': notificationSource,
        'notificationSource': notificationSource,

        /// Mantidos para o NotificationBell identificar usuário/foto.
        'actorId': currentUserId,
        'actorName': actorName,

        'contractId': _contractId,
        'contractNumber': _contractNumber,
        'processNumber': _contractNumber,
        'processoAdministrativo': _dfdData?.processoAdministrativo,
        'contractTitle': _contractTitle,
        'contractSummary': _contractTitle,
        'descricaoObjeto': _dfdData?.descricaoObjeto,
        ...extra,
      },
    );
  }

  Future<void> _safeNotify({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus status = NotificationStatus.info,

    /// Compatibilidade temporária com chamadas antigas.
    NotificationStatus? type,

    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    try {
      await _notify(
        context: context,
        title: title,
        subtitle: subtitle,
        details: details,
        status: status,
        type: type,
        duration: duration,
        saveInBell: saveInBell,
        sendPush: sendPush,
        extra: extra,
      );
    } catch (e, stack) {
      debugPrint('Falha ao enviar notificação de validade: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ValidityCubit>(
      create: (context) {
        final permissionState = context.read<PermissionCubit>().state;

        final cubit = ValidityCubit(
          repository: ValidityRepository(),
          initialPermissions: permissionState.current,
          initialTenantId: permissionState.activeTenantId,
          moduleId: 'contracts_validity',
        );

        if (_contractId.isNotEmpty) {
          cubit.loadForContract(_contractId);
        }

        return cubit;
      },
      child: BlocListener<PermissionCubit, PermissionState>(
        listenWhen: (previous, current) {
          return previous.current != current.current ||
              previous.activeTenantId != current.activeTenantId;
        },
        listener: (context, permissionState) {
          context.read<ValidityCubit>().updatePermissions(
            permissions: permissionState.current,
            tenantId: permissionState.activeTenantId,
          );
        },
        child: BlocBuilder<ValidityCubit, ValidityState>(
          builder: (context, state) {
            final cubit = context.read<ValidityCubit>();

            final isBusy = state.isLoading || state.isSaving;
            final isEditable = cubit.isEditable;

            Future<void> handleAddAttachment() async {
              final selected = state.selectedValidity;

              if (selected == null) {
                await _safeNotify(
                  context: context,
                  title: 'Salve a validade primeiro',
                  subtitle: 'Depois você poderá anexar arquivos.',
                  status: NotificationStatus.info,
                );
                return;
              }

              try {
                final tempRepo = ValidityRepository();
                final (bytes, originalName) = await tempRepo.pickFileBytes();

                if (!context.mounted) return;

                final suggestion = _suggestLabelFromName(
                  selected,
                  originalName,
                );

                final label = await askLabelDialog(context, suggestion);

                if (!context.mounted) return;
                if (label == null || label.trim().isEmpty) return;

                await cubit.addAttachmentFromBytes(
                  bytes: bytes,
                  originalName: originalName,
                  customLabel: label.trim(),
                );

                if (!context.mounted) return;

                await _safeNotify(
                  context: context,
                  title: 'Arquivo anexado',
                  subtitle: label.trim(),
                  status: NotificationStatus.success,
                  saveInBell: true,
                  sendPush: true,
                  extra: <String, dynamic>{
                    'action': 'validity_attachment_created',
                    'validityId': selected.id,
                    'orderNumber': selected.orderNumber,
                    'orderType': selected.ordertype,
                    'orderDate': selected.orderdate?.toIso8601String(),
                    'validityStartDate': selected.orderdate?.toIso8601String(),
                    'attachmentLabel': label.trim(),
                  },
                );
              } catch (e) {
                if (!context.mounted) return;

                await _safeNotify(
                  context: context,
                  title: 'Erro ao anexar arquivo',
                  subtitle: '$e',
                  status: NotificationStatus.error,
                  duration: const Duration(seconds: 6),
                );
              }
            }

            Future<void> handleOpenAttachment(int index) async {
              if (index < 0 || index >= state.attachments.length) return;

              final attachment = state.attachments[index];
              final url = attachment.url.trim();

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

                await _safeNotify(
                  context: context,
                  title: 'Arquivo removido',
                  subtitle: attachment.label,
                  status: NotificationStatus.warning,
                  saveInBell: true,
                  sendPush: true,
                  extra: <String, dynamic>{
                    'action': 'validity_attachment_deleted',
                    'validityId': selected?.id,
                    'orderNumber': selected?.orderNumber,
                    'orderType': selected?.ordertype,
                    'orderDate': selected?.orderdate?.toIso8601String(),
                    'validityStartDate':
                    selected?.orderdate?.toIso8601String(),
                    'attachmentLabel': attachment.label,
                    'attachmentUrl': attachment.url,
                  },
                );
              } catch (e) {
                if (!context.mounted) return;

                await _safeNotify(
                  context: context,
                  title: 'Erro ao remover arquivo',
                  subtitle: '$e',
                  status: NotificationStatus.error,
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

                final selectedAfterSave = cubit.state.selectedValidity;
                final validity = selectedAfterSave ?? selectedBeforeSave;

                final actorName = _resolveActorName(
                  FirebaseAuth.instance.currentUser?.uid,
                );

                await _safeNotify(
                  context: context,
                  title: isNew ? 'Validade criada' : 'Validade atualizada',
                  subtitle: isNew
                      ? 'Ordem salva por $actorName.'
                      : 'Ordem atualizada por $actorName.',
                  status: NotificationStatus.success,
                  saveInBell: true,
                  sendPush: true,
                  extra: <String, dynamic>{
                    'action': isNew ? 'validity_created' : 'validity_updated',
                    'validityId': validity?.id,
                    'orderNumber': validity?.orderNumber,
                    'orderType': validity?.ordertype,
                    'orderDate': validity?.orderdate?.toIso8601String(),
                    'validityStartDate':
                    validity?.orderdate?.toIso8601String(),
                  },
                );
              } catch (e) {
                if (!context.mounted) return;

                await _safeNotify(
                  context: context,
                  title: 'Erro ao salvar validade',
                  subtitle: '$e',
                  status: NotificationStatus.error,
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

                await _safeNotify(
                  context: context,
                  title: 'Anexo renomeado',
                  subtitle: newItem.label,
                  status: NotificationStatus.success,
                  saveInBell: true,
                  sendPush: true,
                  extra: <String, dynamic>{
                    'action': 'validity_attachment_renamed',
                    'validityId': selected?.id,
                    'orderNumber': selected?.orderNumber,
                    'orderType': selected?.ordertype,
                    'orderDate': selected?.orderdate?.toIso8601String(),
                    'validityStartDate':
                    selected?.orderdate?.toIso8601String(),
                    'oldAttachmentLabel': oldItem.label,
                    'newAttachmentLabel': newItem.label,
                    'attachmentUrl': newItem.url,
                  },
                );

                return true;
              } catch (e) {
                if (!context.mounted) return false;

                await _safeNotify(
                  context: context,
                  title: 'Falha ao renomear anexo',
                  subtitle: '$e',
                  status: NotificationStatus.error,
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

                await _safeNotify(
                  context: context,
                  title: 'Validade apagada',
                  subtitle:
                  'Ordem ${deleted.orderNumber ?? '-'} removida por $actorName.',
                  status: NotificationStatus.warning,
                  saveInBell: true,
                  sendPush: true,
                  extra: <String, dynamic>{
                    'action': 'validity_deleted',
                    'validityId': id,
                    'orderNumber': deleted.orderNumber,
                    'orderType': deleted.ordertype,
                    'orderDate': deleted.orderdate?.toIso8601String(),
                    'validityStartDate':
                    deleted.orderdate?.toIso8601String(),
                  },
                );
              } catch (e) {
                if (!context.mounted) return;

                await _safeNotify(
                  context: context,
                  title: 'Erro ao apagar validade',
                  subtitle: '$e',
                  status: NotificationStatus.error,
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
                              contractData: widget.contractData,
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
                            const SizedBox(height: 20),
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
      ),
    );
  }
}