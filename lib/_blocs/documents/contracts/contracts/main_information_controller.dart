/*
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_store.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_rules.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_storage_bloc.dart';

/// Controller da tela de Informações Gerais do Contrato.
/// - Mantém os controllers de texto
/// - Sincroniza com ContractData
/// - Salva/atualiza via ContractsStore
/// - Atualiza URL do PDF via ContractStorageBloc/ContractsStore
class MainInformationController extends ChangeNotifier {
  MainInformationController({
    required this.contractsStore,
    required this.contractStorageBloc,
    required this.moduleKey,
    this.forceEditable = false,
  });

  // ================= Injeções =================
  final ContractsStore contractsStore;
  final ContractStorageBloc contractStorageBloc;

  // Apenas para cenários onde você controla permissões por módulo
  final String moduleKey;
  final bool forceEditable;

  // ================= Estado da UI =================
  final formKey = GlobalKey<FormState>();
  bool showErrors = false;
  bool isSaving = false;

  bool get isEditable => forceEditable; // adapte aqui se tiver ACL dinâmica
  bool get isBtnEnabled {
    // Habilita se: não está salvando e campos essenciais preenchidos
    return !isSaving &&
        (contractStatusCtrl.text.trim().isNotEmpty) &&
        (contractBiddingProcessNumberCtrl.text.trim().isNotEmpty) &&
        (contractNumberCtrl.text.trim().isNotEmpty) &&
        (initialValueOfContractCtrl.text.trim().isNotEmpty) &&
        (summarySubjectContractCtrl.text.trim().isNotEmpty) &&
        (contractRegionOfStateCtrl.text.trim().isNotEmpty) &&
        (contractTextKmCtrl.text.trim().isNotEmpty) &&
        (initialValidityContractDaysCtrl.text.trim().isNotEmpty) &&
        (initialValidityExecutionDaysCtrl.text.trim().isNotEmpty) &&
        // Tipo de obra é dropdown obrigatório
        (contractWorkTypeCtrl.text.trim().isNotEmpty);
  }

  // ================= Modelo =================
  late ContractData contractData;

  // ================= Controllers =================
  // Campos “empresa”
  final TextEditingController contractCompanyLeaderCtrl = TextEditingController();
  final TextEditingController contractCompaniesInvolvedCtrl = TextEditingController();
  final TextEditingController cnoNumberCtrl = TextEditingController();
  final TextEditingController cnpjNumberCtrl = TextEditingController(); // (se usar)
  final TextEditingController generalNumberCtrl = TextEditingController(); // (se usar)

  // Campos “gerais do contrato”
  final TextEditingController contractStatusCtrl = TextEditingController();
  final TextEditingController contractBiddingProcessNumberCtrl = TextEditingController();
  final TextEditingController contractNumberCtrl = TextEditingController();
  final TextEditingController initialValueOfContractCtrl = TextEditingController();
  final TextEditingController contractHighWayCtrl = TextEditingController();
  final TextEditingController summarySubjectContractCtrl = TextEditingController();
  final TextEditingController contractRegionOfStateCtrl = TextEditingController();
  final TextEditingController contractTextKmCtrl = TextEditingController();
  final TextEditingController contractTypeCtrl = TextEditingController();      // texto livre (Tipo de contrato)
  final TextEditingController contractWorkTypeCtrl = TextEditingController();  // NOVO: dropdown (Tipo de obra)
  final TextEditingController contractServiceTypeCtrl = TextEditingController();
  final TextEditingController datapublicacaodoeCtrl = TextEditingController();
  final TextEditingController initialValidityContractDaysCtrl = TextEditingController();
  final TextEditingController initialValidityExecutionDaysCtrl = TextEditingController();

  // Descrição
  final TextEditingController contractObjectDescriptionCtrl = TextEditingController();

  // Gestor
  final TextEditingController regionalManagerCtrl = TextEditingController();
  final TextEditingController managerIdCtrl = TextEditingController();
  final TextEditingController managerPhoneNumberCtrl = TextEditingController();
  final TextEditingController cpfContractManagerCtrl = TextEditingController();
  final TextEditingController contractManagerArtNumberCtrl = TextEditingController();

  // ================= Ciclo de vida =================
  Future<void> init(BuildContext context, {ContractData? initial}) async {
    contractData = _clone(initial ?? ContractData.empty());

    // Preenche os controllers a partir do modelo atual
    _fillControllersFromModel();

    notifyListeners();
  }

  @override
  void dispose() {
    // Empresa
    contractCompanyLeaderCtrl.dispose();
    contractCompaniesInvolvedCtrl.dispose();
    cnoNumberCtrl.dispose();
    cnpjNumberCtrl.dispose();
    generalNumberCtrl.dispose();

    // Gerais do contrato
    contractStatusCtrl.dispose();
    contractBiddingProcessNumberCtrl.dispose();
    contractNumberCtrl.dispose();
    initialValueOfContractCtrl.dispose();
    contractHighWayCtrl.dispose();
    summarySubjectContractCtrl.dispose();
    contractRegionOfStateCtrl.dispose();
    contractTextKmCtrl.dispose();
    contractTypeCtrl.dispose();
    contractWorkTypeCtrl.dispose(); // NOVO
    contractServiceTypeCtrl.dispose();
    datapublicacaodoeCtrl.dispose();
    initialValidityContractDaysCtrl.dispose();
    initialValidityExecutionDaysCtrl.dispose();

    // Descrição
    contractObjectDescriptionCtrl.dispose();

    // Gestor
    regionalManagerCtrl.dispose();
    managerIdCtrl.dispose();
    managerPhoneNumberCtrl.dispose();
    cpfContractManagerCtrl.dispose();
    contractManagerArtNumberCtrl.dispose();

    super.dispose();
  }

  // ================= Operações =================

  /// Salva/Atualiza as informações.
  Future<void> saveInformation(
      BuildContext context, {
        void Function(ContractData)? onSaved,
      }) async {
    showErrors = true;
    notifyListeners();

    if (!(formKey.currentState?.validate() ?? false)) return;

    // a) aplica controllers -> modelo
    _applyControllersToModel();

    // b) status de salvamento
    isSaving = true;
    notifyListeners();

    try {
      // c) salva via store
      final saved = await contractsStore.saveOrUpdate(contractData);

      // d) atualiza a instância local com o retorno (id, timestamps etc.)
      contractData = _clone(saved);

      // e) callback externo
      onSaved?.call(contractData);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Após upload de PDF, salva a URL no Firestore via store e atualiza a UI.
  Future<void> salvarUrlPdfDoContratoEAtualizarUI(
      BuildContext context, {
        required String contractId,
        required String url,
        void Function(ContractData)? onSaved,
      }) async {
    await contractsStore.salvarUrlPdfDoContrato(contractId, url);

    // Garantir que o modelo local esteja atualizado com a URL
    final updated = await contractsStore.getById(contractId);
    if (updated != null) {
      contractData = _clone(updated);
      onSaved?.call(contractData);
      notifyListeners();
    }
  }

  // ================= Helpers internos =================

  ContractData _clone(ContractData src) {
    // Clonagem superficial segura para evitar side-effects
    return ContractData(
      id: src.id,
      managerId: src.managerId,
      summarySubjectContract: src.summarySubjectContract,
      contractNumber: src.contractNumber,
      mainContractHighway: src.mainContractHighway,
      restriction: src.restriction,
      contractServices: src.contractServices,
      contractManagerArtNumber: src.contractManagerArtNumber,
      contractExtKm: src.contractExtKm,
      regionOfState: src.regionOfState,
      managerPhoneNumber: src.managerPhoneNumber,
      companyLeader: src.companyLeader,
      generalNumber: src.generalNumber,
      contractNumberProcess: src.contractNumberProcess,
      automaticNumberSiafe: src.automaticNumberSiafe,
      physicalPercentage: src.physicalPercentage,
      regionalManager: src.regionalManager,
      contractStatus: src.contractStatus,
      contractObjectDescription: src.contractObjectDescription,
      contractType: src.contractType,
      workType: src.workType, // NOVO
      contractCompaniesInvolved: src.contractCompaniesInvolved,
      urlContractPdf: src.urlContractPdf,
      initialValidityExecutionDays: src.initialValidityExecutionDays,
      initialValidityContractDays: src.initialValidityContractDays,
      cpfContractManager: src.cpfContractManager,
      cnoNumber: src.cnoNumber,
      cnpjNumber: src.cnpjNumber,
      existContract: src.existContract,
      publicationDateDoe: src.publicationDateDoe,
      financialPercentage: src.financialPercentage,
      initialValueContract: src.initialValueContract,
      permissionContractId:
      Map<String, Map<String, bool>>.fromEntries(src.permissionContractId.entries.map(
            (e) => MapEntry(e.key, Map<String, bool>.from(e.value)),
      )),
    );
  }

  void _fillControllersFromModel() {
    // Empresa
    contractCompanyLeaderCtrl.text = (contractData.companyLeader ?? '');
    contractCompaniesInvolvedCtrl.text = (contractData.contractCompaniesInvolved ?? '');
    cnoNumberCtrl.text = (contractData.cnoNumber ?? '');
    cnpjNumberCtrl.text = (contractData.cnpjNumber?.toString() ?? '');
    generalNumberCtrl.text = (contractData.generalNumber ?? '');

    // Gerais
    contractStatusCtrl.text = (contractData.contractStatus ?? '');
    contractBiddingProcessNumberCtrl.text = (contractData.contractNumberProcess ?? '');
    contractNumberCtrl.text = (contractData.contractNumber ?? '');
    initialValueOfContractCtrl.text = _formatCurrency(contractData.initialValueContract);
    contractHighWayCtrl.text = (contractData.mainContractHighway ?? '');
    summarySubjectContractCtrl.text = (contractData.summarySubjectContract ?? '');
    contractRegionOfStateCtrl.text = (contractData.regionOfState ?? '');
    contractTextKmCtrl.text = _formatNumber(contractData.contractExtKm, decimals: 3);
    contractTypeCtrl.text = (contractData.contractType ?? ''); // texto livre
    contractWorkTypeCtrl.text = (contractData.workType ?? ''); // NOVO: dropdown
    contractServiceTypeCtrl.text = (contractData.contractServices ?? '');
    datapublicacaodoeCtrl.text =
    contractData.publicationDateDoe != null ? contractData.publicationDateDoe!.toIso8601String() : '';
    initialValidityContractDaysCtrl.text =
    (contractData.initialValidityContractDays?.toString() ?? '');
    initialValidityExecutionDaysCtrl.text =
    (contractData.initialValidityExecutionDays?.toString() ?? '');

    // Descrição
    contractObjectDescriptionCtrl.text = (contractData.contractObjectDescription ?? '');

    // Gestor
    regionalManagerCtrl.text = (contractData.regionalManager ?? '');
    managerIdCtrl.text = (contractData.managerId ?? '');
    managerPhoneNumberCtrl.text = (contractData.managerPhoneNumber ?? '');
    cpfContractManagerCtrl.text = (contractData.cpfContractManager?.toString() ?? '');
    contractManagerArtNumberCtrl.text = (contractData.contractManagerArtNumber ?? '');
  }

  void _applyControllersToModel() {
    // Empresa
    contractData.companyLeader = _nullIfEmpty(contractCompanyLeaderCtrl.text);
    contractData.contractCompaniesInvolved = _nullIfEmpty(contractCompaniesInvolvedCtrl.text);
    contractData.cnoNumber = _nullIfEmpty(cnoNumberCtrl.text);
    contractData.cnpjNumber = _tryParseInt(cnpjNumberCtrl.text);
    contractData.generalNumber = _nullIfEmpty(generalNumberCtrl.text);

    // Gerais
    contractData.contractStatus = _normalizeFromList(contractStatusCtrl.text, ContractRules.statusTypes);
    contractData.contractNumberProcess = _nullIfEmpty(contractBiddingProcessNumberCtrl.text);
    contractData.contractNumber = _nullIfEmpty(contractNumberCtrl.text);
    contractData.initialValueContract = _parseCurrency(initialValueOfContractCtrl.text);
    contractData.mainContractHighway = _nullIfEmpty(contractHighWayCtrl.text);
    contractData.summarySubjectContract = _nullIfEmpty(summarySubjectContractCtrl.text);
    contractData.regionOfState = _nullIfEmpty(contractRegionOfStateCtrl.text);
    contractData.contractExtKm = _tryParseDouble(contractTextKmCtrl.text);
    contractData.contractType = _nullIfEmpty(contractTypeCtrl.text); // texto livre
    contractData.workType = _normalizeFromList(contractWorkTypeCtrl.text, ContractRules.workTypes); // NOVO
    contractData.contractServices = _nullIfEmpty(contractServiceTypeCtrl.text);

    // datapublicacaodoe: a UI já seta contractData.publicationDateDoe no onChanged do CustomDateField
    // Caso queira forçar parse a partir do texto, descomente:
    // contractData.publicationDateDoe = _tryParseIso(datapublicacaodoeCtrl.text);

    contractData.initialValidityContractDays =
        _tryParseInt(initialValidityContractDaysCtrl.text);
    contractData.initialValidityExecutionDays =
        _tryParseInt(initialValidityExecutionDaysCtrl.text);

    // Descrição
    contractData.contractObjectDescription = _nullIfEmpty(contractObjectDescriptionCtrl.text);

    // Gestor
    contractData.regionalManager = _nullIfEmpty(regionalManagerCtrl.text);
    contractData.managerId = _nullIfEmpty(managerIdCtrl.text);
    contractData.managerPhoneNumber = _nullIfEmpty(managerPhoneNumberCtrl.text);
    contractData.cpfContractManager = _tryParseInt(cpfContractManagerCtrl.text);
    contractData.contractManagerArtNumber = _nullIfEmpty(contractManagerArtNumberCtrl.text);
  }

  // ================= Utilitários =================

  String _nullIfEmpty(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? '' : s;
  }

  String _formatCurrency(double? value) {
    if (value == null) return '';
    // Formato amigável "R$ 1.234,56" apenas como string simples (a máscara do campo cuida do resto)
    return 'R\$ ${_formatNumber(value, decimals: 2, decimalComma: true, thousandsDot: true)}';
  }

  String _formatNumber(num? value, {int decimals = 0, bool decimalComma = false, bool thousandsDot = false}) {
    if (value == null) return '';
    String s = value.toStringAsFixed(decimals);
    if (decimalComma) {
      // troca ponto por vírgula
      s = s.replaceAll('.', ',');
    }
    if (thousandsDot) {
      // insere separador de milhar simples (não é locale-aware completa)
      final parts = s.split(decimalComma ? ',' : '.');
      String intPart = parts[0];
      String fracPart = parts.length > 1 ? parts[1] : '';
      final buf = StringBuffer();
      for (int i = 0; i < intPart.length; i++) {
        final revIndex = intPart.length - i;
        buf.write(intPart[i]);
        final remain = intPart.length - i - 1;
        if (remain > 0 && (remain % 3 == 0)) buf.write('.');
      }
      s = buf.toString();
      if (decimals > 0) {
        s = '$s${decimalComma ? ',' : '.'}$fracPart';
      }
    }
    return s;
  }

  double? _parseCurrency(String? text) {
    if (text == null) return null;
    var s = text.trim();
    if (s.isEmpty) return null;
    // Remove "R$", espaços e pontos de milhar. Troca vírgula por ponto.
    s = s.replaceAll('R\$', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s);
  }

  double? _tryParseDouble(String? text) {
    if (text == null) return null;
    final s = text.trim().replaceAll(',', '.');
    return double.tryParse(s);
  }

  int? _tryParseInt(String? text) {
    if (text == null) return null;
    final s = text.trim().replaceAll(RegExp(r'[^0-9-]'), '');
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  DateTime? _tryParseIso(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    try {
      return DateTime.parse(text.trim());
    } catch (_) {
      return null;
    }
  }

  /// Normaliza um valor contra uma lista (case-insensitive). Retorna exatamente como está na lista.
  String? _normalizeFromList(String? value, List<String> candidates) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final found = candidates.firstWhereOrNull(
          (c) => c.toUpperCase() == v.toUpperCase(),
    );
    return found ?? v; // se não achou, mantém o digitado
  }
}
*/
