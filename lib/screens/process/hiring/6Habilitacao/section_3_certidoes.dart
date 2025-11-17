import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';
import 'package:siged/screens/process/hiring/6Habilitacao/certidao_card.dart';

class SectionCertidoes extends StatelessWidget {
  final HabilitacaoController controller;
  const SectionCertidoes({super.key, required this.controller});


  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('3) Certidões de Regularidade'),
        CertidaoCard(
          titulo: 'FGTS (CRF)',
          statusCtrl: c.crfFgtsStatusCtrl,
          validadeCtrl: c.crfFgtsValidadeCtrl,
          linkCtrl: c.crfFgtsLinkCtrl,
          itemsStatus: HiringData.tiposCertidoes,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 8),
        CertidaoCard(
          titulo: 'INSS (CND Previdenciária)',
          statusCtrl: c.cndInssStatusCtrl,
          validadeCtrl: c.cndInssValidadeCtrl,
          linkCtrl: c.cndInssLinkCtrl,
          itemsStatus: HiringData.tiposCertidoes,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 8),
        CertidaoCard(
          titulo: 'Fazenda Federal (RFB/PGFN)',
          statusCtrl: c.cndFederalStatusCtrl,
          validadeCtrl: c.cndFederalValidadeCtrl,
          linkCtrl: c.cndFederalLinkCtrl,
          itemsStatus: HiringData.tiposCertidoes,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 8),
        CertidaoCard(
          titulo: 'Fazenda Estadual',
          statusCtrl: c.cndEstadualStatusCtrl,
          validadeCtrl: c.cndEstadualValidadeCtrl,
          linkCtrl: c.cndEstadualLinkCtrl,
          itemsStatus: HiringData.tiposCertidoes,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 8),
        CertidaoCard(
          titulo: 'Fazenda Municipal',
          statusCtrl: c.cndMunicipalStatusCtrl,
          validadeCtrl: c.cndMunicipalValidadeCtrl,
          linkCtrl: c.cndMunicipalLinkCtrl,
          itemsStatus: HiringData.tiposCertidoes,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 8),
        CertidaoCard(
          titulo: 'CNDT (Trabalhista)',
          statusCtrl: c.cndtStatusCtrl,
          validadeCtrl: c.cndtValidadeCtrl,
          linkCtrl: c.cndtLinkCtrl,
          itemsStatus: HiringData.tiposCertidoes,
          enabled: c.isEditable,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
