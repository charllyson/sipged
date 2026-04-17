import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/land/notification/land_notification_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/notification/land_notification_data.dart';
import 'package:sipged/_blocs/modules/planning/land/notification/land_notification_state.dart';

import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_widgets/input/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

class LandNotification extends StatefulWidget {
  final String contractId;
  final String propertyId;
  final String? userId;

  const LandNotification({
    super.key,
    required this.contractId,
    required this.propertyId,
    this.userId,
  });

  @override
  State<LandNotification> createState() => _LandNotificationState();
}

class _LandNotificationState extends State<LandNotification> {
  late final ScrollController _scrollCtrl;

  final processNumberCtrl = TextEditingController();
  final dupNumberCtrl = TextEditingController();
  final doPublicationCtrl = TextEditingController();
  final arCtrl = TextEditingController();
  final negotiationStatusCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  final dupDateCtrl = TextEditingController();
  final doPublicationDateCtrl = TextEditingController();
  final notificationDateCtrl = TextEditingController();
  final agreementDateCtrl = TextEditingController();
  final possessionDateCtrl = TextEditingController();
  final evictionDateCtrl = TextEditingController();
  final registryUpdateDateCtrl = TextEditingController();

  DateTime? _dupDate;
  DateTime? _doPublicationDate;
  DateTime? _notificationDate;
  DateTime? _agreementDate;
  DateTime? _possessionDate;
  DateTime? _evictionDate;
  DateTime? _registryUpdateDate;

  String? _lastSyncKey;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant LandNotification oldWidget) {
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
      context.read<LandNotificationCubit>().initialize(
        contractId: widget.contractId,
        propertyId: widget.propertyId,
      );
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();

    processNumberCtrl.dispose();
    dupNumberCtrl.dispose();
    doPublicationCtrl.dispose();
    arCtrl.dispose();
    negotiationStatusCtrl.dispose();
    notesCtrl.dispose();

    dupDateCtrl.dispose();
    doPublicationDateCtrl.dispose();
    notificationDateCtrl.dispose();
    agreementDateCtrl.dispose();
    possessionDateCtrl.dispose();
    evictionDateCtrl.dispose();
    registryUpdateDateCtrl.dispose();

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

  void _syncFromState(LandNotificationData d) {
    final key = [
      d.id,
      d.updatedAt?.millisecondsSinceEpoch,
      d.processNumber,
      d.dupNumber,
      d.doPublication,
      d.notificationAR,
      d.negotiationStatus,
      d.notes,
      d.dupDate?.millisecondsSinceEpoch,
      d.doPublicationDate?.millisecondsSinceEpoch,
      d.notificationDate?.millisecondsSinceEpoch,
      d.agreementDate?.millisecondsSinceEpoch,
      d.possessionDate?.millisecondsSinceEpoch,
      d.evictionDate?.millisecondsSinceEpoch,
      d.registryUpdateDate?.millisecondsSinceEpoch,
    ].join('_');

    if (_lastSyncKey == key) return;
    _lastSyncKey = key;

    processNumberCtrl.text = d.processNumber;
    dupNumberCtrl.text = d.dupNumber;
    doPublicationCtrl.text = d.doPublication;
    arCtrl.text = d.notificationAR;
    negotiationStatusCtrl.text = d.negotiationStatus;
    notesCtrl.text = d.notes;

    dupDateCtrl.text =
    d.dupDate != null ? SipGedFormatDates.dateToDdMMyyyy(d.dupDate!) : '';
    doPublicationDateCtrl.text = d.doPublicationDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(d.doPublicationDate!)
        : '';
    notificationDateCtrl.text = d.notificationDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(d.notificationDate!)
        : '';
    agreementDateCtrl.text = d.agreementDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(d.agreementDate!)
        : '';
    possessionDateCtrl.text = d.possessionDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(d.possessionDate!)
        : '';
    evictionDateCtrl.text = d.evictionDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(d.evictionDate!)
        : '';
    registryUpdateDateCtrl.text = d.registryUpdateDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(d.registryUpdateDate!)
        : '';

    _dupDate = d.dupDate;
    _doPublicationDate = d.doPublicationDate;
    _notificationDate = d.notificationDate;
    _agreementDate = d.agreementDate;
    _possessionDate = d.possessionDate;
    _evictionDate = d.evictionDate;
    _registryUpdateDate = d.registryUpdateDate;
  }

  LandNotificationData _buildDraft(LandNotificationState state) {
    return state.draft.copyWith(
      processNumber: processNumberCtrl.text.trim(),
      dupNumber: dupNumberCtrl.text.trim(),
      dupDate: _dupDate,
      doPublication: doPublicationCtrl.text.trim(),
      doPublicationDate: _doPublicationDate,
      notificationAR: arCtrl.text.trim(),
      notificationDate: _notificationDate,
      agreementDate: _agreementDate,
      possessionDate: _possessionDate,
      evictionDate: _evictionDate,
      registryUpdateDate: _registryUpdateDate,
      negotiationStatus: negotiationStatusCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
    );
  }

  void _clearForm(LandNotificationState state) {
    final empty = LandNotificationData.empty(
      contractId: state.contractId,
      id: state.propertyId,
    );

    processNumberCtrl.clear();
    dupNumberCtrl.clear();
    doPublicationCtrl.clear();
    arCtrl.clear();
    negotiationStatusCtrl.clear();
    notesCtrl.clear();

    dupDateCtrl.clear();
    doPublicationDateCtrl.clear();
    notificationDateCtrl.clear();
    agreementDateCtrl.clear();
    possessionDateCtrl.clear();
    evictionDateCtrl.clear();
    registryUpdateDateCtrl.clear();

    _dupDate = null;
    _doPublicationDate = null;
    _notificationDate = null;
    _agreementDate = null;
    _possessionDate = null;
    _evictionDate = null;
    _registryUpdateDate = null;

    context.read<LandNotificationCubit>().updateDraft(empty);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LandNotificationCubit, LandNotificationState>(
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

        final bloc = context.read<LandNotificationCubit>();

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
                              controller: processNumberCtrl,
                              labelText: 'Número do Processo',
                            ),
                            CustomTextField(
                              width: w,
                              controller: dupNumberCtrl,
                              labelText: 'Nº do DUP',
                            ),
                            DateFieldChange(
                              width: w,
                              enabled: true,
                              controller: dupDateCtrl,
                              initialValue: _dupDate,
                              labelText: 'Data do DUP',
                              onChanged: (value) {
                                setState(() => _dupDate = value);
                              },
                            ),
                            CustomTextField(
                              width: w,
                              controller: doPublicationCtrl,
                              labelText: 'DO / Seção / Página',
                            ),
                            DateFieldChange(
                              width: w,
                              enabled: true,
                              controller: doPublicationDateCtrl,
                              initialValue: _doPublicationDate,
                              labelText: 'Data da Publicação',
                              onChanged: (value) {
                                setState(() => _doPublicationDate = value);
                              },
                            ),
                            CustomTextField(
                              width: w,
                              controller: arCtrl,
                              labelText: 'AR (Aviso de Recebimento)',
                            ),
                            DateFieldChange(
                              width: w,
                              enabled: true,
                              controller: notificationDateCtrl,
                              initialValue: _notificationDate,
                              labelText: 'Data da Notificação',
                              onChanged: (value) {
                                setState(() => _notificationDate = value);
                              },
                            ),
                            DateFieldChange(
                              width: w,
                              enabled: true,
                              controller: agreementDateCtrl,
                              initialValue: _agreementDate,
                              labelText: 'Data do Acordo',
                              onChanged: (value) {
                                setState(() => _agreementDate = value);
                              },
                            ),
                            DateFieldChange(
                              width: w,
                              enabled: true,
                              controller: possessionDateCtrl,
                              initialValue: _possessionDate,
                              labelText: 'Data da Imissão na Posse',
                              onChanged: (value) {
                                setState(() => _possessionDate = value);
                              },
                            ),
                            DateFieldChange(
                              width: w,
                              enabled: true,
                              controller: evictionDateCtrl,
                              initialValue: _evictionDate,
                              labelText: 'Data da Desocupação',
                              onChanged: (value) {
                                setState(() => _evictionDate = value);
                              },
                            ),
                            DateFieldChange(
                              width: w,
                              enabled: true,
                              controller: registryUpdateDateCtrl,
                              initialValue: _registryUpdateDate,
                              labelText: 'Data da Atualização do Registro',
                              onChanged: (value) {
                                setState(() => _registryUpdateDate = value);
                              },
                            ),
                            CustomTextField(
                              width: w,
                              controller: negotiationStatusCtrl,
                              labelText: 'Status da Negociação',
                            ),
                            CustomTextField(
                              width: w * 2 + 12,
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