import 'package:flutter/material.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_data.dart';
import 'package:siged/screens/process/hiring/6Habilitacao/certidao_card.dart';

class SectionCertidoes extends StatefulWidget {
  final HabilitacaoData data;
  final bool isEditable;
  final void Function(HabilitacaoData updated) onChanged;

  const SectionCertidoes({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionCertidoes> createState() => _SectionCertidoesState();
}

class _SectionCertidoesState extends State<SectionCertidoes> {
  late HabilitacaoData _localData;

  @override
  void initState() {
    super.initState();
    _localData = widget.data;
  }

  @override
  void didUpdateWidget(covariant SectionCertidoes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _localData = widget.data;
    }
  }

  void _updateLocal(HabilitacaoData updated) {
    setState(() {
      _localData = updated;
    });
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final d = _localData;
    final items = HiringData.tiposCertidoes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '3) Certidões de Regularidade'),
        CertidaoCard(
          titulo: 'FGTS (CRF)',
          statusCtrl: TextEditingController(text: d.fgtsStatus ?? ''),
          validadeCtrl:
          TextEditingController(text: d.fgtsValidade ?? ''),
          linkCtrl: TextEditingController(text: d.fgtsLink ?? ''),
          itemsStatus: items,
          enabled: widget.isEditable,
          // Para manter simples, deixamos o Card responsável por emitir onChanged via controller
          // mas se quiser “stateful-free”, o ideal é adaptar CertidaoCard para receber data+onChanged também.
        ),
        const SizedBox(height: 8),
        CertidaoCard(
          titulo: 'INSS (CND Previdenciária)',
          statusCtrl: TextEditingController(text: d.inssStatus ?? ''),
          validadeCtrl:
          TextEditingController(text: d.inssValidade ?? ''),
          linkCtrl: TextEditingController(text: d.inssLink ?? ''),
          itemsStatus: items,
          enabled: widget.isEditable,
        ),
        const SizedBox(height: 8),
        CertidaoCard(
          titulo: 'Fazenda Federal (RFB/PGFN)',
          statusCtrl:
          TextEditingController(text: d.federalStatus ?? ''),
          validadeCtrl:
          TextEditingController(text: d.federalValidade ?? ''),
          linkCtrl:
          TextEditingController(text: d.federalLink ?? ''),
          itemsStatus: items,
          enabled: widget.isEditable,
        ),
        const SizedBox(height: 8),
        CertidaoCard(
          titulo: 'Fazenda Estadual',
          statusCtrl:
          TextEditingController(text: d.estadualStatus ?? ''),
          validadeCtrl:
          TextEditingController(text: d.estadualValidade ?? ''),
          linkCtrl:
          TextEditingController(text: d.estadualLink ?? ''),
          itemsStatus: items,
          enabled: widget.isEditable,
        ),
        const SizedBox(height: 8),
        CertidaoCard(
          titulo: 'Fazenda Municipal',
          statusCtrl:
          TextEditingController(text: d.municipalStatus ?? ''),
          validadeCtrl:
          TextEditingController(text: d.municipalValidade ?? ''),
          linkCtrl:
          TextEditingController(text: d.municipalLink ?? ''),
          itemsStatus: items,
          enabled: widget.isEditable,
        ),
        const SizedBox(height: 8),
        CertidaoCard(
          titulo: 'CNDT (Trabalhista)',
          statusCtrl: TextEditingController(text: d.cndtStatus ?? ''),
          validadeCtrl:
          TextEditingController(text: d.cndtValidade ?? ''),
          linkCtrl: TextEditingController(text: d.cndtLink ?? ''),
          itemsStatus: items,
          enabled: widget.isEditable,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
