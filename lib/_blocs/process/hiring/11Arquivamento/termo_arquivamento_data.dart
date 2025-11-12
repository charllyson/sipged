import 'package:equatable/equatable.dart';

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

  Map<String, dynamic> toFlatMap() => {
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

  factory TermoArquivamentoData.fromFlatMap(Map<String, dynamic>? map) {
    if (map == null) return const TermoArquivamentoData();
    return TermoArquivamentoData(
      taNumero: map['taNumero'],
      taData: map['taData'],
      taProcesso: map['taProcesso'],
      taResponsavelUserId: map['taResponsavelUserId'],
      taMotivo: map['taMotivo'],
      taAbrangencia: map['taAbrangencia'],
      taDescricaoAbrangencia: map['taDescricaoAbrangencia'],
      taFundamentosLegais: map['taFundamentosLegais'],
      taJustificativa: map['taJustificativa'],
      taPecasAnexas: map['taPecasAnexas'],
      taLinks: map['taLinks'],
      taAutoridadeUserId: map['taAutoridadeUserId'],
      taDecisao: map['taDecisao'],
      taDataDecisao: map['taDataDecisao'],
      taObservacoesDecisao: map['taObservacoesDecisao'],
      taReaberturaCondicao: map['taReaberturaCondicao'],
      taPrazoReabertura: map['taPrazoReabertura'],
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
      taDescricaoAbrangencia: taDescricaoAbrangencia ?? this.taDescricaoAbrangencia,
      taFundamentosLegais: taFundamentosLegais ?? this.taFundamentosLegais,
      taJustificativa: taJustificativa ?? this.taJustificativa,
      taPecasAnexas: taPecasAnexas ?? this.taPecasAnexas,
      taLinks: taLinks ?? this.taLinks,
      taAutoridadeUserId: taAutoridadeUserId ?? this.taAutoridadeUserId,
      taDecisao: taDecisao ?? this.taDecisao,
      taDataDecisao: taDataDecisao ?? this.taDataDecisao,
      taObservacoesDecisao: taObservacoesDecisao ?? this.taObservacoesDecisao,
      taReaberturaCondicao: taReaberturaCondicao ?? this.taReaberturaCondicao,
      taPrazoReabertura: taPrazoReabertura ?? this.taPrazoReabertura,
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
