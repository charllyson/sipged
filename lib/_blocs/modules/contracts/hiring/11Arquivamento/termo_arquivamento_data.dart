// lib/_blocs/modules/contracts/hiring/10Arquivamento/termo_arquivamento_data.dart

import 'package:equatable/equatable.dart';

class TermoArquivamentoData extends Equatable {
  /// Chaves estáveis das seções do Termo de Arquivamento.
  /// Substitui o antigo arquivo termo_arquivamento_sections.dart.
  static const sectionMetadados = 'metadados';
  static const sectionMotivo = 'motivo';
  static const sectionFundamentacao = 'fundamentacao';
  static const sectionPecas = 'pecas';
  static const sectionDecisao = 'decisao';
  static const sectionReabertura = 'reabertura';

  static const sectionKeys = <String>[
    sectionMetadados,
    sectionMotivo,
    sectionFundamentacao,
    sectionPecas,
    sectionDecisao,
    sectionReabertura,
  ];

  // 1) Metadados
  final String? taNumero;
  final String? taData;
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

  static String _string(dynamic value) {
    return (value ?? '').toString();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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
  }

  Map<String, dynamic> toFlatMap() => toMap();

  factory TermoArquivamentoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TermoArquivamentoData.empty();

    return TermoArquivamentoData(
      taNumero: _string(map['taNumero']),
      taData: _string(map['taData']),
      taProcesso: _string(map['taProcesso']),
      taResponsavelUserId: map['taResponsavelUserId']?.toString(),
      taMotivo: _string(map['taMotivo']),
      taAbrangencia: _string(map['taAbrangencia']),
      taDescricaoAbrangencia: _string(map['taDescricaoAbrangencia']),
      taFundamentosLegais: _string(map['taFundamentosLegais']),
      taJustificativa: _string(map['taJustificativa']),
      taPecasAnexas: _string(map['taPecasAnexas']),
      taLinks: _string(map['taLinks']),
      taAutoridadeUserId: map['taAutoridadeUserId']?.toString(),
      taDecisao: _string(map['taDecisao']),
      taDataDecisao: _string(map['taDataDecisao']),
      taObservacoesDecisao: _string(map['taObservacoesDecisao']),
      taReaberturaCondicao: _string(map['taReaberturaCondicao']),
      taPrazoReabertura: _string(map['taPrazoReabertura']),
    );
  }

  factory TermoArquivamentoData.fromFlatMap(Map<String, dynamic>? map) {
    return TermoArquivamentoData.fromMap(map);
  }

  factory TermoArquivamentoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final metadados =
        sections[sectionMetadados] ?? const <String, dynamic>{};
    final motivo = sections[sectionMotivo] ?? const <String, dynamic>{};
    final fundamentacao =
        sections[sectionFundamentacao] ?? const <String, dynamic>{};
    final pecas = sections[sectionPecas] ?? const <String, dynamic>{};
    final decisao = sections[sectionDecisao] ?? const <String, dynamic>{};
    final reabertura =
        sections[sectionReabertura] ?? const <String, dynamic>{};

    return TermoArquivamentoData(
      taNumero: _string(metadados['taNumero']),
      taData: _string(metadados['taData']),
      taProcesso: _string(metadados['taProcesso']),
      taResponsavelUserId: metadados['taResponsavelUserId']?.toString(),
      taMotivo: _string(motivo['taMotivo']),
      taAbrangencia: _string(motivo['taAbrangencia']),
      taDescricaoAbrangencia: _string(motivo['taDescricaoAbrangencia']),
      taFundamentosLegais: _string(fundamentacao['taFundamentosLegais']),
      taJustificativa: _string(fundamentacao['taJustificativa']),
      taPecasAnexas: _string(pecas['taPecasAnexas']),
      taLinks: _string(pecas['taLinks']),
      taAutoridadeUserId: decisao['taAutoridadeUserId']?.toString(),
      taDecisao: _string(decisao['taDecisao']),
      taDataDecisao: _string(decisao['taDataDecisao']),
      taObservacoesDecisao: _string(decisao['taObservacoesDecisao']),
      taReaberturaCondicao: _string(reabertura['taReaberturaCondicao']),
      taPrazoReabertura: _string(reabertura['taPrazoReabertura']),
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
      taResponsavelUserId: taResponsavelUserId ?? this.taResponsavelUserId,
      taMotivo: taMotivo ?? this.taMotivo,
      taAbrangencia: taAbrangencia ?? this.taAbrangencia,
      taDescricaoAbrangencia:
      taDescricaoAbrangencia ?? this.taDescricaoAbrangencia,
      taFundamentosLegais: taFundamentosLegais ?? this.taFundamentosLegais,
      taJustificativa: taJustificativa ?? this.taJustificativa,
      taPecasAnexas: taPecasAnexas ?? this.taPecasAnexas,
      taLinks: taLinks ?? this.taLinks,
      taAutoridadeUserId: taAutoridadeUserId ?? this.taAutoridadeUserId,
      taDecisao: taDecisao ?? this.taDecisao,
      taDataDecisao: taDataDecisao ?? this.taDataDecisao,
      taObservacoesDecisao:
      taObservacoesDecisao ?? this.taObservacoesDecisao,
      taReaberturaCondicao:
      taReaberturaCondicao ?? this.taReaberturaCondicao,
      taPrazoReabertura: taPrazoReabertura ?? this.taPrazoReabertura,
    );
  }

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionMetadados: <String, dynamic>{
        'taNumero': taNumero,
        'taData': taData,
        'taProcesso': taProcesso,
        'taResponsavelUserId': taResponsavelUserId,
      },
      sectionMotivo: <String, dynamic>{
        'taMotivo': taMotivo,
        'taAbrangencia': taAbrangencia,
        'taDescricaoAbrangencia': taDescricaoAbrangencia,
      },
      sectionFundamentacao: <String, dynamic>{
        'taFundamentosLegais': taFundamentosLegais,
        'taJustificativa': taJustificativa,
      },
      sectionPecas: <String, dynamic>{
        'taPecasAnexas': taPecasAnexas,
        'taLinks': taLinks,
      },
      sectionDecisao: <String, dynamic>{
        'taAutoridadeUserId': taAutoridadeUserId,
        'taDecisao': taDecisao,
        'taDataDecisao': taDataDecisao,
        'taObservacoesDecisao': taObservacoesDecisao,
      },
      sectionReabertura: <String, dynamic>{
        'taReaberturaCondicao': taReaberturaCondicao,
        'taPrazoReabertura': taPrazoReabertura,
      },
    };
  }

  @override
  List<Object?> get props => <Object?>[
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