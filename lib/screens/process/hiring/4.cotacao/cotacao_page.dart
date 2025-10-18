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
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/screens/process/hiring/4.cotacao/cotacao_controller.dart';

class CotacaoPage extends StatefulWidget {
  final CotacaoController controller;
  final bool readOnly;

  const CotacaoPage({
    super.key,
    required this.controller,
    this.readOnly = false,
  });

  @override
  State<CotacaoPage> createState() => _CotacaoPageState();
}

class _CotacaoPageState extends State<CotacaoPage> with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx,
    itemsPerLine: itemsPerLine,
    spacing: 12,
    margin: 12,
    extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller..isEditable = !widget.readOnly;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pesquisa de Preços / Cotação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // 1) Metadados
          _Section('1) Metadados'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.ctNumeroCtrl,
                labelText: 'Nº da cotação / referência',
                enabled: c.isEditable,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.ctDataAberturaCtrl,
                labelText: 'Data de abertura',
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
              child: CustomTextField(
                controller: c.ctDataEncerramentoCtrl,
                labelText: 'Data de encerramento',
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
              width: _w(context),
              child: AutocompleteUserClass(
                label: 'Responsável pela pesquisa',
                controller: c.ctResponsavelCtrl,
                enabled: c.isEditable,
                allUsers: users,
                initialUserId: c.ctResponsavelUserId,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Metodologia',
                controller: c.ctMetodologiaCtrl,
                items: const ['SINAPI', 'Painel de Preços', 'Cotações diretas', 'Misto'],
                onChanged: (v) => setState(() => c.ctMetodologiaCtrl.text = v ?? ''),
                validator: validateRequired,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 2) Objeto/Itens (resumo)
          _Section('2) Objeto/Itens (resumo)'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.ctObjetoCtrl,
                labelText: 'Objeto/escopo resumido da cotação',
                maxLines: 3,
                enabled: c.isEditable,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.ctUnidadeMedidaCtrl,
                labelText: 'Unidade de medida',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.ctQuantidadeCtrl,
                labelText: 'Quantidade estimada',
                enabled: c.isEditable,
                keyboardType: TextInputType.number,
                //validator: validateNumber,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.ctEspecificacoesCtrl,
                labelText: 'Especificações técnicas relevantes',
                maxLines: 3,
                enabled: c.isEditable,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 3) Fornecedores convidados
          _Section('3) Convite/Divulgação'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Meio de divulgação',
                controller: c.ctMeioDivulgacaoCtrl,
                items: const ['E-mail', 'Portal/Website', 'Telefone', 'Misto'],
                onChanged: (v) => setState(() => c.ctMeioDivulgacaoCtrl.text = v ?? ''),
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.ctFornecedoresConvidadosCtrl,
                labelText: 'Fornecedores convidados (nomes/CNPJ/e-mails)',
                maxLines: 3,
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.ctPrazoRespostaCtrl,
                labelText: 'Prazo para resposta (dd/mm/aaaa hh:mm)',
                enabled: c.isEditable,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 4) Respostas dos fornecedores (até 3 slots simples)
          _Section('4) Respostas dos Fornecedores'),
          _FornecedorCard(
            title: 'Fornecedor 1',
            nomeCtrl: c.f1NomeCtrl,
            cnpjCtrl: c.f1CnpjCtrl,
            valorCtrl: c.f1ValorCtrl,
            dataCtrl: c.f1DataRecebimentoCtrl,
            linkCtrl: c.f1LinkPropostaCtrl,
            enabled: c.isEditable,
          ),
          const SizedBox(height: 8),
          _FornecedorCard(
            title: 'Fornecedor 2',
            nomeCtrl: c.f2NomeCtrl,
            cnpjCtrl: c.f2CnpjCtrl,
            valorCtrl: c.f2ValorCtrl,
            dataCtrl: c.f2DataRecebimentoCtrl,
            linkCtrl: c.f2LinkPropostaCtrl,
            enabled: c.isEditable,
          ),
          const SizedBox(height: 8),
          _FornecedorCard(
            title: 'Fornecedor 3',
            nomeCtrl: c.f3NomeCtrl,
            cnpjCtrl: c.f3CnpjCtrl,
            valorCtrl: c.f3ValorCtrl,
            dataCtrl: c.f3DataRecebimentoCtrl,
            linkCtrl: c.f3LinkPropostaCtrl,
            enabled: c.isEditable,
          ),
          const SizedBox(height: 16),

          // 5) Consolidação / Resultado
          _Section('5) Consolidação e Resultado'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Critério de consolidação',
                controller: c.ctCriterioConsolidacaoCtrl,
                items: const ['Média simples', 'Mediana', 'Menor preço válido', 'Outros'],
                onChanged: (v) => setState(() => c.ctCriterioConsolidacaoCtrl.text = v ?? ''),
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.ctValorConsolidadoCtrl,
                labelText: 'Valor consolidado (R\$)',
                enabled: c.isEditable,
                keyboardType: TextInputType.number,
                //validator: validateNumber,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.ctObservacoesCtrl,
                labelText: 'Observações / exclusões / premissas',
                maxLines: 3,
                enabled: c.isEditable,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 6) Evidências/Anexos
          _Section('6) Evidências/Anexos'),
          CustomTextField(
            controller: c.ctLinksAnexosCtrl,
            labelText: 'Links (SEI, propostas, planilhas, prints do Painel etc.)',
            maxLines: 2,
            enabled: c.isEditable,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FornecedorCard extends StatelessWidget with FormValidationMixin {
  final String title;
  final TextEditingController nomeCtrl;
  final TextEditingController cnpjCtrl;
  final TextEditingController valorCtrl;
  final TextEditingController dataCtrl;
  final TextEditingController linkCtrl;
  final bool enabled;

  _FornecedorCard({
    required this.title,
    required this.nomeCtrl,
    required this.cnpjCtrl,
    required this.valorCtrl,
    required this.dataCtrl,
    required this.linkCtrl,
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
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: cs.primary)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: nomeCtrl,
                labelText: 'Razão/Nome',
                enabled: enabled,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: cnpjCtrl,
                labelText: 'CNPJ',
                enabled: enabled,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                  TextInputMask(mask: '99.999.999/9999-99'),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: valorCtrl,
                labelText: 'Valor cotado (R\$)',
                enabled: enabled,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: dataCtrl,
                labelText: 'Data recebimento',
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
                labelText: 'Link/Arquivo da proposta',
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
