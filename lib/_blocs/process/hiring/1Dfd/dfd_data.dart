// lib/_blocs/process/hiring/1Dfd/dfd_data.dart

class DfdData {
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
  final String dataSolicitacao; // dd/mm/aaaa
  final String protocoloSei;

  // 2) Objeto
  final String tipoContratacao;
  final String modalidadeEstimativa;
  final String? regimeExecucao; // opcional
  final String descricaoObjeto;
  final String justificativa;

  // 3) Localização
  final String uf;
  final String municipio;
  final String rodovia;
  final String kmInicial;
  final String kmFinal;
  final String naturezaIntervencao;
  final String prazoExecucaoDias;
  final String vigenciaMeses;

  // 4) Orçamento
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
    required this.protocoloSei,
    required this.tipoContratacao,
    required this.modalidadeEstimativa,
    this.regimeExecucao,
    required this.descricaoObjeto,
    required this.justificativa,
    required this.uf,
    required this.municipio,
    required this.rodovia,
    required this.kmInicial,
    required this.kmFinal,
    required this.naturezaIntervencao,
    this.prazoExecucaoDias = '',
    this.vigenciaMeses = '',
    required this.fonteRecurso,
    required this.programaTrabalho,
    required this.ptres,
    required this.naturezaDespesa,
    required this.estimativaValor,
    required this.metodologiaEstimativa,
    required this.riscos,
    required this.impactoNaoContratar,
    required this.prioridade,
    required this.dataLimite,
    required this.motivacaoLegal,
    required this.amparoNormativo,
    this.etpAnexo,
    this.projetoBasico,
    this.termoMatrizRiscos,
    this.parecerJuridico,
    this.autorizacaoAbertura,
    required this.linksDocumentos,
    required this.autoridadeAprovadora,
    this.autoridadeUserId,
    required this.autoridadeCpf,
    required this.dataAprovacao,
    required this.parecerResumo,
    required this.observacoes,
  });

  static List<String> statusTypes = [
    'EM ANDAMENTO',
    'A INICIAR',
    'CONCLUÍDO',
    'PARALISADO',
    'CANCELADO',
    'EM PROJETO',
  ];

  static Map<String, int> priorityStatus = {
    'EM ANDAMENTO': 0,
    'A INICIAR': 1,
    'EM PROJETO': 2,
    'PARALISADO': 3,
    'CONCLUÍDO': 4,
    'CANCELADO': 5,
  };

  static List<String> typeOfService = [
    'IMPLANTAÇÃO',
    'PAVIMENTAÇÃO',
    'IMPLANTAÇÃO E PAVIMENTAÇÃO',
    'RESTAURAÇÃO',
    'DUPLICAÇÃO',
    'CONSERVAÇÃO',
    'MANUTENÇÃO',
    'VICINAIS',
    'VIAS URBANAS',
    'OAE',
    'SINALIZAÇÃO',
    'CONSTRUÇÃO',
    'REABILITAÇÃO',
    'GERENCIAMENTO',
    'SUPERVISÃO',
    'FISCALIZAÇÃO',
    'ELABORAÇÃO DE PROJETO',
  ];

  static const List<String> workTypes = [
    'RODOVIÁRIA',
    'CONSTRUÇÃO CIVIL',
    'ARTES ESPECIAIS',
  ];

  static const List<String> regions = [
    'AGRESTE',
    'NORTE',
    'METROPOLITANA',
    'SERTÃO',
    'SUL',
    'VALE DO MUNDAÚ',
    'VALE DO PARAÍBA'
  ];

  static String getTitleByStatus(String status) {
    switch (status) {
      case 'EM ANDAMENTO':
        return 'Demandas em Andamento';
      case 'A INICIAR':
        return 'Demandas a Iniciar';
      case 'CONCLUÍDO':
        return 'Demandas Concluídas';
      case 'EM PROJETO':
        return 'Demandas em Projeto';
      case 'PARALISADO':
        return 'Demandas Paralisadas';
      case 'CANCELADO':
        return 'Demandas Canceladas';
      default:
        return 'Outro';
    }
  }

  static const List<String> tiposDeContratacao = [
    'Obra de engenharia',
    'Serviço de engenharia',
    'Serviço comum',
    'Aquisição de material/equipamento',
  ];

  static const List<String> modalidadeDeContratacao = [
    'Dispensa',
    'Inexigibilidade',
    'Pregão',
    'Concorrência',
    'RDC',
    'Concurso'
  ];

  static const List<String> regimeDeExecucao = [
    'Preço global',
    'Preço unitário',
    'Técnica e preço',
    'Melhor técnica',
    'Maior desconto',
    'Outro'
  ];

  Map<String, dynamic> toMap() => {
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
    'protocoloSei': protocoloSei,
    'tipoContratacao': tipoContratacao,
    'modalidadeEstimativa': modalidadeEstimativa,
    'regimeExecucao': regimeExecucao,
    'descricaoObjeto': descricaoObjeto,
    'justificativa': justificativa,
    'uf': uf,
    'municipio': municipio,
    'rodovia': rodovia,
    'kmInicial': kmInicial,
    'kmFinal': kmFinal,
    'naturezaIntervencao': naturezaIntervencao,
    'prazoExecucaoDias': prazoExecucaoDias,
    'vigenciaMeses': vigenciaMeses,
    'fonteRecurso': fonteRecurso,
    'programaTrabalho': programaTrabalho,
    'ptres': ptres,
    'naturezaDespesa': naturezaDespesa,
    'estimativaValor': estimativaValor,
    'metodologiaEstimativa': metodologiaEstimativa,
    'riscos': riscos,
    'impactoNaoContratar': impactoNaoContratar,
    'prioridade': prioridade,
    'dataLimite': dataLimite,
    'motivacaoLegal': motivacaoLegal,
    'amparoNormativo': amparoNormativo,
    'etpAnexo': etpAnexo,
    'projetoBasico': projetoBasico,
    'termoMatrizRiscos': termoMatrizRiscos,
    'parecerJuridico': parecerJuridico,
    'autorizacaoAbertura': autorizacaoAbertura,
    'linksDocumentos': linksDocumentos,
    'autoridadeAprovadora': autoridadeAprovadora,
    'autoridadeUserId': autoridadeUserId,
    'autoridadeCpf': autoridadeCpf,
    'dataAprovacao': dataAprovacao,
    'parecerResumo': parecerResumo,
    'observacoes': observacoes,
  };

  factory DfdData.fromMap(Map<String, dynamic> map) => DfdData(
    orgaoDemandante: map['orgaoDemandante'] ?? '',
    unidadeSolicitante: map['unidadeSolicitante'] ?? '',
    regional: map['regional'],
    solicitanteNome: map['solicitanteNome'] ?? '',
    solicitanteUserId: map['solicitanteUserId'],
    solicitanteCpf: map['solicitanteCpf'] ?? '',
    solicitanteCargo: map['solicitanteCargo'] ?? '',
    solicitanteEmail: map['solicitanteEmail'] ?? '',
    solicitanteTelefone: map['solicitanteTelefone'] ?? '',
    dataSolicitacao: map['dataSolicitacao'] ?? '',
    protocoloSei: map['protocoloSei'] ?? '',
    tipoContratacao: map['tipoContratacao'] ?? '',
    modalidadeEstimativa: map['modalidadeEstimativa'] ?? '',
    regimeExecucao: map['regimeExecucao'],
    descricaoObjeto: map['descricaoObjeto'] ?? '',
    justificativa: map['justificativa'] ?? '',
    uf: map['uf'] ?? '',
    municipio: map['municipio'] ?? '',
    rodovia: map['rodovia'] ?? '',
    kmInicial: map['kmInicial'] ?? '',
    kmFinal: map['kmFinal'] ?? '',
    naturezaIntervencao: map['naturezaIntervencao'] ?? '',
    prazoExecucaoDias: map['prazoExecucaoDias'] ?? '',
    vigenciaMeses: map['vigenciaMeses'] ?? '',
    fonteRecurso: map['fonteRecurso'] ?? '',
    programaTrabalho: map['programaTrabalho'] ?? '',
    ptres: map['ptres'] ?? '',
    naturezaDespesa: map['naturezaDespesa'] ?? '',
    estimativaValor: map['estimativaValor'] ?? '',
    metodologiaEstimativa: map['metodologiaEstimativa'] ?? '',
    riscos: map['riscos'] ?? '',
    impactoNaoContratar: map['impactoNaoContratar'] ?? '',
    prioridade: map['prioridade'] ?? '',
    dataLimite: map['dataLimite'] ?? '',
    motivacaoLegal: map['motivacaoLegal'] ?? '',
    amparoNormativo: map['amparoNormativo'] ?? '',
    etpAnexo: map['etpAnexo'],
    projetoBasico: map['projetoBasico'],
    termoMatrizRiscos: map['termoMatrizRiscos'],
    parecerJuridico: map['parecerJuridico'],
    autorizacaoAbertura: map['autorizacaoAbertura'],
    linksDocumentos: map['linksDocumentos'] ?? '',
    autoridadeAprovadora: map['autoridadeAprovadora'] ?? '',
    autoridadeUserId: map['autoridadeUserId'],
    autoridadeCpf: map['autoridadeCpf'] ?? '',
    dataAprovacao: map['dataAprovacao'] ?? '',
    parecerResumo: map['parecerResumo'] ?? '',
    observacoes: map['observacoes'] ?? '',
  );


}
