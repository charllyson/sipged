// lib/screens/modules/planning/rightWay/property/lane_regularization_details_panel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/planning/highway_domain/lane_regularization_data.dart';
import 'package:sipged/_blocs/modules/planning/highway_domain/lane_regularization_storage_bloc.dart';

// ✅ NOVO: sem intl
import 'package:sipged/_utils/formats/sipged_format_numbers.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';

// Attachment igual ao usado nas Medições/SideListBox
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class LaneRegularizationDetailsPanel extends StatefulWidget {
  final ProcessData contract;
  final String propertyId;

  const LaneRegularizationDetailsPanel({
    super.key,
    required this.contract,
    required this.propertyId,
  });

  @override
  State<LaneRegularizationDetailsPanel> createState() =>
      _LaneRegularizationDetailsPanelState();
}

class _LaneRegularizationDetailsPanelState
    extends State<LaneRegularizationDetailsPanel> {
  final _db = FirebaseFirestore.instance;
  late final LaneRegularizationStorageBloc _storage;

  // anexos persistidos (com label, url, path, etc.)
  List<Attachment> _geos = const [];
  List<Attachment> _docs = const [];
  bool _loadingFiles = false;

  // ===== Helpers =====

  String fmtDoubleNullable(double? v, {int fractionDigits = 2, String empty = '-'}) {
    if (v == null) return empty;
    return SipGedFormatNumbers.decimalPtBr(v, fractionDigits: fractionDigits);
  }

  String fmtPriceNullable(double? v, {String empty = '-'}) {
    if (v == null) return empty;
    return SipGedFormatMoney.doubleToText(v);
  }

  String _baseName(String name) {
    var s = name.trim();
    final q = s.indexOf('?');
    if (q != -1) s = s.substring(0, q);
    final h = s.indexOf('#');
    if (h != -1) s = s.substring(0, h);
    s = s.split('/').last;
    return s.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  DocumentReference<Map<String, dynamic>> get _propRef => _db
      .collection('contracts')
      .doc(widget.contract.id)
      .collection('planning_right_way_properties')
      .doc(widget.propertyId);

  @override
  void initState() {
    super.initState();
    _storage = LaneRegularizationStorageBloc();
    _reloadFiles();
  }

  Future<void> _persistAttachments() async {
    await _propRef.set({
      'geoAttachments': _geos.map((e) => e.toMap()).toList(),
      'docAttachments': _docs.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Carrega anexos do Firestore; se vazio, migra do Storage e persiste.
  Future<void> _reloadFiles() async {
    if (!mounted) return;
    setState(() => _loadingFiles = true);
    try {
      final snap = await _propRef.get();
      final data = snap.data() ?? {};
      List<Attachment> geos = [];
      List<Attachment> docs = [];

      final rawGeos = (data['geoAttachments'] as List?)
          ?.map((e) => Attachment.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      final rawDocs = (data['docAttachments'] as List?)
          ?.map((e) => Attachment.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Migração quando arrays ainda não existem ou vazios
      if (rawGeos == null || rawGeos.isEmpty) {
        final listed = await _storage.listarGeo(
          contractId: widget.contract.id!,
          propertyId: widget.propertyId,
        );
        geos = listed
            .map((f) => Attachment(
          id: f.name,
          label: _baseName(f.name),
          url: f.url,
          path: f.path,
          ext: '', // geo
          createdAt: DateTime.now(),
        ))
            .toList();
      } else {
        geos = rawGeos;
      }

      if (rawDocs == null || rawDocs.isEmpty) {
        final listed = await _storage.listarDocs(
          contractId: widget.contract.id!,
          propertyId: widget.propertyId,
        );
        docs = listed
            .map((f) => Attachment(
          id: f.name,
          label: _baseName(f.name),
          url: f.url,
          path: f.path,
          ext: '.pdf',
          createdAt: DateTime.now(),
        ))
            .toList();
      } else {
        docs = rawDocs;
      }

      _geos = geos;
      _docs = docs;

      // Persiste se migramos
      await _persistAttachments();
    } finally {
      if (mounted) setState(() => _loadingFiles = false);
    }
  }

  Future<void> _addGeo() async {
    String? last;
    try {
      final uploaded = await _storage.uploadGeoWithPickerDetailed(
        contractId: widget.contract.id!,
        propertyId: widget.propertyId,
        onProgress: (p) {
          final m =
              'Enviando georreferenciado ${(p * 100).toStringAsFixed(0)}%';
          if (m != last && mounted) {
            // ⚡ feedback rápido de progresso
            NotificationCenter.instance.show(
              AppNotification(
                title: Text(m),
                type: AppNotificationType.info,
                leadingLabel: const Text('Regularização'),
                duration: const Duration(milliseconds: 700),
              ),
            );
            last = m;
          }
        },
      );

      final suggestion = _baseName(uploaded.name);
      final label = (await askLabelDialog(context, suggestion))?.trim();

      final att = Attachment(
        id: uploaded.name,
        label: (label == null || label.isEmpty) ? suggestion : label,
        url: uploaded.url,
        path: uploaded.path,
        ext: '',
        createdAt: DateTime.now(),
      );

      setState(() => _geos = [att, ..._geos]);
      await _persistAttachments();

      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Arquivo georreferenciado adicionado!'),
          type: AppNotificationType.success,
          leadingLabel: const Text('Regularização'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Falha ao adicionar georreferenciado'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Regularização'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _addDoc() async {
    String? last;
    try {
      final uploaded = await _storage.uploadDocWithPickerDetailed(
        contractId: widget.contract.id!,
        propertyId: widget.propertyId,
        onProgress: (p) {
          final m = 'Enviando arquivo ${(p * 100).toStringAsFixed(0)}%';
          if (m != last && mounted) {
            NotificationCenter.instance.show(
              AppNotification(
                title: Text(m),
                type: AppNotificationType.info,
                leadingLabel: const Text('Regularização'),
                duration: const Duration(milliseconds: 700),
              ),
            );
            last = m;
          }
        },
      );

      final suggestion = _baseName(uploaded.name);
      final label = (await askLabelDialog(context, suggestion))?.trim();

      final att = Attachment(
        id: uploaded.name,
        label: (label == null || label.isEmpty) ? suggestion : label,
        url: uploaded.url,
        path: uploaded.path,
        ext: '.pdf',
        createdAt: DateTime.now(),
      );

      setState(() => _docs = [att, ..._docs]);
      await _persistAttachments();

      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Arquivo adicionado!'),
          type: AppNotificationType.success,
          leadingLabel: const Text('Regularização'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Falha ao adicionar anexo'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Regularização'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _removeAttachment({required bool isGeo, required int index}) async {
    try {
      final list = isGeo ? _geos : _docs;
      if (index < 0 || index >= list.length) return;
      final item = list[index];

      await _storage.deleteByPath(item.path); // apaga no Storage
      setState(() {
        if (isGeo) {
          _geos = List.of(_geos)..removeAt(index);
        } else {
          _docs = List.of(_docs)..removeAt(index);
        }
      });
      await _persistAttachments();

      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: Text(isGeo
              ? 'Arquivo georreferenciado removido.'
              : 'Arquivo removido.'),
          type: AppNotificationType.success,
          leadingLabel: const Text('Regularização'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Erro ao remover'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Regularização'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _renameAttachment({required bool isGeo, required int index}) async {
    final list = isGeo ? _geos : _docs;
    if (index < 0 || index >= list.length) return;
    final current = list[index];

    final newLabel = await askLabelDialog(context, current.label);
    if (newLabel == null || newLabel.isEmpty || newLabel == current.label) return;

    setState(() {
      if (isGeo) {
        _geos = List.of(_geos);
        _geos[index] = current..label = newLabel;
      } else {
        _docs = List.of(_docs);
        _docs[index] = current..label = newLabel;
      }
    });
    await _persistAttachments();

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Rótulo atualizado'),
        subtitle: Text(newLabel),
        type: AppNotificationType.success,
        leadingLabel: const Text('Regularização'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Stream<LaneRegularizationData?> _propStream() {
    final col = _db
        .collection('contracts')
        .doc(widget.contract.id)
        .collection('planning_right_way_properties')
        .doc(widget.propertyId);

    return col.snapshots().map((snap) {
      if (!snap.exists) return null;
      return LaneRegularizationData.fromDocument(snap);
    });
  }

  // ==== UI helpers ====

  Widget _card(Widget child) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundClean(), // (se o seu widget chama BackgroundClean, ajuste aqui)
        StreamBuilder<LaneRegularizationData?>(
          stream: _propStream(),
          builder: (ctx, snap) {
            final prop = snap.data;
            final loading = snap.connectionState == ConnectionState.waiting;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                // Cabeçalho
                _card(
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person_pin_circle, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loading
                                    ? 'Carregando…'
                                    : (prop?.ownerName?.trim().isNotEmpty == true
                                    ? prop!.ownerName!
                                    : 'Proprietário não informado'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  _chip('CPF/CNPJ', prop?.cpfCnpj ?? '-'),
                                  _chip('Tipo', prop?.propertyType ?? '-'),
                                  _chip('Status', prop?.status ?? '-'),
                                  _chip('Município', prop?.city ?? '-'),
                                  _chip('UF', prop?.state ?? '-'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Registro / Localização
                _card(
                  Column(
                    children: [
                      _tile(
                        icon: Icons.gavel_outlined,
                        title: 'Matrícula / Cartório',
                        subtitle:
                        'Matrícula: ${prop?.registryNumber ?? '-'}\n'
                            'Cartório: ${prop?.registryOffice ?? '-'}\n'
                            'Endereço/Descrição: ${prop?.address ?? '-'}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Processos / Datas
                _card(
                  Column(
                    children: [
                      _tile(
                        icon: Icons.description_outlined,
                        title: 'Processo',
                        subtitle: prop?.processNumber ?? '-',
                      ),
                      const Divider(height: 0),
                      _tile(
                        icon: Icons.mail_outline,
                        title: 'Notificação',
                        subtitle: prop?.notificationDate == null
                            ? '-'
                            : SipGedFormatDates.dateToDdMMyyyy(prop!.notificationDate!),
                      ),
                      const Divider(height: 0),
                      _tile(
                        icon: Icons.search_outlined,
                        title: 'Vistoria',
                        subtitle: prop?.inspectionDate == null
                            ? '-'
                            : SipGedFormatDates.dateToDdMMyyyy(prop!.inspectionDate!),
                      ),
                      const Divider(height: 0),
                      _tile(
                        icon: Icons.handshake_outlined,
                        title: 'Acordo/Indenização',
                        subtitle: prop?.agreementDate == null
                            ? '-'
                            : SipGedFormatDates.dateToDdMMyyyy(prop!.agreementDate!),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Áreas e Valor
                _card(
                  Column(
                    children: [
                      _tile(
                        icon: Icons.square_foot_outlined,
                        title: 'Áreas (m²)',
                        subtitle:
                        'Total: ${fmtDoubleNullable(prop?.totalArea, fractionDigits: 2)}'
                            ' | Afetada: ${fmtDoubleNullable(prop?.affectedArea, fractionDigits: 2)}',
                      ),
                      const Divider(height: 0),
                      _tile(
                        icon: Icons.payments_outlined,
                        title: 'Indenização (R\$)',
                        subtitle: fmtPriceNullable(prop?.indemnityValue),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Contatos
                _card(
                  Column(
                    children: [
                      _tile(
                        icon: Icons.phone_outlined,
                        title: 'Contato',
                        subtitle:
                        'Telefone: ${prop?.phone ?? '-'}\n'
                            'E-mail: ${prop?.email ?? '-'}',
                      ),
                      if ((prop?.notes?.trim().isNotEmpty ?? false)) ...[
                        const Divider(height: 0),
                        _tile(
                          icon: Icons.sticky_note_2_outlined,
                          title: 'Observações',
                          subtitle: prop!.notes!,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // GEORREFERENCIADOS
                _card(
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.map_outlined),
                        title: const Text('Georreferenciados (KML/KMZ/GeoJSON)'),
                        subtitle: Text(
                          _loadingFiles
                              ? 'Carregando…'
                              : _geos.isEmpty
                              ? 'Nenhum arquivo'
                              : '${_geos.length} arquivo(s)',
                        ),
                        trailing: IconButton(
                          tooltip: 'Adicionar georreferenciado',
                          icon: const Icon(Icons.upload_file),
                          onPressed: _addGeo,
                        ),
                      ),
                      const Divider(height: 0),
                      if (_geos.isNotEmpty)
                        ..._geos.asMap().entries.map((e) {
                          final i = e.key;
                          final g = e.value;
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(g.label, overflow: TextOverflow.ellipsis),
                            subtitle: Text(g.id, overflow: TextOverflow.ellipsis),
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  tooltip: 'Abrir',
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => _openUrl(g.url),
                                ),
                                IconButton(
                                  tooltip: 'Renomear',
                                  icon: const Icon(Icons.drive_file_rename_outline),
                                  onPressed: () => _renameAttachment(isGeo: true, index: i),
                                ),
                                IconButton(
                                  tooltip: 'Remover',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removeAttachment(isGeo: true, index: i),
                                ),
                              ],
                            ),
                          );
                        }),
                      if (_geos.isEmpty && !_loadingFiles)
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '— Nenhum arquivo adicionado —',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // DOCUMENTOS (PDF)
                _card(
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf_outlined),
                        title: const Text('Documentos (PDF)'),
                        subtitle: Text(
                          _loadingFiles
                              ? 'Carregando…'
                              : _docs.isEmpty
                              ? 'Nenhum arquivo'
                              : '${_docs.length} arquivo(s)',
                        ),
                        trailing: IconButton(
                          tooltip: 'Adicionar PDF',
                          icon: const Icon(Icons.upload_file),
                          onPressed: _addDoc,
                        ),
                      ),
                      const Divider(height: 0),
                      if (_docs.isNotEmpty)
                        ..._docs.asMap().entries.map((e) {
                          final i = e.key;
                          final d = e.value;
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(d.label, overflow: TextOverflow.ellipsis),
                            subtitle: Text(d.id, overflow: TextOverflow.ellipsis),
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  tooltip: 'Abrir',
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => _openUrl(d.url),
                                ),
                                IconButton(
                                  tooltip: 'Renomear',
                                  icon: const Icon(Icons.drive_file_rename_outline),
                                  onPressed: () => _renameAttachment(isGeo: false, index: i),
                                ),
                                IconButton(
                                  tooltip: 'Remover',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removeAttachment(isGeo: false, index: i),
                                ),
                              ],
                            ),
                          );
                        }),
                      if (_docs.isEmpty && !_loadingFiles)
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '— Nenhum arquivo adicionado —',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      label: Text('$label: $value'),
    );
  }
}
