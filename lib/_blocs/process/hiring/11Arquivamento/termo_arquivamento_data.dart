import 'package:equatable/equatable.dart';

import 'termo_arquivamento_sections.dart';

class TermoArquivamentoData extends Equatable {
  // 1) Metadados
  final String? taNumero;
  final String? taData;       // dd/MM/yyyy
  final String? taProcesso;
  final String? taResponsavelUserId;

  // 2) Motivo e Abrangência
  final String? taMotivo;
  final String? taAbrangencia;
  final String? taDescricaoAbrangencia;

  // 3) Fundamentação
  final String? taFundamentosLegais;
  final String? taJustificativa;

  // 4) Peças Anexas
  final String? taPecasAnexas;
  final String? taLinks;

  // 5) Decisão
  final String? taAutoridadeUserId;
  final String? taDecisao;
  final String? taDataDecisao;
  final String? taObservacoesDecisao;

  // 6) Reabertura
  final String? taReaberturaCondicao;
  final String? taPrazoReabertura;

  const TermoArquivamentoData({
    this.taNumero,
    this.taData,
    this.taProcesso,
    this.taResponsavelUserId,
    this.taMotivo,
    this.taAbrangencia,
    this.taDescricaoAbrangencia,
    this.taFundamentosLegais,
    this.taJustificativa,
    this.taPecasAnexas,
    this.taLinks,
    this.taAutoridadeUserId,
    this.taDecisao,
    this.taDataDecisao,
    this.taObservacoesDecisao,
    this.taReaberturaCondicao,
    this.taPrazoReabertura,
  });

  /// Construtor "vazio" para inicializar formulários
  const TermoArquivamentoData.empty()
      : taNumero = '',
        taData = '',
        taProcesso = '',
        taResponsavelUserId = null,
        taMotivo = '',
        taAbrangencia = '',
        taDescricaoAbrangencia = '',
        taFundamentosLegais = '',
        taJustificativa = '',
        taPecasAnexas = '',
        taLinks = '',
        taAutoridadeUserId = null,
        taDecisao = '',
        taDataDecisao = '',
        taObservacoesDecisao = '',
        taReaberturaCondicao = '',
        taPrazoReabertura = '';

  // ---------------------------------------------------------------------------
  // Map "flat" (doc único no Firestore)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() => {
    'taNumero': taNumero,
    'taData': taData,
    'taProcesso': taProcesso,
    'taResponsavelUserId': taResponsavelUserId,
    'taMotivo': taMotivo,
    'taAbrangencia': taAbrangencia,
    'taDescricaoAbrangencia': taDescricaoAbrangencia,
    'taFundamentosLegais': taFundamentosLegais,
    'taJustificativa': taJustificativa,
    'taPecasAnexas': taPecasAnexas,
    'taLinks': taLinks,
    'taAutoridadeUserId': taAutoridadeUserId,
    'taDecisao': taDecisao,
    'taDataDecisao': taDataDecisao,
    'taObservacoesDecisao': taObservacoesDecisao,
    'taReaberturaCondicao': taReaberturaCondicao,
    'taPrazoReabertura': taPrazoReabertura,
  };

  /// Mantém compatibilidade com o nome antigo, se você ainda estiver usando
  Map<String, dynamic> toFlatMap() => toMap();

  factory TermoArquivamentoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TermoArquivamentoData.empty();

    return TermoArquivamentoData(
      taNumero: (map['taNumero'] ?? '').toString(),
      taData: (map['taData'] ?? '').toString(),
      taProcesso: (map['taProcesso'] ?? '').toString(),
      taResponsavelUserId: map['taResponsavelUserId']?.toString(),
      taMotivo: (map['taMotivo'] ?? '').toString(),
      taAbrangencia: (map['taAbrangencia'] ?? '').toString(),
      taDescricaoAbrangencia:
      (map['taDescricaoAbrangencia'] ?? '').toString(),
      taFundamentosLegais:
      (map['taFundamentosLegais'] ?? '').toString(),
      taJustificativa: (map['taJustificativa'] ?? '').toString(),
      taPecasAnexas: (map['taPecasAnexas'] ?? '').toString(),
      taLinks: (map['taLinks'] ?? '').toString(),
      taAutoridadeUserId: map['taAutoridadeUserId']?.toString(),
      taDecisao: (map['taDecisao'] ?? '').toString(),
      taDataDecisao: (map['taDataDecisao'] ?? '').toString(),
      taObservacoesDecisao:
      (map['taObservacoesDecisao'] ?? '').toString(),
      taReaberturaCondicao:
      (map['taReaberturaCondicao'] ?? '').toString(),
      taPrazoReabertura:
      (map['taPrazoReabertura'] ?? '').toString(),
    );
  }

  /// Mantém compatibilidade com o nome antigo, se alguma coisa ainda chamar isso
  factory TermoArquivamentoData.fromFlatMap(Map<String, dynamic>? map) =>
      TermoArquivamentoData.fromMap(map);

  /// A partir da estrutura em seções (usada no Firestore)
  factory TermoArquivamentoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final m  = sections[TermoArquivamentoSections.metadados]     ?? const <String, dynamic>{};
    final mot= sections[TermoArquivamentoSections.motivo]        ?? const <String, dynamic>{};
    final f  = sections[TermoArquivamentoSections.fundamentacao] ?? const <String, dynamic>{};
    final p  = sections[TermoArquivamentoSections.pecas]         ?? const <String, dynamic>{};
    final d  = sections[TermoArquivamentoSections.decisao]       ?? const <String, dynamic>{};
    final r  = sections[TermoArquivamentoSections.reabertura]    ?? const <String, dynamic>{};

    return TermoArquivamentoData(
      // 1) Metadados
      taNumero: (m['taNumero'] ?? '').toString(),
      taData: (m['taData'] ?? '').toString(),
      taProcesso: (m['taProcesso'] ?? '').toString(),
      taResponsavelUserId: m['taResponsavelUserId']?.toString(),

      // 2) Motivo e Abrangência
      taMotivo: (mot['taMotivo'] ?? '').toString(),
      taAbrangencia: (mot['taAbrangencia'] ?? '').toString(),
      taDescricaoAbrangencia:
      (mot['taDescricaoAbrangencia'] ?? '').toString(),

      // 3) Fundamentação
      taFundamentosLegais:
      (f['taFundamentosLegais'] ?? '').toString(),
      taJustificativa: (f['taJustificativa'] ?? '').toString(),

      // 4) Peças Anexas
      taPecasAnexas: (p['taPecasAnexas'] ?? '').toString(),
      taLinks: (p['taLinks'] ?? '').toString(),

      // 5) Decisão
      taAutoridadeUserId: d['taAutoridadeUserId']?.toString(),
      taDecisao: (d['taDecisao'] ?? '').toString(),
      taDataDecisao: (d['taDataDecisao'] ?? '').toString(),
      taObservacoesDecisao:
      (d['taObservacoesDecisao'] ?? '').toString(),

      // 6) Reabertura
      taReaberturaCondicao:
      (r['taReaberturaCondicao'] ?? '').toString(),
      taPrazoReabertura:
      (r['taPrazoReabertura'] ?? '').toString(),
    );
  }

  TermoArquivamentoData copyWith({
    String? taNumero,
    String? taData,
    String? taProcesso,
    String? taResponsavelUserId,
    String? taMotivo,
    String? taAbrangencia,
    String? taDescricaoAbrangencia,
    String? taFundamentosLegais,
    String? taJustificativa,
    String? taPecasAnexas,
    String? taLinks,
    String? taAutoridadeUserId,
    String? taDecisao,
    String? taDataDecisao,
    String? taObservacoesDecisao,
    String? taReaberturaCondicao,
    String? taPrazoReabertura,
  }) {
    return TermoArquivamentoData(
      taNumero: taNumero ?? this.taNumero,
      taData: taData ?? this.taData,
      taProcesso: taProcesso ?? this.taProcesso,
      taResponsavelUserId:
      taResponsavelUserId ?? this.taResponsavelUserId,
      taMotivo: taMotivo ?? this.taMotivo,
      taAbrangencia: taAbrangencia ?? this.taAbrangencia,
      taDescricaoAbrangencia:
      taDescricaoAbrangencia ?? this.taDescricaoAbrangencia,
      taFundamentosLegais:
      taFundamentosLegais ?? this.taFundamentosLegais,
      taJustificativa: taJustificativa ?? this.taJustificativa,
      taPecasAnexas: taPecasAnexas ?? this.taPecasAnexas,
      taLinks: taLinks ?? this.taLinks,
      taAutoridadeUserId:
      taAutoridadeUserId ?? this.taAutoridadeUserId,
      taDecisao: taDecisao ?? this.taDecisao,
      taDataDecisao: taDataDecisao ?? this.taDataDecisao,
      taObservacoesDecisao:
      taObservacoesDecisao ?? this.taObservacoesDecisao,
      taReaberturaCondicao:
      taReaberturaCondicao ?? this.taReaberturaCondicao,
      taPrazoReabertura:
      taPrazoReabertura ?? this.taPrazoReabertura,
    );
  }

  @override
  List<Object?> get props => [
    taNumero,
    taData,
    taProcesso,
    taResponsavelUserId,
    taMotivo,
    taAbrangencia,
    taDescricaoAbrangencia,
    taFundamentosLegais,
    taJustificativa,
    taPecasAnexas,
    taLinks,
    taAutoridadeUserId,
    taDecisao,
    taDataDecisao,
    taObservacoesDecisao,
    taReaberturaCondicao,
    taPrazoReabertura,
  ];
}

// -----------------------------------------------------------------------------
// Mapeamento p/ estrutura em seções (mesma usada no Firestore)
// -----------------------------------------------------------------------------
extension TermoArquivamentoDataSections on TermoArquivamentoData {
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      TermoArquivamentoSections.metadados: {
        'taNumero': taNumero,
        'taData': taData,
        'taProcesso': taProcesso,
        'taResponsavelUserId': taResponsavelUserId,
      },
      TermoArquivamentoSections.motivo: {
        'taMotivo': taMotivo,
        'taAbrangencia': taAbrangencia,
        'taDescricaoAbrangencia': taDescricaoAbrangencia,
      },
      TermoArquivamentoSections.fundamentacao: {
        'taFundamentosLegais': taFundamentosLegais,
        'taJustificativa': taJustificativa,
      },
      TermoArquivamentoSections.pecas: {
        'taPecasAnexas': taPecasAnexas,
        'taLinks': taLinks,
      },
      TermoArquivamentoSections.decisao: {
        'taAutoridadeUserId': taAutoridadeUserId,
        'taDecisao': taDecisao,
        'taDataDecisao': taDataDecisao,
        'taObservacoesDecisao': taObservacoesDecisao,
      },
      TermoArquivamentoSections.reabertura: {
        'taReaberturaCondicao': taReaberturaCondicao,
        'taPrazoReabertura': taPrazoReabertura,
      },
    };
  }
}
