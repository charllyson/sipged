// lib/_blocs/process/hiring/10Publicacao/publicacao_extrato_controller.dart
import 'package:flutter/material.dart';

class PublicacaoExtratoController extends ChangeNotifier {
  bool isEditable;
  PublicacaoExtratoController({this.isEditable = true});

  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  // 1) Metadados do Extrato
  final peTipoExtratoCtrl    = TextEditingController();
  final peNumeroContratoCtrl = TextEditingController();
  final peProcessoCtrl       = TextEditingController();
  final peObjetoResumoCtrl   = TextEditingController();

  // 2) Partes / Valores / Vigência
  final peContratadaRazaoCtrl = TextEditingController();
  final peContratadaCnpjCtrl  = TextEditingController();
  final peValorCtrl           = TextEditingController();
  final peVigenciaCtrl        = TextEditingController();
  String? cnoRef;

  // 3) Veículo de Publicação
  final peVeiculoCtrl        = TextEditingController();
  final peEdicaoNumeroCtrl   = TextEditingController();
  final peDataEnvioCtrl      = TextEditingController();
  final peDataPublicacaoCtrl = TextEditingController();
  final peLinkPublicacaoCtrl = TextEditingController();

  // 4) Status / Prazos
  final peStatusCtrl      = TextEditingController();
  final pePrazoLegalCtrl  = TextEditingController();
  final peObservacoesCtrl = TextEditingController();

  // 5) Responsável
  final peResponsavelCtrl = TextEditingController();
  String? peResponsavelUserId;

  bool _looksUid(String? v) => v != null && v.trim().length >= 20 && !v.contains(' ');

  Map<String, Map<String, dynamic>> toSectionMaps() => {
    'metadados': {
      'tipoExtrato': peTipoExtratoCtrl.text,
      'numeroContrato': peNumeroContratoCtrl.text,
      'processo': peProcessoCtrl.text,
      'objetoResumo': peObjetoResumoCtrl.text,
    },
    'partes': {
      'contratadaRazao': peContratadaRazaoCtrl.text,
      'contratadaCnpj': peContratadaCnpjCtrl.text,
      'valor': peValorCtrl.text,
      'vigencia': peVigenciaCtrl.text,
      'cnoRef': cnoRef,
    },
    'veiculo': {
      'veiculo': peVeiculoCtrl.text,
      'edicaoNumero': peEdicaoNumeroCtrl.text,
      'dataEnvio': peDataEnvioCtrl.text,
      'dataPublicacao': peDataPublicacaoCtrl.text,
      'linkPublicacao': peLinkPublicacaoCtrl.text,
    },
    'status': {
      'status': peStatusCtrl.text,
      'prazoLegal': pePrazoLegalCtrl.text,
      'observacoes': peObservacoesCtrl.text,
    },
    'responsavel': {
      'responsavelNome': peResponsavelCtrl.text,
      'responsavelUserId': peResponsavelUserId,
    },
  };

  void fromSectionMaps(Map<String, Map<String, dynamic>> sections) {
    final m = sections['metadados'] ?? const {};
    peTipoExtratoCtrl.text    = m['tipoExtrato'] ?? '';
    peNumeroContratoCtrl.text = m['numeroContrato'] ?? '';
    peProcessoCtrl.text       = m['processo'] ?? '';
    peObjetoResumoCtrl.text   = m['objetoResumo'] ?? '';

    final p = sections['partes'] ?? const {};
    peContratadaRazaoCtrl.text = p['contratadaRazao'] ?? '';
    peContratadaCnpjCtrl.text  = p['contratadaCnpj'] ?? '';
    peValorCtrl.text           = p['valor'] ?? '';
    peVigenciaCtrl.text        = p['vigencia'] ?? '';
    cnoRef                     = p['cnoRef'];

    final v = sections['veiculo'] ?? const {};
    peVeiculoCtrl.text        = v['veiculo'] ?? '';
    peEdicaoNumeroCtrl.text   = v['edicaoNumero'] ?? '';
    peDataEnvioCtrl.text      = v['dataEnvio'] ?? '';
    peDataPublicacaoCtrl.text = v['dataPublicacao'] ?? '';
    peLinkPublicacaoCtrl.text = v['linkPublicacao'] ?? '';

    final s = sections['status'] ?? const {};
    peStatusCtrl.text      = s['status'] ?? '';
    pePrazoLegalCtrl.text  = s['prazoLegal'] ?? '';
    peObservacoesCtrl.text = s['observacoes'] ?? '';

    final r = sections['responsavel'] ?? const {};
    // Normaliza: se vier apenas UID no campo de nome, joga pro userId e limpa o campo de texto
    peResponsavelUserId = r['responsavelUserId'] ?? (_looksUid(r['responsavelNome']) ? r['responsavelNome'] : null);
    peResponsavelCtrl.text = _looksUid(r['responsavelNome']) ? '' : (r['responsavelNome'] ?? '');

    notifyListeners();
  }

  String? quickValidate() {
    if (peTipoExtratoCtrl.text.trim().isEmpty) return 'Selecione o tipo de extrato.';
    if (peNumeroContratoCtrl.text.trim().isEmpty) return 'Informe o Nº do contrato/ARP.';
    if (peProcessoCtrl.text.trim().isEmpty) return 'Informe o Nº do processo.';
    if (peObjetoResumoCtrl.text.trim().isEmpty) return 'Informe o Objeto (resumo).';
    if (peContratadaRazaoCtrl.text.trim().isEmpty) return 'Informe a razão social da contratada.';
    if (peContratadaCnpjCtrl.text.trim().isEmpty) return 'Informe o CNPJ da contratada.';
    if (peVeiculoCtrl.text.trim().isEmpty) return 'Selecione o veículo de publicação.';
    if ((peResponsavelUserId == null || peResponsavelUserId!.isEmpty) &&
        peResponsavelCtrl.text.trim().isEmpty) {
      return 'Selecione o responsável pela publicação.';
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in [
      peTipoExtratoCtrl, peNumeroContratoCtrl, peProcessoCtrl, peObjetoResumoCtrl,
      peContratadaRazaoCtrl, peContratadaCnpjCtrl, peValorCtrl, peVigenciaCtrl,
      peVeiculoCtrl, peEdicaoNumeroCtrl, peDataEnvioCtrl, peDataPublicacaoCtrl, peLinkPublicacaoCtrl,
      peStatusCtrl, pePrazoLegalCtrl, peObservacoesCtrl,
      peResponsavelCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }
}
