import 'package:flutter/material.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';
import '../../../../_blocs/modules/transit/infractions/infractions_data.dart';

class InfractionsTableSection extends StatelessWidget {
  final List<InfractionsData> listData;
  final InfractionsData? selectedItem;
  final void Function(InfractionsData item) onTapItem;
  final void Function(String id) onDelete;

  const InfractionsTableSection({
    super.key,
    required this.listData,
    required this.selectedItem,
    required this.onTapItem,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PagedTableChanged<InfractionsData>(
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
        PagedColum<InfractionsData>(
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
          getter: (d) => d.latitude?.toString() ?? '',
          textAlign: TextAlign.center,
          maxWidth: 120,
        ),
        PagedColum<InfractionsData>(
          title: 'LONGITUDE',
          getter: (d) => d.longitude?.toString() ?? '',
          textAlign: TextAlign.center,
          maxWidth: 120,
        ),
      ],
    );
  }
}