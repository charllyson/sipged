import 'package:flutter/material.dart';
import 'package:sisged/_widgets/table/paged_table_changed.dart';
import '../../../../_blocs/sectors/transit/infractions/infractions_data.dart';

class InfractionsTableSection extends StatelessWidget {
  final List<InfractionsData> listData;
  final InfractionsData? selectedItem;

  final void Function(InfractionsData item) onTapItem;
  final void Function(String id) onDelete;

  final int currentPage;
  final int totalPages;
  final Future<void> Function(int page) onPageChange;

  const InfractionsTableSection({
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
    return PagedTableChanged<InfractionsData>(
      // dados e seleção
      listData: listData,
      getKey: (d) => d.id ?? '',
      selectedKey: selectedItem?.id,          // mantém a linha “clicada” em verde
      keepSelectionInternally: false,         // seleção controlada de fora

      // ações
      onTapItem: onTapItem,
      onDelete: (d) {
        final id = d.id;
        if (id != null && id.isNotEmpty) onDelete(id);
      },

      // paginação
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChange: (p) async => onPageChange(p),

      // colunas (alinhadas ao seu modelo)
      columns: [
        PagedColumnSpec<InfractionsData>(
          title: 'AIT',
          getter: (d) => (d.aitNumber ?? ''),
          textAlign: TextAlign.center,
          maxWidth: 120,
        ),
        PagedColumnSpec<InfractionsData>(
          title: 'DATA',
          getter: (d) {
            final dt = d.dateInfraction;
            if (dt == null) return '';
            final dd = dt.day.toString().padLeft(2, '0');
            final mm = dt.month.toString().padLeft(2, '0');
            final yy = dt.year.toString();
            return '$dd/$mm/$yy';
          },
          textAlign: TextAlign.center,
          maxWidth: 110,
        ),
        PagedColumnSpec<InfractionsData>(
          title: 'HORA',
          getter: (d) {
            final dt = d.dateInfraction;
            if (dt == null) return '';
            final hh = dt.hour.toString().padLeft(2, '0');
            final mi = dt.minute.toString().padLeft(2, '0');
            return '$hh:$mi';
          },
          textAlign: TextAlign.center,
          maxWidth: 90,
        ),
        PagedColumnSpec<InfractionsData>(
          title: 'CÓDIGO',
          getter: (d) => (d.codeInfraction ?? ''),
          textAlign: TextAlign.center,
          maxWidth: 110,
        ),
        PagedColumnSpec<InfractionsData>(
          title: 'DESCRIÇÃO',
          getter: (d) => (d.descriptionInfraction ?? ''),
          maxWidth: 260,
        ),
        PagedColumnSpec<InfractionsData>(
          title: 'ÓRGÃO',
          getter: (d) => (d.organCode ?? ''),
          textAlign: TextAlign.center,
          maxWidth: 120,
        ),
        PagedColumnSpec<InfractionsData>(
          title: 'AUTORIDADE',
          getter: (d) => (d.organAuthority ?? ''),
          textAlign: TextAlign.center,
          maxWidth: 160,
        ),
        PagedColumnSpec<InfractionsData>(
          title: 'ENDEREÇO',
          getter: (d) => (d.addressInfraction ?? ''),
          maxWidth: 260,
        ),
        PagedColumnSpec<InfractionsData>(
          title: 'BAIRRO',
          getter: (d) => (d.bairro ?? ''),
          textAlign: TextAlign.center,
          maxWidth: 140,
        ),
        PagedColumnSpec<InfractionsData>(
          title: 'LATITUDE',
          getter: (d) => (d.latitude ?? '').toString(),
          textAlign: TextAlign.center,
          maxWidth: 120,
        ),
        PagedColumnSpec<InfractionsData>(
          title: 'LONGITUDE',
          getter: (d) => (d.longitude ?? '').toString(),
          textAlign: TextAlign.center,
          maxWidth: 120,
        ),
      ],
    );
  }
}
