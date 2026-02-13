import 'package:equatable/equatable.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_sections.dart';

class ParecerJuridicoData extends Equatable {
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
    // Metadados
    this.numero,
    this.data,
    this.orgao,
    this.pareceristaUserId,
    this.pareceristaNome,
    this.refProcesso,

    // Documentos / Checklist
    this.documentosExaminados,
    this.linksAnexos,

    // Conclusão / Recomendações
    this.conclusao,
    this.dataAssinatura,
    this.recomendacoes,
    this.ajustesObrigatorios,

    // Pendências
    this.pendDescricao,
    this.pendPrazo,
    this.pendResponsavel,

    // Assinaturas / Autoridade
    this.autoridadeUserId,
    this.autoridadeNome,
    this.local,
    this.observacoesFinais,
  });

  /// Construtor vazio, útil para inicializar formulários
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

  // ---------------------------------------------------------------------------
  // Map flat (doc único)
  // ---------------------------------------------------------------------------
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
    if (m == null) return const ParecerJuridicoData.empty();
    return ParecerJuridicoData(
      numero: (m['numero'] ?? '').toString(),
      data: (m['data'] ?? '').toString(),
      orgao: (m['orgao'] ?? '').toString(),
      pareceristaUserId: m['pareceristaUserId']?.toString(),
      pareceristaNome: (m['pareceristaNome'] ?? '').toString(),
      refProcesso: (m['refProcesso'] ?? '').toString(),
      documentosExaminados: (m['documentosExaminados'] ?? '').toString(),
      linksAnexos: (m['linksAnexos'] ?? '').toString(),
      conclusao: (m['conclusao'] ?? '').toString(),
      dataAssinatura: (m['dataAssinatura'] ?? '').toString(),
      recomendacoes: (m['recomendacoes'] ?? '').toString(),
      ajustesObrigatorios: (m['ajustesObrigatorios'] ?? '').toString(),
      pendDescricao: (m['pendDescricao'] ?? '').toString(),
      pendPrazo: (m['pendPrazo'] ?? '').toString(),
      pendResponsavel: (m['pendResponsavel'] ?? '').toString(),
      autoridadeUserId: m['autoridadeUserId']?.toString(),
      autoridadeNome: (m['autoridadeNome'] ?? '').toString(),
      local: (m['local'] ?? '').toString(),
      observacoesFinais: (m['observacoesFinais'] ?? '').toString(),
    );
  }

  /// A partir da estrutura em seções usada no Firestore
  factory ParecerJuridicoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final m  = sections[ParecerSections.metadados]   ?? const <String, dynamic>{};
    final d  = sections[ParecerSections.documentos]  ?? const <String, dynamic>{};
    final ch = sections[ParecerSections.checklist]   ?? const <String, dynamic>{};
    final c  = sections[ParecerSections.conclusao]   ?? const <String, dynamic>{};
    final p  = sections[ParecerSections.pendencias]  ?? const <String, dynamic>{};
    final a  = sections[ParecerSections.assinaturas] ?? const <String, dynamic>{};

    return ParecerJuridicoData(
      // Metadados
      numero: (m['numero'] ?? '').toString(),
      data: (m['data'] ?? '').toString(),
      orgao: (m['orgao'] ?? '').toString(),
      pareceristaUserId: m['pareceristaUserId']?.toString(),
      pareceristaNome: (m['pareceristaNome'] ?? '').toString(),
      refProcesso: (m['refProcesso'] ?? '').toString(),

      // Documentos / Checklist
      documentosExaminados: (ch['documentosExaminados'] ?? d['documentosExaminados'] ?? '').toString(),
      linksAnexos: (d['linksAnexos'] ?? '').toString(),

      // Conclusão
      conclusao: (c['conclusao'] ?? '').toString(),
      dataAssinatura: (c['dataAssinatura'] ?? a['dataAssinatura'] ?? '').toString(),
      recomendacoes: (c['recomendacoes'] ?? '').toString(),
      ajustesObrigatorios: (c['ajustesObrigatorios'] ?? '').toString(),

      // Pendências
      pendDescricao: (p['pendDescricao'] ?? '').toString(),
      pendPrazo: (p['pendPrazo'] ?? '').toString(),
      pendResponsavel: (p['pendResponsavel'] ?? '').toString(),

      // Assinaturas / Autoridade
      autoridadeUserId: a['autoridadeUserId']?.toString(),
      autoridadeNome: (a['autoridadeNome'] ?? '').toString(),
      local: (a['local'] ?? '').toString(),
      observacoesFinais: (a['observacoesFinais'] ?? '').toString(),
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

  @override
  List<Object?> get props => [
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

// -----------------------------------------------------------------------------
// Mapeamento p/ estrutura em seções (mesma usada no Firestore)
// -----------------------------------------------------------------------------
extension ParecerJuridicoDataSections on ParecerJuridicoData {
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      ParecerSections.metadados: {
        'numero': numero,
        'data': data,
        'orgao': orgao,
        'pareceristaUserId': pareceristaUserId,
        'pareceristaNome': pareceristaNome,
        'refProcesso': refProcesso,
      },
      ParecerSections.documentos: {
        'linksAnexos': linksAnexos,
      },
      ParecerSections.checklist: {
        'documentosExaminados': documentosExaminados,
      },
      ParecerSections.conclusao: {
        'conclusao': conclusao,
        'dataAssinatura': dataAssinatura,
        'recomendacoes': recomendacoes,
        'ajustesObrigatorios': ajustesObrigatorios,
      },
      ParecerSections.pendencias: {
        'pendDescricao': pendDescricao,
        'pendPrazo': pendPrazo,
        'pendResponsavel': pendResponsavel,
      },
      ParecerSections.assinaturas: {
        'autoridadeUserId': autoridadeUserId,
        'autoridadeNome': autoridadeNome,
        'local': local,
        'observacoesFinais': observacoesFinais,
      },
    };
  }
}
