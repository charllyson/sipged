// lib/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_utils/formatters/sipged_format_firestore.dart';

/// =============================================================================
///                              DFD DATA MODEL
/// =============================================================================
class DfdData extends Equatable {
  /// Chaves estáveis das seções do DFD.
  static const sectionIdentificacao = 'identificacao';
  static const sectionObjeto = 'objeto';
  static const sectionLocalizacao = 'localizacao';
  static const sectionEstimativa = 'estimativa';
  static const sectionRiscos = 'riscos';
  static const sectionDocumentos = 'documentos';
  static const sectionAprovacao = 'aprovacao';
  static const sectionObservacoes = 'observacoes';

  static const sectionKeys = <String>[
    sectionIdentificacao,
    sectionObjeto,
    sectionLocalizacao,
    sectionEstimativa,
    sectionRiscos,
    sectionDocumentos,
    sectionAprovacao,
    sectionObservacoes,
  ];

  /// Runtime only: id do contrato vem do path.
  /// Não deve ser persistido no Firestore.
  final String? contractId;

  // 1) Identificação - labels
  final String? orgaoDemandante;
  final String? unidadeSolicitante;
  final String? regional;

  // 1) Identificação - IDs
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

  /// IDs auxiliares para dropdowns dinâmicos globais.
  final String? companyId;
  final String? unitId;
  final String? regionId;

  // 2) Objeto - labels
  final String? tipoContratacao;
  final String? modalidadeEstimativa;
  final String? regimeExecucao;
  final String? descricaoObjeto;
  final String? justificativa;
  final String? tipoObra;
  final double? valorDemanda;

  // 2) Objeto - IDs
  final String? tipoContratacaoId;
  final String? modalidadeEstimativaId;
  final String? regimeExecucaoId;
  final String? tipoObraId;

  // 3) Localização - labels
  final String? uf;
  final String? municipio;
  final String? rodovia;
  final String? kmInicial;
  final String? kmFinal;
  final String? naturezaIntervencao;
  final int? prazoExecucaoDias;
  final int? vigenciaMeses;
  final double? extensaoKm;

  // 3) Localização - IDs
  final String? ufId;
  final String? municipioId;
  final String? rodoviaId;
  final String? naturezaIntervencaoId;

  // 4) Estimativa - labels
  final String? fonteRecurso;
  final String? programaTrabalho;
  final String? ptres;
  final String? naturezaDespesa;
  final double? estimativaValor;
  final String? metodologiaEstimativa;

  // 4) Estimativa - IDs
  final String? fonteRecursoId;
  final String? programaTrabalhoId;
  final String? ptresId;
  final String? naturezaDespesaId;
  final String? metodologiaEstimativaId;

  // 5) Riscos - labels
  final String? riscos;
  final String? impactoNaoContratar;
  final String? prioridade;
  final DateTime? dataLimite;
  final String? motivacaoLegal;
  final String? amparoNormativo;

  // 5) Riscos - IDs
  final String? prioridadeId;

  // 6) Documentos
  final String? etpAnexo;
  final String? projetoBasico;
  final String? termoMatrizRiscos;
  final String? parecerJuridico;
  final String? autorizacaoAbertura;
  final String? linksDocumentos;

  // 7) Aprovação - labels
  final String? autoridadeAprovadora;
  final String? autoridadeUserId;
  final String? autoridadeCpf;
  final DateTime? dataAprovacao;
  final String? parecerResumo;

  // 7) Aprovação - IDs
  final String? autoridadeAprovadoraId;

  // 8) Observações
  final String? observacoes;

  const DfdData({
    this.contractId,
    this.orgaoDemandante,
    this.unidadeSolicitante,
    this.regional,
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
    this.companyId,
    this.unitId,
    this.regionId,
    this.tipoContratacao,
    this.modalidadeEstimativa,
    this.regimeExecucao,
    this.descricaoObjeto,
    this.justificativa,
    this.tipoObra,
    this.valorDemanda,
    this.tipoContratacaoId,
    this.modalidadeEstimativaId,
    this.regimeExecucaoId,
    this.tipoObraId,
    this.uf,
    this.municipio,
    this.rodovia,
    this.kmInicial,
    this.kmFinal,
    this.naturezaIntervencao,
    this.prazoExecucaoDias,
    this.vigenciaMeses,
    this.extensaoKm,
    this.ufId,
    this.municipioId,
    this.rodoviaId,
    this.naturezaIntervencaoId,
    this.fonteRecurso,
    this.programaTrabalho,
    this.ptres,
    this.naturezaDespesa,
    this.estimativaValor,
    this.metodologiaEstimativa,
    this.fonteRecursoId,
    this.programaTrabalhoId,
    this.ptresId,
    this.naturezaDespesaId,
    this.metodologiaEstimativaId,
    this.riscos,
    this.impactoNaoContratar,
    this.prioridade,
    this.dataLimite,
    this.motivacaoLegal,
    this.amparoNormativo,
    this.prioridadeId,
    this.etpAnexo,
    this.projetoBasico,
    this.termoMatrizRiscos,
    this.parecerJuridico,
    this.autorizacaoAbertura,
    this.linksDocumentos,
    this.autoridadeAprovadora,
    this.autoridadeUserId,
    this.autoridadeCpf,
    this.dataAprovacao,
    this.parecerResumo,
    this.autoridadeAprovadoraId,
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

  factory DfdData.fromSectionsMap(
      Map<String, dynamic>? sections, {
        String? contractId,
      }) {
    if (sections == null || sections.isEmpty) {
      return const DfdData.empty();
    }

    Map<String, dynamic> sec(String key) {
      final raw = sections[key];

      if (raw is Map<String, dynamic>) {
        return raw;
      }

      if (raw is Map) {
        return raw.map(
              (key, value) => MapEntry(
            key.toString(),
            value,
          ),
        );
      }

      return const <String, dynamic>{};
    }

    final ident = sec(sectionIdentificacao);
    final objeto = sec(sectionObjeto);
    final localizacao = sec(sectionLocalizacao);
    final estimativa = sec(sectionEstimativa);
    final riscosMap = sec(sectionRiscos);
    final documentos = sec(sectionDocumentos);
    final aprovacao = sec(sectionAprovacao);
    final observacoesMap = sec(sectionObservacoes);

    String? s(Map<String, dynamic> map, String key) {
      final value = map[key];

      if (value == null) {
        return null;
      }

      final text = value.toString();

      return text;
    }

    int? i(Map<String, dynamic> map, String key) {
      return SipGedFormatFirestore.toInt(map[key]);
    }

    return DfdData(
      contractId: contractId,

      // 1) Identificação - labels
      orgaoDemandante: s(ident, 'orgaoDemandante'),
      unidadeSolicitante: s(ident, 'unidadeSolicitante'),
      regional: s(ident, 'regional'),

      // 1) Identificação - IDs
      orgaoDemandanteId: s(ident, 'orgaoDemandanteId'),
      unidadeSolicitanteId: s(ident, 'unidadeSolicitanteId'),
      regionalId: s(ident, 'regionalId'),

      solicitanteNome: s(ident, 'solicitanteNome'),
      solicitanteUserId: s(ident, 'solicitanteUserId'),
      solicitanteCpf: s(ident, 'solicitanteCpf'),
      solicitanteCargo: s(ident, 'solicitanteCargo'),
      solicitanteEmail: s(ident, 'solicitanteEmail'),
      solicitanteTelefone: s(ident, 'solicitanteTelefone'),
      dataSolicitacao: SipGedFormatFirestore.toDate(
        ident['dataSolicitacao'],
      ),
      processoAdministrativo: s(ident, 'numeroProcessoContratacao'),
      statusDemanda: s(ident, 'statusContrato'),

      companyId: s(ident, 'companyId'),
      unitId: s(ident, 'unitId'),
      regionId: s(ident, 'regionId') ?? s(localizacao, 'regionId'),

      // 2) Objeto - labels
      tipoContratacao: s(objeto, 'tipoContratacao'),
      modalidadeEstimativa: s(objeto, 'modalidadeEstimativa'),
      regimeExecucao: s(objeto, 'regimeExecucao'),
      descricaoObjeto: s(objeto, 'descricaoObjeto'),
      justificativa: s(objeto, 'justificativa'),
      tipoObra: s(objeto, 'tipoObra'),
      valorDemanda: SipGedFormatFirestore.toDouble(
        objeto['valorDemanda'],
      ),

      // 2) Objeto - IDs
      tipoContratacaoId: s(objeto, 'tipoContratacaoId'),
      modalidadeEstimativaId: s(objeto, 'modalidadeEstimativaId'),
      regimeExecucaoId: s(objeto, 'regimeExecucaoId'),
      tipoObraId: s(objeto, 'tipoObraId'),

      // 3) Localização - labels
      uf: s(localizacao, 'uf'),
      municipio: s(localizacao, 'municipio'),
      rodovia: s(localizacao, 'rodovia'),
      kmInicial: s(localizacao, 'kmInicial'),
      kmFinal: s(localizacao, 'kmFinal'),
      naturezaIntervencao: s(localizacao, 'naturezaIntervencao'),
      prazoExecucaoDias: i(localizacao, 'prazoExecucaoDias'),
      vigenciaMeses: i(localizacao, 'vigenciaMeses'),
      extensaoKm: SipGedFormatFirestore.toDouble(
        localizacao['extensaoKm'],
      ),

      // 3) Localização - IDs
      ufId: s(localizacao, 'ufId'),
      municipioId: s(localizacao, 'municipioId'),
      rodoviaId: s(localizacao, 'rodoviaId'),
      naturezaIntervencaoId: s(localizacao, 'naturezaIntervencaoId'),

      // 4) Estimativa - labels
      fonteRecurso: s(estimativa, 'fonteRecurso'),
      programaTrabalho: s(estimativa, 'programaTrabalho'),
      ptres: s(estimativa, 'ptres'),
      naturezaDespesa: s(estimativa, 'naturezaDespesa'),
      estimativaValor: SipGedFormatFirestore.toDouble(
        estimativa['estimativaValor'],
      ),
      metodologiaEstimativa: s(estimativa, 'metodologiaEstimativa'),

      // 4) Estimativa - IDs
      fonteRecursoId: s(estimativa, 'fonteRecursoId'),
      programaTrabalhoId: s(estimativa, 'programaTrabalhoId'),
      ptresId: s(estimativa, 'ptresId'),
      naturezaDespesaId: s(estimativa, 'naturezaDespesaId'),
      metodologiaEstimativaId: s(estimativa, 'metodologiaEstimativaId'),

      // 5) Riscos - labels
      riscos: s(riscosMap, 'riscos'),
      impactoNaoContratar: s(riscosMap, 'impactoNaoContratar'),
      prioridade: s(riscosMap, 'prioridade'),
      dataLimite: SipGedFormatFirestore.toDate(
        riscosMap['dataLimite'],
      ),
      motivacaoLegal: s(riscosMap, 'motivacaoLegal'),
      amparoNormativo: s(riscosMap, 'amparoNormativo'),

      // 5) Riscos - IDs
      prioridadeId: s(riscosMap, 'prioridadeId'),

      // 6) Documentos
      etpAnexo: s(documentos, 'etpAnexo'),
      projetoBasico: s(documentos, 'projetoBasico'),
      termoMatrizRiscos: s(documentos, 'termoMatrizRiscos'),
      parecerJuridico: s(documentos, 'parecerJuridico'),
      autorizacaoAbertura: s(documentos, 'autorizacaoAbertura'),
      linksDocumentos: s(documentos, 'linksDocumentos'),

      // 7) Aprovação - labels
      autoridadeAprovadora: s(aprovacao, 'autoridadeAprovadora'),
      autoridadeUserId: s(aprovacao, 'autoridadeUserId'),
      autoridadeCpf: s(aprovacao, 'autoridadeCpf'),
      dataAprovacao: SipGedFormatFirestore.toDate(
        aprovacao['dataAprovacao'],
      ),
      parecerResumo: s(aprovacao, 'parecerResumo'),

      // 7) Aprovação - IDs
      autoridadeAprovadoraId: s(aprovacao, 'autoridadeAprovadoraId'),

      // 8) Observações
      observacoes: s(observacoesMap, 'observacoes'),
    );
  }

  factory DfdData.fromMap(
      Map<String, dynamic>? map, {
        String? contractId,
      }) {
    if (map == null) {
      return const DfdData.empty();
    }

    String? s(String key) {
      final value = map[key];

      if (value == null) {
        return null;
      }

      return value.toString();
    }

    return DfdData(
      contractId: contractId,

      orgaoDemandante: s('orgaoDemandante'),
      unidadeSolicitante: s('unidadeSolicitante'),
      regional: s('regional'),

      orgaoDemandanteId: s('orgaoDemandanteId'),
      unidadeSolicitanteId: s('unidadeSolicitanteId'),
      regionalId: s('regionalId'),

      solicitanteNome: s('solicitanteNome'),
      solicitanteUserId: s('solicitanteUserId'),
      solicitanteCpf: s('solicitanteCpf'),
      solicitanteCargo: s('solicitanteCargo'),
      solicitanteEmail: s('solicitanteEmail'),
      solicitanteTelefone: s('solicitanteTelefone'),
      dataSolicitacao: SipGedFormatFirestore.toDate(
        map['dataSolicitacao'],
      ),
      processoAdministrativo: s('numeroProcessoContratacao'),
      statusDemanda: s('statusContrato'),

      companyId: s('companyId'),
      unitId: s('unitId'),
      regionId: s('regionId'),

      tipoContratacao: s('tipoContratacao'),
      modalidadeEstimativa: s('modalidadeEstimativa'),
      regimeExecucao: s('regimeExecucao'),
      descricaoObjeto: s('descricaoObjeto'),
      justificativa: s('justificativa'),
      tipoObra: s('tipoObra'),
      valorDemanda: SipGedFormatFirestore.toDouble(
        map['valorDemanda'],
      ),

      tipoContratacaoId: s('tipoContratacaoId'),
      modalidadeEstimativaId: s('modalidadeEstimativaId'),
      regimeExecucaoId: s('regimeExecucaoId'),
      tipoObraId: s('tipoObraId'),

      uf: s('uf'),
      municipio: s('municipio'),
      rodovia: s('rodovia'),
      kmInicial: s('kmInicial'),
      kmFinal: s('kmFinal'),
      naturezaIntervencao: s('naturezaIntervencao'),
      prazoExecucaoDias: SipGedFormatFirestore.toInt(
        map['prazoExecucaoDias'],
      ),
      vigenciaMeses: SipGedFormatFirestore.toInt(
        map['vigenciaMeses'],
      ),
      extensaoKm: SipGedFormatFirestore.toDouble(
        map['extensaoKm'],
      ),

      ufId: s('ufId'),
      municipioId: s('municipioId'),
      rodoviaId: s('rodoviaId'),
      naturezaIntervencaoId: s('naturezaIntervencaoId'),

      fonteRecurso: s('fonteRecurso'),
      programaTrabalho: s('programaTrabalho'),
      ptres: s('ptres'),
      naturezaDespesa: s('naturezaDespesa'),
      estimativaValor: SipGedFormatFirestore.toDouble(
        map['estimativaValor'],
      ),
      metodologiaEstimativa: s('metodologiaEstimativa'),

      fonteRecursoId: s('fonteRecursoId'),
      programaTrabalhoId: s('programaTrabalhoId'),
      ptresId: s('ptresId'),
      naturezaDespesaId: s('naturezaDespesaId'),
      metodologiaEstimativaId: s('metodologiaEstimativaId'),

      riscos: s('riscos'),
      impactoNaoContratar: s('impactoNaoContratar'),
      prioridade: s('prioridade'),
      dataLimite: SipGedFormatFirestore.toDate(
        map['dataLimite'],
      ),
      motivacaoLegal: s('motivacaoLegal'),
      amparoNormativo: s('amparoNormativo'),

      prioridadeId: s('prioridadeId'),

      etpAnexo: s('etpAnexo'),
      projetoBasico: s('projetoBasico'),
      termoMatrizRiscos: s('termoMatrizRiscos'),
      parecerJuridico: s('parecerJuridico'),
      autorizacaoAbertura: s('autorizacaoAbertura'),
      linksDocumentos: s('linksDocumentos'),

      autoridadeAprovadora: s('autoridadeAprovadora'),
      autoridadeUserId: s('autoridadeUserId'),
      autoridadeCpf: s('autoridadeCpf'),
      dataAprovacao: SipGedFormatFirestore.toDate(
        map['dataAprovacao'],
      ),
      parecerResumo: s('parecerResumo'),

      autoridadeAprovadoraId: s('autoridadeAprovadoraId'),

      observacoes: s('observacoes'),
    );
  }

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
      processoAdministrativo:
      processoAdministrativo ?? this.processoAdministrativo,
      statusDemanda: statusDemanda ?? this.statusDemanda,
      companyId: companyId ?? this.companyId,
      unitId: unitId ?? this.unitId,
      regionId: regionId ?? this.regionId,
      tipoContratacao: tipoContratacao ?? this.tipoContratacao,
      modalidadeEstimativa:
      modalidadeEstimativa ?? this.modalidadeEstimativa,
      regimeExecucao: regimeExecucao ?? this.regimeExecucao,
      descricaoObjeto: descricaoObjeto ?? this.descricaoObjeto,
      justificativa: justificativa ?? this.justificativa,
      tipoObra: tipoObra ?? this.tipoObra,
      valorDemanda: valorDemanda ?? this.valorDemanda,
      tipoContratacaoId: tipoContratacaoId ?? this.tipoContratacaoId,
      modalidadeEstimativaId:
      modalidadeEstimativaId ?? this.modalidadeEstimativaId,
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
      naturezaIntervencaoId:
      naturezaIntervencaoId ?? this.naturezaIntervencaoId,
      fonteRecurso: fonteRecurso ?? this.fonteRecurso,
      programaTrabalho: programaTrabalho ?? this.programaTrabalho,
      ptres: ptres ?? this.ptres,
      naturezaDespesa: naturezaDespesa ?? this.naturezaDespesa,
      estimativaValor: estimativaValor ?? this.estimativaValor,
      metodologiaEstimativa:
      metodologiaEstimativa ?? this.metodologiaEstimativa,
      fonteRecursoId: fonteRecursoId ?? this.fonteRecursoId,
      programaTrabalhoId: programaTrabalhoId ?? this.programaTrabalhoId,
      ptresId: ptresId ?? this.ptresId,
      naturezaDespesaId: naturezaDespesaId ?? this.naturezaDespesaId,
      metodologiaEstimativaId:
      metodologiaEstimativaId ?? this.metodologiaEstimativaId,
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
      autoridadeAprovadoraId:
      autoridadeAprovadoraId ?? this.autoridadeAprovadoraId,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orgaoDemandante':
      SipGedFormatFirestore.toFirestoreValue(orgaoDemandante),
      'unidadeSolicitante':
      SipGedFormatFirestore.toFirestoreValue(unidadeSolicitante),
      'regional': SipGedFormatFirestore.toFirestoreValue(regional),
      'orgaoDemandanteId':
      SipGedFormatFirestore.toFirestoreValue(orgaoDemandanteId),
      'unidadeSolicitanteId':
      SipGedFormatFirestore.toFirestoreValue(unidadeSolicitanteId),
      'regionalId': SipGedFormatFirestore.toFirestoreValue(regionalId),
      'solicitanteNome':
      SipGedFormatFirestore.toFirestoreValue(solicitanteNome),
      'solicitanteUserId':
      SipGedFormatFirestore.toFirestoreValue(solicitanteUserId),
      'solicitanteCpf':
      SipGedFormatFirestore.toFirestoreValue(solicitanteCpf),
      'solicitanteCargo':
      SipGedFormatFirestore.toFirestoreValue(solicitanteCargo),
      'solicitanteEmail':
      SipGedFormatFirestore.toFirestoreValue(solicitanteEmail),
      'solicitanteTelefone':
      SipGedFormatFirestore.toFirestoreValue(solicitanteTelefone),
      'dataSolicitacao':
      SipGedFormatFirestore.toFirestoreValue(dataSolicitacao),
      'numeroProcessoContratacao':
      SipGedFormatFirestore.toFirestoreValue(processoAdministrativo),
      'statusContrato': SipGedFormatFirestore.toFirestoreValue(statusDemanda),
      'companyId': SipGedFormatFirestore.toFirestoreValue(companyId),
      'unitId': SipGedFormatFirestore.toFirestoreValue(unitId),
      'regionId': SipGedFormatFirestore.toFirestoreValue(regionId),
      'tipoContratacao':
      SipGedFormatFirestore.toFirestoreValue(tipoContratacao),
      'modalidadeEstimativa':
      SipGedFormatFirestore.toFirestoreValue(modalidadeEstimativa),
      'regimeExecucao': SipGedFormatFirestore.toFirestoreValue(regimeExecucao),
      'descricaoObjeto':
      SipGedFormatFirestore.toFirestoreValue(descricaoObjeto),
      'justificativa': SipGedFormatFirestore.toFirestoreValue(justificativa),
      'tipoObra': SipGedFormatFirestore.toFirestoreValue(tipoObra),
      'valorDemanda': SipGedFormatFirestore.toFirestoreValue(valorDemanda),
      'tipoContratacaoId':
      SipGedFormatFirestore.toFirestoreValue(tipoContratacaoId),
      'modalidadeEstimativaId':
      SipGedFormatFirestore.toFirestoreValue(modalidadeEstimativaId),
      'regimeExecucaoId':
      SipGedFormatFirestore.toFirestoreValue(regimeExecucaoId),
      'tipoObraId': SipGedFormatFirestore.toFirestoreValue(tipoObraId),
      'uf': SipGedFormatFirestore.toFirestoreValue(uf),
      'municipio': SipGedFormatFirestore.toFirestoreValue(municipio),
      'rodovia': SipGedFormatFirestore.toFirestoreValue(rodovia),
      'kmInicial': SipGedFormatFirestore.toFirestoreValue(kmInicial),
      'kmFinal': SipGedFormatFirestore.toFirestoreValue(kmFinal),
      'naturezaIntervencao':
      SipGedFormatFirestore.toFirestoreValue(naturezaIntervencao),
      'prazoExecucaoDias':
      SipGedFormatFirestore.toFirestoreValue(prazoExecucaoDias),
      'vigenciaMeses': SipGedFormatFirestore.toFirestoreValue(vigenciaMeses),
      'extensaoKm': SipGedFormatFirestore.toFirestoreValue(extensaoKm),
      'ufId': SipGedFormatFirestore.toFirestoreValue(ufId),
      'municipioId': SipGedFormatFirestore.toFirestoreValue(municipioId),
      'rodoviaId': SipGedFormatFirestore.toFirestoreValue(rodoviaId),
      'naturezaIntervencaoId':
      SipGedFormatFirestore.toFirestoreValue(naturezaIntervencaoId),
      'fonteRecurso': SipGedFormatFirestore.toFirestoreValue(fonteRecurso),
      'programaTrabalho':
      SipGedFormatFirestore.toFirestoreValue(programaTrabalho),
      'ptres': SipGedFormatFirestore.toFirestoreValue(ptres),
      'naturezaDespesa':
      SipGedFormatFirestore.toFirestoreValue(naturezaDespesa),
      'estimativaValor':
      SipGedFormatFirestore.toFirestoreValue(estimativaValor),
      'metodologiaEstimativa':
      SipGedFormatFirestore.toFirestoreValue(metodologiaEstimativa),
      'fonteRecursoId':
      SipGedFormatFirestore.toFirestoreValue(fonteRecursoId),
      'programaTrabalhoId':
      SipGedFormatFirestore.toFirestoreValue(programaTrabalhoId),
      'ptresId': SipGedFormatFirestore.toFirestoreValue(ptresId),
      'naturezaDespesaId':
      SipGedFormatFirestore.toFirestoreValue(naturezaDespesaId),
      'metodologiaEstimativaId':
      SipGedFormatFirestore.toFirestoreValue(metodologiaEstimativaId),
      'riscos': SipGedFormatFirestore.toFirestoreValue(riscos),
      'impactoNaoContratar':
      SipGedFormatFirestore.toFirestoreValue(impactoNaoContratar),
      'prioridade': SipGedFormatFirestore.toFirestoreValue(prioridade),
      'dataLimite': SipGedFormatFirestore.toFirestoreValue(dataLimite),
      'motivacaoLegal':
      SipGedFormatFirestore.toFirestoreValue(motivacaoLegal),
      'amparoNormativo':
      SipGedFormatFirestore.toFirestoreValue(amparoNormativo),
      'prioridadeId': SipGedFormatFirestore.toFirestoreValue(prioridadeId),
      'etpAnexo': SipGedFormatFirestore.toFirestoreValue(etpAnexo),
      'projetoBasico': SipGedFormatFirestore.toFirestoreValue(projetoBasico),
      'termoMatrizRiscos':
      SipGedFormatFirestore.toFirestoreValue(termoMatrizRiscos),
      'parecerJuridico':
      SipGedFormatFirestore.toFirestoreValue(parecerJuridico),
      'autorizacaoAbertura':
      SipGedFormatFirestore.toFirestoreValue(autorizacaoAbertura),
      'linksDocumentos':
      SipGedFormatFirestore.toFirestoreValue(linksDocumentos),
      'autoridadeAprovadora':
      SipGedFormatFirestore.toFirestoreValue(autoridadeAprovadora),
      'autoridadeUserId':
      SipGedFormatFirestore.toFirestoreValue(autoridadeUserId),
      'autoridadeCpf': SipGedFormatFirestore.toFirestoreValue(autoridadeCpf),
      'dataAprovacao': SipGedFormatFirestore.toFirestoreValue(dataAprovacao),
      'parecerResumo': SipGedFormatFirestore.toFirestoreValue(parecerResumo),
      'autoridadeAprovadoraId':
      SipGedFormatFirestore.toFirestoreValue(autoridadeAprovadoraId),
      'observacoes': SipGedFormatFirestore.toFirestoreValue(observacoes),
    };
  }

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionIdentificacao: <String, dynamic>{
        'orgaoDemandante':
        SipGedFormatFirestore.toFirestoreValue(orgaoDemandante),
        'unidadeSolicitante':
        SipGedFormatFirestore.toFirestoreValue(unidadeSolicitante),
        'regional': SipGedFormatFirestore.toFirestoreValue(regional),
        'orgaoDemandanteId':
        SipGedFormatFirestore.toFirestoreValue(orgaoDemandanteId),
        'unidadeSolicitanteId':
        SipGedFormatFirestore.toFirestoreValue(unidadeSolicitanteId),
        'regionalId': SipGedFormatFirestore.toFirestoreValue(regionalId),
        'solicitanteNome':
        SipGedFormatFirestore.toFirestoreValue(solicitanteNome),
        'solicitanteUserId':
        SipGedFormatFirestore.toFirestoreValue(solicitanteUserId),
        'solicitanteCpf':
        SipGedFormatFirestore.toFirestoreValue(solicitanteCpf),
        'solicitanteCargo':
        SipGedFormatFirestore.toFirestoreValue(solicitanteCargo),
        'solicitanteEmail':
        SipGedFormatFirestore.toFirestoreValue(solicitanteEmail),
        'solicitanteTelefone':
        SipGedFormatFirestore.toFirestoreValue(solicitanteTelefone),
        'dataSolicitacao':
        SipGedFormatFirestore.toFirestoreValue(dataSolicitacao),
        'numeroProcessoContratacao':
        SipGedFormatFirestore.toFirestoreValue(processoAdministrativo),
        'statusContrato': SipGedFormatFirestore.toFirestoreValue(statusDemanda),
        'companyId': SipGedFormatFirestore.toFirestoreValue(companyId),
        'unitId': SipGedFormatFirestore.toFirestoreValue(unitId),
        'regionId': SipGedFormatFirestore.toFirestoreValue(regionId),
      },
      sectionObjeto: <String, dynamic>{
        'tipoContratacao':
        SipGedFormatFirestore.toFirestoreValue(tipoContratacao),
        'modalidadeEstimativa':
        SipGedFormatFirestore.toFirestoreValue(modalidadeEstimativa),
        'regimeExecucao':
        SipGedFormatFirestore.toFirestoreValue(regimeExecucao),
        'descricaoObjeto':
        SipGedFormatFirestore.toFirestoreValue(descricaoObjeto),
        'justificativa': SipGedFormatFirestore.toFirestoreValue(justificativa),
        'tipoObra': SipGedFormatFirestore.toFirestoreValue(tipoObra),
        'valorDemanda': SipGedFormatFirestore.toFirestoreValue(valorDemanda),
        'tipoContratacaoId':
        SipGedFormatFirestore.toFirestoreValue(tipoContratacaoId),
        'modalidadeEstimativaId':
        SipGedFormatFirestore.toFirestoreValue(modalidadeEstimativaId),
        'regimeExecucaoId':
        SipGedFormatFirestore.toFirestoreValue(regimeExecucaoId),
        'tipoObraId': SipGedFormatFirestore.toFirestoreValue(tipoObraId),
      },
      sectionLocalizacao: <String, dynamic>{
        'uf': SipGedFormatFirestore.toFirestoreValue(uf),
        'municipio': SipGedFormatFirestore.toFirestoreValue(municipio),
        'rodovia': SipGedFormatFirestore.toFirestoreValue(rodovia),
        'kmInicial': SipGedFormatFirestore.toFirestoreValue(kmInicial),
        'kmFinal': SipGedFormatFirestore.toFirestoreValue(kmFinal),
        'naturezaIntervencao':
        SipGedFormatFirestore.toFirestoreValue(naturezaIntervencao),
        'prazoExecucaoDias':
        SipGedFormatFirestore.toFirestoreValue(prazoExecucaoDias),
        'vigenciaMeses': SipGedFormatFirestore.toFirestoreValue(vigenciaMeses),
        'extensaoKm': SipGedFormatFirestore.toFirestoreValue(extensaoKm),
        'ufId': SipGedFormatFirestore.toFirestoreValue(ufId),
        'municipioId': SipGedFormatFirestore.toFirestoreValue(municipioId),
        'rodoviaId': SipGedFormatFirestore.toFirestoreValue(rodoviaId),
        'naturezaIntervencaoId':
        SipGedFormatFirestore.toFirestoreValue(naturezaIntervencaoId),
        'regionId': SipGedFormatFirestore.toFirestoreValue(regionId),
      },
      sectionEstimativa: <String, dynamic>{
        'fonteRecurso': SipGedFormatFirestore.toFirestoreValue(fonteRecurso),
        'programaTrabalho':
        SipGedFormatFirestore.toFirestoreValue(programaTrabalho),
        'ptres': SipGedFormatFirestore.toFirestoreValue(ptres),
        'naturezaDespesa':
        SipGedFormatFirestore.toFirestoreValue(naturezaDespesa),
        'estimativaValor':
        SipGedFormatFirestore.toFirestoreValue(estimativaValor),
        'metodologiaEstimativa':
        SipGedFormatFirestore.toFirestoreValue(metodologiaEstimativa),
        'fonteRecursoId':
        SipGedFormatFirestore.toFirestoreValue(fonteRecursoId),
        'programaTrabalhoId':
        SipGedFormatFirestore.toFirestoreValue(programaTrabalhoId),
        'ptresId': SipGedFormatFirestore.toFirestoreValue(ptresId),
        'naturezaDespesaId':
        SipGedFormatFirestore.toFirestoreValue(naturezaDespesaId),
        'metodologiaEstimativaId':
        SipGedFormatFirestore.toFirestoreValue(metodologiaEstimativaId),
      },
      sectionRiscos: <String, dynamic>{
        'riscos': SipGedFormatFirestore.toFirestoreValue(riscos),
        'impactoNaoContratar':
        SipGedFormatFirestore.toFirestoreValue(impactoNaoContratar),
        'prioridade': SipGedFormatFirestore.toFirestoreValue(prioridade),
        'prioridadeId': SipGedFormatFirestore.toFirestoreValue(prioridadeId),
        'dataLimite': SipGedFormatFirestore.toFirestoreValue(dataLimite),
        'motivacaoLegal':
        SipGedFormatFirestore.toFirestoreValue(motivacaoLegal),
        'amparoNormativo':
        SipGedFormatFirestore.toFirestoreValue(amparoNormativo),
      },
      sectionDocumentos: <String, dynamic>{
        'etpAnexo': SipGedFormatFirestore.toFirestoreValue(etpAnexo),
        'projetoBasico': SipGedFormatFirestore.toFirestoreValue(projetoBasico),
        'termoMatrizRiscos':
        SipGedFormatFirestore.toFirestoreValue(termoMatrizRiscos),
        'parecerJuridico':
        SipGedFormatFirestore.toFirestoreValue(parecerJuridico),
        'autorizacaoAbertura':
        SipGedFormatFirestore.toFirestoreValue(autorizacaoAbertura),
        'linksDocumentos':
        SipGedFormatFirestore.toFirestoreValue(linksDocumentos),
      },
      sectionAprovacao: <String, dynamic>{
        'autoridadeAprovadora':
        SipGedFormatFirestore.toFirestoreValue(autoridadeAprovadora),
        'autoridadeAprovadoraId':
        SipGedFormatFirestore.toFirestoreValue(autoridadeAprovadoraId),
        'autoridadeUserId':
        SipGedFormatFirestore.toFirestoreValue(autoridadeUserId),
        'autoridadeCpf': SipGedFormatFirestore.toFirestoreValue(autoridadeCpf),
        'dataAprovacao': SipGedFormatFirestore.toFirestoreValue(dataAprovacao),
        'parecerResumo': SipGedFormatFirestore.toFirestoreValue(parecerResumo),
      },
      sectionObservacoes: <String, dynamic>{
        'observacoes': SipGedFormatFirestore.toFirestoreValue(observacoes),
      },
    };
  }

  @override
  List<Object?> get props => <Object?>[
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