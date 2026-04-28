import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/land/property/land_property_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/property/land_property_data.dart';
import 'package:sipged/_blocs/modules/planning/land/property/land_property_state.dart';

import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_utils/formatters/sipged_format_numbers.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/list/files/side_list_box.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';
import 'package:url_launcher/url_launcher.dart';

class LandProperty extends StatefulWidget {
  final String contractId;
  final String? propertyId;
  final String? userId;
  final ValueChanged<String?>? onSavedPropertyId;

  const LandProperty({
    super.key,
    required this.contractId,
    this.propertyId,
    this.userId,
    this.onSavedPropertyId,
  });

  @override
  State<LandProperty> createState() => _LandPropertyState();
}

class _LandPropertyState extends State<LandProperty> {
  late final ScrollController _scrollCtrl;

  final registryCtrl = TextEditingController();
  final registryOfficeCtrl = TextEditingController();
  final propertyTypeCtrl = TextEditingController();
  final statusCtrl = TextEditingController();
  final currentStageCtrl = TextEditingController();
  final useOfLandCtrl = TextEditingController();

  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();

  final roadIdCtrl = TextEditingController();
  final roadNameCtrl = TextEditingController();
  final segmentIdCtrl = TextEditingController();
  final kmStartCtrl = TextEditingController();
  final kmEndCtrl = TextEditingController();
  final laneSideCtrl = TextEditingController();

  final totalAreaCtrl = TextEditingController();
  final affectedAreaCtrl = TextEditingController();
  final remainingAreaCtrl = TextEditingController();

  final hasImprovementsCtrl = TextEditingController();
  final improvementsSummaryCtrl = TextEditingController();

  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();

  String? _lastSyncKey;
  List<Attachment> _attachments = const [];

  static const List<String> _propertyTypeItems = [
    'URBANO',
    'RURAL',
    'MISTO',
    'POSSE',
    'OUTRO',
  ];

  static const List<String> _statusItems = [
    'CADASTRADO',
    'EM ANÁLISE',
    'EM NEGOCIAÇÃO',
    'ACORDO FIRMADO',
    'JUDICIALIZADO',
    'PAGO',
    'ENCERRADO',
  ];

  static const List<String> _stageItems = [
    'CADASTRO',
    'LEVANTAMENTO',
    'AVALIAÇÃO',
    'NEGOCIAÇÃO',
    'PAGAMENTO',
    'REGISTRO',
    'CONCLUÍDO',
  ];

  static const List<String> _useOfLandItems = [
    'RESIDENCIAL',
    'COMERCIAL',
    'INDUSTRIAL',
    'INSTITUCIONAL',
    'AGRÍCOLA',
    'PASTAGEM',
    'MISTO',
    'OUTRO',
  ];

  static const List<String> _laneSideItems = [
    'DIREITO',
    'ESQUERDO',
    'AMBOS',
    'EIXO',
    'NÃO INFORMADO',
  ];

  static const List<String> _yesNoItems = [
    'Sim',
    'Não',
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant LandProperty oldWidget) {
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

      context.read<LandPropertyCubit>().initialize(
        contractId: widget.contractId,
        propertyId: widget.propertyId,
      );
    });
  }

  void _notify({
    required String title,
    String? subtitle,
    String? details,
    required NotificationType type,
  }) {
    if (!mounted) return;

    context.read<NotificationCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        details: details,
        type: type,
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();

    for (final c in [
      registryCtrl,
      registryOfficeCtrl,
      propertyTypeCtrl,
      statusCtrl,
      currentStageCtrl,
      useOfLandCtrl,
      addressCtrl,
      cityCtrl,
      stateCtrl,
      roadIdCtrl,
      roadNameCtrl,
      segmentIdCtrl,
      kmStartCtrl,
      kmEndCtrl,
      laneSideCtrl,
      totalAreaCtrl,
      affectedAreaCtrl,
      remainingAreaCtrl,
      hasImprovementsCtrl,
      improvementsSummaryCtrl,
      latitudeCtrl,
      longitudeCtrl,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  double _responsiveWidth(BuildContext context, double reserved) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 4,
      reservedWidth: reserved,
      spacing: 12,
      margin: 12,
      extraPadding: 24,
      spaceBetweenReserved: 12,
    );
  }

  double _toDouble(String value) {
    return SipGedFormatNumbers.toDouble(value) ?? 0;
  }

  void _syncFromState(LandPropertyData d) {
    final attachmentsToken = d.attachments
        .map((a) => '${a.id}_${a.label}_${a.url}_${a.path}')
        .join('|');

    final syncKey = [
      d.id,
      d.updatedAt?.millisecondsSinceEpoch,
      d.registryNumber,
      d.registryOffice,
      d.propertyType,
      d.status,
      d.currentStage,
      d.useOfLand,
      d.address,
      d.city,
      d.state,
      d.roadId,
      d.roadName,
      d.segmentId,
      d.kmStart,
      d.kmEnd,
      d.laneSide,
      d.totalArea,
      d.affectedArea,
      d.remainingArea,
      d.hasImprovements,
      d.improvementsSummary,
      d.latitude,
      d.longitude,
      attachmentsToken,
    ].join('_');

    if (_lastSyncKey == syncKey) return;
    _lastSyncKey = syncKey;

    registryCtrl.text = d.registryNumber;
    registryOfficeCtrl.text = d.registryOffice;
    propertyTypeCtrl.text = d.propertyType;
    statusCtrl.text = d.status;
    currentStageCtrl.text = d.currentStage;
    useOfLandCtrl.text = d.useOfLand;

    addressCtrl.text = d.address;
    cityCtrl.text = d.city;
    stateCtrl.text = d.state;

    roadIdCtrl.text = d.roadId;
    roadNameCtrl.text = d.roadName;
    segmentIdCtrl.text = d.segmentId;
    kmStartCtrl.text = d.kmStart == 0 ? '' : d.kmStart.toString();
    kmEndCtrl.text = d.kmEnd == 0 ? '' : d.kmEnd.toString();
    laneSideCtrl.text = d.laneSide;

    totalAreaCtrl.text = d.totalArea == 0 ? '' : d.totalArea.toString();
    affectedAreaCtrl.text = d.affectedArea == 0 ? '' : d.affectedArea.toString();
    remainingAreaCtrl.text =
    d.remainingArea == 0 ? '' : d.remainingArea.toString();

    hasImprovementsCtrl.text = d.hasImprovements ? 'Sim' : 'Não';
    improvementsSummaryCtrl.text = d.improvementsSummary;

    latitudeCtrl.text = d.latitude == 0 ? '' : d.latitude.toString();
    longitudeCtrl.text = d.longitude == 0 ? '' : d.longitude.toString();

    _attachments = List<Attachment>.from(d.attachments);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _notify(
        title: 'Não foi possível abrir o arquivo',
        subtitle: 'Verifique se o link do anexo está válido.',
        type: NotificationType.error,
      );
    }
  }

  LandPropertyData _buildDraft(LandPropertyState state) {
    final hasImprovements =
        hasImprovementsCtrl.text.trim().toLowerCase() == 'sim';

    return state.draft.copyWith(
      registryNumber: registryCtrl.text.trim(),
      registryOffice: registryOfficeCtrl.text.trim(),
      propertyType: propertyTypeCtrl.text.trim(),
      status: statusCtrl.text.trim(),
      currentStage: currentStageCtrl.text.trim(),
      useOfLand: useOfLandCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      state: stateCtrl.text.trim().toUpperCase(),
      roadId: roadIdCtrl.text.trim(),
      roadName: roadNameCtrl.text.trim(),
      segmentId: segmentIdCtrl.text.trim(),
      kmStart: _toDouble(kmStartCtrl.text),
      kmEnd: _toDouble(kmEndCtrl.text),
      laneSide: laneSideCtrl.text.trim(),
      totalArea: _toDouble(totalAreaCtrl.text),
      affectedArea: _toDouble(affectedAreaCtrl.text),
      remainingArea: _toDouble(remainingAreaCtrl.text),
      hasImprovements: hasImprovements,
      improvementsSummary: improvementsSummaryCtrl.text.trim(),
      latitude: _toDouble(latitudeCtrl.text),
      longitude: _toDouble(longitudeCtrl.text),
      attachments: _attachments,
    );
  }

  void _clearForm(LandPropertyState state) {
    final empty = LandPropertyData.empty(
      contractId: state.contractId,
      id: null,
    );

    for (final c in [
      registryCtrl,
      registryOfficeCtrl,
      propertyTypeCtrl,
      statusCtrl,
      currentStageCtrl,
      useOfLandCtrl,
      addressCtrl,
      cityCtrl,
      stateCtrl,
      roadIdCtrl,
      roadNameCtrl,
      segmentIdCtrl,
      kmStartCtrl,
      kmEndCtrl,
      laneSideCtrl,
      totalAreaCtrl,
      affectedAreaCtrl,
      remainingAreaCtrl,
      hasImprovementsCtrl,
      improvementsSummaryCtrl,
      latitudeCtrl,
      longitudeCtrl,
    ]) {
      c.clear();
    }

    hasImprovementsCtrl.text = 'Não';
    _attachments = const [];

    context.read<LandPropertyCubit>().updateDraft(empty);
    widget.onSavedPropertyId?.call(null);

    _notify(
      title: 'Formulário limpo',
      subtitle: 'Os campos do imóvel foram reiniciados.',
      type: NotificationType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LandPropertyCubit, LandPropertyState>(
      listenWhen: (previous, current) =>
      previous.error != current.error ||
          previous.successMessage != current.successMessage ||
          previous.propertyId != current.propertyId,
      listener: (context, state) {
        final error = state.error?.trim();
        final success = state.successMessage?.trim();

        if (error != null && error.isNotEmpty) {
          _notify(
            title: 'Erro no imóvel',
            subtitle: 'Não foi possível concluir a operação.',
            details: error,
            type: NotificationType.error,
          );
          context.read<LandPropertyCubit>().clearMessages();
        }

        if (success != null && success.isNotEmpty) {
          _notify(
            title: 'Imóvel atualizado',
            subtitle: success,
            type: NotificationType.success,
          );
          context.read<LandPropertyCubit>().clearMessages();
        }

        if ((state.propertyId ?? '').isNotEmpty) {
          widget.onSavedPropertyId?.call(state.propertyId);
        }
      },
      builder: (context, state) {
        final bloc = context.read<LandPropertyCubit>();
        _syncFromState(state.draft);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 920;
            final sideWidth = isSmall ? constraints.maxWidth : 300.0;
            final reserved = isSmall ? 0.0 : (sideWidth + 12.0);
            final w = _responsiveWidth(context, reserved);

            final side = SideListBox(
              title: 'Arquivos do Imóvel',
              items: _attachments,
              selectedIndex: null,
              width: sideWidth,
              openOnTap: false,
              onAddPressed: () async {
                final suggestion = await askLabelDialog(context, 'Documento');
                if (suggestion == null) return;

                final now = DateTime.now().millisecondsSinceEpoch;
                final updated = List<Attachment>.from(_attachments)
                  ..add(
                    Attachment(
                      id: 'local_$now',
                      label: suggestion,
                      url: '',
                      path: '',
                      ext: '',
                      size: 0,
                      contentType: '',
                      createdAt: DateTime.now(),
                    ),
                  );

                setState(() {
                  _attachments = updated;
                });

                bloc.updateDraft(
                  _buildDraft(state).copyWith(attachments: updated),
                );

                _notify(
                  title: 'Anexo adicionado',
                  subtitle: 'O documento foi incluído na lista do imóvel.',
                  type: NotificationType.success,
                );
              },
              onTap: (i) {
                if (i < 0 || i >= _attachments.length) return;

                final url = _attachments[i].url;
                if (url.trim().isNotEmpty) {
                  _openUrl(url);
                } else {
                  _notify(
                    title: 'Arquivo sem link',
                    subtitle:
                    'Este item ainda não possui URL vinculada para abertura.',
                    type: NotificationType.info,
                  );
                }
              },
              onDelete: (i) {
                if (i < 0 || i >= _attachments.length) return;

                final updated = List<Attachment>.from(_attachments)
                  ..removeAt(i);

                setState(() {
                  _attachments = updated;
                });

                bloc.updateDraft(
                  _buildDraft(state).copyWith(attachments: updated),
                );

                _notify(
                  title: 'Anexo removido',
                  subtitle: 'O documento foi removido da lista do imóvel.',
                  type: NotificationType.info,
                );
              },
              onItemsChanged: (items) {
                final updated = items.whereType<Attachment>().toList();

                setState(() {
                  _attachments = updated;
                });

                bloc.updateDraft(
                  _buildDraft(state).copyWith(attachments: updated),
                );
              },
              onRenamePersist: ({
                required int index,
                required Attachment oldItem,
                required Attachment newItem,
              }) async {
                if (index < 0 || index >= _attachments.length) return false;

                final updated = List<Attachment>.from(_attachments);
                updated[index] = newItem;

                setState(() {
                  _attachments = updated;
                });

                bloc.updateDraft(
                  _buildDraft(state).copyWith(attachments: updated),
                );

                _notify(
                  title: 'Anexo renomeado',
                  subtitle: 'O rótulo do documento foi atualizado.',
                  type: NotificationType.success,
                );

                return true;
              },
            );

            final body = Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (state.loading) const LinearProgressIndicator(),
                if (state.loading) const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CustomTextField(
                      width: w,
                      controller: registryCtrl,
                      labelText: 'Nº Matrícula',
                    ),
                    CustomTextField(
                      width: w,
                      controller: registryOfficeCtrl,
                      labelText: 'Cartório',
                    ),
                    DropDownChange(
                      width: w,
                      enabled: true,
                      labelText: 'Tipo do Imóvel',
                      items: _propertyTypeItems,
                      controller: propertyTypeCtrl,
                    ),
                    DropDownChange(
                      width: w,
                      enabled: true,
                      labelText: 'Status',
                      items: _statusItems,
                      controller: statusCtrl,
                    ),
                    DropDownChange(
                      width: w,
                      enabled: true,
                      labelText: 'Etapa Atual',
                      items: _stageItems,
                      controller: currentStageCtrl,
                    ),
                    DropDownChange(
                      width: w,
                      enabled: true,
                      labelText: 'Uso do Solo',
                      items: _useOfLandItems,
                      controller: useOfLandCtrl,
                    ),
                    CustomTextField(
                      width: w,
                      controller: addressCtrl,
                      labelText: 'Endereço / Descrição',
                    ),
                    CustomTextField(
                      width: w,
                      controller: cityCtrl,
                      labelText: 'Município',
                    ),
                    CustomTextField(
                      width: w,
                      controller: stateCtrl,
                      labelText: 'UF',
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(2),
                      ],
                    ),
                    CustomTextField(
                      width: w,
                      controller: roadIdCtrl,
                      labelText: 'ID da Rodovia',
                    ),
                    CustomTextField(
                      width: w,
                      controller: roadNameCtrl,
                      labelText: 'Nome da Rodovia',
                    ),
                    CustomTextField(
                      width: w,
                      controller: segmentIdCtrl,
                      labelText: 'ID do Segmento',
                    ),
                    CustomTextField(
                      width: w,
                      controller: kmStartCtrl,
                      labelText: 'KM Inicial',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]')),
                      ],
                    ),
                    CustomTextField(
                      width: w,
                      controller: kmEndCtrl,
                      labelText: 'KM Final',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]')),
                      ],
                    ),
                    DropDownChange(
                      width: w,
                      enabled: true,
                      labelText: 'Lado da Via',
                      items: _laneSideItems,
                      controller: laneSideCtrl,
                    ),
                    CustomTextField(
                      width: w,
                      controller: totalAreaCtrl,
                      labelText: 'Área Total (m²)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]')),
                      ],
                    ),
                    CustomTextField(
                      width: w,
                      controller: affectedAreaCtrl,
                      labelText: 'Área Atingida (m²)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]')),
                      ],
                    ),
                    CustomTextField(
                      width: w,
                      controller: remainingAreaCtrl,
                      labelText: 'Área Remanescente (m²)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]')),
                      ],
                    ),
                    DropDownChange(
                      width: w,
                      enabled: true,
                      labelText: 'Possui benfeitorias?',
                      items: _yesNoItems,
                      controller: hasImprovementsCtrl,
                    ),
                    CustomTextField(
                      width: (w * 2) + 12,
                      controller: improvementsSummaryCtrl,
                      labelText: 'Resumo das Benfeitorias',
                      maxLines: 2,
                    ),
                    CustomTextField(
                      width: w,
                      controller: latitudeCtrl,
                      labelText: 'Latitude',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]')),
                      ],
                    ),
                    CustomTextField(
                      width: w,
                      controller: longitudeCtrl,
                      labelText: 'Longitude',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                      icon: state.saving
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: LoadingTreeDots(
                          size: 16,
                          centered: false,
                        ),
                      )
                          : const Icon(Icons.save),
                      label: Text(
                        state.saving
                            ? 'Salvando...'
                            : (state.propertyId ?? '').isNotEmpty
                            ? 'Atualizar'
                            : 'Salvar',
                      ),
                      onPressed: state.saving
                          ? null
                          : () async {
                        bloc.updateDraft(_buildDraft(state));
                        await bloc.save(userId: widget.userId);
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text('Limpar'),
                      onPressed: state.saving ? null : () => _clearForm(state),
                    ),
                    if ((state.propertyId ?? '').isNotEmpty)
                      TextButton.icon(
                        icon: state.deleting
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: LoadingTreeDots(
                            size: 16,
                            centered: false,
                          ),
                        )
                            : const Icon(Icons.delete_outline),
                        label: Text(state.deleting ? 'Excluindo...' : 'Excluir'),
                        onPressed: state.deleting ? null : bloc.delete,
                      ),
                  ],
                ),
              ],
            );

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
                  child: isSmall
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      side,
                      const SizedBox(height: 12),
                      body,
                    ],
                  )
                      : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: sideWidth, child: side),
                      const SizedBox(width: 12),
                      Expanded(child: body),
                    ],
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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}