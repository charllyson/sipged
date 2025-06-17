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
import '../../../../_provider/user/user_provider.dart';
import '../../../../_utils/date_utils.dart';
import '../../../../_utils/responsive_utils.dart';
import '../../../../_widgets/autocomplete/autocomplete_user_class.dart';
import '../../../../_widgets/formats/input_formatters.dart';
import '../../../../_widgets/input/custom_text_field.dart';
import '../../../../_widgets/input/custom_text_max_lines_field.dart';
import '../../../../_widgets/input/drop_down_botton_change.dart';
import '../../../../_widgets/mask_class.dart';
import '../../../../_widgets/validates/form_validation_mixin.dart';

class MainInformationPage extends StatefulWidget {
  final void Function(ContractData)? onSaved;
  final ContractData? contractData;

  const MainInformationPage({
    super.key,
    this.contractData,
    this.onSaved,
  });

  @override
  State<MainInformationPage> createState() => _MainInformationPageState();
}

class _MainInformationPageState extends State<MainInformationPage> with FormValidationMixin{
  late ContractsBloc _contractsBloc;
  late UserBloc _userBloc;
  ContractData? _contractData;
  late UserData _currentUser;
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _isEditable = false;
  bool _formValidated = false;
  bool _showErrors = false;

  String? managerId;
  String? contractNumber;
  String? mainContractHighway;

  final _contractStatusCtrl = TextEditingController();
  final _financialCtrl = TextEditingController();
  final _physicalCtrl = TextEditingController();
  final _contractTextKmCtrl = TextEditingController();

  final _contractBiddingProcessNumberCtrl = TextEditingController();
  final _contractNumberCtrl = TextEditingController();
  final _contractManagerArtNumberCtrl = TextEditingController();
  final _summarySubjectContractCtrl = TextEditingController();
  final _regionOfStateCtrl = TextEditingController();
  final _managerPhoneNumberCtrl = TextEditingController();
  final _contractCompanyLeaderCtrl = TextEditingController();
  final _generalNumberCtrl = TextEditingController();
  final _automaticNumberSiafeCtrl = TextEditingController();
  final _regionalManagerCtrl = TextEditingController();
  final _contractObjectDescriptionCtrl = TextEditingController();
  final _contractCompaniesInvolvedCtrl = TextEditingController();
  final _contractTypeCtrl = TextEditingController();
  final _cnoNumberCtrl = TextEditingController();
  final _cnpjNumberCtrl = TextEditingController();
  final _existContractCtrl = TextEditingController();
  final _initialValidityExecutionDaysCtrl = TextEditingController();
  final _initialValidityContractDaysCtrl = TextEditingController();
  final _cpfContractManagerCtrl = TextEditingController();
  final _urlContractPdfCtrl = TextEditingController();
  final _initialValidityExecutionDateCtrl = TextEditingController();
  final _initialValidityContractDateCtrl = TextEditingController();
  final _financialPercentageCtrl = TextEditingController();
  final _physicalPercentageCtrl = TextEditingController();
  final _initialValueOfContractCtrl = TextEditingController();
  final _managerIdCtrl = TextEditingController();
  final _datapublicacaodoeCtrl = TextEditingController();
  final _mainContractHighwayCtrl = TextEditingController();



  final List<String> _typesOfStatus = [
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

    _summarySubjectContractCtrl.text = widget.contractData?.summarySubjectContract ?? '';
    _contractTextKmCtrl.text = widget.contractData?.contractextkm?.toStringAsFixed(3) ?? '';
    _financialCtrl.text = widget.contractData?.financialpercentage?.toStringAsFixed(2) ?? '';
    _physicalCtrl.text = widget.contractData?.physicalPercentage?.toStringAsFixed(2) ?? '';
    _contractTypeCtrl.text = widget.contractData?.contractServices ?? '';
    _contractStatusCtrl.text = _typesOfStatus.contains(status) ? status! : '';
    if (widget.contractData?.datapublicacaodoe != null) {
      _datapublicacaodoeCtrl.text = convertDateTimeToDDMMYYYY(
        widget.contractData!.datapublicacaodoe!,
      );
    }
    _contractBiddingProcessNumberCtrl.text = widget.contractData?.contractBiddingProcessNumber ?? '';
    _contractNumberCtrl.text = widget.contractData?.contractNumber ?? '';
    _contractManagerArtNumberCtrl.text = widget.contractData?.contractManagerArtNumber ?? '';
    _regionOfStateCtrl.text = widget.contractData?.regionOfState ?? '';
    _managerPhoneNumberCtrl.text = widget.contractData?.managerPhoneNumber ?? '';
    _contractCompanyLeaderCtrl.text = widget.contractData?.contractCompanyLeader ?? '';
    _generalNumberCtrl.text = widget.contractData?.generalNumber ?? '';
    _automaticNumberSiafeCtrl.text = widget.contractData?.automaticNumberSiafe ?? '';
    _regionalManagerCtrl.text = widget.contractData?.regionalManager ?? '';
    _contractObjectDescriptionCtrl.text = widget.contractData?.contractObjectDescription ?? '';
    _contractCompaniesInvolvedCtrl.text = widget.contractData?.contractCompaniesInvolved ?? '';
    _contractTypeCtrl.text = widget.contractData?.contractType ?? '';
    _cnoNumberCtrl.text = widget.contractData?.cnoNumber?.toString() ?? '';
    _cnpjNumberCtrl.text = widget.contractData?.cnpjNumber?.toString() ?? '';
    _existContractCtrl.text = widget.contractData?.existContract?.toString() ?? '';
    _initialValidityExecutionDaysCtrl.text = widget.contractData?.initialValidityExecutionDays?.toString() ?? '';
    _initialValidityContractDaysCtrl.text = widget.contractData?.initialValidityContractDays?.toString() ?? '';
    _cpfContractManagerCtrl.text = widget.contractData?.cpfContractManager?.toString() ?? '';
    _urlContractPdfCtrl.text = widget.contractData?.urlContractPdf ?? '';
    if (widget.contractData?.initialvalidityexecutiondate != null) {
      _initialValidityExecutionDateCtrl.text = convertDateTimeToDDMMYYYY(
        widget.contractData!.initialvalidityexecutiondate!,
      );
    }
    if (widget.contractData?.initialvaliditycontractdate != null) {
      _initialValidityContractDateCtrl.text = convertDateTimeToDDMMYYYY(
        widget.contractData!.initialvaliditycontractdate!,
      );
    }
    _financialPercentageCtrl.text = widget.contractData?.financialpercentage?.toStringAsFixed(2) ?? '';
    _physicalPercentageCtrl.text = widget.contractData?.physicalPercentage?.toStringAsFixed(2) ?? '';
    _mainContractHighwayCtrl.text = widget.contractData?.mainContractHighway ?? '';


    setupValidation([
      _contractStatusCtrl,
      _datapublicacaodoeCtrl,
      _contractTypeCtrl,
      _financialCtrl,
      _physicalCtrl,
      _summarySubjectContractCtrl,
      _contractTextKmCtrl,
    ], _validateForm);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).userData;
      if (user != null) {
        _currentUser = user;
        _isEditable = _userBloc.getUserCreateEditPermissions(userData: user);
      }
      _contractData = widget.contractData ?? ContractData(contractStatus: _contractStatusCtrl.text);
      setState(() {});
    });
  }

  void _validateForm() {
    final valid = areFieldsFilled([
      _contractStatusCtrl,
      _datapublicacaodoeCtrl,
      _contractTypeCtrl,
      _financialCtrl,
      _physicalCtrl,
      _summarySubjectContractCtrl,
      _contractTextKmCtrl,
    ], minLength: 1);

    if (_formValidated != valid) {
      setState(() => _formValidated = valid);
    }
  }

  bool isDisabled(String module) {
    final perms = _currentUser.modulePermissions[module] ?? {};
    return !(perms['create'] ?? false || (perms['edit'] ?? false));
  }

  Future<void> _saveInformation() async {
    if (!_formValidated) {
      setState(() => _showErrors = true); // ativa exibição dos erros
      return;
    }

    setState(() => _isSaving = true);
    try {
      _contractData?.datapublicacaodoe = stringToDate(_datapublicacaodoeCtrl.text);
      await _contractsBloc.salvarOuAtualizarContrato(_contractData!);
      widget.onSaved?.call(_contractData!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrato salvo com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar contrato: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_contractData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _isEditable ? Colors.blue.shade300 : Colors.grey.shade400,
        onPressed: (){
          final isValid = _formKey.currentState?.validate() ?? false;
          if (!isValid) return;
          _saveInformation();
        },
        icon: _isSaving
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.save, color: Colors.white),
        label: Text(_isSaving ? 'Salvando...' : 'Salvar', style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          BackgroundCleaner(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
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
                        width: responsiveInputsFourPerLine(context),
                        child: DropDownButtonChange(
                          validator: validateDropdown,
                          enabled: _isEditable,
                          labelText: 'Status do contrato',
                          items: _typesOfStatus,
                          controller: _contractStatusCtrl,
                          onChanged:
                              (value) =>
                                  _contractData?.contractStatus = value,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Avanço financeiro',
                          controller: _financialCtrl,
                          onChanged: (v) {
                            final raw = v?.replaceAll('%', '').replaceAll(',', '.');
                            final parsed = double.tryParse(raw ?? '');
                            if (parsed != null && parsed <= 100) {
                              _contractData?.financialpercentage = parsed;
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
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Avanço físico',
                          controller: _physicalCtrl,
                          onChanged: (v) {
                            final raw = v
                                ?.replaceAll('%', '')
                                .replaceAll(',', '.');
                            final parsed = double.tryParse(raw ?? '');
                            if (parsed != null && parsed <= 100) {
                              _contractData?.physicalPercentage = parsed;
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
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          enabled: _isEditable,
                          labelText: 'Valor contratado',
                          controller: _initialValueOfContractCtrl,
                          onChanged: (v) => _contractData?.valorinicialdocontrato = stringToDouble(v),
                          inputFormatters: [
                            CurrencyInputFormatter(
                              leadingSymbol: 'R\$',
                              useSymbolPadding: true,
                              thousandSeparator: ThousandSeparator.Period,
                              mantissaLength: 2,
                            ),
                          ],
                          validator: validateRequired,
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Nº do processo',
                          initialValue:
                              _contractData?.contractBiddingProcessNumber,
                          onChanged:
                              (v) =>
                                  _contractData?.contractBiddingProcessNumber = v,
                          inputFormatters: [processoMaskFormatter],
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Nº do contrato',
                          initialValue: _contractData?.contractNumber,
                          onChanged: (v) => _contractData?.contractNumber = v,
                          inputFormatters: [contractMaskFormatter],
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Tipo de contrato',
                          initialValue: _contractData?.contractType,
                          onChanged: (v) => _contractData?.contractType = v,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Região',
                          initialValue: _contractData?.regionOfState,
                          onChanged: (v) => _contractData?.regionOfState = v,
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
                        width: responsiveInputsFourPerLine(context),
                        child: DropDownButtonChange(
                          validator: validateDropdown,
                          enabled: _isEditable,
                          labelText: 'Tipo de Serviço',
                          items: _typeOfService,
                          controller: _contractTypeCtrl,
                          onChanged: (v) => _contractData?.contractServices = v,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Rodovia',
                          controller: _mainContractHighwayCtrl,
                          onChanged: (v) => _contractData?.mainContractHighway = v,
                          inputFormatters: [highwayMaskFormatter],
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Resumo do objeto',
                          controller: _summarySubjectContractCtrl,
                          onChanged:
                              (v) => _contractData?.summarySubjectContract = v,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Extensão (km)',
                          controller: _contractTextKmCtrl,
                          onChanged: (v) => _contractData?.contractextkm = double.tryParse(v ?? ''),
                          inputFormatters: [
                            ThreeDecimalTextInputFormatter(decimalDigits: 3),
                          ],
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Data da DOE',
                          controller: _datapublicacaodoeCtrl,
                          keyboardType: TextInputType.datetime,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            TextInputMask(mask: '99/99/9999'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Empresa líder',
                          controller: _contractCompanyLeaderCtrl,
                          onChanged:
                              (v) => _contractData?.contractCompanyLeader = v,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Consórcio envolvidas',
                          controller: _contractCompaniesInvolvedCtrl,
                          onChanged:
                              (v) => _contractData?.contractCompaniesInvolved = v,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'CNPJ',
                          controller: _cnpjNumberCtrl,
                          onChanged: (value) {
                            final parsed = int.tryParse(value!);
                            if (parsed != null) {
                              _contractData?.cnpjNumber = parsed;
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(14),
                            TextInputMask(mask: '99.999.999/9999-99'),
                          ],
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'CNO',
                          controller: _cnoNumberCtrl,
                          onChanged: (v) => _contractData?.cnpjNumber = int.tryParse(v!) ?? 0,
                          keyboardType: TextInputType.number,
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
                        width: responsiveInputsOnePerLine(context),
                        child: CustomTextMaxLinesField(
                          enabled: _isEditable,
                          labelText: 'Descrição do objeto',
                          controller: _contractObjectDescriptionCtrl,
                          maxLines: 5,
                          maxLength: 500,
                          onChanged: (v) => _contractData?.contractObjectDescription = v,
                          validator: validateRequired,
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
                        controller: _regionalManagerCtrl,
                        validator: validateRequired,
                        enabled: _isEditable,
                        allUsers: Provider.of<UserProvider>(context).userDataList,
                        getValue: () => _contractData?.regionalManager,
                        setValue: (id) => _contractData?.regionalManager = id,
                        label: 'Gerente Regional',
                      ),
                      AutocompleteUserClass(
                        controller: _managerIdCtrl,
                        validator: validateRequired,
                        enabled: _isEditable,
                        allUsers: Provider.of<UserProvider>(context).userDataList,
                        getValue: () => _contractData?.managerId,
                        setValue: (id) => _contractData?.managerId = id,
                        label: 'Fical da obra',
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'CPF do responsável',
                          controller: _cpfContractManagerCtrl,
                          onChanged: (v) =>
                          _contractData?.cpfContractManager =
                              int.tryParse(v?.replaceAll(RegExp(r'\D'), '') ?? ''),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                            TextInputMask(mask: '999.999.999-99'),
                          ],
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Nº ART',
                          controller: _contractManagerArtNumberCtrl,
                          onChanged:
                              (v) => _contractData?.contractManagerArtNumber = v,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Telefone',
                          controller: _managerPhoneNumberCtrl,
                          onChanged: (v) => _contractData?.managerPhoneNumber = v,
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
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Nº SIAFE',
                          controller: _automaticNumberSiafeCtrl,
                          onChanged:
                              (v) => _contractData?.automaticNumberSiafe = v,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    removeValidation([
      _contractStatusCtrl,
      _financialCtrl,
      _physicalCtrl,
    ], _validateForm);
    _contractStatusCtrl.dispose();
    _financialCtrl.dispose();
    _physicalCtrl.dispose();
    super.dispose();
  }
}
