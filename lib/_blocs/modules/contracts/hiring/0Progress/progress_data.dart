import 'package:flutter/material.dart';

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

  static DateTime? _ts(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final toDate = (value as dynamic).toDate;

      if (toDate is Function) {
        return toDate();
      }
    } catch (_) {}

    return null;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
            (key, val) => MapEntry(
          key.toString(),
          val,
        ),
      );
    }

    return <String, dynamic>{};
  }

  factory ProgressData.fromMap(Map<String, dynamic>? map) {
    final approval = _map(map?['approval']);
    final approvedBy = _map(approval['approvedBy']);

    final stage = _map(map?['stage']);
    final responsible = _map(stage['responsible']);
    final approver = _map(stage['approver']);

    return ProgressData(
      approved: approval['approved'] == true,
      approverUid: approvedBy['uid'] as String?,
      approverName: approvedBy['name'] as String?,
      approvalCreatedAt: _ts(approval['createdAt']),
      approvalUpdatedAt: _ts(approval['updatedAt']),
      completed: stage['completed'] == true,
      responsibleUserId: responsible['uid'] as String?,
      responsibleName: responsible['name'] as String?,
      approverUserId: approver['uid'] as String?,
      stageApproverName: approver['name'] as String?,
      stageUpdatedAt: _ts(stage['updatedAt']),
    );
  }

  // ===========================================================================
  // CORES DE STATUS
  // ===========================================================================

  static ({
  Color background,
  Color border,
  Color title,
  }) certidaoColorsForStatus(
      String status,
      ThemeData theme,
      ) {
    Color bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    Color border = theme.dividerColor;
    Color title = theme.colorScheme.onSurface;

    switch (status) {
      case 'Válida':
        bg = Colors.green.shade50;
        border = Colors.green.shade400;
        title = Colors.green.shade800;
        break;

      case 'Vencida':
        bg = Colors.red.shade50;
        border = Colors.red.shade400;
        title = Colors.red.shade800;
        break;

      case 'Em atualização':
        bg = Colors.orange.shade50;
        border = Colors.orange.shade400;
        title = Colors.orange.shade800;
        break;

      case 'Dispensada':
        bg = Colors.blueGrey.shade50;
        border = Colors.blueGrey.shade300;
        title = Colors.blueGrey.shade800;
        break;

      case 'Não se aplica':
        bg = Colors.grey.shade100;
        border = Colors.grey.shade400;
        title = Colors.grey.shade800;
        break;
    }

    return (
    background: bg,
    border: border,
    title: title,
    );
  }

  static ({
  Color background,
  Color border,
  Color title,
  }) checklistColorsForStatus(
      String status,
      ThemeData theme,
      ) {
    Color bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    Color border = theme.dividerColor;
    Color title = theme.colorScheme.onSurface;

    switch (status) {
      case 'Conforme':
        bg = Colors.green.shade50;
        border = Colors.green.shade400;
        title = Colors.green.shade800;
        break;

      case 'Parcial':
        bg = Colors.orange.shade50;
        border = Colors.orange.shade400;
        title = Colors.orange.shade800;
        break;

      case 'Não conforme':
        bg = Colors.red.shade50;
        border = Colors.red.shade400;
        title = Colors.red.shade800;
        break;

      case 'N/A':
        bg = Colors.grey.shade100;
        border = Colors.grey.shade400;
        title = Colors.grey.shade700;
        break;
    }

    return (
    background: bg,
    border: border,
    title: title,
    );
  }

  // ===========================================================================
  // LISTAS DE DOMÍNIO
  // ===========================================================================

  static const dfd = 'dfd';
  static const etp = 'etp';
  static const tr = 'tr';
  static const cotacao = 'cotacao';
  static const edital = 'edital';
  static const habilitacao = 'habilitacao';
  static const dotacao = 'dotacao';
  static const minuta = 'minuta';
  static const parecer = 'parecer';
  static const publicacao = 'publicacao';
  static const arquivamento = 'arquivamento';

  /// Ordem de desbloqueio.
  static const ordered = <String>[
    dfd,
    etp,
    tr,
    cotacao,
    edital,
    habilitacao,
    dotacao,
    minuta,
    parecer,
    publicacao,
    arquivamento,
  ];

  static const List<String> tiposDeContratacao = <String>[
    'Obra de engenharia',
    'Serviço de engenharia',
    'Serviço comum',
    'Aquisição de material/equipamento',
  ];

  static const List<String> modalidadeDeContratacao = <String>[
    'Dispensa',
    'Inexigibilidade',
    'Pregão',
    'Concorrência',
    'RDC',
    'Concurso',
  ];

  static const List<String> regimeDeExecucao = <String>[
    'Preço global',
    'Preço unitário',
    'Técnica e preço',
    'Melhor técnica',
    'Maior desconto',
    'Outro',
  ];

  static const List<String> metodologia = <String>[
    'SINAPI',
    'Painel de Preços',
    'Cotações diretas',
    'Misto',
  ];

  static const List<String> complexibilidade = <String>[
    'Baixo',
    'Moderado',
    'Alto',
    'Crítico',
  ];

  static const List<String> criterioConsolidacao = <String>[
    'Média simples',
    'Mediana',
    'Menor preço válido',
    'Outros',
  ];

  static const List<String> criterioJulgamento = <String>[
    'Menor preço',
    'Técnica e preço',
    'Maior desconto',
    'Maior retorno econômico',
  ];

  static const List<String> statusProposta = <String>[
    'Classificada',
    'Desclassificada',
  ];

  static const List<String> docAtestados = <String>[
    'Apresentados',
    'Parciais',
    'Não apresentados',
    'Dispensados',
  ];

  static const List<String> situacaoHabilitacao = <String>[
    'Habilitada',
    'Habilitada com ressalvas',
    'Não habilitada',
    'Aguardando complementos',
  ];

  static const List<String> tiposCertidoes = <String>[
    'Válida',
    'Vencida',
    'Em atualização',
    'Dispensada',
    'Não se aplica',
  ];

  static const List<String> fontsRecuros = <String>[
    '0100 - Tesouro',
    '0120 - Convênios',
    '0150 - Vinculados',
    'Outros',
  ];

  static const List<String> parecerConclusao = <String>[
    'Favorável',
    'Favorável com recomendações',
    'Favorável condicionado (ajustes obrigatórios)',
    'Desfavorável',
  ];

  static const List<String> checklistProposta = <String>[
    'Conforme',
    'Parcial',
    'Não conforme',
    'Não se aplica',
  ];

  static const List<String> tipoExtrato = <String>[
    'Extrato de Contrato',
    'Extrato de ARP',
    'Extrato de Aditivo/Apostilamento',
  ];

  static const List<String> veiculoDivulgacao = <String>[
    'DOE/Estadual',
    'DOU',
    'Diário Municipal',
    'PNCP',
    'Site Oficial',
    'Outro',
  ];

  static const List<String> statusPublicacao = <String>[
    'Rascunho',
    'Enviado',
    'Publicado',
    'Devolvido para ajustes',
  ];

  static const List<String> motivoArquivamento = <String>[
    'Concluído com êxito (objeto atendido)',
    'Desistência/Perda de objeto',
    'Fracasso/Deserto',
    'Inviabilidade técnica/econômica',
    'Determinação superior',
    'Outros',
  ];

  static const List<String> abrangencia = <String>[
    'Total',
    'Parcial (lotes/itens)',
  ];

  static const List<String> decisaoArquivamento = <String>[
    'Aprovo o arquivamento',
    'Arquivar após saneamento',
    'Não aprovo',
  ];

  static const List<String> statusTypes = <String>[
    'EM ANDAMENTO',
    'A INICIAR',
    'CONCLUÍDO',
    'PARALISADO',
    'CANCELADO',
    'EM PROJETO',
  ];

  static const Map<String, int> priorityStatus = <String, int>{
    'EM ANDAMENTO': 0,
    'A INICIAR': 1,
    'EM PROJETO': 2,
    'PARALISADO': 3,
    'CONCLUÍDO': 4,
    'CANCELADO': 5,
  };

  static const List<String> typeOfService = <String>[
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

  static const List<String> workTypes = <String>[
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