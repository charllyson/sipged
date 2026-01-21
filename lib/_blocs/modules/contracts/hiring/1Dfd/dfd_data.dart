import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dfd_sections.dart';

/// ---------------------------------------------------------------------------
/// HELPERS DE CONVERSÃO
/// ---------------------------------------------------------------------------

dynamic _toFirestoreValue(dynamic value) {
  if (value == null) return null;

  if (value is Timestamp) return value;
  if (value is DateTime) return Timestamp.fromDate(value);
  if (value is num) return value;
  if (value is String) return value.trim();

  return value;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  final s = value.toString().trim();
  if (s.isEmpty) return null;

  final normalized = s.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized);
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;

  final s = value.toString().trim();
  if (s.isEmpty) return null;

  try {
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}

/// =============================================================================
///                              DFD DATA MODEL
/// =============================================================================
class DfdData extends Equatable {
  /// Runtime only: id do contrato (vem do path).
  /// NÃO deve ser persistido no Firestore (já é implícito no caminho).
  final String? contractId;

  // 1) Identificação (labels)
  final String? orgaoDemandante;
  final String? unidadeSolicitante;
  final String? regional;

  // 1) Identificação (IDs do Setup)
  final String? orgaoDemandanteId;
  final String? unidadeSolicitanteId;
  final String? regionalId;

  final String? solicitanteNome;
  final String? solicitanteUserId;
  final String? solicitanteCpf;
  final String? solicitanteCargo;
  final String? solicitanteEmail;
  final String? solicitanteTelefone;
  final DateTime? dataSolicitacao;
  final String? processoAdministrativo;
  final String? statusDemanda;

  /// IDs auxiliares (para dropdowns dinâmicos globais)
  final String? companyId;
  final String? unitId;
  final String? regionId;

  // 2) Objeto (labels)
  final String? tipoContratacao;
  final String? modalidadeEstimativa;
  final String? regimeExecucao;
  final String? descricaoObjeto;
  final String? justificativa;
  final String? tipoObra;
  final double? valorDemanda;

  // 2) Objeto (IDs do Setup)
  final String? tipoContratacaoId;
  final String? modalidadeEstimativaId;
  final String? regimeExecucaoId;
  final String? tipoObraId;

  // 3) Localização (labels)
  final String? uf;
  final String? municipio;
  final String? rodovia;
  final String? kmInicial;
  final String? kmFinal;
  final String? naturezaIntervencao;
  final int? prazoExecucaoDias;
  final int? vigenciaMeses;
  final double? extensaoKm;

  // 3) Localização (IDs do Setup)
  final String? ufId;
  final String? municipioId;
  final String? rodoviaId;
  final String? naturezaIntervencaoId;

  // 4) Estimativa (labels)
  final String? fonteRecurso;
  final String? programaTrabalho;
  final String? ptres;
  final String? naturezaDespesa;
  final double? estimativaValor;
  final String? metodologiaEstimativa;

  // 4) Estimativa (IDs do Setup)
  final String? fonteRecursoId;
  final String? programaTrabalhoId;
  final String? ptresId;
  final String? naturezaDespesaId;
  final String? metodologiaEstimativaId;

  // 5) Riscos (labels)
  final String? riscos;
  final String? impactoNaoContratar;
  final String? prioridade;
  final DateTime? dataLimite;
  final String? motivacaoLegal;
  final String? amparoNormativo;

  // 5) Riscos (IDs do Setup)
  final String? prioridadeId;

  // 6) Documentos
  final String? etpAnexo;
  final String? projetoBasico;
  final String? termoMatrizRiscos;
  final String? parecerJuridico;
  final String? autorizacaoAbertura;
  final String? linksDocumentos;

  // 7) Aprovação (labels)
  final String? autoridadeAprovadora;
  final String? autoridadeUserId;
  final String? autoridadeCpf;
  final DateTime? dataAprovacao;
  final String? parecerResumo;

  // 7) Aprovação (IDs do Setup)
  final String? autoridadeAprovadoraId;

  // 8) Observações
  final String? observacoes;

  const DfdData({
    this.contractId,

    // 1) Identificação (labels)
    this.orgaoDemandante,
    this.unidadeSolicitante,
    this.regional,

    // 1) Identificação (ids)
    this.orgaoDemandanteId,
    this.unidadeSolicitanteId,
    this.regionalId,

    this.solicitanteNome,
    this.solicitanteUserId,
    this.solicitanteCpf,
    this.solicitanteCargo,
    this.solicitanteEmail,
    this.solicitanteTelefone,
    this.dataSolicitacao,
    this.processoAdministrativo,
    this.statusDemanda,

    // auxiliary
    this.companyId,
    this.unitId,
    this.regionId,

    // 2) Objeto (labels)
    this.tipoContratacao,
    this.modalidadeEstimativa,
    this.regimeExecucao,
    this.descricaoObjeto,
    this.justificativa,
    this.tipoObra,
    this.valorDemanda,

    // 2) Objeto (ids)
    this.tipoContratacaoId,
    this.modalidadeEstimativaId,
    this.regimeExecucaoId,
    this.tipoObraId,

    // 3) Localização (labels)
    this.uf,
    this.municipio,
    this.rodovia,
    this.kmInicial,
    this.kmFinal,
    this.naturezaIntervencao,
    this.prazoExecucaoDias,
    this.vigenciaMeses,
    this.extensaoKm,

    // 3) Localização (ids)
    this.ufId,
    this.municipioId,
    this.rodoviaId,
    this.naturezaIntervencaoId,

    // 4) Estimativa (labels)
    this.fonteRecurso,
    this.programaTrabalho,
    this.ptres,
    this.naturezaDespesa,
    this.estimativaValor,
    this.metodologiaEstimativa,

    // 4) Estimativa (ids)
    this.fonteRecursoId,
    this.programaTrabalhoId,
    this.ptresId,
    this.naturezaDespesaId,
    this.metodologiaEstimativaId,

    // 5) Riscos (labels)
    this.riscos,
    this.impactoNaoContratar,
    this.prioridade,
    this.dataLimite,
    this.motivacaoLegal,
    this.amparoNormativo,

    // 5) Riscos (ids)
    this.prioridadeId,

    // 6) Documentos
    this.etpAnexo,
    this.projetoBasico,
    this.termoMatrizRiscos,
    this.parecerJuridico,
    this.autorizacaoAbertura,
    this.linksDocumentos,

    // 7) Aprovação (labels)
    this.autoridadeAprovadora,
    this.autoridadeUserId,
    this.autoridadeCpf,
    this.dataAprovacao,
    this.parecerResumo,

    // 7) Aprovação (ids)
    this.autoridadeAprovadoraId,

    // 8) Observações
    this.observacoes,
  });

  const DfdData.empty()
      : contractId = null,
        orgaoDemandante = '',
        unidadeSolicitante = '',
        regional = null,
        orgaoDemandanteId = null,
        unidadeSolicitanteId = null,
        regionalId = null,
        solicitanteNome = '',
        solicitanteUserId = null,
        solicitanteCpf = '',
        solicitanteCargo = '',
        solicitanteEmail = '',
        solicitanteTelefone = '',
        dataSolicitacao = null,
        processoAdministrativo = '',
        statusDemanda = null,
        companyId = null,
        unitId = null,
        regionId = null,
        tipoContratacao = '',
        modalidadeEstimativa = '',
        regimeExecucao = null,
        descricaoObjeto = '',
        justificativa = '',
        tipoObra = null,
        valorDemanda = null,
        tipoContratacaoId = null,
        modalidadeEstimativaId = null,
        regimeExecucaoId = null,
        tipoObraId = null,
        uf = '',
        municipio = '',
        rodovia = '',
        kmInicial = '',
        kmFinal = '',
        naturezaIntervencao = '',
        prazoExecucaoDias = null,
        vigenciaMeses = null,
        extensaoKm = null,
        ufId = null,
        municipioId = null,
        rodoviaId = null,
        naturezaIntervencaoId = null,
        fonteRecurso = '',
        programaTrabalho = '',
        ptres = '',
        naturezaDespesa = '',
        estimativaValor = null,
        metodologiaEstimativa = '',
        fonteRecursoId = null,
        programaTrabalhoId = null,
        ptresId = null,
        naturezaDespesaId = null,
        metodologiaEstimativaId = null,
        riscos = '',
        impactoNaoContratar = '',
        prioridade = '',
        dataLimite = null,
        motivacaoLegal = '',
        amparoNormativo = '',
        prioridadeId = null,
        etpAnexo = null,
        projetoBasico = null,
        termoMatrizRiscos = null,
        parecerJuridico = null,
        autorizacaoAbertura = null,
        linksDocumentos = '',
        autoridadeAprovadora = '',
        autoridadeUserId = null,
        autoridadeCpf = '',
        dataAprovacao = null,
        parecerResumo = '',
        autoridadeAprovadoraId = null,
        observacoes = '';

  /// ---------------------------------------------------------------------------
  /// Deserialização a partir de sectionsData (DFD em subdocumentos)
  /// ---------------------------------------------------------------------------
  factory DfdData.fromSectionsMap(
      Map<String, dynamic>? sections, {
        String? contractId,
      }) {
    if (sections == null || sections.isEmpty) {
      return const DfdData.empty();
    }

    Map<String, dynamic> _sec(String key) {
      final raw = sections[key];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v));
      }
      return const <String, dynamic>{};
    }

    final ident = _sec(DfdSections.identificacao);
    final objeto = _sec(DfdSections.objeto);
    final localizacao = _sec(DfdSections.localizacao);
    final estimativa = _sec(DfdSections.estimativa);
    final riscos = _sec(DfdSections.riscos);
    final documentos = _sec(DfdSections.documentos);
    final aprovacao = _sec(DfdSections.aprovacao);
    final observacoes = _sec(DfdSections.observacoes);

    String? _s(Map<String, dynamic> m, String key) => m[key]?.toString();

    int? _i(Map<String, dynamic> m, String key) {
      final v = m[key];
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    String? _readIdCompat(Map<String, dynamic> m, String newKey, List<String> oldKeys) {
      final direct = m[newKey]?.toString();
      if (direct != null && direct.trim().isNotEmpty) return direct.trim();
      for (final k in oldKeys) {
        final v = m[k]?.toString();
        if (v != null && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    return DfdData(
      contractId: contractId,

      // 1) Identificação (labels)
      orgaoDemandante: _s(ident, 'orgaoDemandante'),
      unidadeSolicitante: _s(ident, 'unidadeSolicitante'),
      regional: _s(ident, 'regional'),

      // 1) Identificação (ids)
      orgaoDemandanteId: _readIdCompat(ident, 'orgaoDemandanteId', const ['orgaoDemandante_id']),
      unidadeSolicitanteId: _readIdCompat(ident, 'unidadeSolicitanteId', const ['unidadeSolicitante_id']),
      regionalId: _readIdCompat(ident, 'regionalId', const ['regional_id']),

      solicitanteNome: _s(ident, 'solicitanteNome'),
      solicitanteUserId: _s(ident, 'solicitanteUserId'),
      solicitanteCpf: _s(ident, 'solicitanteCpf'),
      solicitanteCargo: _s(ident, 'solicitanteCargo'),
      solicitanteEmail: _s(ident, 'solicitanteEmail'),
      solicitanteTelefone: _s(ident, 'solicitanteTelefone'),
      dataSolicitacao: _parseDate(ident['dataSolicitacao']),
      processoAdministrativo: _s(ident, 'numeroProcessoContratacao'),
      statusDemanda: _s(ident, 'statusContrato'),

      companyId: _s(ident, 'companyId'),
      unitId: _s(ident, 'unitId'),
      regionId: _s(ident, 'regionId') ?? _s(localizacao, 'regionId'),

      // 2) Objeto (labels)
      tipoContratacao: _s(objeto, 'tipoContratacao'),
      modalidadeEstimativa: _s(objeto, 'modalidadeEstimativa'),
      regimeExecucao: _s(objeto, 'regimeExecucao'),
      descricaoObjeto: _s(objeto, 'descricaoObjeto'),
      justificativa: _s(objeto, 'justificativa'),
      tipoObra: _s(objeto, 'tipoObra'),
      valorDemanda: _parseDouble(objeto['valorDemanda']),

      // 2) Objeto (ids)
      tipoContratacaoId: _readIdCompat(objeto, 'tipoContratacaoId', const ['tipoContratacao_id']),
      modalidadeEstimativaId: _readIdCompat(objeto, 'modalidadeEstimativaId', const ['modalidadeEstimativa_id']),
      regimeExecucaoId: _readIdCompat(objeto, 'regimeExecucaoId', const ['regimeExecucao_id']),
      tipoObraId: _readIdCompat(objeto, 'tipoObraId', const ['tipoObra_id']),

      // 3) Localização (labels)
      uf: _s(localizacao, 'uf'),
      municipio: _s(localizacao, 'municipio'),
      rodovia: _s(localizacao, 'rodovia'),
      kmInicial: _s(localizacao, 'kmInicial'),
      kmFinal: _s(localizacao, 'kmFinal'),
      naturezaIntervencao: _s(localizacao, 'naturezaIntervencao') ?? _s(ident, 'naturezaIntervencao'),
      prazoExecucaoDias: _i(localizacao, 'prazoExecucaoDias'),
      vigenciaMeses: _i(localizacao, 'vigenciaMeses'),
      extensaoKm: _parseDouble(localizacao['extensaoKm']),

      // 3) Localização (ids)
      ufId: _readIdCompat(localizacao, 'ufId', const ['uf_id']),
      municipioId: _readIdCompat(localizacao, 'municipioId', const ['municipio_id']),
      rodoviaId: _readIdCompat(localizacao, 'rodoviaId', const ['rodovia_id']),
      naturezaIntervencaoId: _readIdCompat(localizacao, 'naturezaIntervencaoId', const ['naturezaIntervencao_id']),

      // 4) Estimativa (labels)
      fonteRecurso: _s(estimativa, 'fonteRecurso'),
      programaTrabalho: _s(estimativa, 'programaTrabalho'),
      ptres: _s(estimativa, 'ptres'),
      naturezaDespesa: _s(estimativa, 'naturezaDespesa'),
      estimativaValor: _parseDouble(estimativa['estimativaValor']),
      metodologiaEstimativa: _s(estimativa, 'metodologiaEstimativa'),

      // 4) Estimativa (ids)
      fonteRecursoId: _readIdCompat(estimativa, 'fonteRecursoId', const ['fonteRecurso_id']),
      programaTrabalhoId: _readIdCompat(estimativa, 'programaTrabalhoId', const ['programaTrabalho_id']),
      ptresId: _readIdCompat(estimativa, 'ptresId', const ['ptres_id']),
      naturezaDespesaId: _readIdCompat(estimativa, 'naturezaDespesaId', const ['naturezaDespesa_id']),
      metodologiaEstimativaId: _readIdCompat(estimativa, 'metodologiaEstimativaId', const ['metodologiaEstimativa_id']),

      // 5) Riscos (labels)
      riscos: _s(riscos, 'riscos'),
      impactoNaoContratar: _s(riscos, 'impactoNaoContratar'),
      prioridade: _s(riscos, 'prioridade'),
      dataLimite: _parseDate(riscos['dataLimite']),
      motivacaoLegal: _s(riscos, 'motivacaoLegal'),
      amparoNormativo: _s(riscos, 'amparoNormativo'),

      // 5) Riscos (ids)
      prioridadeId: _readIdCompat(riscos, 'prioridadeId', const ['prioridade_id']),

      // 6) Documentos
      etpAnexo: _s(documentos, 'etpAnexo'),
      projetoBasico: _s(documentos, 'projetoBasico'),
      termoMatrizRiscos: _s(documentos, 'termoMatrizRiscos'),
      parecerJuridico: _s(documentos, 'parecerJuridico'),
      autorizacaoAbertura: _s(documentos, 'autorizacaoAbertura'),
      linksDocumentos: _s(documentos, 'linksDocumentos'),

      // 7) Aprovação (labels)
      autoridadeAprovadora: _s(aprovacao, 'autoridadeAprovadora'),
      autoridadeUserId: _s(aprovacao, 'autoridadeUserId'),
      autoridadeCpf: _s(aprovacao, 'autoridadeCpf'),
      dataAprovacao: _parseDate(aprovacao['dataAprovacao']),
      parecerResumo: _s(aprovacao, 'parecerResumo'),

      // 7) Aprovação (ids)
      autoridadeAprovadoraId: _readIdCompat(aprovacao, 'autoridadeAprovadoraId', const ['autoridadeAprovadora_id']),

      // 8) Observações
      observacoes: _s(observacoes, 'observacoes'),
    );
  }

  /// ---------------------------------------------------------------------------
  /// Deserialização do Firestore (map flat)
  /// ---------------------------------------------------------------------------
  factory DfdData.fromMap(
      Map<String, dynamic>? map, {
        String? contractId,
      }) {
    if (map == null) return const DfdData.empty();

    String? _idCompat(String newKey, List<String> oldKeys) {
      final direct = map[newKey]?.toString();
      if (direct != null && direct.trim().isNotEmpty) return direct.trim();
      for (final k in oldKeys) {
        final v = map[k]?.toString();
        if (v != null && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    return DfdData(
      contractId: contractId,

      orgaoDemandante: map['orgaoDemandante']?.toString(),
      unidadeSolicitante: map['unidadeSolicitante']?.toString(),
      regional: map['regional']?.toString(),

      orgaoDemandanteId: _idCompat('orgaoDemandanteId', const ['orgaoDemandante_id']),
      unidadeSolicitanteId: _idCompat('unidadeSolicitanteId', const ['unidadeSolicitante_id']),
      regionalId: _idCompat('regionalId', const ['regional_id']),

      solicitanteNome: map['solicitanteNome']?.toString(),
      solicitanteUserId: map['solicitanteUserId']?.toString(),
      solicitanteCpf: map['solicitanteCpf']?.toString(),
      solicitanteCargo: map['solicitanteCargo']?.toString(),
      solicitanteEmail: map['solicitanteEmail']?.toString(),
      solicitanteTelefone: map['solicitanteTelefone']?.toString(),
      dataSolicitacao: _parseDate(map['dataSolicitacao']),
      processoAdministrativo: map['numeroProcessoContratacao']?.toString(),
      statusDemanda: map['statusContrato']?.toString(),

      companyId: map['companyId']?.toString(),
      unitId: map['unitId']?.toString(),
      regionId: map['regionId']?.toString(),

      tipoContratacao: map['tipoContratacao']?.toString(),
      modalidadeEstimativa: map['modalidadeEstimativa']?.toString(),
      regimeExecucao: map['regimeExecucao']?.toString(),
      descricaoObjeto: map['descricaoObjeto']?.toString(),
      justificativa: map['justificativa']?.toString(),
      tipoObra: map['tipoObra']?.toString(),
      valorDemanda: _parseDouble(map['valorDemanda']),

      tipoContratacaoId: _idCompat('tipoContratacaoId', const ['tipoContratacao_id']),
      modalidadeEstimativaId: _idCompat('modalidadeEstimativaId', const ['modalidadeEstimativa_id']),
      regimeExecucaoId: _idCompat('regimeExecucaoId', const ['regimeExecucao_id']),
      tipoObraId: _idCompat('tipoObraId', const ['tipoObra_id']),

      uf: map['uf']?.toString(),
      municipio: map['municipio']?.toString(),
      rodovia: map['rodovia']?.toString(),
      kmInicial: map['kmInicial']?.toString(),
      kmFinal: map['kmFinal']?.toString(),
      naturezaIntervencao: map['naturezaIntervencao']?.toString(),
      prazoExecucaoDias: map['prazoExecucaoDias'] is int
          ? map['prazoExecucaoDias']
          : int.tryParse(map['prazoExecucaoDias']?.toString() ?? ''),
      vigenciaMeses: map['vigenciaMeses'] is int
          ? map['vigenciaMeses']
          : int.tryParse(map['vigenciaMeses']?.toString() ?? ''),
      extensaoKm: _parseDouble(map['extensaoKm']),

      ufId: _idCompat('ufId', const ['uf_id']),
      municipioId: _idCompat('municipioId', const ['municipio_id']),
      rodoviaId: _idCompat('rodoviaId', const ['rodovia_id']),
      naturezaIntervencaoId: _idCompat('naturezaIntervencaoId', const ['naturezaIntervencao_id']),

      fonteRecurso: map['fonteRecurso']?.toString(),
      programaTrabalho: map['programaTrabalho']?.toString(),
      ptres: map['ptres']?.toString(),
      naturezaDespesa: map['naturezaDespesa']?.toString(),
      estimativaValor: _parseDouble(map['estimativaValor']),
      metodologiaEstimativa: map['metodologiaEstimativa']?.toString(),

      fonteRecursoId: _idCompat('fonteRecursoId', const ['fonteRecurso_id']),
      programaTrabalhoId: _idCompat('programaTrabalhoId', const ['programaTrabalho_id']),
      ptresId: _idCompat('ptresId', const ['ptres_id']),
      naturezaDespesaId: _idCompat('naturezaDespesaId', const ['naturezaDespesa_id']),
      metodologiaEstimativaId: _idCompat('metodologiaEstimativaId', const ['metodologiaEstimativa_id']),

      riscos: map['riscos']?.toString(),
      impactoNaoContratar: map['impactoNaoContratar']?.toString(),
      prioridade: map['prioridade']?.toString(),
      dataLimite: _parseDate(map['dataLimite']),
      motivacaoLegal: map['motivacaoLegal']?.toString(),
      amparoNormativo: map['amparoNormativo']?.toString(),

      prioridadeId: _idCompat('prioridadeId', const ['prioridade_id']),

      etpAnexo: map['etpAnexo']?.toString(),
      projetoBasico: map['projetoBasico']?.toString(),
      termoMatrizRiscos: map['termoMatrizRiscos']?.toString(),
      parecerJuridico: map['parecerJuridico']?.toString(),
      autorizacaoAbertura: map['autorizacaoAbertura']?.toString(),
      linksDocumentos: map['linksDocumentos']?.toString(),

      autoridadeAprovadora: map['autoridadeAprovadora']?.toString(),
      autoridadeUserId: map['autoridadeUserId']?.toString(),
      autoridadeCpf: map['autoridadeCpf']?.toString(),
      dataAprovacao: _parseDate(map['dataAprovacao']),
      parecerResumo: map['parecerResumo']?.toString(),

      autoridadeAprovadoraId: _idCompat('autoridadeAprovadoraId', const ['autoridadeAprovadora_id']),

      observacoes: map['observacoes']?.toString(),
    );
  }

  /// ---------------------------------------------------------------------------
  /// COPYWITH
  /// ---------------------------------------------------------------------------
  DfdData copyWith({
    String? contractId,

    String? orgaoDemandante,
    String? unidadeSolicitante,
    String? regional,

    String? orgaoDemandanteId,
    String? unidadeSolicitanteId,
    String? regionalId,

    String? solicitanteNome,
    String? solicitanteUserId,
    String? solicitanteCpf,
    String? solicitanteCargo,
    String? solicitanteEmail,
    String? solicitanteTelefone,
    DateTime? dataSolicitacao,
    String? processoAdministrativo,
    String? statusDemanda,

    String? companyId,
    String? unitId,
    String? regionId,

    String? tipoContratacao,
    String? modalidadeEstimativa,
    String? regimeExecucao,
    String? descricaoObjeto,
    String? justificativa,
    String? tipoObra,
    double? valorDemanda,

    String? tipoContratacaoId,
    String? modalidadeEstimativaId,
    String? regimeExecucaoId,
    String? tipoObraId,

    String? uf,
    String? municipio,
    String? rodovia,
    String? kmInicial,
    String? kmFinal,
    String? naturezaIntervencao,
    int? prazoExecucaoDias,
    int? vigenciaMeses,
    double? extensaoKm,

    String? ufId,
    String? municipioId,
    String? rodoviaId,
    String? naturezaIntervencaoId,

    String? fonteRecurso,
    String? programaTrabalho,
    String? ptres,
    String? naturezaDespesa,
    double? estimativaValor,
    String? metodologiaEstimativa,

    String? fonteRecursoId,
    String? programaTrabalhoId,
    String? ptresId,
    String? naturezaDespesaId,
    String? metodologiaEstimativaId,

    String? riscos,
    String? impactoNaoContratar,
    String? prioridade,
    DateTime? dataLimite,
    String? motivacaoLegal,
    String? amparoNormativo,

    String? prioridadeId,

    String? etpAnexo,
    String? projetoBasico,
    String? termoMatrizRiscos,
    String? parecerJuridico,
    String? autorizacaoAbertura,
    String? linksDocumentos,

    String? autoridadeAprovadora,
    String? autoridadeUserId,
    String? autoridadeCpf,
    DateTime? dataAprovacao,
    String? parecerResumo,

    String? autoridadeAprovadoraId,

    String? observacoes,
  }) {
    return DfdData(
      contractId: contractId ?? this.contractId,

      orgaoDemandante: orgaoDemandante ?? this.orgaoDemandante,
      unidadeSolicitante: unidadeSolicitante ?? this.unidadeSolicitante,
      regional: regional ?? this.regional,

      orgaoDemandanteId: orgaoDemandanteId ?? this.orgaoDemandanteId,
      unidadeSolicitanteId: unidadeSolicitanteId ?? this.unidadeSolicitanteId,
      regionalId: regionalId ?? this.regionalId,

      solicitanteNome: solicitanteNome ?? this.solicitanteNome,
      solicitanteUserId: solicitanteUserId ?? this.solicitanteUserId,
      solicitanteCpf: solicitanteCpf ?? this.solicitanteCpf,
      solicitanteCargo: solicitanteCargo ?? this.solicitanteCargo,
      solicitanteEmail: solicitanteEmail ?? this.solicitanteEmail,
      solicitanteTelefone: solicitanteTelefone ?? this.solicitanteTelefone,
      dataSolicitacao: dataSolicitacao ?? this.dataSolicitacao,
      processoAdministrativo: processoAdministrativo ?? this.processoAdministrativo,
      statusDemanda: statusDemanda ?? this.statusDemanda,

      companyId: companyId ?? this.companyId,
      unitId: unitId ?? this.unitId,
      regionId: regionId ?? this.regionId,

      tipoContratacao: tipoContratacao ?? this.tipoContratacao,
      modalidadeEstimativa: modalidadeEstimativa ?? this.modalidadeEstimativa,
      regimeExecucao: regimeExecucao ?? this.regimeExecucao,
      descricaoObjeto: descricaoObjeto ?? this.descricaoObjeto,
      justificativa: justificativa ?? this.justificativa,
      tipoObra: tipoObra ?? this.tipoObra,
      valorDemanda: valorDemanda ?? this.valorDemanda,

      tipoContratacaoId: tipoContratacaoId ?? this.tipoContratacaoId,
      modalidadeEstimativaId: modalidadeEstimativaId ?? this.modalidadeEstimativaId,
      regimeExecucaoId: regimeExecucaoId ?? this.regimeExecucaoId,
      tipoObraId: tipoObraId ?? this.tipoObraId,

      uf: uf ?? this.uf,
      municipio: municipio ?? this.municipio,
      rodovia: rodovia ?? this.rodovia,
      kmInicial: kmInicial ?? this.kmInicial,
      kmFinal: kmFinal ?? this.kmFinal,
      naturezaIntervencao: naturezaIntervencao ?? this.naturezaIntervencao,
      prazoExecucaoDias: prazoExecucaoDias ?? this.prazoExecucaoDias,
      vigenciaMeses: vigenciaMeses ?? this.vigenciaMeses,
      extensaoKm: extensaoKm ?? this.extensaoKm,

      ufId: ufId ?? this.ufId,
      municipioId: municipioId ?? this.municipioId,
      rodoviaId: rodoviaId ?? this.rodoviaId,
      naturezaIntervencaoId: naturezaIntervencaoId ?? this.naturezaIntervencaoId,

      fonteRecurso: fonteRecurso ?? this.fonteRecurso,
      programaTrabalho: programaTrabalho ?? this.programaTrabalho,
      ptres: ptres ?? this.ptres,
      naturezaDespesa: naturezaDespesa ?? this.naturezaDespesa,
      estimativaValor: estimativaValor ?? this.estimativaValor,
      metodologiaEstimativa: metodologiaEstimativa ?? this.metodologiaEstimativa,

      fonteRecursoId: fonteRecursoId ?? this.fonteRecursoId,
      programaTrabalhoId: programaTrabalhoId ?? this.programaTrabalhoId,
      ptresId: ptresId ?? this.ptresId,
      naturezaDespesaId: naturezaDespesaId ?? this.naturezaDespesaId,
      metodologiaEstimativaId: metodologiaEstimativaId ?? this.metodologiaEstimativaId,

      riscos: riscos ?? this.riscos,
      impactoNaoContratar: impactoNaoContratar ?? this.impactoNaoContratar,
      prioridade: prioridade ?? this.prioridade,
      dataLimite: dataLimite ?? this.dataLimite,
      motivacaoLegal: motivacaoLegal ?? this.motivacaoLegal,
      amparoNormativo: amparoNormativo ?? this.amparoNormativo,

      prioridadeId: prioridadeId ?? this.prioridadeId,

      etpAnexo: etpAnexo ?? this.etpAnexo,
      projetoBasico: projetoBasico ?? this.projetoBasico,
      termoMatrizRiscos: termoMatrizRiscos ?? this.termoMatrizRiscos,
      parecerJuridico: parecerJuridico ?? this.parecerJuridico,
      autorizacaoAbertura: autorizacaoAbertura ?? this.autorizacaoAbertura,
      linksDocumentos: linksDocumentos ?? this.linksDocumentos,

      autoridadeAprovadora: autoridadeAprovadora ?? this.autoridadeAprovadora,
      autoridadeUserId: autoridadeUserId ?? this.autoridadeUserId,
      autoridadeCpf: autoridadeCpf ?? this.autoridadeCpf,
      dataAprovacao: dataAprovacao ?? this.dataAprovacao,
      parecerResumo: parecerResumo ?? this.parecerResumo,

      autoridadeAprovadoraId: autoridadeAprovadoraId ?? this.autoridadeAprovadoraId,

      observacoes: observacoes ?? this.observacoes,
    );
  }

  /// ---------------------------------------------------------------------------
  /// Serialização Firestore (map flat) — NÃO inclui contractId
  /// ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() => {
    // 1) Identificação (labels)
    'orgaoDemandante': _toFirestoreValue(orgaoDemandante),
    'unidadeSolicitante': _toFirestoreValue(unidadeSolicitante),
    'regional': _toFirestoreValue(regional),

    // 1) Identificação (ids)
    'orgaoDemandanteId': _toFirestoreValue(orgaoDemandanteId),
    'unidadeSolicitanteId': _toFirestoreValue(unidadeSolicitanteId),
    'regionalId': _toFirestoreValue(regionalId),

    'solicitanteNome': _toFirestoreValue(solicitanteNome),
    'solicitanteUserId': _toFirestoreValue(solicitanteUserId),
    'solicitanteCpf': _toFirestoreValue(solicitanteCpf),
    'solicitanteCargo': _toFirestoreValue(solicitanteCargo),
    'solicitanteEmail': _toFirestoreValue(solicitanteEmail),
    'solicitanteTelefone': _toFirestoreValue(solicitanteTelefone),
    'dataSolicitacao': _toFirestoreValue(dataSolicitacao),
    'numeroProcessoContratacao': _toFirestoreValue(processoAdministrativo),
    'statusContrato': _toFirestoreValue(statusDemanda),
    'companyId': _toFirestoreValue(companyId),
    'unitId': _toFirestoreValue(unitId),
    'regionId': _toFirestoreValue(regionId),

    // 2) Objeto (labels)
    'tipoContratacao': _toFirestoreValue(tipoContratacao),
    'modalidadeEstimativa': _toFirestoreValue(modalidadeEstimativa),
    'regimeExecucao': _toFirestoreValue(regimeExecucao),
    'descricaoObjeto': _toFirestoreValue(descricaoObjeto),
    'justificativa': _toFirestoreValue(justificativa),
    'tipoObra': _toFirestoreValue(tipoObra),
    'valorDemanda': _toFirestoreValue(valorDemanda),

    // 2) Objeto (ids)
    'tipoContratacaoId': _toFirestoreValue(tipoContratacaoId),
    'modalidadeEstimativaId': _toFirestoreValue(modalidadeEstimativaId),
    'regimeExecucaoId': _toFirestoreValue(regimeExecucaoId),
    'tipoObraId': _toFirestoreValue(tipoObraId),

    // 3) Localização (labels)
    'uf': _toFirestoreValue(uf),
    'municipio': _toFirestoreValue(municipio),
    'rodovia': _toFirestoreValue(rodovia),
    'kmInicial': _toFirestoreValue(kmInicial),
    'kmFinal': _toFirestoreValue(kmFinal),
    'naturezaIntervencao': _toFirestoreValue(naturezaIntervencao),
    'prazoExecucaoDias': _toFirestoreValue(prazoExecucaoDias),
    'vigenciaMeses': _toFirestoreValue(vigenciaMeses),
    'extensaoKm': _toFirestoreValue(extensaoKm),

    // 3) Localização (ids)
    'ufId': _toFirestoreValue(ufId),
    'municipioId': _toFirestoreValue(municipioId),
    'rodoviaId': _toFirestoreValue(rodoviaId),
    'naturezaIntervencaoId': _toFirestoreValue(naturezaIntervencaoId),

    // 4) Estimativa (labels)
    'fonteRecurso': _toFirestoreValue(fonteRecurso),
    'programaTrabalho': _toFirestoreValue(programaTrabalho),
    'ptres': _toFirestoreValue(ptres),
    'naturezaDespesa': _toFirestoreValue(naturezaDespesa),
    'estimativaValor': _toFirestoreValue(estimativaValor),
    'metodologiaEstimativa': _toFirestoreValue(metodologiaEstimativa),

    // 4) Estimativa (ids)
    'fonteRecursoId': _toFirestoreValue(fonteRecursoId),
    'programaTrabalhoId': _toFirestoreValue(programaTrabalhoId),
    'ptresId': _toFirestoreValue(ptresId),
    'naturezaDespesaId': _toFirestoreValue(naturezaDespesaId),
    'metodologiaEstimativaId': _toFirestoreValue(metodologiaEstimativaId),

    // 5) Riscos (labels)
    'riscos': _toFirestoreValue(riscos),
    'impactoNaoContratar': _toFirestoreValue(impactoNaoContratar),
    'prioridade': _toFirestoreValue(prioridade),
    'dataLimite': _toFirestoreValue(dataLimite),
    'motivacaoLegal': _toFirestoreValue(motivacaoLegal),
    'amparoNormativo': _toFirestoreValue(amparoNormativo),

    // 5) Riscos (ids)
    'prioridadeId': _toFirestoreValue(prioridadeId),

    // 6) Documentos
    'etpAnexo': _toFirestoreValue(etpAnexo),
    'projetoBasico': _toFirestoreValue(projetoBasico),
    'termoMatrizRiscos': _toFirestoreValue(termoMatrizRiscos),
    'parecerJuridico': _toFirestoreValue(parecerJuridico),
    'autorizacaoAbertura': _toFirestoreValue(autorizacaoAbertura),
    'linksDocumentos': _toFirestoreValue(linksDocumentos),

    // 7) Aprovação (labels)
    'autoridadeAprovadora': _toFirestoreValue(autoridadeAprovadora),
    'autoridadeUserId': _toFirestoreValue(autoridadeUserId),
    'autoridadeCpf': _toFirestoreValue(autoridadeCpf),
    'dataAprovacao': _toFirestoreValue(dataAprovacao),
    'parecerResumo': _toFirestoreValue(parecerResumo),

    // 7) Aprovação (ids)
    'autoridadeAprovadoraId': _toFirestoreValue(autoridadeAprovadoraId),

    // 8) Observações
    'observacoes': _toFirestoreValue(observacoes),
  };

  /// ---------------------------------------------------------------------------
  /// Seções para salvar no Firestore (submaps) — NÃO inclui contractId
  /// ---------------------------------------------------------------------------
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      DfdSections.identificacao: {
        'orgaoDemandante': _toFirestoreValue(orgaoDemandante),
        'unidadeSolicitante': _toFirestoreValue(unidadeSolicitante),
        'regional': _toFirestoreValue(regional),
        'orgaoDemandanteId': _toFirestoreValue(orgaoDemandanteId),
        'unidadeSolicitanteId': _toFirestoreValue(unidadeSolicitanteId),
        'regionalId': _toFirestoreValue(regionalId),
        'solicitanteNome': _toFirestoreValue(solicitanteNome),
        'solicitanteUserId': _toFirestoreValue(solicitanteUserId),
        'solicitanteCpf': _toFirestoreValue(solicitanteCpf),
        'solicitanteCargo': _toFirestoreValue(solicitanteCargo),
        'solicitanteEmail': _toFirestoreValue(solicitanteEmail),
        'solicitanteTelefone': _toFirestoreValue(solicitanteTelefone),
        'dataSolicitacao': _toFirestoreValue(dataSolicitacao),
        'numeroProcessoContratacao': _toFirestoreValue(processoAdministrativo),
        'statusContrato': _toFirestoreValue(statusDemanda),
        'companyId': _toFirestoreValue(companyId),
        'unitId': _toFirestoreValue(unitId),
        'regionId': _toFirestoreValue(regionId),
      },
      DfdSections.objeto: {
        'tipoContratacao': _toFirestoreValue(tipoContratacao),
        'modalidadeEstimativa': _toFirestoreValue(modalidadeEstimativa),
        'regimeExecucao': _toFirestoreValue(regimeExecucao),
        'descricaoObjeto': _toFirestoreValue(descricaoObjeto),
        'justificativa': _toFirestoreValue(justificativa),
        'tipoObra': _toFirestoreValue(tipoObra),
        'valorDemanda': _toFirestoreValue(valorDemanda),
        'tipoContratacaoId': _toFirestoreValue(tipoContratacaoId),
        'modalidadeEstimativaId': _toFirestoreValue(modalidadeEstimativaId),
        'regimeExecucaoId': _toFirestoreValue(regimeExecucaoId),
        'tipoObraId': _toFirestoreValue(tipoObraId),
      },
      DfdSections.localizacao: {
        'uf': _toFirestoreValue(uf),
        'municipio': _toFirestoreValue(municipio),
        'rodovia': _toFirestoreValue(rodovia),
        'kmInicial': _toFirestoreValue(kmInicial),
        'kmFinal': _toFirestoreValue(kmFinal),
        'naturezaIntervencao': _toFirestoreValue(naturezaIntervencao),
        'prazoExecucaoDias': _toFirestoreValue(prazoExecucaoDias),
        'vigenciaMeses': _toFirestoreValue(vigenciaMeses),
        'extensaoKm': _toFirestoreValue(extensaoKm),
        'ufId': _toFirestoreValue(ufId),
        'municipioId': _toFirestoreValue(municipioId),
        'rodoviaId': _toFirestoreValue(rodoviaId),
        'naturezaIntervencaoId': _toFirestoreValue(naturezaIntervencaoId),
        'regionId': _toFirestoreValue(regionId),
      },
      DfdSections.estimativa: {
        'fonteRecurso': _toFirestoreValue(fonteRecurso),
        'programaTrabalho': _toFirestoreValue(programaTrabalho),
        'ptres': _toFirestoreValue(ptres),
        'naturezaDespesa': _toFirestoreValue(naturezaDespesa),
        'estimativaValor': _toFirestoreValue(estimativaValor),
        'metodologiaEstimativa': _toFirestoreValue(metodologiaEstimativa),
        'fonteRecursoId': _toFirestoreValue(fonteRecursoId),
        'programaTrabalhoId': _toFirestoreValue(programaTrabalhoId),
        'ptresId': _toFirestoreValue(ptresId),
        'naturezaDespesaId': _toFirestoreValue(naturezaDespesaId),
        'metodologiaEstimativaId': _toFirestoreValue(metodologiaEstimativaId),
      },
      DfdSections.riscos: {
        'riscos': _toFirestoreValue(riscos),
        'impactoNaoContratar': _toFirestoreValue(impactoNaoContratar),
        'prioridade': _toFirestoreValue(prioridade),
        'prioridadeId': _toFirestoreValue(prioridadeId),
        'dataLimite': _toFirestoreValue(dataLimite),
        'motivacaoLegal': _toFirestoreValue(motivacaoLegal),
        'amparoNormativo': _toFirestoreValue(amparoNormativo),
      },
      DfdSections.documentos: {
        'etpAnexo': _toFirestoreValue(etpAnexo),
        'projetoBasico': _toFirestoreValue(projetoBasico),
        'termoMatrizRiscos': _toFirestoreValue(termoMatrizRiscos),
        'parecerJuridico': _toFirestoreValue(parecerJuridico),
        'autorizacaoAbertura': _toFirestoreValue(autorizacaoAbertura),
        'linksDocumentos': _toFirestoreValue(linksDocumentos),
      },
      DfdSections.aprovacao: {
        'autoridadeAprovadora': _toFirestoreValue(autoridadeAprovadora),
        'autoridadeAprovadoraId': _toFirestoreValue(autoridadeAprovadoraId),
        'autoridadeUserId': _toFirestoreValue(autoridadeUserId),
        'autoridadeCpf': _toFirestoreValue(autoridadeCpf),
        'dataAprovacao': _toFirestoreValue(dataAprovacao),
        'parecerResumo': _toFirestoreValue(parecerResumo),
      },
      DfdSections.observacoes: {
        'observacoes': _toFirestoreValue(observacoes),
      },
    };
  }

  @override
  List<Object?> get props => [
    contractId,

    orgaoDemandante,
    unidadeSolicitante,
    regional,

    orgaoDemandanteId,
    unidadeSolicitanteId,
    regionalId,

    solicitanteNome,
    solicitanteUserId,
    solicitanteCpf,
    solicitanteCargo,
    solicitanteEmail,
    solicitanteTelefone,
    dataSolicitacao,
    processoAdministrativo,
    statusDemanda,
    companyId,
    unitId,
    regionId,

    tipoContratacao,
    modalidadeEstimativa,
    regimeExecucao,
    descricaoObjeto,
    justificativa,
    tipoObra,
    valorDemanda,

    tipoContratacaoId,
    modalidadeEstimativaId,
    regimeExecucaoId,
    tipoObraId,

    uf,
    municipio,
    rodovia,
    kmInicial,
    kmFinal,
    naturezaIntervencao,
    prazoExecucaoDias,
    vigenciaMeses,
    extensaoKm,

    ufId,
    municipioId,
    rodoviaId,
    naturezaIntervencaoId,

    fonteRecurso,
    programaTrabalho,
    ptres,
    naturezaDespesa,
    estimativaValor,
    metodologiaEstimativa,

    fonteRecursoId,
    programaTrabalhoId,
    ptresId,
    naturezaDespesaId,
    metodologiaEstimativaId,

    riscos,
    impactoNaoContratar,
    prioridade,
    dataLimite,
    motivacaoLegal,
    amparoNormativo,

    prioridadeId,

    etpAnexo,
    projetoBasico,
    termoMatrizRiscos,
    parecerJuridico,
    autorizacaoAbertura,
    linksDocumentos,

    autoridadeAprovadora,
    autoridadeAprovadoraId,
    autoridadeUserId,
    autoridadeCpf,
    dataAprovacao,
    parecerResumo,

    observacoes,
  ];
}
