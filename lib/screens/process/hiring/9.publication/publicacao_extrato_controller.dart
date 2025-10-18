import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller de TESTE para Publicação do Extrato.
/// Dropdowns usam TextEditingController (compatível com DropDownButtonChange).
class PublicacaoExtratoController extends ChangeNotifier {
  bool isEditable = true;

  // 1) Metadados do extrato
  final peTipoExtratoCtrl = TextEditingController();        // DropDown
  final peNumeroContratoCtrl = TextEditingController();
  final peProcessoCtrl = TextEditingController();
  final peObjetoResumoCtrl = TextEditingController();

  // 2) Partes / Valores / Vigência
  final peContratadaRazaoCtrl = TextEditingController();
  final peContratadaCnpjCtrl = TextEditingController();
  final peValorCtrl = TextEditingController();
  final peVigenciaCtrl = TextEditingController();

  // 3) Veículo
  final peVeiculoCtrl = TextEditingController();            // DropDown
  final peEdicaoNumeroCtrl = TextEditingController();
  final peDataEnvioCtrl = TextEditingController();
  final peDataPublicacaoCtrl = TextEditingController();
  final peLinkPublicacaoCtrl = TextEditingController();

  // 4) Status / Prazos
  final peStatusCtrl = TextEditingController();             // DropDown
  final pePrazoLegalCtrl = TextEditingController();         // DropDown
  final peObservacoesCtrl = TextEditingController();

  // 5) Responsável
  final peResponsavelCtrl = TextEditingController();        // Autocomplete fake
  String? peResponsavelUserId;

  void initWithMock() {
    peTipoExtratoCtrl.text = 'Extrato de Contrato';
    peNumeroContratoCtrl.text = 'CT 012/2025';
    peProcessoCtrl.text = 'SEI 64000.000000/2025-11';
    peObjetoResumoCtrl.text = 'Restauração do pavimento e sinalização na AL-101.';

    peContratadaRazaoCtrl.text = 'FC Empreendimentos Ltda.';
    peContratadaCnpjCtrl.text = '12.345.678/0001-90';
    peValorCtrl.text = '12.500.000,00';
    peVigenciaCtrl.text = '12 meses';

    peVeiculoCtrl.text = 'DOE/Estadual';
    peEdicaoNumeroCtrl.text = 'Edição 27.345';
    peDataEnvioCtrl.text = '25/09/2025';
    peDataPublicacaoCtrl.text = '26/09/2025';
    peLinkPublicacaoCtrl.text = 'https://doe.exemplo/al-27-345-extrato';

    peStatusCtrl.text = 'Publicado';
    pePrazoLegalCtrl.text = 'Sim';
    peObservacoesCtrl.text = 'Publicação dentro do prazo legal.';

    peResponsavelCtrl.text = 'Carla Menezes (uid:u1)'; peResponsavelUserId = 'u1';
    notifyListeners();
  }

  String? quickValidate() {
    if (peTipoExtratoCtrl.text.trim().isEmpty) return 'Selecione o tipo de extrato.';
    if (peNumeroContratoCtrl.text.trim().isEmpty) return 'Informe o nº do contrato/ARP.';
    if (peProcessoCtrl.text.trim().isEmpty) return 'Informe o nº do processo.';
    if (peObjetoResumoCtrl.text.trim().isEmpty) return 'Informe o objeto.';
    if (peVeiculoCtrl.text.trim().isEmpty) return 'Selecione o veículo de publicação.';
    if (peResponsavelCtrl.text.trim().isEmpty) return 'Informe o responsável.';
    return null;
  }

  Map<String, dynamic> save() {
    final e = quickValidate();
    if (e != null) throw StateError(e);
    return toMap();
  }

  Map<String, dynamic> toMap() => {
    'tipoExtrato': peTipoExtratoCtrl.text,
    'numeroContrato': peNumeroContratoCtrl.text,
    'processo': peProcessoCtrl.text,
    'objetoResumo': peObjetoResumoCtrl.text,

    'contratadaRazao': peContratadaRazaoCtrl.text,
    'contratadaCnpj': peContratadaCnpjCtrl.text,
    'valor': peValorCtrl.text,
    'vigencia': peVigenciaCtrl.text,

    'veiculo': peVeiculoCtrl.text,
    'edicaoNumero': peEdicaoNumeroCtrl.text,
    'dataEnvio': peDataEnvioCtrl.text,
    'dataPublicacao': peDataPublicacaoCtrl.text,
    'linkPublicacao': peLinkPublicacaoCtrl.text,

    'status': peStatusCtrl.text,
    'prazoLegal': pePrazoLegalCtrl.text,
    'observacoes': peObservacoesCtrl.text,

    'responsavelNome': peResponsavelCtrl.text,
    'responsavelUserId': peResponsavelUserId,
  };

  void fromMap(Map<String, dynamic> m) {
    peTipoExtratoCtrl.text = m['tipoExtrato'] ?? '';
    peNumeroContratoCtrl.text = m['numeroContrato'] ?? '';
    peProcessoCtrl.text = m['processo'] ?? '';
    peObjetoResumoCtrl.text = m['objetoResumo'] ?? '';

    peContratadaRazaoCtrl.text = m['contratadaRazao'] ?? '';
    peContratadaCnpjCtrl.text = m['contratadaCnpj'] ?? '';
    peValorCtrl.text = m['valor'] ?? '';
    peVigenciaCtrl.text = m['vigencia'] ?? '';

    peVeiculoCtrl.text = m['veiculo'] ?? '';
    peEdicaoNumeroCtrl.text = m['edicaoNumero'] ?? '';
    peDataEnvioCtrl.text = m['dataEnvio'] ?? '';
    peDataPublicacaoCtrl.text = m['dataPublicacao'] ?? '';
    peLinkPublicacaoCtrl.text = m['linkPublicacao'] ?? '';

    peStatusCtrl.text = m['status'] ?? '';
    pePrazoLegalCtrl.text = m['prazoLegal'] ?? '';
    peObservacoesCtrl.text = m['observacoes'] ?? '';

    peResponsavelCtrl.text = m['responsavelNome'] ?? '';
    peResponsavelUserId = m['responsavelUserId'];
    notifyListeners();
  }

  void clear() {
    for (final ctrl in [
      peTipoExtratoCtrl, peNumeroContratoCtrl, peProcessoCtrl, peObjetoResumoCtrl,
      peContratadaRazaoCtrl, peContratadaCnpjCtrl, peValorCtrl, peVigenciaCtrl,
      peVeiculoCtrl, peEdicaoNumeroCtrl, peDataEnvioCtrl, peDataPublicacaoCtrl, peLinkPublicacaoCtrl,
      peStatusCtrl, pePrazoLegalCtrl, peObservacoesCtrl,
      peResponsavelCtrl,
    ]) { ctrl.clear(); }
    peResponsavelUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      peTipoExtratoCtrl, peNumeroContratoCtrl, peProcessoCtrl, peObjetoResumoCtrl,
      peContratadaRazaoCtrl, peContratadaCnpjCtrl, peValorCtrl, peVigenciaCtrl,
      peVeiculoCtrl, peEdicaoNumeroCtrl, peDataEnvioCtrl, peDataPublicacaoCtrl, peLinkPublicacaoCtrl,
      peStatusCtrl, pePrazoLegalCtrl, peObservacoesCtrl,
      peResponsavelCtrl,
    ]) { ctrl.dispose(); }
    super.dispose();
  }
}
