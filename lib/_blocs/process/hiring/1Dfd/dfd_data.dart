// lib/_blocs/process/hiring/1Dfd/dfd_data.dart
import 'package:equatable/equatable.dart';

import 'dfd_sections.dart';

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  final s = value.toString().trim();
  if (s.isEmpty) return null;

  // aceita "1.234,56" ou "1234.56"
  final normalized = s.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized);
}

class DfdData extends Equatable {
  // 1) Identificação
  final String orgaoDemandante;
  final String unidadeSolicitante;
  final String? regional;
  final String solicitanteNome;
  final String? solicitanteUserId;
  final String solicitanteCpf;
  final String solicitanteCargo;
  final String solicitanteEmail;
  final String solicitanteTelefone;
  final String dataSolicitacao; // dd/mm/aaaa (mantido como String)
  final String processoAdministrativo;
  final String? statusDemanda; // <<< novo campo (status do contrato/demanda)

  // 2) Objeto
  final String tipoContratacao;
  final String modalidadeEstimativa;
  final String? regimeExecucao; // opcional
  final String descricaoObjeto;
  final String justificativa;
  final String? tipoObra;

  /// 🆕 Valor da demanda (estimativa em número, usado no formulário Objeto)
  final double? valorDemanda;

  // 3) Localização
  final String uf;
  final String municipio;
  final String rodovia;
  final String kmInicial;
  final String kmFinal;
  final String naturezaIntervencao;
  final String prazoExecucaoDias;
  final String vigenciaMeses;
  final double? extensaoKm;

  // 4) Orçamento / Estimativa
  final String fonteRecurso;
  final String programaTrabalho;
  final String ptres;
  final String naturezaDespesa;
  final String estimativaValor;
  final String metodologiaEstimativa;

  // 5) Riscos
  final String riscos;
  final String impactoNaoContratar;
  final String prioridade;
  final String dataLimite;
  final String motivacaoLegal;
  final String amparoNormativo;

  // 6) Documentos
  final String? etpAnexo;
  final String? projetoBasico;
  final String? termoMatrizRiscos;
  final String? parecerJuridico;
  final String? autorizacaoAbertura;
  final String linksDocumentos;

  // 7) Aprovação
  final String autoridadeAprovadora;
  final String? autoridadeUserId;
  final String autoridadeCpf;
  final String dataAprovacao;
  final String parecerResumo;

  // 8) Observações
  final String observacoes;

  const DfdData({
    // 1) Identificação
    required this.orgaoDemandante,
    required this.unidadeSolicitante,
    this.regional,
    required this.solicitanteNome,
    this.solicitanteUserId,
    required this.solicitanteCpf,
    required this.solicitanteCargo,
    required this.solicitanteEmail,
    required this.solicitanteTelefone,
    required this.dataSolicitacao,
    required this.processoAdministrativo,
    this.statusDemanda,

    // 2) Objeto
    required this.tipoContratacao,
    required this.modalidadeEstimativa,
    this.regimeExecucao,
    required this.descricaoObjeto,
    required this.justificativa,
    this.tipoObra,
    this.valorDemanda,

    // 3) Localização
    required this.uf,
    required this.municipio,
    required this.rodovia,
    required this.kmInicial,
    required this.kmFinal,
    required this.naturezaIntervencao,
    this.prazoExecucaoDias = '',
    this.vigenciaMeses = '',
    this.extensaoKm,

    // 4) Orçamento / Estimativa
    required this.fonteRecurso,
    required this.programaTrabalho,
    required this.ptres,
    required this.naturezaDespesa,
    required this.estimativaValor,
    required this.metodologiaEstimativa,

    // 5) Riscos
    required this.riscos,
    required this.impactoNaoContratar,
    required this.prioridade,
    required this.dataLimite,
    required this.motivacaoLegal,
    required this.amparoNormativo,

    // 6) Documentos
    this.etpAnexo,
    this.projetoBasico,
    this.termoMatrizRiscos,
    this.parecerJuridico,
    this.autorizacaoAbertura,
    required this.linksDocumentos,

    // 7) Aprovação
    required this.autoridadeAprovadora,
    this.autoridadeUserId,
    required this.autoridadeCpf,
    required this.dataAprovacao,
    required this.parecerResumo,

    // 8) Observações
    required this.observacoes,
  });

  /// Construtor "vazio" útil para inicializar o form
  const DfdData.empty()
      : orgaoDemandante = '',
        unidadeSolicitante = '',
        regional = null,
        solicitanteNome = '',
        solicitanteUserId = null,
        solicitanteCpf = '',
        solicitanteCargo = '',
        solicitanteEmail = '',
        solicitanteTelefone = '',
        dataSolicitacao = '',
        processoAdministrativo = '',
        statusDemanda = null,
        tipoContratacao = '',
        modalidadeEstimativa = '',
        regimeExecucao = null,
        descricaoObjeto = '',
        justificativa = '',
        tipoObra = null,
        valorDemanda = null,
        uf = '',
        municipio = '',
        rodovia = '',
        kmInicial = '',
        kmFinal = '',
        naturezaIntervencao = '',
        prazoExecucaoDias = '',
        vigenciaMeses = '',
        extensaoKm = null,
        fonteRecurso = '',
        programaTrabalho = '',
        ptres = '',
        naturezaDespesa = '',
        estimativaValor = '',
        metodologiaEstimativa = '',
        riscos = '',
        impactoNaoContratar = '',
        prioridade = '',
        dataLimite = '',
        motivacaoLegal = '',
        amparoNormativo = '',
        etpAnexo = null,
        projetoBasico = null,
        termoMatrizRiscos = null,
        parecerJuridico = null,
        autorizacaoAbertura = null,
        linksDocumentos = '',
        autoridadeAprovadora = '',
        autoridadeUserId = null,
        autoridadeCpf = '',
        dataAprovacao = '',
        parecerResumo = '',
        observacoes = '';

  // ---------------------------------------------------------------------------
  // Map "flat" (sem seções) — compat direto com Firestore, se precisar
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() => {
    // 1) Identificação
    'orgaoDemandante': orgaoDemandante,
    'unidadeSolicitante': unidadeSolicitante,
    'regional': regional,
    'solicitanteNome': solicitanteNome,
    'solicitanteUserId': solicitanteUserId,
    'solicitanteCpf': solicitanteCpf,
    'solicitanteCargo': solicitanteCargo,
    'solicitanteEmail': solicitanteEmail,
    'solicitanteTelefone': solicitanteTelefone,
    'dataSolicitacao': dataSolicitacao,
    'numeroProcessoContratacao': processoAdministrativo,
    'statusContrato': statusDemanda,

    // 2) Objeto
    'tipoContratacao': tipoContratacao,
    'modalidadeEstimativa': modalidadeEstimativa,
    'regimeExecucao': regimeExecucao,
    'descricaoObjeto': descricaoObjeto,
    'justificativa': justificativa,
    'tipoObra': tipoObra,
    'valorDemanda': valorDemanda,

    // 3) Localização
    'uf': uf,
    'municipio': municipio,
    'rodovia': rodovia,
    'kmInicial': kmInicial,
    'kmFinal': kmFinal,
    'naturezaIntervencao': naturezaIntervencao,
    'prazoExecucaoDias': prazoExecucaoDias,
    'vigenciaMeses': vigenciaMeses,
    'extensaoKm': extensaoKm,

    // 4) Orçamento / Estimativa
    'fonteRecurso': fonteRecurso,
    'programaTrabalho': programaTrabalho,
    'ptres': ptres,
    'naturezaDespesa': naturezaDespesa,
    'estimativaValor': estimativaValor,
    'metodologiaEstimativa': metodologiaEstimativa,

    // 5) Riscos
    'riscos': riscos,
    'impactoNaoContratar': impactoNaoContratar,
    'prioridade': prioridade,
    'dataLimite': dataLimite,
    'motivacaoLegal': motivacaoLegal,
    'amparoNormativo': amparoNormativo,

    // 6) Documentos
    'etpAnexo': etpAnexo,
    'projetoBasico': projetoBasico,
    'termoMatrizRiscos': termoMatrizRiscos,
    'parecerJuridico': parecerJuridico,
    'autorizacaoAbertura': autorizacaoAbertura,
    'linksDocumentos': linksDocumentos,

    // 7) Aprovação
    'autoridadeAprovadora': autoridadeAprovadora,
    'autoridadeUserId': autoridadeUserId,
    'autoridadeCpf': autoridadeCpf,
    'dataAprovacao': dataAprovacao,
    'parecerResumo': parecerResumo,

    // 8) Observações
    'observacoes': observacoes,
  };

  factory DfdData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DfdData.empty();

    return DfdData(
      // 1) Identificação
      orgaoDemandante: (map['orgaoDemandante'] ?? '').toString(),
      unidadeSolicitante: (map['unidadeSolicitante'] ?? '').toString(),
      regional: map['regional']?.toString(),
      solicitanteNome: (map['solicitanteNome'] ?? '').toString(),
      solicitanteUserId: map['solicitanteUserId']?.toString(),
      solicitanteCpf: (map['solicitanteCpf'] ?? '').toString(),
      solicitanteCargo: (map['solicitanteCargo'] ?? '').toString(),
      solicitanteEmail: (map['solicitanteEmail'] ?? '').toString(),
      solicitanteTelefone:
      (map['solicitanteTelefone'] ?? '').toString(),
      dataSolicitacao: (map['dataSolicitacao'] ?? '').toString(),
      processoAdministrativo:
      (map['numeroProcessoContratacao'] ?? '').toString(),
      statusDemanda: map['statusContrato']?.toString(),

      // 2) Objeto
      tipoContratacao: (map['tipoContratacao'] ?? '').toString(),
      modalidadeEstimativa:
      (map['modalidadeEstimativa'] ?? '').toString(),
      regimeExecucao: map['regimeExecucao']?.toString(),
      descricaoObjeto: (map['descricaoObjeto'] ?? '').toString(),
      justificativa: (map['justificativa'] ?? '').toString(),
      tipoObra: map['tipoObra']?.toString(),
      valorDemanda: _parseDouble(map['valorDemanda']),

      // 3) Localização
      uf: (map['uf'] ?? '').toString(),
      municipio: (map['municipio'] ?? '').toString(),
      rodovia: (map['rodovia'] ?? '').toString(),
      kmInicial: (map['kmInicial'] ?? '').toString(),
      kmFinal: (map['kmFinal'] ?? '').toString(),
      naturezaIntervencao:
      (map['naturezaIntervencao'] ?? '').toString(),
      prazoExecucaoDias:
      (map['prazoExecucaoDias'] ?? '').toString(),
      vigenciaMeses: (map['vigenciaMeses'] ?? '').toString(),
      extensaoKm: _parseDouble(map['extensaoKm']),

      // 4) Orçamento / Estimativa
      fonteRecurso: (map['fonteRecurso'] ?? '').toString(),
      programaTrabalho:
      (map['programaTrabalho'] ?? '').toString(),
      ptres: (map['ptres'] ?? '').toString(),
      naturezaDespesa:
      (map['naturezaDespesa'] ?? '').toString(),
      estimativaValor: (map['estimativaValor'] ?? '').toString(),
      metodologiaEstimativa:
      (map['metodologiaEstimativa'] ?? '').toString(),

      // 5) Riscos
      riscos: (map['riscos'] ?? '').toString(),
      impactoNaoContratar:
      (map['impactoNaoContratar'] ?? '').toString(),
      prioridade: (map['prioridade'] ?? '').toString(),
      dataLimite: (map['dataLimite'] ?? '').toString(),
      motivacaoLegal: (map['motivacaoLegal'] ?? '').toString(),
      amparoNormativo:
      (map['amparoNormativo'] ?? '').toString(),

      // 6) Documentos
      etpAnexo: map['etpAnexo']?.toString(),
      projetoBasico: map['projetoBasico']?.toString(),
      termoMatrizRiscos: map['termoMatrizRiscos']?.toString(),
      parecerJuridico: map['parecerJuridico']?.toString(),
      autorizacaoAbertura:
      map['autorizacaoAbertura']?.toString(),
      linksDocumentos: (map['linksDocumentos'] ?? '').toString(),

      // 7) Aprovação
      autoridadeAprovadora:
      (map['autoridadeAprovadora'] ?? '').toString(),
      autoridadeUserId: map['autoridadeUserId']?.toString(),
      autoridadeCpf: (map['autoridadeCpf'] ?? '').toString(),
      dataAprovacao: (map['dataAprovacao'] ?? '').toString(),
      parecerResumo: (map['parecerResumo'] ?? '').toString(),

      // 8) Observações
      observacoes: (map['observacoes'] ?? '').toString(),
    );
  }

  // ---------------------------------------------------------------------------
  // Seções (identificacao/objeto/localizacao/estimativa/riscos/documentos/
  //          aprovacao/observacoes)
  // ---------------------------------------------------------------------------

  factory DfdData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final i =
        sections[DfdSections.identificacao] ?? const <String, dynamic>{};
    final o =
        sections[DfdSections.objeto] ?? const <String, dynamic>{};
    final l =
        sections[DfdSections.localizacao] ?? const <String, dynamic>{};
    final e =
        sections[DfdSections.estimativa] ?? const <String, dynamic>{};
    final r =
        sections[DfdSections.riscos] ?? const <String, dynamic>{};
    final d =
        sections[DfdSections.documentos] ?? const <String, dynamic>{};
    final a =
        sections[DfdSections.aprovacao] ?? const <String, dynamic>{};
    final ob =
        sections[DfdSections.observacoes] ?? const <String, dynamic>{};

    return DfdData(
      // 1) Identificação
      orgaoDemandante: (i['orgaoDemandante'] ?? '').toString(),
      unidadeSolicitante: (i['unidadeSolicitante'] ?? '').toString(),
      regional: i['regional']?.toString(),
      solicitanteNome: (i['solicitanteNome'] ?? '').toString(),
      solicitanteUserId: i['solicitanteUserId']?.toString(),
      solicitanteCpf: (i['solicitanteCpf'] ?? '').toString(),
      solicitanteCargo: (i['solicitanteCargo'] ?? '').toString(),
      solicitanteEmail: (i['solicitanteEmail'] ?? '').toString(),
      solicitanteTelefone:
      (i['solicitanteTelefone'] ?? '').toString(),
      dataSolicitacao: (i['dataSolicitacao'] ?? '').toString(),
      processoAdministrativo:
      (i['numeroProcessoContratacao'] ?? '').toString(),
      statusDemanda: i['statusContrato']?.toString(),

      // 2) Objeto
      tipoContratacao: (o['tipoContratacao'] ?? '').toString(),
      modalidadeEstimativa:
      (o['modalidadeEstimativa'] ?? '').toString(),
      regimeExecucao: o['regimeExecucao']?.toString(),
      descricaoObjeto: (o['descricaoObjeto'] ?? '').toString(),
      justificativa: (o['justificativa'] ?? '').toString(),
      tipoObra: o['tipoObra']?.toString(),
      valorDemanda: _parseDouble(o['valorDemanda']),

      // 3) Localização
      uf: (l['uf'] ?? '').toString(),
      municipio: (l['municipio'] ?? '').toString(),
      rodovia: (l['rodovia'] ?? '').toString(),
      kmInicial: (l['kmInicial'] ?? '').toString(),
      kmFinal: (l['kmFinal'] ?? '').toString(),
      naturezaIntervencao:
      (l['naturezaIntervencao'] ?? '').toString(),
      prazoExecucaoDias:
      (l['prazoExecucaoDias'] ?? '').toString(),
      vigenciaMeses: (l['vigenciaMeses'] ?? '').toString(),
      extensaoKm: _parseDouble(l['extensaoKm']),

      // 4) Orçamento / Estimativa
      fonteRecurso: (e['fonteRecurso'] ?? '').toString(),
      programaTrabalho:
      (e['programaTrabalho'] ?? '').toString(),
      ptres: (e['ptres'] ?? '').toString(),
      naturezaDespesa:
      (e['naturezaDespesa'] ?? '').toString(),
      estimativaValor: (e['estimativaValor'] ?? '').toString(),
      metodologiaEstimativa:
      (e['metodologiaEstimativa'] ?? '').toString(),

      // 5) Riscos
      riscos: (r['riscos'] ?? '').toString(),
      impactoNaoContratar:
      (r['impactoNaoContratar'] ?? '').toString(),
      prioridade: (r['prioridade'] ?? '').toString(),
      dataLimite: (r['dataLimite'] ?? '').toString(),
      motivacaoLegal: (r['motivacaoLegal'] ?? '').toString(),
      amparoNormativo:
      (r['amparoNormativo'] ?? '').toString(),

      // 6) Documentos
      etpAnexo: d['etpAnexo']?.toString(),
      projetoBasico: d['projetoBasico']?.toString(),
      termoMatrizRiscos: d['termoMatrizRiscos']?.toString(),
      parecerJuridico: d['parecerJuridico']?.toString(),
      autorizacaoAbertura:
      d['autorizacaoAbertura']?.toString(),
      linksDocumentos: (d['linksDocumentos'] ?? '').toString(),

      // 7) Aprovação
      autoridadeAprovadora:
      (a['autoridadeAprovadora'] ?? '').toString(),
      autoridadeUserId: a['autoridadeUserId']?.toString(),
      autoridadeCpf: (a['autoridadeCpf'] ?? '').toString(),
      dataAprovacao: (a['dataAprovacao'] ?? '').toString(),
      parecerResumo: (a['parecerResumo'] ?? '').toString(),

      // 8) Observações
      observacoes: (ob['observacoes'] ?? '').toString(),
    );
  }

  DfdData copyWith({
    String? orgaoDemandante,
    String? unidadeSolicitante,
    String? regional,
    String? solicitanteNome,
    String? solicitanteUserId,
    String? solicitanteCpf,
    String? solicitanteCargo,
    String? solicitanteEmail,
    String? solicitanteTelefone,
    String? dataSolicitacao,
    String? numeroProcessoContratacao,
    String? statusContrato,
    String? tipoContratacao,
    String? modalidadeEstimativa,
    String? regimeExecucao,
    String? descricaoObjeto,
    String? justificativa,
    String? tipoObra,
    double? valorDemanda,
    String? uf,
    String? municipio,
    String? rodovia,
    String? kmInicial,
    String? kmFinal,
    String? naturezaIntervencao,
    String? prazoExecucaoDias,
    String? vigenciaMeses,
    double? extensaoKm,
    String? fonteRecurso,
    String? programaTrabalho,
    String? ptres,
    String? naturezaDespesa,
    String? estimativaValor,
    String? metodologiaEstimativa,
    String? riscos,
    String? impactoNaoContratar,
    String? prioridade,
    String? dataLimite,
    String? motivacaoLegal,
    String? amparoNormativo,
    String? etpAnexo,
    String? projetoBasico,
    String? termoMatrizRiscos,
    String? parecerJuridico,
    String? autorizacaoAbertura,
    String? linksDocumentos,
    String? autoridadeAprovadora,
    String? autoridadeUserId,
    String? autoridadeCpf,
    String? dataAprovacao,
    String? parecerResumo,
    String? observacoes,
  }) {
    return DfdData(
      orgaoDemandante: orgaoDemandante ?? this.orgaoDemandante,
      unidadeSolicitante:
      unidadeSolicitante ?? this.unidadeSolicitante,
      regional: regional ?? this.regional,
      solicitanteNome: solicitanteNome ?? this.solicitanteNome,
      solicitanteUserId:
      solicitanteUserId ?? this.solicitanteUserId,
      solicitanteCpf: solicitanteCpf ?? this.solicitanteCpf,
      solicitanteCargo: solicitanteCargo ?? this.solicitanteCargo,
      solicitanteEmail: solicitanteEmail ?? this.solicitanteEmail,
      solicitanteTelefone:
      solicitanteTelefone ?? this.solicitanteTelefone,
      dataSolicitacao: dataSolicitacao ?? this.dataSolicitacao,
      processoAdministrativo:
      numeroProcessoContratacao ?? this.processoAdministrativo,
      statusDemanda: statusContrato ?? this.statusDemanda,
      tipoContratacao:
      tipoContratacao ?? this.tipoContratacao,
      modalidadeEstimativa:
      modalidadeEstimativa ?? this.modalidadeEstimativa,
      regimeExecucao: regimeExecucao ?? this.regimeExecucao,
      descricaoObjeto: descricaoObjeto ?? this.descricaoObjeto,
      justificativa: justificativa ?? this.justificativa,
      tipoObra: tipoObra ?? this.tipoObra,
      valorDemanda: valorDemanda ?? this.valorDemanda,
      uf: uf ?? this.uf,
      municipio: municipio ?? this.municipio,
      rodovia: rodovia ?? this.rodovia,
      kmInicial: kmInicial ?? this.kmInicial,
      kmFinal: kmFinal ?? this.kmFinal,
      naturezaIntervencao:
      naturezaIntervencao ?? this.naturezaIntervencao,
      prazoExecucaoDias:
      prazoExecucaoDias ?? this.prazoExecucaoDias,
      vigenciaMeses: vigenciaMeses ?? this.vigenciaMeses,
      extensaoKm: extensaoKm ?? this.extensaoKm,
      fonteRecurso: fonteRecurso ?? this.fonteRecurso,
      programaTrabalho:
      programaTrabalho ?? this.programaTrabalho,
      ptres: ptres ?? this.ptres,
      naturezaDespesa:
      naturezaDespesa ?? this.naturezaDespesa,
      estimativaValor: estimativaValor ?? this.estimativaValor,
      metodologiaEstimativa:
      metodologiaEstimativa ?? this.metodologiaEstimativa,
      riscos: riscos ?? this.riscos,
      impactoNaoContratar:
      impactoNaoContratar ?? this.impactoNaoContratar,
      prioridade: prioridade ?? this.prioridade,
      dataLimite: dataLimite ?? this.dataLimite,
      motivacaoLegal: motivacaoLegal ?? this.motivacaoLegal,
      amparoNormativo: amparoNormativo ?? this.amparoNormativo,
      etpAnexo: etpAnexo ?? this.etpAnexo,
      projetoBasico: projetoBasico ?? this.projetoBasico,
      termoMatrizRiscos:
      termoMatrizRiscos ?? this.termoMatrizRiscos,
      parecerJuridico:
      parecerJuridico ?? this.parecerJuridico,
      autorizacaoAbertura:
      autorizacaoAbertura ?? this.autorizacaoAbertura,
      linksDocumentos:
      linksDocumentos ?? this.linksDocumentos,
      autoridadeAprovadora:
      autoridadeAprovadora ?? this.autoridadeAprovadora,
      autoridadeUserId:
      autoridadeUserId ?? this.autoridadeUserId,
      autoridadeCpf: autoridadeCpf ?? this.autoridadeCpf,
      dataAprovacao: dataAprovacao ?? this.dataAprovacao,
      parecerResumo: parecerResumo ?? this.parecerResumo,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  @override
  List<Object?> get props => [
    orgaoDemandante,
    unidadeSolicitante,
    regional,
    solicitanteNome,
    solicitanteUserId,
    solicitanteCpf,
    solicitanteCargo,
    solicitanteEmail,
    solicitanteTelefone,
    dataSolicitacao,
    processoAdministrativo,
    statusDemanda,
    tipoContratacao,
    modalidadeEstimativa,
    regimeExecucao,
    descricaoObjeto,
    justificativa,
    tipoObra,
    valorDemanda,
    uf,
    municipio,
    rodovia,
    kmInicial,
    kmFinal,
    naturezaIntervencao,
    prazoExecucaoDias,
    vigenciaMeses,
    extensaoKm,
    fonteRecurso,
    programaTrabalho,
    ptres,
    naturezaDespesa,
    estimativaValor,
    metodologiaEstimativa,
    riscos,
    impactoNaoContratar,
    prioridade,
    dataLimite,
    motivacaoLegal,
    amparoNormativo,
    etpAnexo,
    projetoBasico,
    termoMatrizRiscos,
    parecerJuridico,
    autorizacaoAbertura,
    linksDocumentos,
    autoridadeAprovadora,
    autoridadeUserId,
    autoridadeCpf,
    dataAprovacao,
    parecerResumo,
    observacoes,
  ];
}

// -----------------------------------------------------------------------------
// Mapeamento p/ estrutura em seções (mesma usada no Firestore)
// -----------------------------------------------------------------------------
extension DfdDataSections on DfdData {
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      DfdSections.identificacao: {
        'orgaoDemandante': orgaoDemandante,
        'unidadeSolicitante': unidadeSolicitante,
        'regional': regional,
        'solicitanteNome': solicitanteNome,
        'solicitanteUserId': solicitanteUserId,
        'solicitanteCpf': solicitanteCpf,
        'solicitanteCargo': solicitanteCargo,
        'solicitanteEmail': solicitanteEmail,
        'solicitanteTelefone': solicitanteTelefone,
        'dataSolicitacao': dataSolicitacao,
        'numeroProcessoContratacao': processoAdministrativo,
        'statusContrato': statusDemanda,
      },
      DfdSections.objeto: {
        'tipoContratacao': tipoContratacao,
        'modalidadeEstimativa': modalidadeEstimativa,
        'regimeExecucao': regimeExecucao,
        'descricaoObjeto': descricaoObjeto,
        'justificativa': justificativa,
        'tipoObra': tipoObra,
        'valorDemanda': valorDemanda,
      },
      DfdSections.localizacao: {
        'uf': uf,
        'municipio': municipio,
        'rodovia': rodovia,
        'kmInicial': kmInicial,
        'kmFinal': kmFinal,
        'naturezaIntervencao': naturezaIntervencao,
        'prazoExecucaoDias': prazoExecucaoDias,
        'vigenciaMeses': vigenciaMeses,
        'extensaoKm': extensaoKm,
      },
      DfdSections.estimativa: {
        'fonteRecurso': fonteRecurso,
        'programaTrabalho': programaTrabalho,
        'ptres': ptres,
        'naturezaDespesa': naturezaDespesa,
        'estimativaValor': estimativaValor,
        'metodologiaEstimativa': metodologiaEstimativa,
      },
      DfdSections.riscos: {
        'riscos': riscos,
        'impactoNaoContratar': impactoNaoContratar,
        'prioridade': prioridade,
        'dataLimite': dataLimite,
        'motivacaoLegal': motivacaoLegal,
        'amparoNormativo': amparoNormativo,
      },
      DfdSections.documentos: {
        'etpAnexo': etpAnexo,
        'projetoBasico': projetoBasico,
        'termoMatrizRiscos': termoMatrizRiscos,
        'parecerJuridico': parecerJuridico,
        'autorizacaoAbertura': autorizacaoAbertura,
        'linksDocumentos': linksDocumentos,
      },
      DfdSections.aprovacao: {
        'autoridadeAprovadora': autoridadeAprovadora,
        'autoridadeUserId': autoridadeUserId,
        'autoridadeCpf': autoridadeCpf,
        'dataAprovacao': dataAprovacao,
        'parecerResumo': parecerResumo,
      },
      DfdSections.observacoes: {
        'observacoes': observacoes,
      },
    };
  }
}
