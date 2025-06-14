import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:provider/provider.dart';
import 'package:sisgeo/_blocs/user/user_bloc.dart';
import 'package:sisgeo/_widgets/background/background_cleaner.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import '../../../../_blocs/contracts/contracts_bloc.dart';
import '../../../../_datas/contracts/contracts_data.dart';
import '../../../../_datas/user/user_data.dart';
import '../../../../_models/user/user_model.dart';
import '../../../../_widgets/autocomplete/autocomplete_user_class.dart';
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
  late UserBloc _userBloc;
  late ContractData _contractData;
  bool _isSaving = false;
  final _statusContratoCtrl = TextEditingController();
  final _dataDoeCtrl = TextEditingController();
  final _typeOfServiceCtrl = TextEditingController();

  final List<String> _tiposDeStatus = [
    'A INICIAR',
    'EM ANDAMENTO',
    'CONCLUÍDO',
    'PARALIZADO',
    'CANCELADO',
  ];

  final List<String> _typeOfService = [
    'IMPLANTAÇÃO',
    'PAVIMENTAÇÃO',
    'IMPLANTAÇÃO E PAVIMENTAÇÃO',
    'RESTAURAÇÃO',
    'DUPLICAÇÃO',
    'CONSTRUÇÃO',
    'REABILITAÇÃO',
    'GERENCIAMENTO',
    'SUPERVISÃO',
    'FISCALIZAÇÃO',
    'ELABORAÇÃO DE PROJETO',
  ];

  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    _userBloc = UserBloc();
    _userBloc.getAllUsers(context);
    final status = widget.contractData?.contractStatus?.toUpperCase().trim();
    _statusContratoCtrl.text = _tiposDeStatus.contains(status) ? status! : '';

    if (widget.contractData?.datapublicacaodoe != null) {
      _dataDoeCtrl.text = convertDateTimeToDDMMYYYY(
        widget.contractData!.datapublicacaodoe!,
      );
    }

    _contractData =
        widget.contractData ??
        ContractData(contractStatus: _statusContratoCtrl.text);
  }

  double getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const spacing = 12.0;
    const margin = 8;
    const horizontalPadding = 32.0; // somando os dois lados (Padding 16 + 16)

    if (screenWidth < 600) {
      return screenWidth - margin * 2 - horizontalPadding; // 1 por linha
    } else if (screenWidth < 900) {
      return (screenWidth - margin * 2 - spacing * 1 - horizontalPadding) /
          2; // 2 por linha
    } else if (screenWidth < 1300) {
      return (screenWidth - margin * 2 - spacing * 2 - horizontalPadding) /
          3; // 3 por linha
    } else {
      return (screenWidth - margin * 2 - spacing * 3 - horizontalPadding) /
          4; // 4 por linha
    }
  }

  DateTime? stringToDate(String input) {
    final parts = input.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  Future<void> _salvarInformacoes() async {
    setState(() => _isSaving = true);
    try {
      _contractData.datapublicacaodoe = stringToDate(_dataDoeCtrl.text);

      await _contractsBloc.salvarOuAtualizarContrato(_contractData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrato salvo com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar contrato: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildFieldReal(
    String label,
    String? initialValue,
    void Function(String?)? onChanged,
  ) {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final larguraShapefile = 300.0;
    final larguraTotalDisponivel = screenWidth - 32 - 12; // padding + spacing
    final larguraDescricao = larguraTotalDisponivel > larguraShapefile + 100
        ? larguraTotalDisponivel - larguraShapefile
        : larguraTotalDisponivel;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade300,
        onPressed: _isSaving ? null : _salvarInformacoes,
        icon:
            _isSaving
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _isSaving ? 'Salvando...' : 'Salvar',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          BackgroundCleaner(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informações gerais do contrato',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: DropDownButtonChange(
                        labelText: 'Status do contrato',
                        items: _tiposDeStatus,
                        controller: _statusContratoCtrl,
                        onChanged:
                            (value) =>
                                _contractData.contractStatus = value ?? '',
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Avanço financeiro',
                        initialValue: _contractData.financialpercentage
                            ?.toStringAsFixed(2),
                        onChanged: (v) {
                          final raw = v
                              ?.replaceAll('%', '')
                              .replaceAll(',', '.');
                          final parsed = double.tryParse(raw ?? '');
                          if (parsed != null && parsed <= 100) {
                            _contractData.financialpercentage = parsed;
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'\d|\.|,')),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final text = newValue.text
                                .replaceAll('%', '')
                                .replaceAll(',', '.');
                            final value = double.tryParse(text);
                            if (value == null || value > 100) return oldValue;
                            return newValue.copyWith(
                              text: '${value.toStringAsFixed(2)}%',
                            );
                          }),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Avanço físico',
                        initialValue: _contractData.physicalPercentage
                            ?.toStringAsFixed(2),
                        onChanged: (v) {
                          final raw = v
                              ?.replaceAll('%', '')
                              .replaceAll(',', '.');
                          final parsed = double.tryParse(raw ?? '');
                          if (parsed != null && parsed <= 100) {
                            _contractData.physicalPercentage = parsed;
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'\d|\.|,')),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final text = newValue.text
                                .replaceAll('%', '')
                                .replaceAll(',', '.');
                            final value = double.tryParse(text);
                            if (value == null || value > 100) return oldValue;
                            return newValue.copyWith(
                              text: '${value.toStringAsFixed(2)}%',
                            );
                          }),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: _buildFieldReal(
                        'Valor contratado',
                        priceToString(_contractData.valorinicialdocontrato),
                        (v) =>
                            _contractData
                                .valorinicialdocontrato = stringToDouble(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Nº do processo',
                        initialValue:
                            _contractData.contractBiddingProcessNumber,
                        onChanged:
                            (v) =>
                                _contractData.contractBiddingProcessNumber = v,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Nº do contrato',
                        initialValue: _contractData.contractNumber,
                        onChanged: (v) => _contractData.contractNumber = v,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Tipo de contrato',
                        initialValue: _contractData.contractType,
                        onChanged: (v) => _contractData.contractType = v,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Região',
                        initialValue: _contractData.regionOfState,
                        onChanged: (v) => _contractData.regionOfState = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: DropDownButtonChange(
                        labelText: 'Tipo de Serviço',
                        items: _typeOfService,
                        controller: _typeOfServiceCtrl,
                        onChanged: (v) => _contractData.contractServices = v,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Rodovia',
                        initialValue: _contractData.mainContractHighway,
                        onChanged: (v) => _contractData.mainContractHighway = v,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Resumo do objeto',
                        initialValue: _contractData.summarySubjectContract,
                        onChanged:
                            (v) => _contractData.summarySubjectContract = v,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Extensão (km)',
                        initialValue: _contractData.contractextkm
                            ?.toStringAsFixed(3),
                        onChanged:
                            (v) =>
                                _contractData.contractextkm = double.tryParse(
                                  v ?? '',
                                ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: getResponsiveWidth(context),
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: larguraDescricao,
                      child: CustomTextMaxLinesField(
                        labelText: 'Descrição do objeto',
                        initialValue: _contractData.contractObjectDescription ?? '',
                        maxLines: 5,
                        maxLength: 500,
                        onChanged: (v) => _contractData.contractObjectDescription = v,
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gestor do contrato',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AutocompleteUserClass(
                      allUsers: Provider.of<UserProvider>(context).userDataList,
                      getValue: () => _contractData.regionalManager,
                      setValue: (id) => _contractData.regionalManager = id,
                      label: 'Gerente Regional',
                    ),
                    AutocompleteUserClass(
                      allUsers: Provider.of<UserProvider>(context).userDataList,
                      getValue: () => _contractData.managerId,
                      setValue: (id) => _contractData.managerId = id,
                      label: 'Fical da obra',
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'CPF do responsável',
                        initialValue:
                        _contractData.cpfContractManager?.toString(),
                        onChanged:
                            (v) =>
                        _contractData.cpfContractManager =
                        v?.replaceAll(RegExp(r'\D'), '') as int?,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                          TextInputMask(mask: '999.999.999-99'),
                        ],
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Nº ART',
                        initialValue: _contractData.contractManagerArtNumber,
                        onChanged:
                            (v) => _contractData.contractManagerArtNumber = v,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Telefone',
                        initialValue: _contractData.managerPhoneNumber,
                        onChanged: (v) => _contractData.managerPhoneNumber = v,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                          TextInputMask(mask: '(99) 99999-9999'),
                        ],
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Informações financeiras',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Nº SIAFE',
                        initialValue: _contractData.automaticNumberSiafe,
                        onChanged:
                            (v) => _contractData.automaticNumberSiafe = v,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Empresa contratada',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'CNPJ',
                        initialValue: _contractData.cnpjNumber?.toString(),
                        onChanged:
                            (v) =>
                                _contractData.cnpjNumber =
                                    v?.replaceAll(RegExp(r'\D'), '') as int?,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(14),
                          TextInputMask(mask: '99.999.999/9999-99'),
                        ],
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'CNO',
                        initialValue: _contractData.cnoNumber?.toString(),
                        onChanged: (v) => _contractData.cnoNumber = v,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Empresa líder',
                        initialValue: _contractData.contractCompanyLeader,
                        onChanged:
                            (v) => _contractData.contractCompanyLeader = v,
                      ),
                    ),
                    SizedBox(
                      width: getResponsiveWidth(context),
                      child: CustomTextField(
                        labelText: 'Empresas envolvidas',
                        initialValue: _contractData.contractCompaniesInvolved,
                        onChanged:
                            (v) => _contractData.contractCompaniesInvolved = v,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
