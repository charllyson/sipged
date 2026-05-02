// lib/_blocs/system/notification/notification_source.dart

import 'package:flutter/material.dart';

enum NotificationSource {
  general,
  budget,
  contract,
  additives,
  apostilles,
  measurements,
  validity,
  schedule,
}

extension NotificationSourceExtension on NotificationSource {
  String get key {
    switch (this) {
      case NotificationSource.general:
        return 'general';
      case NotificationSource.budget:
        return 'budget';
      case NotificationSource.contract:
        return 'contract';
      case NotificationSource.additives:
        return 'additives';
      case NotificationSource.apostilles:
        return 'apostilles';
      case NotificationSource.measurements:
        return 'measurements';
      case NotificationSource.validity:
        return 'validity';
      case NotificationSource.schedule:
        return 'schedule';
    }
  }

  String get title {
    switch (this) {
      case NotificationSource.general:
        return 'Geral';
      case NotificationSource.budget:
        return 'Orçamento';
      case NotificationSource.contract:
        return 'Contrato';
      case NotificationSource.additives:
        return 'Aditivos';
      case NotificationSource.apostilles:
        return 'Apostilamentos';
      case NotificationSource.measurements:
        return 'Medições';
      case NotificationSource.validity:
        return 'Vigências';
      case NotificationSource.schedule:
        return 'Cronograma';
    }
  }

  String get subtitle {
    switch (this) {
      case NotificationSource.general:
        return 'Notificações gerais, avisos do sistema e comunicações institucionais.';
      case NotificationSource.budget:
        return 'Atualizações, importações e alterações no orçamento contratual.';
      case NotificationSource.contract:
        return 'Eventos das etapas do processo de contratação.';
      case NotificationSource.additives:
        return 'Criação, atualização e acompanhamento de aditivos contratuais.';
      case NotificationSource.apostilles:
        return 'Criação, atualização e acompanhamento de apostilamentos.';
      case NotificationSource.measurements:
        return 'Boletins, reajustes, revisões e atualizações de medições.';
      case NotificationSource.validity:
        return 'Alertas e atualizações de vigência contratual.';
      case NotificationSource.schedule:
        return 'Atualizações em cronogramas físicos e operacionais.';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationSource.general:
        return Icons.notifications_rounded;
      case NotificationSource.budget:
        return Icons.table_chart_rounded;
      case NotificationSource.contract:
        return Icons.assignment_rounded;
      case NotificationSource.additives:
        return Icons.post_add_rounded;
      case NotificationSource.apostilles:
        return Icons.edit_document;
      case NotificationSource.measurements:
        return Icons.payments_rounded;
      case NotificationSource.validity:
        return Icons.event_available_rounded;
      case NotificationSource.schedule:
        return Icons.timeline_rounded;
    }
  }

  List<NotificationSubSource> get subSources {
    return NotificationSubSource.values
        .where((item) => item.source == this)
        .toList(growable: false);
  }

  static NotificationSource fromString(String? value) {
    final clean = (value ?? '').trim().toLowerCase();

    for (final source in NotificationSource.values) {
      if (source.key == clean) return source;
    }

    return NotificationSource.general;
  }
}

enum NotificationSubSource {
  // ---------------------------------------------------------------------------
  // GERAL
  // ---------------------------------------------------------------------------

  generalSystem,
  generalNotices,
  generalAds,

  // ---------------------------------------------------------------------------
  // ORÇAMENTO
  // ---------------------------------------------------------------------------

  budgetGeneral,

  // ---------------------------------------------------------------------------
  // CONTRATO / PROCESSO DE CONTRATAÇÃO
  // ---------------------------------------------------------------------------

  contractsHiringDfd,
  contractsHiringEtp,
  contractsHiringTr,
  contractsHiringCotacao,
  contractsHiringEdital,
  contractsHiringHabilitacao,
  contractsHiringDotacao,
  contractsHiringMinuta,
  contractsHiringParecer,
  contractsHiringPublicacao,
  contractsHiringArquivamento,

  // ---------------------------------------------------------------------------
  // ADITIVOS
  // ---------------------------------------------------------------------------

  additivesGeneral,

  // ---------------------------------------------------------------------------
  // APOSTILAMENTOS
  // ---------------------------------------------------------------------------

  apostillesGeneral,

  // ---------------------------------------------------------------------------
  // MEDIÇÕES
  // ---------------------------------------------------------------------------

  measurementsBulletin,
  measurementsAdjustments,
  measurementsRevision,

  // ---------------------------------------------------------------------------
  // VIGÊNCIAS
  // ---------------------------------------------------------------------------

  validityGeneral,

  // ---------------------------------------------------------------------------
  // CRONOGRAMA
  // ---------------------------------------------------------------------------

  scheduleGeneral,
}

extension NotificationSubSourceExtension on NotificationSubSource {
  NotificationSource get source {
    switch (this) {
      case NotificationSubSource.generalSystem:
      case NotificationSubSource.generalNotices:
      case NotificationSubSource.generalAds:
        return NotificationSource.general;

      case NotificationSubSource.budgetGeneral:
        return NotificationSource.budget;

      case NotificationSubSource.contractsHiringDfd:
      case NotificationSubSource.contractsHiringEtp:
      case NotificationSubSource.contractsHiringTr:
      case NotificationSubSource.contractsHiringCotacao:
      case NotificationSubSource.contractsHiringEdital:
      case NotificationSubSource.contractsHiringHabilitacao:
      case NotificationSubSource.contractsHiringDotacao:
      case NotificationSubSource.contractsHiringMinuta:
      case NotificationSubSource.contractsHiringParecer:
      case NotificationSubSource.contractsHiringPublicacao:
      case NotificationSubSource.contractsHiringArquivamento:
        return NotificationSource.contract;

      case NotificationSubSource.additivesGeneral:
        return NotificationSource.additives;

      case NotificationSubSource.apostillesGeneral:
        return NotificationSource.apostilles;

      case NotificationSubSource.measurementsBulletin:
      case NotificationSubSource.measurementsAdjustments:
      case NotificationSubSource.measurementsRevision:
        return NotificationSource.measurements;

      case NotificationSubSource.validityGeneral:
        return NotificationSource.validity;

      case NotificationSubSource.scheduleGeneral:
        return NotificationSource.schedule;
    }
  }

  String get key {
    switch (this) {
      case NotificationSubSource.generalSystem:
        return 'general_system';
      case NotificationSubSource.generalNotices:
        return 'general_notices';
      case NotificationSubSource.generalAds:
        return 'general_ads';

      case NotificationSubSource.budgetGeneral:
        return 'budget_general';

      case NotificationSubSource.contractsHiringDfd:
        return 'contracts_hiring_dfd';
      case NotificationSubSource.contractsHiringEtp:
        return 'contracts_hiring_etp';
      case NotificationSubSource.contractsHiringTr:
        return 'contracts_hiring_tr';
      case NotificationSubSource.contractsHiringCotacao:
        return 'contracts_hiring_cotacao';
      case NotificationSubSource.contractsHiringEdital:
        return 'contracts_hiring_edital';
      case NotificationSubSource.contractsHiringHabilitacao:
        return 'contracts_hiring_habilitacao';
      case NotificationSubSource.contractsHiringDotacao:
        return 'contracts_hiring_dotacao';
      case NotificationSubSource.contractsHiringMinuta:
        return 'contracts_hiring_minuta';
      case NotificationSubSource.contractsHiringParecer:
        return 'contracts_hiring_parecer';
      case NotificationSubSource.contractsHiringPublicacao:
        return 'contracts_hiring_publicacao';
      case NotificationSubSource.contractsHiringArquivamento:
        return 'contracts_hiring_arquivamento';

      case NotificationSubSource.additivesGeneral:
        return 'additives_general';

      case NotificationSubSource.apostillesGeneral:
        return 'apostilles_general';

      case NotificationSubSource.measurementsBulletin:
        return 'measurements_bulletin';
      case NotificationSubSource.measurementsAdjustments:
        return 'measurements_adjustments';
      case NotificationSubSource.measurementsRevision:
        return 'measurements_revision';

      case NotificationSubSource.validityGeneral:
        return 'validity_general';

      case NotificationSubSource.scheduleGeneral:
        return 'schedule_general';
    }
  }

  String get title {
    switch (this) {
      case NotificationSubSource.generalSystem:
        return 'Notificações do sistema';
      case NotificationSubSource.generalNotices:
        return 'Avisos';
      case NotificationSubSource.generalAds:
        return 'Publicidade';

      case NotificationSubSource.budgetGeneral:
        return 'Orçamento';

      case NotificationSubSource.contractsHiringDfd:
        return 'DFD';
      case NotificationSubSource.contractsHiringEtp:
        return 'ETP';
      case NotificationSubSource.contractsHiringTr:
        return 'Termo de Referência';
      case NotificationSubSource.contractsHiringCotacao:
        return 'Cotação';
      case NotificationSubSource.contractsHiringEdital:
        return 'Edital / Julgamento';
      case NotificationSubSource.contractsHiringHabilitacao:
        return 'Habilitação';
      case NotificationSubSource.contractsHiringDotacao:
        return 'Dotação Orçamentária';
      case NotificationSubSource.contractsHiringMinuta:
        return 'Minuta do Contrato';
      case NotificationSubSource.contractsHiringParecer:
        return 'Parecer Jurídico';
      case NotificationSubSource.contractsHiringPublicacao:
        return 'Publicação / Extrato';
      case NotificationSubSource.contractsHiringArquivamento:
        return 'Arquivamento';

      case NotificationSubSource.additivesGeneral:
        return 'Aditivos';

      case NotificationSubSource.apostillesGeneral:
        return 'Apostilamentos';

      case NotificationSubSource.measurementsBulletin:
        return 'Boletim';
      case NotificationSubSource.measurementsAdjustments:
        return 'Reajustes';
      case NotificationSubSource.measurementsRevision:
        return 'Revisão';

      case NotificationSubSource.validityGeneral:
        return 'Vigências';

      case NotificationSubSource.scheduleGeneral:
        return 'Cronograma';
    }
  }

  String get subtitle {
    switch (this) {
      case NotificationSubSource.generalSystem:
        return 'Eventos internos, atualizações e mensagens operacionais do SIPGED.';
      case NotificationSubSource.generalNotices:
        return 'Comunicados gerais enviados aos usuários do sistema.';
      case NotificationSubSource.generalAds:
        return 'Campanhas, divulgações e comunicações institucionais.';

      case NotificationSubSource.budgetGeneral:
        return 'Importação, edição, salvamento e atualização do orçamento contratual.';

      case NotificationSubSource.contractsHiringDfd:
        return 'Documento de Formalização de Demanda.';
      case NotificationSubSource.contractsHiringEtp:
        return 'Estudo Técnico Preliminar.';
      case NotificationSubSource.contractsHiringTr:
        return 'Termo de Referência e suas atualizações.';
      case NotificationSubSource.contractsHiringCotacao:
        return 'Cotações, fornecedores e consolidação de preços.';
      case NotificationSubSource.contractsHiringEdital:
        return 'Edital, julgamento, propostas, lances e resultado.';
      case NotificationSubSource.contractsHiringHabilitacao:
        return 'Habilitação e regularidade da empresa.';
      case NotificationSubSource.contractsHiringDotacao:
        return 'Dotação, reserva, empenho e programação orçamentária.';
      case NotificationSubSource.contractsHiringMinuta:
        return 'Minuta contratual e dados prévios à formalização.';
      case NotificationSubSource.contractsHiringParecer:
        return 'Parecer jurídico, checklist, conclusão e assinaturas.';
      case NotificationSubSource.contractsHiringPublicacao:
        return 'Publicação de extrato, veículo, prazos e responsáveis.';
      case NotificationSubSource.contractsHiringArquivamento:
        return 'Termo de arquivamento, decisão e possibilidade de reabertura.';

      case NotificationSubSource.additivesGeneral:
        return 'Criação, edição, aprovação e acompanhamento de aditivos.';

      case NotificationSubSource.apostillesGeneral:
        return 'Criação, edição, aprovação e acompanhamento de apostilamentos.';

      case NotificationSubSource.measurementsBulletin:
        return 'Boletins de medição e atualizações principais.';
      case NotificationSubSource.measurementsAdjustments:
        return 'Reajustes de valores vinculados às medições.';
      case NotificationSubSource.measurementsRevision:
        return 'Revisões, processos de revisão e valores revisados.';

      case NotificationSubSource.validityGeneral:
        return 'Prazos, alertas de vencimento e atualizações de vigência.';

      case NotificationSubSource.scheduleGeneral:
        return 'Cronogramas físicos, operacionais e atualizações de execução.';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationSubSource.generalSystem:
        return Icons.settings_suggest_rounded;
      case NotificationSubSource.generalNotices:
        return Icons.campaign_rounded;
      case NotificationSubSource.generalAds:
        return Icons.ads_click_rounded;

      case NotificationSubSource.budgetGeneral:
        return Icons.table_chart_rounded;

      case NotificationSubSource.contractsHiringDfd:
        return Icons.assignment_turned_in_outlined;
      case NotificationSubSource.contractsHiringEtp:
        return Icons.description_outlined;
      case NotificationSubSource.contractsHiringTr:
        return Icons.rule_folder_outlined;
      case NotificationSubSource.contractsHiringCotacao:
        return Icons.request_quote_outlined;
      case NotificationSubSource.contractsHiringEdital:
        return Icons.gavel_outlined;
      case NotificationSubSource.contractsHiringHabilitacao:
        return Icons.verified_user_outlined;
      case NotificationSubSource.contractsHiringDotacao:
        return Icons.account_balance_wallet_outlined;
      case NotificationSubSource.contractsHiringMinuta:
        return Icons.article_outlined;
      case NotificationSubSource.contractsHiringParecer:
        return Icons.balance_outlined;
      case NotificationSubSource.contractsHiringPublicacao:
        return Icons.campaign_outlined;
      case NotificationSubSource.contractsHiringArquivamento:
        return Icons.archive_outlined;

      case NotificationSubSource.additivesGeneral:
        return Icons.post_add_rounded;

      case NotificationSubSource.apostillesGeneral:
        return Icons.edit_document;

      case NotificationSubSource.measurementsBulletin:
        return Icons.receipt_long_outlined;
      case NotificationSubSource.measurementsAdjustments:
        return Icons.trending_up_rounded;
      case NotificationSubSource.measurementsRevision:
        return Icons.manage_search_rounded;

      case NotificationSubSource.validityGeneral:
        return Icons.event_available_rounded;

      case NotificationSubSource.scheduleGeneral:
        return Icons.timeline_rounded;
    }
  }

  static NotificationSubSource fromString(String? value) {
    final clean = (value ?? '').trim().toLowerCase();

    for (final item in NotificationSubSource.values) {
      if (item.key == clean) return item;
    }

    return NotificationSubSource.generalSystem;
  }

  static NotificationSubSource? tryFromString(String? value) {
    final clean = (value ?? '').trim().toLowerCase();

    if (clean.isEmpty) return null;

    for (final item in NotificationSubSource.values) {
      if (item.key == clean) return item;
    }

    return null;
  }
}

class NotificationSourceGroup {
  final NotificationSource source;
  final List<NotificationSubSource> subSources;

  const NotificationSourceGroup({
    required this.source,
    required this.subSources,
  });

  String get key => source.key;

  String get title => source.title;

  String get subtitle => source.subtitle;

  IconData get icon => source.icon;
}

class NotificationSourceRegistry {
  const NotificationSourceRegistry._();

  static List<NotificationSourceGroup> get groups {
    return NotificationSource.values.map((source) {
      return NotificationSourceGroup(
        source: source,
        subSources: source.subSources,
      );
    }).toList(growable: false);
  }

  static List<NotificationSubSource> get allSubSources {
    return NotificationSubSource.values;
  }

  static NotificationSubSource resolveSubSource(String? value) {
    return NotificationSubSourceExtension.fromString(value);
  }

  static NotificationSubSource? tryResolveSubSource(String? value) {
    return NotificationSubSourceExtension.tryFromString(value);
  }

  static NotificationSource resolveSource(String? value) {
    return NotificationSourceExtension.fromString(value);
  }

  static bool containsSubSource(String? value) {
    return tryResolveSubSource(value) != null;
  }

  static List<NotificationSubSource> subSourcesOf(NotificationSource source) {
    return source.subSources;
  }
}