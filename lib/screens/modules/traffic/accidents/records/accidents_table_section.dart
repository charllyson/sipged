import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class AccidentsTableSection extends StatelessWidget {
  final List<AccidentsData> listData;
  final AccidentsData? selectedItem;
  final void Function(AccidentsData item) onTapItem;
  final void Function(String id) onDelete;
  final void Function(AccidentsData item) onPrint;
  final void Function(AccidentsData item) onPublicLink;

  const AccidentsTableSection({
    super.key,
    required this.listData,
    required this.selectedItem,
    required this.onTapItem,
    required this.onDelete,
    required this.onPrint,
    required this.onPublicLink,
  });

  @override
  Widget build(BuildContext context) {
    return PagedTableChanged<AccidentsData>(
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
        PagedColum<AccidentsData>(
          title: 'QR',
          maxWidth: 56,
          cellBuilder: (d) => IconButton(
            tooltip: d.publicReportIsValid
                ? 'Boletim público (válido)'
                : 'Gerar/abrir boletim público',
            icon: Icon(
              Icons.qr_code,
              color: d.publicReportIsValid ? Colors.green : Colors.blueGrey,
            ),
            onPressed: () => onPublicLink(d),
          ),
        ),
        PagedColum<AccidentsData>(
          title: 'IMPR.',
          maxWidth: 72,
          cellBuilder: (d) => IconButton(
            tooltip: 'Imprimir print',
            icon: const Icon(Icons.confirmation_num),
            onPressed: () => onPrint(d),
          ),
        ),
        PagedColum<AccidentsData>(
          title: 'ORDEM',
          getter: (d) => (d.order ?? '-').toString(),
          textAlign: TextAlign.center,
          maxWidth: 80,
        ),
        PagedColum<AccidentsData>(
          title: 'CIDADE',
          getter: (d) => d.city ?? '-',
          maxWidth: 160,
        ),
        PagedColum<AccidentsData>(
          title: 'TIPO',
          getter: (d) => d.typeOfAccident ?? '-',
          maxWidth: 160,
        ),
        PagedColum<AccidentsData>(
          title: 'DATA',
          getter: (d) {
            final dt = d.date;
            if (dt == null) return '-';
            final dd = dt.day.toString().padLeft(2, '0');
            final mm = dt.month.toString().padLeft(2, '0');
            final yy = dt.year.toString();
            return '$dd/$mm/$yy';
          },
          textAlign: TextAlign.center,
          maxWidth: 120,
        ),
      ],
    );
  }
}