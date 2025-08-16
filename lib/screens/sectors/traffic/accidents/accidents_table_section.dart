import 'package:flutter/material.dart';
import 'package:sisged/_widgets/table/paged_table_changed.dart';
import '../../../../_datas/sectors/transit/accidents/accidents_data.dart';
import '../../../../_utils/date_utils.dart';
import '../../../../_widgets/formats/format_field.dart'; // convertDateTimeToDDMMYYYY, hourToString

class AccidentsTableSection extends StatelessWidget {
  final List<AccidentsData> listData;
  final AccidentsData? selectedItem;

  final void Function(AccidentsData item) onTapItem;
  final void Function(String id) onDelete;

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
  });

  @override
  Widget build(BuildContext context) {
    return PagedTableChanged<AccidentsData>(
      // dados e seleção
      listData: listData,
      getKey: (d) => d.id ?? '',
      selectedKey: selectedItem?.id,
      keepSelectionInternally: false, // seleção controlada de fora (controller)

      // ações de linha
      onTapItem: onTapItem,
      onDelete: (d) {
        final id = d.id;
        if (id != null && id.isNotEmpty) onDelete(id);
      },

      // paginação
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChange: onPageChange, // controller.loadPage

      // colunas
      columns: [
        PagedColumnSpec<AccidentsData>(
          title: 'ORDEM',
          getter: (d) => (d.order ?? '-').toString(),
          textAlign: TextAlign.center,
          maxWidth: 100,
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'RODOVIA',
          getter: (d) => d.highway ?? '-',
          textAlign: TextAlign.center,
          maxWidth: 140,
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'DATA',
          getter: (d) => d.date != null ? convertDateTimeToDDMMYYYY(d.date!) : '-',
          textAlign: TextAlign.center,
          maxWidth: 120,
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'HORA',
          getter: (d) => d.date != null ? hourToString(d.date!) : '-',
          textAlign: TextAlign.center,
          maxWidth: 100,
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'CIDADE',
          getter: (d) => d.city ?? '-',
          textAlign: TextAlign.center,
          maxWidth: 160,
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'LOCAL',
          getter: (d) => d.referencePoint ?? '-',
          textAlign: TextAlign.center,
          maxWidth: 200,
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'TIPO DE ACIDENTE',
          getter: (d) => d.typeOfAccident ?? '-',
          textAlign: TextAlign.center,
          maxWidth: 180,
        ),
        PagedColumnSpec<AccidentsData>(
          title: 'VÍTIMAS',
          getter: (d) => (d.scoresVictims ?? 0).toString(),
          textAlign: TextAlign.center,
          maxWidth: 120,
        ),
      ],
    );
  }
}
