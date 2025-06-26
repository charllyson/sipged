import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:provider/provider.dart';
import 'package:sisgeo/_blocs/user/user_bloc.dart';
import 'package:sisgeo/_widgets/background/background_cleaner.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import '../../../../_blocs/contracts/contracts_bloc.dart';
import '../../../../_class/archives/pdf/pdf_icon_action.dart';
import '../../../../_class/archives/pdf/web_pdf_viewer.dart';
import '../../../../_datas/contracts/contracts_data.dart';
import '../../../../_datas/user/user_data.dart';
import '../../../../_provider/user/user_provider.dart';
import '../../../../_utils/date_utils.dart';
import '../../../../_utils/responsive_utils.dart';
import '../../../../_widgets/autocomplete/autocomplete_user_class.dart';
import '../../../../_widgets/formats/input_formatters.dart';
import '../../../../_widgets/input/custom_date_field.dart';
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
  late Future<ContractData> _futureContractData;

  final _contractStatusCtrl = TextEditingController();
  final _initialValueOfContractCtrl = TextEditingController();

  final _contractBiddingProcessNumberCtrl = TextEditingController();
  final _contractNumberCtrl = TextEditingController();
  final _contractTypeCtrl = TextEditingController();
  final _contractRegionOfStateCtrl = TextEditingController();

  final _contractServiceCtrl = TextEditingController();
  final _contractHighWayCtrl = TextEditingController();
  final _summarySubjectContractCtrl = TextEditingController();
  final _contractTextKmCtrl = TextEditingController();

  final _datapublicacaodoeCtrl = TextEditingController();
  final _contractCompanyLeaderCtrl = TextEditingController();
  final _contractCompaniesInvolvedCtrl = TextEditingController();

  final _cnoNumberCtrl = TextEditingController();
  final _contractObjectDescriptionCtrl = TextEditingController();
  final _regionalManagerCtrl = TextEditingController();
  final _managerIdCtrl = TextEditingController();

  final _managerPhoneNumberCtrl = TextEditingController();
  final _cpfContractManagerCtrl = TextEditingController();
  final _contractManagerArtNumberCtrl = TextEditingController();

  void setText(TextEditingController ctrl, String? value) {
    ctrl.text = value ?? '';
  }

  String getText(TextEditingController ctrl) {
    return ctrl.text.trim();
  }

  double? getDouble(TextEditingController ctrl) {
    return stringToDouble(ctrl.text.trim());
  }
  final List<String> _contractStatus = [
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
    'MANUTENÇÃO',
    'SINALIZAÇÃO',
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
    _preencherCampos();
    setupValidation([
      _contractStatusCtrl,
      _initialValueOfContractCtrl,

      _contractBiddingProcessNumberCtrl,
      _contractNumberCtrl,
      _contractTypeCtrl,
      _contractRegionOfStateCtrl,

      _contractServiceCtrl,
      _contractHighWayCtrl,
      _summarySubjectContractCtrl,
      _contractTextKmCtrl,

      _datapublicacaodoeCtrl,
      _contractCompanyLeaderCtrl,
      _contractCompaniesInvolvedCtrl,

      _cnoNumberCtrl,
      _contractObjectDescriptionCtrl,
      _regionalManagerCtrl,
      _managerIdCtrl,

      _managerPhoneNumberCtrl,
      _cpfContractManagerCtrl,
      _contractManagerArtNumberCtrl,

    ], _validateForm);
    Provider.of<UserProvider>(context, listen: false).loadAllUsers();
    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user != null) {
      _currentUser = user;
      _isEditable = _userBloc.getUserCreateEditPermissions(userData: user);
    }
  }

  void _validateForm() {
    final valid = areFieldsFilled([
      _contractStatusCtrl,
      _initialValueOfContractCtrl,

      _contractBiddingProcessNumberCtrl,
      _contractNumberCtrl,
      _contractTypeCtrl,
      _contractRegionOfStateCtrl,

      _contractServiceCtrl,
      _contractHighWayCtrl,
      _summarySubjectContractCtrl,
      _contractTextKmCtrl,

      _datapublicacaodoeCtrl,
      _contractCompanyLeaderCtrl,
      _contractCompaniesInvolvedCtrl,

      _cnoNumberCtrl,
      _contractObjectDescriptionCtrl,
      _regionalManagerCtrl,
      _managerIdCtrl,

      _managerPhoneNumberCtrl,
      _cpfContractManagerCtrl,
      _contractManagerArtNumberCtrl,

    ]);

    if (_formValidated != valid) {
      setState(() => _formValidated = valid);
    }
  }

  bool isDisabled(String module) {
    final perms = _currentUser.modulePermissions[module] ?? {};
    return !(perms['create'] ?? false || (perms['edit'] ?? false));
  }

  @override
  void didUpdateWidget(covariant MainInformationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contractData?.id != widget.contractData?.id) {
      _preencherCampos();
    }
  }

  void _preencherCampos() {
    _contractData = widget.contractData;

    setText(_contractStatusCtrl, _contractData?.contractStatus);
    setText(_initialValueOfContractCtrl, priceToString(_contractData?.initialContractValue));

    setText(_contractBiddingProcessNumberCtrl, _contractData?.contractNumberProcess);
    setText(_contractNumberCtrl, _contractData?.contractNumber);
    setText(_contractTypeCtrl, _contractData?.contractType);
    setText(_contractRegionOfStateCtrl, _contractData?.regionOfState);

    setText(_contractServiceCtrl, _contractData?.contractServices);
    setText(_contractHighWayCtrl, _contractData?.mainContractHighway);
    setText(_summarySubjectContractCtrl, _contractData?.summarySubjectContract);
    setText(_contractTextKmCtrl, _contractData?.contractExtKm?.toStringAsFixed(3));

    setText(_datapublicacaodoeCtrl, convertDateTimeToDDMMYYYY(_contractData?.publicationDateDoe));
    setText(_contractCompanyLeaderCtrl, _contractData?.contractCompanyLeader);
    setText(_contractCompaniesInvolvedCtrl, _contractData?.contractCompaniesInvolved);

    setText(_cnoNumberCtrl, _contractData?.cnoNumber?.toString());
    setText(_contractObjectDescriptionCtrl, _contractData?.contractObjectDescription);
    setText(_regionalManagerCtrl, _contractData?.regionalManager);
    setText(_managerIdCtrl, _contractData?.managerId);

    setText(_managerPhoneNumberCtrl, _contractData?.managerPhoneNumber);
    setText(_cpfContractManagerCtrl, _contractData?.cpfContractManager?.toString());
    setText(_contractManagerArtNumberCtrl, _contractData?.contractManagerArtNumber);

  }


  Future<void> _saveInformation() async {
    if (!_formValidated) {
      setState(() => _showErrors = true);
      return;
    }

    _atualizarContractDataDosCampos();

    setState(() => _isSaving = true);
    try {
      await _contractsBloc.salvarOuAtualizarContrato(_contractData!);

      // ✅ Chamar callback se existir
      widget.onSaved?.call(_contractData!);

      // ✅ Atualiza UI com os novos dados
      if (mounted) {
        setState(() {
          _formValidated = false;
          _preencherCampos(); // recarrega os controllers com os novos valores
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrato salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar contrato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _atualizarContractDataDosCampos() {
    _contractData ??= ContractData();

    _contractData!
      ..contractStatus = getText(_contractStatusCtrl)
      ..initialContractValue = getDouble(_initialValueOfContractCtrl)
      ..contractNumberProcess = getText(_contractBiddingProcessNumberCtrl)
      ..contractNumber = getText(_contractNumberCtrl)
      ..contractType = getText(_contractTypeCtrl)
      ..regionOfState = getText(_contractRegionOfStateCtrl)
      ..contractServices = getText(_contractServiceCtrl)
      ..mainContractHighway = getText(_contractHighWayCtrl)
      ..summarySubjectContract = getText(_summarySubjectContractCtrl)
      ..contractExtKm = double.tryParse(getText(_contractTextKmCtrl))
      ..publicationDateDoe = stringToDate(_datapublicacaodoeCtrl.text)
      ..contractCompanyLeader = getText(_contractCompanyLeaderCtrl)
      ..contractCompaniesInvolved = getText(_contractCompaniesInvolvedCtrl)
      ..cnoNumber = getText(_cnoNumberCtrl)
      ..contractObjectDescription = getText(_contractObjectDescriptionCtrl)
      ..regionalManager = getText(_regionalManagerCtrl)
      ..managerId = getText(_managerIdCtrl)
      ..managerPhoneNumber = getText(_managerPhoneNumberCtrl)
      ..cpfContractManager = int.tryParse(_cpfContractManagerCtrl.text.replaceAll(RegExp(r'\D'), ''))
      ..contractManagerArtNumber = getText(_contractManagerArtNumberCtrl);

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
          if (!isValid || _contractData == null) return;
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
                          items: _contractStatus,
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
                          labelText: 'Nº do processo',
                          controller: _contractBiddingProcessNumberCtrl,
                          onChanged: (v) => _contractData?.contractNumberProcess = v,
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
                          controller: _contractNumberCtrl,
                          onChanged: (v) => _contractData?.contractNumber = v,
                          inputFormatters: [contractMaskFormatter],
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          enabled: _isEditable,
                          labelText: 'Valor contratado',
                          controller: _initialValueOfContractCtrl,
                          onChanged: (v) => _contractData?.initialContractValue = stringToDouble(v),
                          inputFormatters: [
                            CurrencyInputFormatter(
                              leadingSymbol: 'R\$',
                              useSymbolPadding: true,
                              thousandSeparator: ThousandSeparator.Period,
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
                      /*SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Avanço financeiro',
                          controller: _financialPercentageCtrl,
                          onChanged: (v) => _contractData?.financialPercentage = removePercentToDouble(v!),
                          inputFormatters: [
                            PercentInputFormatter(mantissaLength: 2),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Avanço físico',
                          controller: _physicalPercentageCtrl,
                          onChanged: (v) => _contractData?.physicalPercentage = removePercentToDouble(v!),
                          inputFormatters: [
                            PercentInputFormatter(mantissaLength: 2),
                          ],
                        ),
                      ),*/
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Resumo do objeto',
                          controller: _summarySubjectContractCtrl,
                          onChanged: (v) => _contractData?.summarySubjectContract = v,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: DropDownButtonChange(
                            validator: validateDropdown,
                            enabled: _isEditable,
                            labelText: 'Tipo de Serviço',
                            items: _typeOfService,
                            controller: _contractServiceCtrl,
                            onChanged: (value) {
                              _contractServiceCtrl.text = value ?? '';
                              _contractData?.contractServices = value;
                            }                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Região',
                          controller: _contractRegionOfStateCtrl,
                          onChanged: (v) => _contractData?.regionOfState = v,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Extensão (km)',
                          controller: _contractTextKmCtrl,
                          onChanged: (v) => _contractData?.contractExtKm = double.tryParse(v!),
                          inputFormatters: [
                            ThreeDecimalTextInputFormatter(decimalDigits: 3),
                          ],
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
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Rodovia',
                          controller: _contractHighWayCtrl,
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
                          labelText: 'Empresa líder',
                          controller: _contractCompanyLeaderCtrl,
                          onChanged: (v) => _contractData?.contractCompanyLeader = v,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Consórcio envolvidas',
                          controller: _contractCompaniesInvolvedCtrl,
                          onChanged: (v) => _contractData?.contractCompaniesInvolved = v,
                        ),
                      ),
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomDateField(
                          initialValue: _contractData?.publicationDateDoe ?? DateTime.now(),
                          validator: validateNoEmptyDate,
                          enabled: _isEditable,
                          labelText: 'Data de publicação do DOE',
                          controller: _datapublicacaodoeCtrl,
                          onChanged: (v) => _contractData?.publicationDateDoe = v,
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
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'Tipo de contrato',
                          controller: _contractTypeCtrl,
                          onChanged: (v) => _contractData?.contractType = v,
                        ),
                      ),
                      /*SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'CNPJ',
                          controller: _cnpjNumberCtrl,
                          onChanged: (value) {
                            final parsed = int.tryParse(value!.replaceAll(RegExp(r'\D'), ''));
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
                      ),*/
                      SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'CNO',
                          controller: _cnoNumberCtrl,
                          onChanged: (v) => _contractData?.cnoNumber = v.toString(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextMaxLinesField(
                          enabled: _isEditable,
                          labelText: 'Descrição do objeto',
                          controller: _contractObjectDescriptionCtrl,
                          maxLines: 5,
                          maxLength: 2000,
                          onChanged: (v) => _contractData?.contractObjectDescription = v,
                          validator: validateRequired,
                        ),
                      ),
                      const SizedBox(width: 12),
                      PdfFileIconActionGeneric(
                        tipo: TipoArquivoPDF.contrato,
                        bloc: _contractsBloc,
                        contrato: widget.contractData!,
                        onUploadSaveToFirestore: (url) async {
                          await _contractsBloc.salvarUrlPdfDoContrato(widget.contractData!.id!, url);
                        },
                      )
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
                        label: 'Gerente Regional',
                        controller: _regionalManagerCtrl,
                        allUsers: Provider.of<UserProvider>(context).userDataList,
                        enabled: _isEditable,
                        initialUserId: _contractData?.regionalManager,
                        onChanged: (id) => _contractData?.regionalManager = id,
                      ),
                      AutocompleteUserClass(
                        label: 'Fiscal da obra',
                        controller: _managerIdCtrl,
                        allUsers: Provider.of<UserProvider>(context).userDataList,
                        initialUserId: _contractData?.managerId,
                        onChanged: (id) => _contractData?.managerId = id,
                        validator: validateRequired,
                        enabled: _isEditable,
                      ),
                     SizedBox(
                        width: responsiveInputsFourPerLine(context),
                        child: CustomTextField(
                          controller: _cpfContractManagerCtrl,
                          validator: validateRequired,
                          enabled: _isEditable,
                          labelText: 'CPF do responsável',
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
      //_financialPercentageCtrl,
      //_physicalPercentageCtrl,
      _initialValueOfContractCtrl,

      _contractBiddingProcessNumberCtrl,
      _contractNumberCtrl,
      _contractTypeCtrl,
      _contractRegionOfStateCtrl,

      _contractServiceCtrl,
      _contractHighWayCtrl,
      _summarySubjectContractCtrl,
      _contractTextKmCtrl,

      _datapublicacaodoeCtrl,
      _contractCompanyLeaderCtrl,
      _contractCompaniesInvolvedCtrl,

      _cnoNumberCtrl,
      _contractObjectDescriptionCtrl,
      _regionalManagerCtrl,
      _managerIdCtrl,

      _managerPhoneNumberCtrl,
      _cpfContractManagerCtrl,
      _contractManagerArtNumberCtrl,

    ], _validateForm);
    _contractStatusCtrl.dispose();
    _initialValueOfContractCtrl.dispose();

    _contractBiddingProcessNumberCtrl.dispose();
    _contractNumberCtrl.dispose();
    _contractTypeCtrl.dispose();
    _contractRegionOfStateCtrl.dispose();

    _contractServiceCtrl.dispose();
    _contractHighWayCtrl.dispose();
    _summarySubjectContractCtrl.dispose();
    _contractTextKmCtrl.dispose();

    _datapublicacaodoeCtrl.dispose();
    _contractCompanyLeaderCtrl.dispose();
    _contractCompaniesInvolvedCtrl.dispose();

    _cnoNumberCtrl.dispose();
    _contractObjectDescriptionCtrl.dispose();
    _regionalManagerCtrl.dispose();
    _managerIdCtrl.dispose();

    _managerPhoneNumberCtrl.dispose();
    _cpfContractManagerCtrl.dispose();
    _contractManagerArtNumberCtrl.dispose();

    super.dispose();
  }
}
