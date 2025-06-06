import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import '../../../../_blocs/contracts/contracts_bloc.dart';
import '../../../../_datas/contracts/contracts_data.dart';
import '../../../../_widgets/input/custom_text_field.dart';
import '../../../../_widgets/input/custom_text_max_lines_field.dart';
import '../../../../_widgets/input/drop_down_botton_change.dart';
import '../validity/validity_page.dart';

class MainInformationPage extends StatefulWidget {
  const MainInformationPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<MainInformationPage> createState() => _MainInformationPageState();
}

class _MainInformationPageState extends State<MainInformationPage> {
  late ContractsBloc _contractsBloc;
  late ContractData _data;
  bool _isSaving = false;
  final List<String> _tiposDeStatus = [
    'A INICIAR',
    'EM ANDAMENTO',
    'CONCLUÍDO',
    'PARALIZADO',
    'CANCELADO',
  ];
  final _statusContratoCtrl = TextEditingController();
  final _dataDoeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();

    final status = widget.contractData?.contractstatus?.toUpperCase().trim();
    _statusContratoCtrl.text = _tiposDeStatus.contains(status) ? status! : '';
    _dataDoeCtrl.text = convertDateTimeToDDMMYYYY(widget.contractData!.datapublicacaodoe!);

    _data = widget.contractData ?? ContractData(contractstatus: _statusContratoCtrl.text);
  }

  Future<void> _salvarInformacoes() async {
    setState(() => _isSaving = true);
    try {
      await _contractsBloc.salvarOuAtualizarContrato(_data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrato salvo com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar contrato: \$e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildField(String label, String? initialValue, void Function(String?)? onChanged, {List<TextInputFormatter>? inputFormatters}) {
    return CustomTextField(
      labelText: label,
      initialValue: initialValue ?? '',
      onChanged: onChanged,
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildFieldReal(String label, String? initialValue, void Function(String?)? onChanged) {
    return CustomTextField(
      labelText: label,
      initialValue: initialValue ?? '',
      onChanged: onChanged,
      inputFormatters: [
        CurrencyInputFormatter(
          leadingSymbol: 'R\$',
          useSymbolPadding: true,
          thousandSeparator: ThousandSeparator.Period,
          mantissaLength: 2,
        ),
      ],
    );
  }

  Widget _buildMultilineField(String label, String? initialValue, void Function(String?)? onChanged) {
    return CustomTextMaxLinesField(
      labelText: label,
      initialValue: initialValue ?? '',
      maxLines: 5,
      maxLength: 500,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text('Informações gerais do contrato', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: DropDownButtonChange(
                      labelText: 'Status do contrato',
                      items: _tiposDeStatus,
                      controller: _statusContratoCtrl,
                      onChanged: (value) => _data.contractstatus = value ?? '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    'Avanço financeiro',
                    _data.financialpercentage != null ? '${_data.financialpercentage!.toStringAsFixed(2)}%' : '',
                        (v) {
                      final raw = v?.replaceAll('%', '').replaceAll(',', '.');
                      final parsed = double.tryParse(raw ?? '');
                      if (parsed != null && parsed <= 100) {
                        _data.financialpercentage = parsed;
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'\d|\.|,')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final text = newValue.text.replaceAll('%', '').replaceAll(',', '.');
                        final value = double.tryParse(text);
                        if (value == null || value > 100) return oldValue;
                        return newValue.copyWith(text: '${value.toStringAsFixed(2)}%');
                      })
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    'Avanço físico',
                    _data.fisicalpercentage != null ? '${_data.fisicalpercentage!.toStringAsFixed(2)}%' : '',
                        (v) {
                      final raw = v?.replaceAll('%', '').replaceAll(',', '.');
                      final parsed = double.tryParse(raw ?? '');
                      if (parsed != null && parsed <= 100) {
                        _data.fisicalpercentage = parsed;
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'\d|\.|,')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final text = newValue.text.replaceAll('%', '').replaceAll(',', '.');
                        final value = double.tryParse(text);
                        if (value == null || value > 100) return oldValue;
                        return newValue.copyWith(text: '${value.toStringAsFixed(2)}%');
                      })
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildField('Nº do processo', _data.contractbiddingprocessnumber, (v) => _data.contractbiddingprocessnumber = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Nº do contrato', _data.contractnumber, (v) => _data.contractnumber = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Tipo de contrato', _data.contracttype, (v) => _data.contracttype = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Região', _data.regionofstate, (v) => _data.regionofstate = v)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildField('Serviço', _data.contractservices, (v) => _data.contractservices = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Rodovia', _data.maincontracthighway, (v) => _data.maincontracthighway = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Resumo do objeto', _data.summarysubjectcontract, (v) => _data.summarysubjectcontract = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Extensão', _data.contractextkm?.toString(), (v) => _data.contractextkm = double.tryParse(v!))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildField('Nº SIAFE', _data.automaticnumbersiafe, (v) => _data.automaticnumbersiafe = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Gerente Regional', _data.regionalmanager, (v) => _data.regionalmanager = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    labelText: 'Data da DOE',
                    controller: _dataDoeCtrl,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TextInputMask(mask: '99/99/9999'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildFieldReal('Valor contratado', priceToString(_data.valorinicialdocontrato), (v) => _data.valorinicialdocontrato = stringToDouble(v))),
              ]),
              const SizedBox(height: 12),
              const Text('Gestor do contrato', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildField('Fiscal', _data.managerid, (v) => _data.managerid = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('CPF do responsável', _data.cpfcontractmanager?.toString(), (v) => _data.cpfcontractmanager = int.tryParse(v!.replaceAll(RegExp(r'[^0-9]'), '')))),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Nº ART', _data.contractmanagerartnumber, (v) => _data.contractmanagerartnumber = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Telefone', _data.managerphonenumber, (v) => _data.managerphonenumber = v)),
              ]),
              const SizedBox(height: 12),
              const Text('Empresa contratada', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildField('CNPJ', _data.cnpjnumber?.toString(), (v) => _data.cnpjnumber = int.tryParse(v!))),
                const SizedBox(width: 12),
                Expanded(child: _buildField('CNO', _data.cnonumber?.toString(), (v) => _data.cnonumber = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Empresa líder', _data.contractcompanyleader, (v) => _data.contractcompanyleader = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Empresas envolvidas', _data.contractcompaniesinvolved, (v) => _data.contractcompaniesinvolved = v)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildMultilineField('Descrição do objeto', _data.contractobjectdescription, (v) => _data.contractobjectdescription = v)),
              ]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _isSaving ? null : _salvarInformacoes,
                    icon: _isSaving ? const CircularProgressIndicator() : const Icon(Icons.save),
                    label: const Text('Salvar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
