// lib/_blocs/process/hiring/9Juridico/parecer_juridico_data.dart
import 'package:equatable/equatable.dart';

class ParecerJuridicoData extends Equatable {
  final String? numero;
  final String? data;
  final String? orgao;
  final String? pareceristaUserId;
  final String? pareceristaNome;

  final String? refProcesso;
  final String? documentosExaminados;
  final String? linksAnexos;

  final String? conclusao;
  final String? dataAssinatura;
  final String? recomendacoes;
  final String? ajustesObrigatorios;

  final String? pendDescricao;
  final String? pendPrazo;
  final String? pendResponsavel;

  final String? autoridadeUserId;
  final String? autoridadeNome;
  final String? local;
  final String? observacoesFinais;

  const ParecerJuridicoData({
    this.numero,
    this.data,
    this.orgao,
    this.pareceristaUserId,
    this.pareceristaNome,
    this.refProcesso,
    this.documentosExaminados,
    this.linksAnexos,
    this.conclusao,
    this.dataAssinatura,
    this.recomendacoes,
    this.ajustesObrigatorios,
    this.pendDescricao,
    this.pendPrazo,
    this.pendResponsavel,
    this.autoridadeUserId,
    this.autoridadeNome,
    this.local,
    this.observacoesFinais,
  });

  Map<String, dynamic> toMap() => {
    'numero': numero,
    'data': data,
    'orgao': orgao,
    'pareceristaUserId': pareceristaUserId,
    'pareceristaNome': pareceristaNome,
    'refProcesso': refProcesso,
    'documentosExaminados': documentosExaminados,
    'linksAnexos': linksAnexos,
    'conclusao': conclusao,
    'dataAssinatura': dataAssinatura,
    'recomendacoes': recomendacoes,
    'ajustesObrigatorios': ajustesObrigatorios,
    'pendDescricao': pendDescricao,
    'pendPrazo': pendPrazo,
    'pendResponsavel': pendResponsavel,
    'autoridadeUserId': autoridadeUserId,
    'autoridadeNome': autoridadeNome,
    'local': local,
    'observacoesFinais': observacoesFinais,
  };

  factory ParecerJuridicoData.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const ParecerJuridicoData();
    return ParecerJuridicoData(
      numero: m['numero'],
      data: m['data'],
      orgao: m['orgao'],
      pareceristaUserId: m['pareceristaUserId'],
      pareceristaNome: m['pareceristaNome'],
      refProcesso: m['refProcesso'],
      documentosExaminados: m['documentosExaminados'],
      linksAnexos: m['linksAnexos'],
      conclusao: m['conclusao'],
      dataAssinatura: m['dataAssinatura'],
      recomendacoes: m['recomendacoes'],
      ajustesObrigatorios: m['ajustesObrigatorios'],
      pendDescricao: m['pendDescricao'],
      pendPrazo: m['pendPrazo'],
      pendResponsavel: m['pendResponsavel'],
      autoridadeUserId: m['autoridadeUserId'],
      autoridadeNome: m['autoridadeNome'],
      local: m['local'],
      observacoesFinais: m['observacoesFinais'],
    );
  }

  @override
  List<Object?> get props => [
    numero, data, orgao, pareceristaUserId, pareceristaNome,
    refProcesso, documentosExaminados, linksAnexos,
    conclusao, dataAssinatura, recomendacoes, ajustesObrigatorios,
    pendDescricao, pendPrazo, pendResponsavel,
    autoridadeUserId, autoridadeNome, local, observacoesFinais,
  ];
}
