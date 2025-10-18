import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/mask_class.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/screens/process/hiring/5.regularidade/regularidade_controller.dart';

class RegularidadePage extends StatefulWidget {
  final RegularidadeController controller;
  final bool readOnly;

  const RegularidadePage({
    super.key,
    required this.controller,
    this.readOnly = false,
  });

  @override
  State<RegularidadePage> createState() => _RegularidadePageState();
}

class _RegularidadePageState extends State<RegularidadePage>
    with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx,
    itemsPerLine: itemsPerLine,
    spacing: 12,
    margin: 12,
    extraPadding: 24,
  );

  List<String> get _status => const [
    'Válida',
    'Vencida',
    'Em atualização',
    'Dispensada',
    'Não se aplica',
  ];

  @override
  Widget build(BuildContext context) {
    final c = widget.controller..isEditable = !widget.readOnly;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Documentos do Gestor / Habilitação do Fornecedor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // 1) Metadados
          _Section('1) Metadados'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.dgNumeroDossieCtrl,
                labelText: 'Nº do dossiê (interno/SEI)',
                enabled: c.isEditable,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.dgDataMontagemCtrl,
                labelText: 'Data de montagem',
                hintText: 'dd/mm/aaaa',
                enabled: c.isEditable,
                validator: validateRequired,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                  TextInputMask(mask: '99/99/9999'),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: AutocompleteUserClass(
                label: 'Responsável pela checagem',
                controller: c.dgResponsavelCtrl,
                allUsers: users,
                enabled: c.isEditable,
                initialUserId: c.dgResponsavelUserId,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.dgLinksPastaCtrl,
                labelText: 'Link da pasta (SEI/Drive/Storage/PNCP)',
                enabled: c.isEditable,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 2) Empresa / Identificação
          _Section('2) Empresa Contratada / Identificação'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.empRazaoSocialCtrl,
                labelText: 'Razão Social',
                enabled: c.isEditable,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.empCnpjCtrl,
                labelText: 'CNPJ',
                enabled: c.isEditable,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                  TextInputMask(mask: '99.999.999/9999-99'),
                ],
                keyboardType: TextInputType.number,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.empSociosRepresentantesCtrl,
                labelText: 'Sócios/Representantes legais (nome/CPF)',
                maxLines: 2,
                enabled: c.isEditable,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 3) Certidões de Regularidade
          _Section('3) Certidões de Regularidade'),
          _CertidaoCard(
            titulo: 'FGTS (CRF)',
            statusCtrl: c.crfFgtsStatusCtrl,
            validadeCtrl: c.crfFgtsValidadeCtrl,
            linkCtrl: c.crfFgtsLinkCtrl,
            itemsStatus: _status,
            enabled: c.isEditable,
          ),
          const SizedBox(height: 8),
          _CertidaoCard(
            titulo: 'INSS (CND Previdenciária)',
            statusCtrl: c.cndInssStatusCtrl,
            validadeCtrl: c.cndInssValidadeCtrl,
            linkCtrl: c.cndInssLinkCtrl,
            itemsStatus: _status,
            enabled: c.isEditable,
          ),
          const SizedBox(height: 8),
          _CertidaoCard(
            titulo: 'Fazenda Federal (RFB/PGFN)',
            statusCtrl: c.cndFederalStatusCtrl,
            validadeCtrl: c.cndFederalValidadeCtrl,
            linkCtrl: c.cndFederalLinkCtrl,
            itemsStatus: _status,
            enabled: c.isEditable,
          ),
          const SizedBox(height: 8),
          _CertidaoCard(
            titulo: 'Fazenda Estadual',
            statusCtrl: c.cndEstadualStatusCtrl,
            validadeCtrl: c.cndEstadualValidadeCtrl,
            linkCtrl: c.cndEstadualLinkCtrl,
            itemsStatus: _status,
            enabled: c.isEditable,
          ),
          const SizedBox(height: 8),
          _CertidaoCard(
            titulo: 'Fazenda Municipal',
            statusCtrl: c.cndMunicipalStatusCtrl,
            validadeCtrl: c.cndMunicipalValidadeCtrl,
            linkCtrl: c.cndMunicipalLinkCtrl,
            itemsStatus: _status,
            enabled: c.isEditable,
          ),
          const SizedBox(height: 8),
          _CertidaoCard(
            titulo: 'CNDT (Trabalhista)',
            statusCtrl: c.cndtStatusCtrl,
            validadeCtrl: c.cndtValidadeCtrl,
            linkCtrl: c.cndtLinkCtrl,
            itemsStatus: _status,
            enabled: c.isEditable,
          ),
          const SizedBox(height: 16),

          // 4) Habilitação Jurídica / Técnica
          _Section('4) Habilitação Jurídica e Técnica'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.docContratoSocialCtrl,
                labelText: 'Contrato/Estatuto social (link/arquivo)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.docCnpjCartaoCtrl,
                labelText: 'Cartão CNPJ (link/arquivo)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Atestados de capacidade técnica',
                controller: c.docAtestadosStatusCtrl,
                items: const ['Apresentados', 'Parciais', 'Não apresentados', 'Dispensados'],
                onChanged: (v) => setState(() => c.docAtestadosStatusCtrl.text = v ?? ''),
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.docAtestadosLinksCtrl,
                labelText: 'Links/observações dos atestados',
                maxLines: 2,
                enabled: c.isEditable,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 5) Documentos da Licitação/Adesão (ARP/Editais/Atas/Ofícios)
          _Section('5) Documentos da Licitação/Adesão'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Modalidade do processo',
                controller: c.procModalidadeCtrl,
                items: const ['Concorrência', 'Pregão', 'RDC', 'Adesão a ARP', 'Dispensa', 'Inexigibilidade'],
                onChanged: (v) => setState(() => c.procModalidadeCtrl.text = v ?? ''),
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.procNumeroCtrl,
                labelText: 'Nº do processo/edital/ARP',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.procAtaSessaoLinkCtrl,
                labelText: 'Ata da sessão (link/arquivo)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.procAtaAdjudicacaoLinkCtrl,
                labelText: 'Ata de adjudicação (link/arquivo)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.procEditalLinkCtrl,
                labelText: 'Edital/Termo de Adesão (link/arquivo)',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.procOficiosComunicacoesCtrl,
                labelText: 'Ofícios/comunicações (links/arquivos)',
                enabled: c.isEditable,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 6) Consolidação / Parecer do Gestor
          _Section('6) Consolidação e Parecer do Gestor'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Situação da habilitação',
                controller: c.dgSituacaoHabilitacaoCtrl,
                items: const ['Habilitada', 'Habilitada com ressalvas', 'Não habilitada', 'Aguardando complementos'],
                onChanged: (v) => setState(() => c.dgSituacaoHabilitacaoCtrl.text = v ?? ''),
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.dgDataConclusaoCtrl,
                labelText: 'Data da conclusão',
                hintText: 'dd/mm/aaaa',
                enabled: c.isEditable,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                  TextInputMask(mask: '99/99/9999'),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.dgParecerConclusivoCtrl,
                labelText: 'Parecer conclusivo do gestor',
                maxLines: 3,
                enabled: c.isEditable,
              ),
            ),
          ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CertidaoCard extends StatelessWidget {
  final String titulo;
  final TextEditingController statusCtrl;
  final TextEditingController validadeCtrl;
  final TextEditingController linkCtrl;
  final List<String> itemsStatus;
  final bool enabled;

  const _CertidaoCard({
    required this.titulo,
    required this.statusCtrl,
    required this.validadeCtrl,
    required this.linkCtrl,
    required this.itemsStatus,
    required this.enabled,
  });

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx,
    itemsPerLine: itemsPerLine,
    spacing: 12,
    margin: 12,
    extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: enabled,
                labelText: 'Status',
                controller: statusCtrl,
                items: itemsStatus,
                onChanged: (v) => statusCtrl.text = v ?? '',
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: validadeCtrl,
                labelText: 'Validade',
                hintText: 'dd/mm/aaaa',
                enabled: enabled,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                  TextInputMask(mask: '99/99/9999'),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: linkCtrl,
                labelText: 'Link/Arquivo',
                enabled: enabled,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: cs.primary,
        ),
      ),
    );
  }
}
