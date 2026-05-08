// lib/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_data.dart

import 'package:equatable/equatable.dart';

class ParecerJuridicoData extends Equatable {
  /// Chaves estáveis das seções do Parecer Jurídico.
  /// Substitui o antigo arquivo parecer_juridico_sections.dart.
  static const sectionMetadados = 'metadados';
  static const sectionDocumentos = 'documentos';
  static const sectionChecklist = 'checklist';
  static const sectionConclusao = 'conclusao';
  static const sectionPendencias = 'pendencias';
  static const sectionAssinaturas = 'assinaturas';

  static const sectionKeys = <String>[
    sectionMetadados,
    sectionDocumentos,
    sectionChecklist,
    sectionConclusao,
    sectionPendencias,
    sectionAssinaturas,
  ];

  // 1) Metadados
  final String? numero;
  final String? data;
  final String? orgao;
  final String? pareceristaUserId;
  final String? pareceristaNome;
  final String? refProcesso;

  // 2) Documentos / Checklist
  final String? documentosExaminados;
  final String? linksAnexos;

  // 3) Conclusão / Recomendações
  final String? conclusao;
  final String? dataAssinatura;
  final String? recomendacoes;
  final String? ajustesObrigatorios;

  // 4) Pendências
  final String? pendDescricao;
  final String? pendPrazo;
  final String? pendResponsavel;

  // 5) Assinaturas / Autoridade
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

  const ParecerJuridicoData.empty()
      : numero = '',
        data = '',
        orgao = '',
        pareceristaUserId = null,
        pareceristaNome = '',
        refProcesso = '',
        documentosExaminados = '',
        linksAnexos = '',
        conclusao = '',
        dataAssinatura = '',
        recomendacoes = '',
        ajustesObrigatorios = '',
        pendDescricao = '',
        pendPrazo = '',
        pendResponsavel = '',
        autoridadeUserId = null,
        autoridadeNome = '',
        local = '',
        observacoesFinais = '';

  static String _text(dynamic value) {
    return (value ?? '').toString();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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
  }

  factory ParecerJuridicoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ParecerJuridicoData.empty();

    return ParecerJuridicoData(
      numero: _text(map['numero']),
      data: _text(map['data']),
      orgao: _text(map['orgao']),
      pareceristaUserId: map['pareceristaUserId']?.toString(),
      pareceristaNome: _text(map['pareceristaNome']),
      refProcesso: _text(map['refProcesso']),
      documentosExaminados: _text(map['documentosExaminados']),
      linksAnexos: _text(map['linksAnexos']),
      conclusao: _text(map['conclusao']),
      dataAssinatura: _text(map['dataAssinatura']),
      recomendacoes: _text(map['recomendacoes']),
      ajustesObrigatorios: _text(map['ajustesObrigatorios']),
      pendDescricao: _text(map['pendDescricao']),
      pendPrazo: _text(map['pendPrazo']),
      pendResponsavel: _text(map['pendResponsavel']),
      autoridadeUserId: map['autoridadeUserId']?.toString(),
      autoridadeNome: _text(map['autoridadeNome']),
      local: _text(map['local']),
      observacoesFinais: _text(map['observacoesFinais']),
    );
  }

  factory ParecerJuridicoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final m = sections[sectionMetadados] ?? const <String, dynamic>{};
    final d = sections[sectionDocumentos] ?? const <String, dynamic>{};
    final ch = sections[sectionChecklist] ?? const <String, dynamic>{};
    final c = sections[sectionConclusao] ?? const <String, dynamic>{};
    final p = sections[sectionPendencias] ?? const <String, dynamic>{};
    final a = sections[sectionAssinaturas] ?? const <String, dynamic>{};

    return ParecerJuridicoData(
      numero: _text(m['numero']),
      data: _text(m['data']),
      orgao: _text(m['orgao']),
      pareceristaUserId: m['pareceristaUserId']?.toString(),
      pareceristaNome: _text(m['pareceristaNome']),
      refProcesso: _text(m['refProcesso']),
      documentosExaminados: _text(
        ch['documentosExaminados'] ?? d['documentosExaminados'],
      ),
      linksAnexos: _text(d['linksAnexos']),
      conclusao: _text(c['conclusao']),
      dataAssinatura: _text(c['dataAssinatura'] ?? a['dataAssinatura']),
      recomendacoes: _text(c['recomendacoes']),
      ajustesObrigatorios: _text(c['ajustesObrigatorios']),
      pendDescricao: _text(p['pendDescricao']),
      pendPrazo: _text(p['pendPrazo']),
      pendResponsavel: _text(p['pendResponsavel']),
      autoridadeUserId: a['autoridadeUserId']?.toString(),
      autoridadeNome: _text(a['autoridadeNome']),
      local: _text(a['local']),
      observacoesFinais: _text(a['observacoesFinais']),
    );
  }

  ParecerJuridicoData copyWith({
    String? numero,
    String? data,
    String? orgao,
    String? pareceristaUserId,
    String? pareceristaNome,
    String? refProcesso,
    String? documentosExaminados,
    String? linksAnexos,
    String? conclusao,
    String? dataAssinatura,
    String? recomendacoes,
    String? ajustesObrigatorios,
    String? pendDescricao,
    String? pendPrazo,
    String? pendResponsavel,
    String? autoridadeUserId,
    String? autoridadeNome,
    String? local,
    String? observacoesFinais,
  }) {
    return ParecerJuridicoData(
      numero: numero ?? this.numero,
      data: data ?? this.data,
      orgao: orgao ?? this.orgao,
      pareceristaUserId: pareceristaUserId ?? this.pareceristaUserId,
      pareceristaNome: pareceristaNome ?? this.pareceristaNome,
      refProcesso: refProcesso ?? this.refProcesso,
      documentosExaminados: documentosExaminados ?? this.documentosExaminados,
      linksAnexos: linksAnexos ?? this.linksAnexos,
      conclusao: conclusao ?? this.conclusao,
      dataAssinatura: dataAssinatura ?? this.dataAssinatura,
      recomendacoes: recomendacoes ?? this.recomendacoes,
      ajustesObrigatorios: ajustesObrigatorios ?? this.ajustesObrigatorios,
      pendDescricao: pendDescricao ?? this.pendDescricao,
      pendPrazo: pendPrazo ?? this.pendPrazo,
      pendResponsavel: pendResponsavel ?? this.pendResponsavel,
      autoridadeUserId: autoridadeUserId ?? this.autoridadeUserId,
      autoridadeNome: autoridadeNome ?? this.autoridadeNome,
      local: local ?? this.local,
      observacoesFinais: observacoesFinais ?? this.observacoesFinais,
    );
  }

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionMetadados: <String, dynamic>{
        'numero': numero,
        'data': data,
        'orgao': orgao,
        'pareceristaUserId': pareceristaUserId,
        'pareceristaNome': pareceristaNome,
        'refProcesso': refProcesso,
      },
      sectionDocumentos: <String, dynamic>{
        'linksAnexos': linksAnexos,
      },
      sectionChecklist: <String, dynamic>{
        'documentosExaminados': documentosExaminados,
      },
      sectionConclusao: <String, dynamic>{
        'conclusao': conclusao,
        'dataAssinatura': dataAssinatura,
        'recomendacoes': recomendacoes,
        'ajustesObrigatorios': ajustesObrigatorios,
      },
      sectionPendencias: <String, dynamic>{
        'pendDescricao': pendDescricao,
        'pendPrazo': pendPrazo,
        'pendResponsavel': pendResponsavel,
      },
      sectionAssinaturas: <String, dynamic>{
        'autoridadeUserId': autoridadeUserId,
        'autoridadeNome': autoridadeNome,
        'local': local,
        'observacoesFinais': observacoesFinais,
      },
    };
  }

  @override
  List<Object?> get props => <Object?>[
    numero,
    data,
    orgao,
    pareceristaUserId,
    pareceristaNome,
    refProcesso,
    documentosExaminados,
    linksAnexos,
    conclusao,
    dataAssinatura,
    recomendacoes,
    ajustesObrigatorios,
    pendDescricao,
    pendPrazo,
    pendResponsavel,
    autoridadeUserId,
    autoridadeNome,
    local,
    observacoesFinais,
  ];
}