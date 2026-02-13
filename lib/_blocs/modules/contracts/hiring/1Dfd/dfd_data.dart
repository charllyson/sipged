import 'package:equatable/equatable.dart';
import 'package:sipged/_utils/formats/sipged_format_firestore.dart';

import 'dfd_sections.dart';

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

    Map<String, dynamic> sec(String key) {
      final raw = sections[key];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v));
      }
      return const <String, dynamic>{};
    }

    final ident = sec(DfdSections.identificacao);
    final objeto = sec(DfdSections.objeto);
    final localizacao = sec(DfdSections.localizacao);
    final estimativa = sec(DfdSections.estimativa);
    final riscos = sec(DfdSections.riscos);
    final documentos = sec(DfdSections.documentos);
    final aprovacao = sec(DfdSections.aprovacao);
    final observacoes = sec(DfdSections.observacoes);

    String? s(Map<String, dynamic> m, String key) => m[key]?.toString();

    int? i(Map<String, dynamic> m, String key) =>
        SipGedFormatFirestore.toInt(m[key]);

    String? readIdCompat(
        Map<String, dynamic> m,
        String newKey,
        List<String> oldKeys,
        ) {
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
      orgaoDemandante: s(ident, 'orgaoDemandante'),
      unidadeSolicitante: s(ident, 'unidadeSolicitante'),
      regional: s(ident, 'regional'),

      // 1) Identificação (ids)
      orgaoDemandanteId:
      readIdCompat(ident, 'orgaoDemandanteId', const ['orgaoDemandante_id']),
      unidadeSolicitanteId: readIdCompat(
          ident, 'unidadeSolicitanteId', const ['unidadeSolicitante_id']),
      regionalId: readIdCompat(ident, 'regionalId', const ['regional_id']),

      solicitanteNome: s(ident, 'solicitanteNome'),
      solicitanteUserId: s(ident, 'solicitanteUserId'),
      solicitanteCpf: s(ident, 'solicitanteCpf'),
      solicitanteCargo: s(ident, 'solicitanteCargo'),
      solicitanteEmail: s(ident, 'solicitanteEmail'),
      solicitanteTelefone: s(ident, 'solicitanteTelefone'),
      dataSolicitacao: SipGedFormatFirestore.toDate(ident['dataSolicitacao']),
      processoAdministrativo: s(ident, 'numeroProcessoContratacao'),
      statusDemanda: s(ident, 'statusContrato'),

      companyId: s(ident, 'companyId'),
      unitId: s(ident, 'unitId'),
      regionId: s(ident, 'regionId') ?? s(localizacao, 'regionId'),

      // 2) Objeto (labels)
      tipoContratacao: s(objeto, 'tipoContratacao'),
      modalidadeEstimativa: s(objeto, 'modalidadeEstimativa'),
      regimeExecucao: s(objeto, 'regimeExecucao'),
      descricaoObjeto: s(objeto, 'descricaoObjeto'),
      justificativa: s(objeto, 'justificativa'),
      tipoObra: s(objeto, 'tipoObra'),
      valorDemanda: SipGedFormatFirestore.toDouble(objeto['valorDemanda']),

      // 2) Objeto (ids)
      tipoContratacaoId: readIdCompat(
          objeto, 'tipoContratacaoId', const ['tipoContratacao_id']),
      modalidadeEstimativaId: readIdCompat(
          objeto, 'modalidadeEstimativaId', const ['modalidadeEstimativa_id']),
      regimeExecucaoId:
      readIdCompat(objeto, 'regimeExecucaoId', const ['regimeExecucao_id']),
      tipoObraId: readIdCompat(objeto, 'tipoObraId', const ['tipoObra_id']),

      // 3) Localização (labels)
      uf: s(localizacao, 'uf'),
      municipio: s(localizacao, 'municipio'),
      rodovia: s(localizacao, 'rodovia'),
      kmInicial: s(localizacao, 'kmInicial'),
      kmFinal: s(localizacao, 'kmFinal'),
      naturezaIntervencao:
      s(localizacao, 'naturezaIntervencao') ?? s(ident, 'naturezaIntervencao'),
      prazoExecucaoDias: i(localizacao, 'prazoExecucaoDias'),
      vigenciaMeses: i(localizacao, 'vigenciaMeses'),
      extensaoKm: SipGedFormatFirestore.toDouble(localizacao['extensaoKm']),

      // 3) Localização (ids)
      ufId: readIdCompat(localizacao, 'ufId', const ['uf_id']),
      municipioId:
      readIdCompat(localizacao, 'municipioId', const ['municipio_id']),
      rodoviaId: readIdCompat(localizacao, 'rodoviaId', const ['rodovia_id']),
      naturezaIntervencaoId: readIdCompat(
          localizacao, 'naturezaIntervencaoId', const ['naturezaIntervencao_id']),

      // 4) Estimativa (labels)
      fonteRecurso: s(estimativa, 'fonteRecurso'),
      programaTrabalho: s(estimativa, 'programaTrabalho'),
      ptres: s(estimativa, 'ptres'),
      naturezaDespesa: s(estimativa, 'naturezaDespesa'),
      estimativaValor: SipGedFormatFirestore.toDouble(estimativa['estimativaValor']),
      metodologiaEstimativa: s(estimativa, 'metodologiaEstimativa'),

      // 4) Estimativa (ids)
      fonteRecursoId:
      readIdCompat(estimativa, 'fonteRecursoId', const ['fonteRecurso_id']),
      programaTrabalhoId: readIdCompat(
          estimativa, 'programaTrabalhoId', const ['programaTrabalho_id']),
      ptresId: readIdCompat(estimativa, 'ptresId', const ['ptres_id']),
      naturezaDespesaId: readIdCompat(
          estimativa, 'naturezaDespesaId', const ['naturezaDespesa_id']),
      metodologiaEstimativaId: readIdCompat(
          estimativa, 'metodologiaEstimativaId', const ['metodologiaEstimativa_id']),

      // 5) Riscos (labels)
      riscos: s(riscos, 'riscos'),
      impactoNaoContratar: s(riscos, 'impactoNaoContratar'),
      prioridade: s(riscos, 'prioridade'),
      dataLimite: SipGedFormatFirestore.toDate(riscos['dataLimite']),
      motivacaoLegal: s(riscos, 'motivacaoLegal'),
      amparoNormativo: s(riscos, 'amparoNormativo'),

      // 5) Riscos (ids)
      prioridadeId:
      readIdCompat(riscos, 'prioridadeId', const ['prioridade_id']),

      // 6) Documentos
      etpAnexo: s(documentos, 'etpAnexo'),
      projetoBasico: s(documentos, 'projetoBasico'),
      termoMatrizRiscos: s(documentos, 'termoMatrizRiscos'),
      parecerJuridico: s(documentos, 'parecerJuridico'),
      autorizacaoAbertura: s(documentos, 'autorizacaoAbertura'),
      linksDocumentos: s(documentos, 'linksDocumentos'),

      // 7) Aprovação (labels)
      autoridadeAprovadora: s(aprovacao, 'autoridadeAprovadora'),
      autoridadeUserId: s(aprovacao, 'autoridadeUserId'),
      autoridadeCpf: s(aprovacao, 'autoridadeCpf'),
      dataAprovacao: SipGedFormatFirestore.toDate(aprovacao['dataAprovacao']),
      parecerResumo: s(aprovacao, 'parecerResumo'),

      // 7) Aprovação (ids)
      autoridadeAprovadoraId: readIdCompat(
          aprovacao, 'autoridadeAprovadoraId', const ['autoridadeAprovadora_id']),

      // 8) Observações
      observacoes: s(observacoes, 'observacoes'),
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

    String? idCompat(String newKey, List<String> oldKeys) {
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

      orgaoDemandanteId: idCompat('orgaoDemandanteId', const ['orgaoDemandante_id']),
      unidadeSolicitanteId: idCompat('unidadeSolicitanteId', const ['unidadeSolicitante_id']),
      regionalId: idCompat('regionalId', const ['regional_id']),

      solicitanteNome: map['solicitanteNome']?.toString(),
      solicitanteUserId: map['solicitanteUserId']?.toString(),
      solicitanteCpf: map['solicitanteCpf']?.toString(),
      solicitanteCargo: map['solicitanteCargo']?.toString(),
      solicitanteEmail: map['solicitanteEmail']?.toString(),
      solicitanteTelefone: map['solicitanteTelefone']?.toString(),
      dataSolicitacao: SipGedFormatFirestore.toDate(map['dataSolicitacao']),
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
      valorDemanda: SipGedFormatFirestore.toDouble(map['valorDemanda']),

      tipoContratacaoId: idCompat('tipoContratacaoId', const ['tipoContratacao_id']),
      modalidadeEstimativaId: idCompat('modalidadeEstimativaId', const ['modalidadeEstimativa_id']),
      regimeExecucaoId: idCompat('regimeExecucaoId', const ['regimeExecucao_id']),
      tipoObraId: idCompat('tipoObraId', const ['tipoObra_id']),

      uf: map['uf']?.toString(),
      municipio: map['municipio']?.toString(),
      rodovia: map['rodovia']?.toString(),
      kmInicial: map['kmInicial']?.toString(),
      kmFinal: map['kmFinal']?.toString(),
      naturezaIntervencao: map['naturezaIntervencao']?.toString(),
      prazoExecucaoDias: SipGedFormatFirestore.toInt(map['prazoExecucaoDias']),
      vigenciaMeses: SipGedFormatFirestore.toInt(map['vigenciaMeses']),
      extensaoKm: SipGedFormatFirestore.toDouble(map['extensaoKm']),

      ufId: idCompat('ufId', const ['uf_id']),
      municipioId: idCompat('municipioId', const ['municipio_id']),
      rodoviaId: idCompat('rodoviaId', const ['rodovia_id']),
      naturezaIntervencaoId: idCompat('naturezaIntervencaoId', const ['naturezaIntervencao_id']),

      fonteRecurso: map['fonteRecurso']?.toString(),
      programaTrabalho: map['programaTrabalho']?.toString(),
      ptres: map['ptres']?.toString(),
      naturezaDespesa: map['naturezaDespesa']?.toString(),
      estimativaValor: SipGedFormatFirestore.toDouble(map['estimativaValor']),
      metodologiaEstimativa: map['metodologiaEstimativa']?.toString(),

      fonteRecursoId: idCompat('fonteRecursoId', const ['fonteRecurso_id']),
      programaTrabalhoId: idCompat('programaTrabalhoId', const ['programaTrabalho_id']),
      ptresId: idCompat('ptresId', const ['ptres_id']),
      naturezaDespesaId: idCompat('naturezaDespesaId', const ['naturezaDespesa_id']),
      metodologiaEstimativaId: idCompat('metodologiaEstimativaId', const ['metodologiaEstimativa_id']),

      riscos: map['riscos']?.toString(),
      impactoNaoContratar: map['impactoNaoContratar']?.toString(),
      prioridade: map['prioridade']?.toString(),
      dataLimite: SipGedFormatFirestore.toDate(map['dataLimite']),
      motivacaoLegal: map['motivacaoLegal']?.toString(),
      amparoNormativo: map['amparoNormativo']?.toString(),

      prioridadeId: idCompat('prioridadeId', const ['prioridade_id']),

      etpAnexo: map['etpAnexo']?.toString(),
      projetoBasico: map['projetoBasico']?.toString(),
      termoMatrizRiscos: map['termoMatrizRiscos']?.toString(),
      parecerJuridico: map['parecerJuridico']?.toString(),
      autorizacaoAbertura: map['autorizacaoAbertura']?.toString(),
      linksDocumentos: map['linksDocumentos']?.toString(),

      autoridadeAprovadora: map['autoridadeAprovadora']?.toString(),
      autoridadeUserId: map['autoridadeUserId']?.toString(),
      autoridadeCpf: map['autoridadeCpf']?.toString(),
      dataAprovacao: SipGedFormatFirestore.toDate(map['dataAprovacao']),
      parecerResumo: map['parecerResumo']?.toString(),

      autoridadeAprovadoraId: idCompat('autoridadeAprovadoraId', const ['autoridadeAprovadora_id']),

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
    'orgaoDemandante': SipGedFormatFirestore.toFirestoreValue(orgaoDemandante),
    'unidadeSolicitante': SipGedFormatFirestore.toFirestoreValue(unidadeSolicitante),
    'regional': SipGedFormatFirestore.toFirestoreValue(regional),

    // 1) Identificação (ids)
    'orgaoDemandanteId': SipGedFormatFirestore.toFirestoreValue(orgaoDemandanteId),
    'unidadeSolicitanteId': SipGedFormatFirestore.toFirestoreValue(unidadeSolicitanteId),
    'regionalId': SipGedFormatFirestore.toFirestoreValue(regionalId),

    'solicitanteNome': SipGedFormatFirestore.toFirestoreValue(solicitanteNome),
    'solicitanteUserId': SipGedFormatFirestore.toFirestoreValue(solicitanteUserId),
    'solicitanteCpf': SipGedFormatFirestore.toFirestoreValue(solicitanteCpf),
    'solicitanteCargo': SipGedFormatFirestore.toFirestoreValue(solicitanteCargo),
    'solicitanteEmail': SipGedFormatFirestore.toFirestoreValue(solicitanteEmail),
    'solicitanteTelefone': SipGedFormatFirestore.toFirestoreValue(solicitanteTelefone),
    'dataSolicitacao': SipGedFormatFirestore.toFirestoreValue(dataSolicitacao),
    'numeroProcessoContratacao': SipGedFormatFirestore.toFirestoreValue(processoAdministrativo),
    'statusContrato': SipGedFormatFirestore.toFirestoreValue(statusDemanda),
    'companyId': SipGedFormatFirestore.toFirestoreValue(companyId),
    'unitId': SipGedFormatFirestore.toFirestoreValue(unitId),
    'regionId': SipGedFormatFirestore.toFirestoreValue(regionId),

    // 2) Objeto (labels)
    'tipoContratacao': SipGedFormatFirestore.toFirestoreValue(tipoContratacao),
    'modalidadeEstimativa': SipGedFormatFirestore.toFirestoreValue(modalidadeEstimativa),
    'regimeExecucao': SipGedFormatFirestore.toFirestoreValue(regimeExecucao),
    'descricaoObjeto': SipGedFormatFirestore.toFirestoreValue(descricaoObjeto),
    'justificativa': SipGedFormatFirestore.toFirestoreValue(justificativa),
    'tipoObra': SipGedFormatFirestore.toFirestoreValue(tipoObra),
    'valorDemanda': SipGedFormatFirestore.toFirestoreValue(valorDemanda),

    // 2) Objeto (ids)
    'tipoContratacaoId': SipGedFormatFirestore.toFirestoreValue(tipoContratacaoId),
    'modalidadeEstimativaId': SipGedFormatFirestore.toFirestoreValue(modalidadeEstimativaId),
    'regimeExecucaoId': SipGedFormatFirestore.toFirestoreValue(regimeExecucaoId),
    'tipoObraId': SipGedFormatFirestore.toFirestoreValue(tipoObraId),

    // 3) Localização (labels)
    'uf': SipGedFormatFirestore.toFirestoreValue(uf),
    'municipio': SipGedFormatFirestore.toFirestoreValue(municipio),
    'rodovia': SipGedFormatFirestore.toFirestoreValue(rodovia),
    'kmInicial': SipGedFormatFirestore.toFirestoreValue(kmInicial),
    'kmFinal': SipGedFormatFirestore.toFirestoreValue(kmFinal),
    'naturezaIntervencao': SipGedFormatFirestore.toFirestoreValue(naturezaIntervencao),
    'prazoExecucaoDias': SipGedFormatFirestore.toFirestoreValue(prazoExecucaoDias),
    'vigenciaMeses': SipGedFormatFirestore.toFirestoreValue(vigenciaMeses),
    'extensaoKm': SipGedFormatFirestore.toFirestoreValue(extensaoKm),

    // 3) Localização (ids)
    'ufId': SipGedFormatFirestore.toFirestoreValue(ufId),
    'municipioId': SipGedFormatFirestore.toFirestoreValue(municipioId),
    'rodoviaId': SipGedFormatFirestore.toFirestoreValue(rodoviaId),
    'naturezaIntervencaoId': SipGedFormatFirestore.toFirestoreValue(naturezaIntervencaoId),

    // 4) Estimativa (labels)
    'fonteRecurso': SipGedFormatFirestore.toFirestoreValue(fonteRecurso),
    'programaTrabalho': SipGedFormatFirestore.toFirestoreValue(programaTrabalho),
    'ptres': SipGedFormatFirestore.toFirestoreValue(ptres),
    'naturezaDespesa': SipGedFormatFirestore.toFirestoreValue(naturezaDespesa),
    'estimativaValor': SipGedFormatFirestore.toFirestoreValue(estimativaValor),
    'metodologiaEstimativa': SipGedFormatFirestore.toFirestoreValue(metodologiaEstimativa),

    // 4) Estimativa (ids)
    'fonteRecursoId': SipGedFormatFirestore.toFirestoreValue(fonteRecursoId),
    'programaTrabalhoId': SipGedFormatFirestore.toFirestoreValue(programaTrabalhoId),
    'ptresId': SipGedFormatFirestore.toFirestoreValue(ptresId),
    'naturezaDespesaId': SipGedFormatFirestore.toFirestoreValue(naturezaDespesaId),
    'metodologiaEstimativaId': SipGedFormatFirestore.toFirestoreValue(metodologiaEstimativaId),

    // 5) Riscos (labels)
    'riscos': SipGedFormatFirestore.toFirestoreValue(riscos),
    'impactoNaoContratar': SipGedFormatFirestore.toFirestoreValue(impactoNaoContratar),
    'prioridade': SipGedFormatFirestore.toFirestoreValue(prioridade),
    'dataLimite': SipGedFormatFirestore.toFirestoreValue(dataLimite),
    'motivacaoLegal': SipGedFormatFirestore.toFirestoreValue(motivacaoLegal),
    'amparoNormativo': SipGedFormatFirestore.toFirestoreValue(amparoNormativo),

    // 5) Riscos (ids)
    'prioridadeId': SipGedFormatFirestore.toFirestoreValue(prioridadeId),

    // 6) Documentos
    'etpAnexo': SipGedFormatFirestore.toFirestoreValue(etpAnexo),
    'projetoBasico': SipGedFormatFirestore.toFirestoreValue(projetoBasico),
    'termoMatrizRiscos': SipGedFormatFirestore.toFirestoreValue(termoMatrizRiscos),
    'parecerJuridico': SipGedFormatFirestore.toFirestoreValue(parecerJuridico),
    'autorizacaoAbertura': SipGedFormatFirestore.toFirestoreValue(autorizacaoAbertura),
    'linksDocumentos': SipGedFormatFirestore.toFirestoreValue(linksDocumentos),

    // 7) Aprovação (labels)
    'autoridadeAprovadora': SipGedFormatFirestore.toFirestoreValue(autoridadeAprovadora),
    'autoridadeUserId': SipGedFormatFirestore.toFirestoreValue(autoridadeUserId),
    'autoridadeCpf': SipGedFormatFirestore.toFirestoreValue(autoridadeCpf),
    'dataAprovacao': SipGedFormatFirestore.toFirestoreValue(dataAprovacao),
    'parecerResumo': SipGedFormatFirestore.toFirestoreValue(parecerResumo),

    // 7) Aprovação (ids)
    'autoridadeAprovadoraId': SipGedFormatFirestore.toFirestoreValue(autoridadeAprovadoraId),

    // 8) Observações
    'observacoes': SipGedFormatFirestore.toFirestoreValue(observacoes),
  };

  /// ---------------------------------------------------------------------------
  /// Seções para salvar no Firestore (submaps) — NÃO inclui contractId
  /// ---------------------------------------------------------------------------
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      DfdSections.identificacao: {
        'orgaoDemandante': SipGedFormatFirestore.toFirestoreValue(orgaoDemandante),
        'unidadeSolicitante': SipGedFormatFirestore.toFirestoreValue(unidadeSolicitante),
        'regional': SipGedFormatFirestore.toFirestoreValue(regional),
        'orgaoDemandanteId': SipGedFormatFirestore.toFirestoreValue(orgaoDemandanteId),
        'unidadeSolicitanteId': SipGedFormatFirestore.toFirestoreValue(unidadeSolicitanteId),
        'regionalId': SipGedFormatFirestore.toFirestoreValue(regionalId),
        'solicitanteNome': SipGedFormatFirestore.toFirestoreValue(solicitanteNome),
        'solicitanteUserId': SipGedFormatFirestore.toFirestoreValue(solicitanteUserId),
        'solicitanteCpf': SipGedFormatFirestore.toFirestoreValue(solicitanteCpf),
        'solicitanteCargo': SipGedFormatFirestore.toFirestoreValue(solicitanteCargo),
        'solicitanteEmail': SipGedFormatFirestore.toFirestoreValue(solicitanteEmail),
        'solicitanteTelefone': SipGedFormatFirestore.toFirestoreValue(solicitanteTelefone),
        'dataSolicitacao': SipGedFormatFirestore.toFirestoreValue(dataSolicitacao),
        'numeroProcessoContratacao': SipGedFormatFirestore.toFirestoreValue(processoAdministrativo),
        'statusContrato': SipGedFormatFirestore.toFirestoreValue(statusDemanda),
        'companyId': SipGedFormatFirestore.toFirestoreValue(companyId),
        'unitId': SipGedFormatFirestore.toFirestoreValue(unitId),
        'regionId': SipGedFormatFirestore.toFirestoreValue(regionId),
      },
      DfdSections.objeto: {
        'tipoContratacao': SipGedFormatFirestore.toFirestoreValue(tipoContratacao),
        'modalidadeEstimativa': SipGedFormatFirestore.toFirestoreValue(modalidadeEstimativa),
        'regimeExecucao': SipGedFormatFirestore.toFirestoreValue(regimeExecucao),
        'descricaoObjeto': SipGedFormatFirestore.toFirestoreValue(descricaoObjeto),
        'justificativa': SipGedFormatFirestore.toFirestoreValue(justificativa),
        'tipoObra': SipGedFormatFirestore.toFirestoreValue(tipoObra),
        'valorDemanda': SipGedFormatFirestore.toFirestoreValue(valorDemanda),
        'tipoContratacaoId': SipGedFormatFirestore.toFirestoreValue(tipoContratacaoId),
        'modalidadeEstimativaId': SipGedFormatFirestore.toFirestoreValue(modalidadeEstimativaId),
        'regimeExecucaoId': SipGedFormatFirestore.toFirestoreValue(regimeExecucaoId),
        'tipoObraId': SipGedFormatFirestore.toFirestoreValue(tipoObraId),
      },
      DfdSections.localizacao: {
        'uf': SipGedFormatFirestore.toFirestoreValue(uf),
        'municipio': SipGedFormatFirestore.toFirestoreValue(municipio),
        'rodovia': SipGedFormatFirestore.toFirestoreValue(rodovia),
        'kmInicial': SipGedFormatFirestore.toFirestoreValue(kmInicial),
        'kmFinal': SipGedFormatFirestore.toFirestoreValue(kmFinal),
        'naturezaIntervencao': SipGedFormatFirestore.toFirestoreValue(naturezaIntervencao),
        'prazoExecucaoDias': SipGedFormatFirestore.toFirestoreValue(prazoExecucaoDias),
        'vigenciaMeses': SipGedFormatFirestore.toFirestoreValue(vigenciaMeses),
        'extensaoKm': SipGedFormatFirestore.toFirestoreValue(extensaoKm),
        'ufId': SipGedFormatFirestore.toFirestoreValue(ufId),
        'municipioId': SipGedFormatFirestore.toFirestoreValue(municipioId),
        'rodoviaId': SipGedFormatFirestore.toFirestoreValue(rodoviaId),
        'naturezaIntervencaoId': SipGedFormatFirestore.toFirestoreValue(naturezaIntervencaoId),
        'regionId': SipGedFormatFirestore.toFirestoreValue(regionId),
      },
      DfdSections.estimativa: {
        'fonteRecurso': SipGedFormatFirestore.toFirestoreValue(fonteRecurso),
        'programaTrabalho': SipGedFormatFirestore.toFirestoreValue(programaTrabalho),
        'ptres': SipGedFormatFirestore.toFirestoreValue(ptres),
        'naturezaDespesa': SipGedFormatFirestore.toFirestoreValue(naturezaDespesa),
        'estimativaValor': SipGedFormatFirestore.toFirestoreValue(estimativaValor),
        'metodologiaEstimativa': SipGedFormatFirestore.toFirestoreValue(metodologiaEstimativa),
        'fonteRecursoId': SipGedFormatFirestore.toFirestoreValue(fonteRecursoId),
        'programaTrabalhoId': SipGedFormatFirestore.toFirestoreValue(programaTrabalhoId),
        'ptresId': SipGedFormatFirestore.toFirestoreValue(ptresId),
        'naturezaDespesaId': SipGedFormatFirestore.toFirestoreValue(naturezaDespesaId),
        'metodologiaEstimativaId': SipGedFormatFirestore.toFirestoreValue(metodologiaEstimativaId),
      },
      DfdSections.riscos: {
        'riscos': SipGedFormatFirestore.toFirestoreValue(riscos),
        'impactoNaoContratar': SipGedFormatFirestore.toFirestoreValue(impactoNaoContratar),
        'prioridade': SipGedFormatFirestore.toFirestoreValue(prioridade),
        'prioridadeId': SipGedFormatFirestore.toFirestoreValue(prioridadeId),
        'dataLimite': SipGedFormatFirestore.toFirestoreValue(dataLimite),
        'motivacaoLegal': SipGedFormatFirestore.toFirestoreValue(motivacaoLegal),
        'amparoNormativo': SipGedFormatFirestore.toFirestoreValue(amparoNormativo),
      },
      DfdSections.documentos: {
        'etpAnexo': SipGedFormatFirestore.toFirestoreValue(etpAnexo),
        'projetoBasico': SipGedFormatFirestore.toFirestoreValue(projetoBasico),
        'termoMatrizRiscos': SipGedFormatFirestore.toFirestoreValue(termoMatrizRiscos),
        'parecerJuridico': SipGedFormatFirestore.toFirestoreValue(parecerJuridico),
        'autorizacaoAbertura': SipGedFormatFirestore.toFirestoreValue(autorizacaoAbertura),
        'linksDocumentos': SipGedFormatFirestore.toFirestoreValue(linksDocumentos),
      },
      DfdSections.aprovacao: {
        'autoridadeAprovadora': SipGedFormatFirestore.toFirestoreValue(autoridadeAprovadora),
        'autoridadeAprovadoraId': SipGedFormatFirestore.toFirestoreValue(autoridadeAprovadoraId),
        'autoridadeUserId': SipGedFormatFirestore.toFirestoreValue(autoridadeUserId),
        'autoridadeCpf': SipGedFormatFirestore.toFirestoreValue(autoridadeCpf),
        'dataAprovacao': SipGedFormatFirestore.toFirestoreValue(dataAprovacao),
        'parecerResumo': SipGedFormatFirestore.toFirestoreValue(parecerResumo),
      },
      DfdSections.observacoes: {
        'observacoes': SipGedFormatFirestore.toFirestoreValue(observacoes),
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
