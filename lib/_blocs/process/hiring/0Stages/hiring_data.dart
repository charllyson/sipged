
class HiringData {
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
    'Concurso',
  ];

  static const List<String> regimeDeExecucao = [
    'Preço global',
    'Preço unitário',
    'Técnica e preço',
    'Melhor técnica',
    'Maior desconto',
    'Outro',
  ];

  static const List<String> metodologia = [
    'SINAPI',
    'Painel de Preços',
    'Cotações diretas',
    'Misto',
  ];

  static const List<String> complexibilidade = [
    'Baixo',
    'Moderado',
    'Alto',
    'Crítico',
  ];

  static const List<String> criterioConsolidacao = [
    'Média simples',
    'Mediana',
    'Menor preço válido',
    'Outros',
  ];

  static const List<String> criterioJulgamento = [
    'Menor preço',
    'Técnica e preço',
    'Maior desconto',
    'Maior retorno econômico',
  ];

  static const List<String> statusProposta = [
    'Classificada',
    'Desclassificada',
  ];

  static const List<String> docAtestados = [
    'Apresentados',
    'Parciais',
    'Não apresentados',
    'Dispensados',
  ];

  static const List<String> situacaoHabilitacao = [
    'Habilitada',
    'Habilitada com ressalvas',
    'Não habilitada',
    'Aguardando complementos',
  ];

  static const List<String> tiposCertidoes = [
    'Válida',
    'Vencida',
    'Em atualização',
    'Dispensada',
    'Não se aplica',
  ];

  static const List<String> fontsRecuros = [
    '0100 - Tesouro',
    '0120 - Convênios',
    '0150 - Vinculados',
    'Outros',
  ];

  static const List<String> parecerConclusao = [
    'Favorável',
    'Favorável com recomendações',
    'Favorável condicionado (ajustes obrigatórios)',
    'Desfavorável',
  ];

  static const List<String> checklistProposta = [
    'Conforme',
    'Parcial',
    'Não conforme',
    'Não se aplica',
  ];

  static const List<String> tipoExtrato = [
    'Extrato de Contrato',
    'Extrato de ARP',
    'Extrato de Aditivo/Apostilamento',
  ];

  static const List<String> veiculoDivulgacao = [
    'DOE/Estadual',
    'DOU',
    'Diário Municipal',
    'PNCP',
    'Site Oficial',
    'Outro',
  ];

  static const List<String> statusPublicacao = [
    'Rascunho',
    'Enviado',
    'Publicado',
    'Devolvido para ajustes',
  ];

  static const List<String> motivoArquivamento = [
    'Concluído com êxito (objeto atendido)',
    'Desistência/Perda de objeto',
    'Fracasso/Deserto',
    'Inviabilidade técnica/econômica',
    'Determinação superior',
    'Outros',
  ];

  static const List<String> abrangencia = [
    'Total',
    'Parcial (lotes/itens)'
  ];

  static const List<String> decisaoArquivamento = [
    'Aprovo o arquivamento',
    'Arquivar após saneamento',
    'Não aprovo',
  ];

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
    'MANUTENÇÃO',
    'OAE',
    'SINALIZAÇÃO',
    'CONSTRUÇÃO',
    'REABILITAÇÃO',
    'GERENCIAMENTO',
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
}
