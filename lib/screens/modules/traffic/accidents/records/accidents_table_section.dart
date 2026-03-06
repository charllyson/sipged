// lib/screens/modules/traffic/accidents/records/accidents_table_section.dart
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class AccidentsTableSection extends StatelessWidget {
  final List<AccidentsData> listData;
  final AccidentsData? selectedItem;
  final void Function(AccidentsData item) onTapItem;
  final void Function(String id) onDelete;

  final void Function(AccidentsData item) onPrint;

  // ✅ novo: gerar/mostrar QR/link público
  final void Function(AccidentsData item) onPublicLink;

  final int currentPage;
  final int totalPages;
  final Future<void> Function(int page) onPageChange;

  const AccidentsTableSection({
    super.key,
    required this.listData,
    required this.selectedItem,
    required this.onTapItem,
    required this.onDelete,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChange,
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
        if (id != null && id.isNotEmpty) onDelete(id);
      },
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChange: onPageChange,
      columns: [
        PagedColumnSpec<AccidentsData>(
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
        PagedColumnSpec<AccidentsData>(
          title: 'IMPR.',
          maxWidth: 72,
          cellBuilder: (d) => IconButton(
            tooltip: 'Imprimir print',
            icon: const Icon(Icons.confirmation_num),
            onPressed: () => onPrint(d),
          ),
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'ORDEM',
          getter: (d) => (d.order ?? '-').toString(),
          textAlign: TextAlign.center,
          maxWidth: 80,
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'CIDADE',
          getter: (d) => d.city ?? '-',
          maxWidth: 160,
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'TIPO',
          getter: (d) => d.typeOfAccident ?? '-',
          maxWidth: 160,
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'DATA',
          getter: (d) => d.date?.toString().split(' ').first ?? '-',
          textAlign: TextAlign.center,
          maxWidth: 120,
        ),
      ],
    );
  }
}