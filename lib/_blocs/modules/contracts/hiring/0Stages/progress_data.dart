// lib/_blocs/modules/contracts/hiring/0Stages/progress_data.dart

import 'package:meta/meta.dart';

@immutable
class ProgressData {
  final bool approved;
  final String? approverUid;
  final String? approverName;
  final DateTime? approvalCreatedAt;
  final DateTime? approvalUpdatedAt;

  final bool completed;
  final String? responsibleUserId;
  final String? approverUserId;
  final String? responsibleName;
  final String? stageApproverName;
  final DateTime? stageUpdatedAt;

  const ProgressData({
    required this.approved,
    this.approverUid,
    this.approverName,
    this.approvalCreatedAt,
    this.approvalUpdatedAt,
    required this.completed,
    this.responsibleUserId,
    this.approverUserId,
    this.responsibleName,
    this.stageApproverName,
    this.stageUpdatedAt,
  });

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    try {
      if (v is DateTime) return v;
      // Compat Firestore Timestamp
      final toDate = (v as dynamic).toDate;
      if (toDate is Function) return toDate();
    } catch (_) {}
    return null;
  }

  static Map<String, dynamic> _map(Object? x) =>
      (x is Map<String, dynamic>) ? x : <String, dynamic>{};

  factory ProgressData.fromMap(Map<String, dynamic>? m) {
    final a = _map(m?['approval']);
    final byA = _map(a['approvedBy']);
    final s = _map(m?['stage']);

    // leitura nested
    final resp = _map(s['responsible']);
    final appr = _map(s['approver']);

    return ProgressData(
      approved: (a['approved'] == true),
      approverUid: byA['uid'] as String?,
      approverName: byA['name'] as String?,
      approvalCreatedAt: _ts(a['createdAt']),
      approvalUpdatedAt: _ts(a['updatedAt']),

      completed: (s['completed'] == true),

      // lidos do formato nested gravado no Firestore
      responsibleUserId: resp['uid'] as String?,
      responsibleName: resp['name'] as String?,

      approverUserId: appr['uid'] as String?,
      stageApproverName: appr['name'] as String?,

      stageUpdatedAt: _ts(s['updatedAt']),
    );
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
