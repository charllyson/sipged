import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/formats/format_field.dart';

import '../../../../../_provider/user/user_provider.dart';
import '../../../../../_datas/system/user_data.dart';

import '../../../../_blocs/documents/contracts/contracts/contracts_bloc.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';

class MainInformationController extends ChangeNotifier {
  // ==== Injeções ====
  final ContractsBloc contractsBloc;
  final UserBloc userBloc;

  /// Chave do módulo usada para checar permissões em `user.modulePermissions[moduleKey]`
  final String moduleKey;

  /// Se informado, força o estado de edição (ignora permissões)
  final bool? forceEditable;

  MainInformationController({
    required this.contractsBloc,
    required this.userBloc,
    this.moduleKey = 'contracts',
    this.forceEditable,
  });

  // ==== Estado geral ====
  final formKey = GlobalKey<FormState>();
  bool isSaving = false;
  bool isEditable = false;
  bool showErrors = false;

  ContractData contractData = ContractData();
  UserData? _currentUser;

  // ==== Controllers de texto ====
  final contractStatusCtrl = TextEditingController();
  final initialValueOfContractCtrl = TextEditingController();

  final contractBiddingProcessNumberCtrl = TextEditingController();
  final contractNumberCtrl = TextEditingController();
  final contractServiceTypeCtrl = TextEditingController();
  final contractRegionOfStateCtrl = TextEditingController();

  final contractTypeCtrl = TextEditingController();
  final contractHighWayCtrl = TextEditingController();
  final summarySubjectContractCtrl = TextEditingController();
  final contractTextKmCtrl = TextEditingController();

  final datapublicacaodoeCtrl = TextEditingController();
  final contractCompanyLeaderCtrl = TextEditingController();
  final contractCompaniesInvolvedCtrl = TextEditingController();

  final cnoNumberCtrl = TextEditingController();
  final contractObjectDescriptionCtrl = TextEditingController();
  final regionalManagerCtrl = TextEditingController();
  final managerIdCtrl = TextEditingController();

  final managerPhoneNumberCtrl = TextEditingController();
  final cpfContractManagerCtrl = TextEditingController();
  final contractManagerArtNumberCtrl = TextEditingController();

  final initialValidityExecutionDaysCtrl = TextEditingController();
  final initialValidityContractDaysCtrl = TextEditingController();

  // ==== Getters auxiliares ====
  bool get isBtnEnabled => isEditable && !isSaving;

  /// Desabilita um módulo caso não tenha create/edit; protege nulo.
  bool isDisabled(String module) {
    final perms = _currentUser?.modulePermissions[module] ?? {};
    return !(perms['create'] == true || perms['edit'] == true);
  }

  // ==== Ciclo de vida ====
  /// Chame no pós-frame do initState da página.
  Future<void> init(BuildContext context, {ContractData? initial}) async {
    // Carrega usuários
    await Provider.of<UserProvider>(context, listen: false).loadAllUsers();

    // Pega usuário atual
    _currentUser = Provider.of<UserProvider>(context, listen: false).userData;

    // Define se pode editar
    if (forceEditable != null) {
      isEditable = forceEditable!;
    } else if (_currentUser != null) {
      // Se quiser usar o UserBloc:
      // isEditable = userBloc.getUserCreateEditPermissions(userData: _currentUser!);
      // Ou diretamente do modulePermissions:
      final perms = _currentUser!.modulePermissions[moduleKey] ?? {};
      isEditable = (perms['create'] == true) || (perms['edit'] == true);
    } else {
      // Fallback: permitir edição durante criação (sem id)
      isEditable = (initial?.id == null);
    }

    contractData = initial ?? ContractData();
    _preencherCampos();
    notifyListeners();
  }

  // ==== Helpers internos ====
  void _setText(TextEditingController c, String? v) => c.text = v ?? '';
  String _getText(TextEditingController c) => c.text.trim();
  double? _getDouble(TextEditingController c) => stringToDouble(c.text.trim());

  // ==== Sincronização Data <-> Controllers ====
  void _preencherCampos() {
    _setText(contractStatusCtrl, contractData.contractStatus);
    _setText(initialValueOfContractCtrl, priceToString(contractData.initialValueContract));

    _setText(contractBiddingProcessNumberCtrl, contractData.contractNumberProcess);
    _setText(contractNumberCtrl, contractData.contractNumber);
    _setText(contractServiceTypeCtrl, contractData.contractServices);
    _setText(contractTypeCtrl, contractData.contractType);
    _setText(contractRegionOfStateCtrl, contractData.regionOfState);

    _setText(contractHighWayCtrl, contractData.mainContractHighway);
    _setText(summarySubjectContractCtrl, contractData.summarySubjectContract);
    _setText(contractTextKmCtrl, contractData.contractExtKm?.toStringAsFixed(3));

    _setText(datapublicacaodoeCtrl, convertDateTimeToDDMMYYYY(contractData.publicationDateDoe));
    _setText(contractCompanyLeaderCtrl, contractData.companyLeader);
    _setText(contractCompaniesInvolvedCtrl, contractData.contractCompaniesInvolved);

    _setText(cnoNumberCtrl, contractData.cnoNumber?.toString());
    _setText(contractObjectDescriptionCtrl, contractData.contractObjectDescription);
    _setText(regionalManagerCtrl, contractData.regionalManager);
    _setText(managerIdCtrl, contractData.managerId);

    _setText(managerPhoneNumberCtrl, contractData.managerPhoneNumber);
    _setText(cpfContractManagerCtrl, contractData.cpfContractManager?.toString());
    _setText(contractManagerArtNumberCtrl, contractData.contractManagerArtNumber);

    _setText(initialValidityExecutionDaysCtrl, contractData.initialValidityExecutionDays?.toString());
    _setText(initialValidityContractDaysCtrl, contractData.initialValidityContractDays?.toString());
  }

  void atualizarContractDataDosCampos() {
    contractData
      ..contractStatus = _getText(contractStatusCtrl)
      ..initialValueContract = _getDouble(initialValueOfContractCtrl)
      ..contractNumberProcess = _getText(contractBiddingProcessNumberCtrl)
      ..contractNumber = _getText(contractNumberCtrl)
      ..contractServices = _getText(contractServiceTypeCtrl)
      ..contractType = _getText(contractTypeCtrl)
      ..regionOfState = _getText(contractRegionOfStateCtrl)
      ..companyLeader = _getText(contractCompanyLeaderCtrl)
      ..mainContractHighway = _getText(contractHighWayCtrl)
      ..summarySubjectContract = _getText(summarySubjectContractCtrl)
      ..contractExtKm = double.tryParse(_getText(contractTextKmCtrl))
      ..publicationDateDoe = stringToDate(datapublicacaodoeCtrl.text)
      ..contractCompaniesInvolved = _getText(contractCompaniesInvolvedCtrl)
      ..cnoNumber = _getText(cnoNumberCtrl)
      ..contractObjectDescription = _getText(contractObjectDescriptionCtrl)
      ..regionalManager = _getText(regionalManagerCtrl)
      ..managerId = _getText(managerIdCtrl)
      ..managerPhoneNumber = _getText(managerPhoneNumberCtrl)
      ..cpfContractManager = int.tryParse(
        cpfContractManagerCtrl.text.replaceAll(RegExp(r'\D'), ''),
      )
      ..contractManagerArtNumber = _getText(contractManagerArtNumberCtrl)
      ..initialValidityExecutionDays = int.tryParse(initialValidityExecutionDaysCtrl.text)
      ..initialValidityContractDays = int.tryParse(initialValidityContractDaysCtrl.text);
  }

  // ==== Ações ====
  Future<void> saveInformation(BuildContext context, {void Function(ContractData)? onSaved}) async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) {
      showErrors = true;
      notifyListeners();
      return;
    }

    atualizarContractDataDosCampos();

    isSaving = true;
    notifyListeners();

    try {
      contractData = await contractsBloc.salvarOuAtualizarContrato(contractData);
      onSaved?.call(contractData);

      await _refreshByIdIfNeeded();
      _preencherCampos();
      notifyListeners();

      _showSnack(context, 'Contrato salvo com sucesso!', Colors.green);
    } catch (e, stack) {
      // ignore: avoid_print
      print(stack);
      _showSnack(context, 'Erro ao salvar contrato: $e', Colors.red);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> salvarUrlPdfDoContratoEAtualizarUI(
      BuildContext context, {
        required String contractId,
        required String url,
        void Function(ContractData)? onSaved,
      }) async {
    try {
      await contractsBloc.salvarUrlPdfDoContrato(contractId, url);
      await _refreshByIdIfNeeded();
      _preencherCampos();
      notifyListeners();
      onSaved?.call(contractData);
      _showSnack(context, 'Contrato salvo com sucesso!', Colors.green);
    } catch (e) {
      _showSnack(context, 'Erro ao salvar PDF do contrato: $e', Colors.red);
    }
  }

  Future<void> _refreshByIdIfNeeded() async {
    if (contractData.id != null) {
      final atualizado = await contractsBloc.getContractById(contractData.id!);
      if (atualizado != null) {
        contractData = atualizado;
      }
    }
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ==== Dispose ====
  @override
  void dispose() {
    contractStatusCtrl.dispose();
    initialValueOfContractCtrl.dispose();

    contractBiddingProcessNumberCtrl.dispose();
    contractNumberCtrl.dispose();
    contractServiceTypeCtrl.dispose();
    contractRegionOfStateCtrl.dispose();

    contractTypeCtrl.dispose();
    contractHighWayCtrl.dispose();
    summarySubjectContractCtrl.dispose();
    contractTextKmCtrl.dispose();

    datapublicacaodoeCtrl.dispose();
    contractCompanyLeaderCtrl.dispose();
    contractCompaniesInvolvedCtrl.dispose();

    cnoNumberCtrl.dispose();
    contractObjectDescriptionCtrl.dispose();
    regionalManagerCtrl.dispose();
    managerIdCtrl.dispose();

    managerPhoneNumberCtrl.dispose();
    cpfContractManagerCtrl.dispose();
    contractManagerArtNumberCtrl.dispose();

    initialValidityExecutionDaysCtrl.dispose();
    initialValidityContractDaysCtrl.dispose();

    super.dispose();
  }
}
