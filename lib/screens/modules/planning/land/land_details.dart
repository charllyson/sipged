/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_utils/formats/sipged_format_numbers.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/planning/land/land_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/land_data.dart';
import 'package:sipged/_blocs/modules/planning/land/land_state.dart';

class LandDetails extends StatelessWidget {
  final ProcessData contract;
  final String propertyId;

  const LandDetails({
    super.key,
    required this.contract,
    required this.propertyId,
  });

  String _fmtDouble(double? v, {int fractionDigits = 2}) {
    if (v == null) return '-';
    return SipGedFormatNumbers.decimalPtBr(v, fractionDigits: fractionDigits);
  }

  String _fmtMoney(double? v) {
    if (v == null) return '-';
    return SipGedFormatMoney.doubleToText(v);
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _card(BuildContext context, Widget child) {
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
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing,
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

  LandData? _findItem(LandState state) {
    try {
      return state.items.firstWhere((e) => e.id == propertyId);
    } catch (_) {
      if (state.draft.id == propertyId) return state.draft;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LandCubit, LandState>(
      builder: (context, state) {
        final item = _findItem(state);

        if (item == null || item.id == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            const BackgroundChange(),
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _card(
                  context,
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
                                (item.ownerName?.trim().isNotEmpty ?? false)
                                    ? item.ownerName!
                                    : 'Proprietário não informado',
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
                                  _chip('CPF/CNPJ', item.cpfCnpj ?? '-'),
                                  _chip('Tipo', item.propertyType ?? '-'),
                                  _chip('Status', item.status ?? '-'),
                                  _chip('Município', item.city ?? '-'),
                                  _chip('UF', item.state ?? '-'),
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
                _card(
                  context,
                  Column(
                    children: [
                      _tile(
                        icon: Icons.gavel_outlined,
                        title: 'Matrícula / Cartório',
                        subtitle:
                        'Matrícula: ${item.registryNumber ?? '-'}\n'
                            'Cartório: ${item.registryOffice ?? '-'}\n'
                            'Endereço/Descrição: ${item.address ?? '-'}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  context,
                  Column(
                    children: [
                      _tile(
                        icon: Icons.description_outlined,
                        title: 'Processo',
                        subtitle: item.processNumber ?? '-',
                      ),
                      const Divider(height: 0),
                      _tile(
                        icon: Icons.mail_outline,
                        title: 'Notificação',
                        subtitle: item.notificationDate == null
                            ? '-'
                            : SipGedFormatDates.dateToDdMMyyyy(
                          item.notificationDate!,
                        ),
                      ),
                      const Divider(height: 0),
                      _tile(
                        icon: Icons.search_outlined,
                        title: 'Vistoria',
                        subtitle: item.inspectionDate == null
                            ? '-'
                            : SipGedFormatDates.dateToDdMMyyyy(
                          item.inspectionDate!,
                        ),
                      ),
                      const Divider(height: 0),
                      _tile(
                        icon: Icons.handshake_outlined,
                        title: 'Acordo/Indenização',
                        subtitle: item.agreementDate == null
                            ? '-'
                            : SipGedFormatDates.dateToDdMMyyyy(
                          item.agreementDate!,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  context,
                  Column(
                    children: [
                      _tile(
                        icon: Icons.square_foot_outlined,
                        title: 'Áreas (m²)',
                        subtitle:
                        'Total: ${_fmtDouble(item.totalArea)} | '
                            'Afetada: ${_fmtDouble(item.affectedArea)}',
                      ),
                      const Divider(height: 0),
                      _tile(
                        icon: Icons.payments_outlined,
                        title: 'Indenização (R\$)',
                        subtitle: _fmtMoney(item.indemnityValue),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  context,
                  Column(
                    children: [
                      _tile(
                        icon: Icons.phone_outlined,
                        title: 'Contato',
                        subtitle:
                        'Telefone: ${item.phone ?? '-'}\n'
                            'E-mail: ${item.email ?? '-'}',
                      ),
                      if ((item.notes?.trim().isNotEmpty ?? false)) ...[
                        const Divider(height: 0),
                        _tile(
                          icon: Icons.sticky_note_2_outlined,
                          title: 'Observações',
                          subtitle: item.notes!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  context,
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.map_outlined),
                        title: const Text('Georreferenciados'),
                        subtitle: Text(
                          item.geoAttachments.isEmpty
                              ? 'Nenhum arquivo'
                              : '${item.geoAttachments.length} arquivo(s)',
                        ),
                      ),
                      const Divider(height: 0),
                      if (item.geoAttachments.isEmpty)
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
                      ...item.geoAttachments.map(
                            (g) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(g.label, overflow: TextOverflow.ellipsis),
                          subtitle: Text(g.id, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            tooltip: 'Abrir',
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => _openUrl(g.url),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  context,
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf_outlined),
                        title: const Text('Documentos (PDF)'),
                        subtitle: Text(
                          item.docAttachments.isEmpty
                              ? 'Nenhum arquivo'
                              : '${item.docAttachments.length} arquivo(s)',
                        ),
                      ),
                      const Divider(height: 0),
                      if (item.docAttachments.isEmpty)
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
                      ...item.docAttachments.map(
                            (d) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(d.label, overflow: TextOverflow.ellipsis),
                          subtitle: Text(d.id, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            tooltip: 'Abrir',
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => _openUrl(d.url),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}*/
