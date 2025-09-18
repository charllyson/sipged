import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/date_utils.dart';

import 'package:siged/_blocs/sectors/planning/right_way_properties/planning_right_way_property_data.dart';
import 'package:siged/_blocs/sectors/planning/right_way_properties/planning_right_way_property_storage_bloc.dart';

class PlanningRightWayPropertyDetailsPanel extends StatefulWidget {
  final ContractData contract;
  final String propertyId;

  const PlanningRightWayPropertyDetailsPanel({
    super.key,
    required this.contract,
    required this.propertyId,
  });

  @override
  State<PlanningRightWayPropertyDetailsPanel> createState() =>
      _PlanningRightWayPropertyDetailsPanelState();
}

class _PlanningRightWayPropertyDetailsPanelState
    extends State<PlanningRightWayPropertyDetailsPanel> {
  final _db = FirebaseFirestore.instance;
  late final PlanningRightWayPropertyStorageBloc _storage;

  // listas de anexos
  List<({String name, String url})> _geos = const [];
  List<({String name, String url})> _docs = const [];
  bool _loadingFiles = false;

  // ===== Helpers de formatação seguros p/ null =====
  String fmtDoubleNullable(double? v, {int fractionDigits = 2}) {
    if (v == null) return '-';
    return doubleToString(v, fractionDigits: fractionDigits);
  }

  String fmtPriceNullable(double? v) {
    if (v == null) return '-';
    return priceToString(v);
  }

  @override
  void initState() {
    super.initState();
    _storage = PlanningRightWayPropertyStorageBloc();
    _reloadFiles();
  }

  Future<void> _reloadFiles() async {
    if (!mounted) return;
    setState(() => _loadingFiles = true);
    try {
      _geos = await _storage.listarGeo(
        contractId: widget.contract.id!,
        propertyId: widget.propertyId,
      );
      _docs = await _storage.listarDocs(
        contractId: widget.contract.id!,
        propertyId: widget.propertyId,
      );
    } finally {
      if (mounted) setState(() => _loadingFiles = false);
    }
  }

  Future<void> _addGeo() async {
    String? last;
    try {
      await _storage.uploadGeoWithPicker(
        contractId: widget.contract.id!,
        propertyId: widget.propertyId,
        onProgress: (p) {
          final m = 'Enviando georreferenciado ${(p * 100).toStringAsFixed(0)}%';
          if (m != last && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(m), duration: const Duration(milliseconds: 700)),
            );
            last = m;
          }
        },
      );
      await _reloadFiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo georreferenciado adicionado!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao adicionar georreferenciado: $e')),
      );
    }
  }

  Future<void> _addDoc() async {
    String? last;
    try {
      await _storage.uploadDocWithPicker(
        contractId: widget.contract.id!,
        propertyId: widget.propertyId,
        onProgress: (p) {
          final m = 'Enviando arquivo ${(p * 100).toStringAsFixed(0)}%';
          if (m != last && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(m), duration: const Duration(milliseconds: 700)),
            );
            last = m;
          }
        },
      );
      await _reloadFiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo adicionado!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao adicionar anexo: $e')),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _removeUrl(String url, {required bool isGeo}) async {
    try {
      await _storage.deleteByUrl(url);
      await _reloadFiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isGeo ? 'Arquivo georreferenciado removido.' : 'Arquivo removido.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover: $e')),
      );
    }
  }

  Stream<PlanningRightWayPropertyData?> _propStream() {
    final col = _db
        .collection('contracts')
        .doc(widget.contract.id)
        .collection('planning_right_way_properties')
        .doc(widget.propertyId);
    return col.snapshots().map((snap) {
      if (!snap.exists) return null;
      return PlanningRightWayPropertyData.fromDocument(snap);
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
        const BackgroundClean(),
        StreamBuilder<PlanningRightWayPropertyData?>(
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
                        'Matrícula: ${prop?.registryNumber ?? '-'}\nCartório: ${prop?.registryOffice ?? '-'}\nEndereço/Descrição: ${prop?.address ?? '-'}',
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
                            : dateTimeToDDMMYYYY(prop!.notificationDate!),
                      ),
                      const Divider(height: 0),
                      _tile(
                        icon: Icons.search_outlined,
                        title: 'Vistoria',
                        subtitle: prop?.inspectionDate == null
                            ? '-'
                            : dateTimeToDDMMYYYY(prop!.inspectionDate!),
                      ),
                      const Divider(height: 0),
                      _tile(
                        icon: Icons.handshake_outlined,
                        title: 'Acordo/Indenização',
                        subtitle: prop?.agreementDate == null
                            ? '-'
                            : dateTimeToDDMMYYYY(prop!.agreementDate!),
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
                        'Total: ${fmtDoubleNullable(prop?.totalArea)} | Afetada: ${fmtDoubleNullable(prop?.affectedArea)}',
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
                        'Telefone: ${prop?.phone ?? '-'}\nE-mail: ${prop?.email ?? '-'}',
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
                        ..._geos.map((g) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(
                            g.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              IconButton(
                                tooltip: 'Abrir',
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => _openUrl(g.url),
                              ),
                              IconButton(
                                tooltip: 'Remover',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeUrl(g.url, isGeo: true),
                              ),
                            ],
                          ),
                        )),
                      if (_geos.isEmpty && !_loadingFiles)
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('— Nenhum arquivo adicionado —',
                                style: TextStyle(color: Colors.black54)),
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
                        ..._docs.map((d) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(
                            d.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              IconButton(
                                tooltip: 'Abrir',
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => _openUrl(d.url),
                              ),
                              IconButton(
                                tooltip: 'Remover',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeUrl(d.url, isGeo: false),
                              ),
                            ],
                          ),
                        )),
                      if (_docs.isEmpty && !_loadingFiles)
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('— Nenhum arquivo adicionado —',
                                style: TextStyle(color: Colors.black54)),
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
