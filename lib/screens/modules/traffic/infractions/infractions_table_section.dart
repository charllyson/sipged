import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/transit/infractions/infractions_data.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class InfractionsTableSection extends StatelessWidget {
  final List<InfractionsData> listData;
  final InfractionsData? selectedItem;
  final void Function(InfractionsData item) onTapItem;
  final void Function(String id) onDelete;

  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPageChanged;

  const InfractionsTableSection({
    super.key,
    required this.listData,
    required this.selectedItem,
    required this.onTapItem,
    required this.onDelete,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';

    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString();

    return '$dd/$mm/$yy';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';

    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');

    return '$hh:$mi';
  }

  String _formatCoord(double? value) {
    if (value == null) return '';

    return value.toStringAsFixed(6);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PagedTableChanged<InfractionsData>(
          listData: listData,
          getKey: (d) => d.id ?? '',
          selectedKey: selectedItem?.id,
          keepSelectionInternally: false,
          onTapItem: onTapItem,
          onDelete: (d) {
            final id = d.id;

            if (id != null && id.isNotEmpty) {
              onDelete(id);
            }
          },
          columns: [
            PagedColum<InfractionsData>(
              title: 'AIT',
              getter: (d) => d.aitNumber ?? '',
              textAlign: TextAlign.center,
              maxWidth: 120,
            ),
            PagedColum<InfractionsData>(
              title: 'DATA',
              getter: (d) => _formatDate(d.dateInfraction),
              textAlign: TextAlign.center,
              maxWidth: 110,
            ),
            PagedColum<InfractionsData>(
              title: 'HORA',
              getter: (d) => _formatTime(d.dateInfraction),
              textAlign: TextAlign.center,
              maxWidth: 90,
            ),
            PagedColum<InfractionsData>(
              title: 'CÓDIGO',
              getter: (d) => d.codeInfraction ?? '',
              textAlign: TextAlign.center,
              maxWidth: 110,
            ),
            PagedColum<InfractionsData>(
              title: 'DESCRIÇÃO',
              getter: (d) => d.descriptionInfraction ?? '',
              maxWidth: 260,
            ),
            PagedColum<InfractionsData>(
              title: 'ÓRGÃO',
              getter: (d) => d.organCode ?? '',
              textAlign: TextAlign.center,
              maxWidth: 120,
            ),
            PagedColum<InfractionsData>(
              title: 'AUTORIDADE',
              getter: (d) => d.organAuthority ?? '',
              textAlign: TextAlign.center,
              maxWidth: 160,
            ),
            PagedColum<InfractionsData>(
              title: 'ENDEREÇO',
              getter: (d) => d.addressInfraction ?? '',
              maxWidth: 260,
            ),
            PagedColum<InfractionsData>(
              title: 'BAIRRO',
              getter: (d) => d.bairro ?? '',
              textAlign: TextAlign.center,
              maxWidth: 140,
            ),
            PagedColum<InfractionsData>(
              title: 'LATITUDE',
              getter: (d) => _formatCoord(d.latitude),
              textAlign: TextAlign.center,
              maxWidth: 120,
            ),
            PagedColum<InfractionsData>(
              title: 'LONGITUDE',
              getter: (d) => _formatCoord(d.longitude),
              textAlign: TextAlign.center,
              maxWidth: 120,
            ),
          ],
        ),
        if (onPageChanged != null && totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: currentPage <= 1
                      ? null
                      : () => onPageChanged!(currentPage - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  'Página $currentPage de $totalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: 'Próxima página',
                  onPressed: currentPage >= totalPages
                      ? null
                      : () => onPageChanged!(currentPage + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}