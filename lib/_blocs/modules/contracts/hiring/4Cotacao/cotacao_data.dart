// lib/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart

import 'package:equatable/equatable.dart';

class CotacaoData extends Equatable {
  /// Chaves estáveis das seções da Cotação.
  /// Substitui o antigo arquivo cotacao_sections.dart.
  static const sectionMetadados = 'metadados';
  static const sectionObjetoItens = 'objetoItens';
  static const sectionConviteDivulgacao = 'conviteDivulgacao';
  static const sectionRespostasFornecedores = 'respostasFornecedores';
  static const sectionVencedora = 'vencedora';
  static const sectionConsolidacaoResultado = 'consolidacaoResultado';
  static const sectionAnexosEvidencias = 'anexosEvidencias';

  static const sectionKeys = <String>[
    sectionMetadados,
    sectionObjetoItens,
    sectionConviteDivulgacao,
    sectionRespostasFornecedores,
    sectionVencedora,
    sectionConsolidacaoResultado,
    sectionAnexosEvidencias,
  ];

  // ===== 1) Metadados =====
  final String? numero;
  final String? dataAbertura;
  final String? dataEncerramento;
  final String? responsavelNome;
  final String? responsavelUserId;
  final String? metodologia;

  // ===== 2) Objeto/Itens =====
  final String? objeto;
  final String? unidadeMedida;
  final String? quantidade;
  final String? especificacoes;

  // ===== 3) Convite/Divulgação =====
  final String? meioDivulgacao;
  final String? fornecedoresConvidados;
  final String? prazoResposta;

  // ===== 4) Respostas dos Fornecedores =====
  final String? f1Nome;
  final String? f1Cnpj;
  final String? f1Valor;
  final String? f1DataRecebimento;
  final String? f1LinkProposta;

  final String? f2Nome;
  final String? f2Cnpj;
  final String? f2Valor;
  final String? f2DataRecebimento;
  final String? f2LinkProposta;

  final String? f3Nome;
  final String? f3Cnpj;
  final String? f3Valor;
  final String? f3DataRecebimento;
  final String? f3LinkProposta;

  // ===== 5) Empresa vencedora =====
  final String? empresaLider;
  final String? consorcioEnvolvidas;

  // ===== 6) Consolidação/Resultado =====
  final String? criterioConsolidacao;
  final String? valorConsolidado;
  final String? observacoes;

  // ===== 7) Anexos/Evidências =====
  final String? linksAnexos;

  const CotacaoData({
    this.numero,
    this.dataAbertura,
    this.dataEncerramento,
    this.responsavelNome,
    this.responsavelUserId,
    this.metodologia,
    this.objeto,
    this.unidadeMedida,
    this.quantidade,
    this.especificacoes,
    this.meioDivulgacao,
    this.fornecedoresConvidados,
    this.prazoResposta,
    this.f1Nome,
    this.f1Cnpj,
    this.f1Valor,
    this.f1DataRecebimento,
    this.f1LinkProposta,
    this.f2Nome,
    this.f2Cnpj,
    this.f2Valor,
    this.f2DataRecebimento,
    this.f2LinkProposta,
    this.f3Nome,
    this.f3Cnpj,
    this.f3Valor,
    this.f3DataRecebimento,
    this.f3LinkProposta,
    this.empresaLider,
    this.consorcioEnvolvidas,
    this.criterioConsolidacao,
    this.valorConsolidado,
    this.observacoes,
    this.linksAnexos,
  });

  const CotacaoData.empty()
      : numero = '',
        dataAbertura = '',
        dataEncerramento = '',
        responsavelNome = '',
        responsavelUserId = null,
        metodologia = '',
        objeto = '',
        unidadeMedida = '',
        quantidade = '',
        especificacoes = '',
        meioDivulgacao = '',
        fornecedoresConvidados = '',
        prazoResposta = '',
        f1Nome = '',
        f1Cnpj = '',
        f1Valor = '',
        f1DataRecebimento = '',
        f1LinkProposta = '',
        f2Nome = '',
        f2Cnpj = '',
        f2Valor = '',
        f2DataRecebimento = '',
        f2LinkProposta = '',
        f3Nome = '',
        f3Cnpj = '',
        f3Valor = '',
        f3DataRecebimento = '',
        f3LinkProposta = '',
        empresaLider = '',
        consorcioEnvolvidas = '',
        criterioConsolidacao = '',
        valorConsolidado = '',
        observacoes = '',
        linksAnexos = '';

  static String _text(dynamic value) {
    return (value ?? '').toString();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'numero': numero,
      'dataAbertura': dataAbertura,
      'dataEncerramento': dataEncerramento,
      'responsavelNome': responsavelNome,
      'responsavelUserId': responsavelUserId,
      'metodologia': metodologia,
      'objeto': objeto,
      'unidadeMedida': unidadeMedida,
      'quantidade': quantidade,
      'especificacoes': especificacoes,
      'meioDivulgacao': meioDivulgacao,
      'fornecedoresConvidados': fornecedoresConvidados,
      'prazoResposta': prazoResposta,
      'f1Nome': f1Nome,
      'f1Cnpj': f1Cnpj,
      'f1Valor': f1Valor,
      'f1DataRecebimento': f1DataRecebimento,
      'f1LinkProposta': f1LinkProposta,
      'f2Nome': f2Nome,
      'f2Cnpj': f2Cnpj,
      'f2Valor': f2Valor,
      'f2DataRecebimento': f2DataRecebimento,
      'f2LinkProposta': f2LinkProposta,
      'f3Nome': f3Nome,
      'f3Cnpj': f3Cnpj,
      'f3Valor': f3Valor,
      'f3DataRecebimento': f3DataRecebimento,
      'f3LinkProposta': f3LinkProposta,
      'empresaLider': empresaLider,
      'consorcioEnvolvidas': consorcioEnvolvidas,
      'criterioConsolidacao': criterioConsolidacao,
      'valorConsolidado': valorConsolidado,
      'observacoes': observacoes,
      'linksAnexos': linksAnexos,
    };
  }

  factory CotacaoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CotacaoData.empty();

    return CotacaoData(
      numero: _text(map['numero']),
      dataAbertura: _text(map['dataAbertura']),
      dataEncerramento: _text(map['dataEncerramento']),
      responsavelNome: _text(map['responsavelNome']),
      responsavelUserId: map['responsavelUserId']?.toString(),
      metodologia: _text(map['metodologia']),
      objeto: _text(map['objeto']),
      unidadeMedida: _text(map['unidadeMedida']),
      quantidade: _text(map['quantidade']),
      especificacoes: _text(map['especificacoes']),
      meioDivulgacao: _text(map['meioDivulgacao']),
      fornecedoresConvidados: _text(map['fornecedoresConvidados']),
      prazoResposta: _text(map['prazoResposta']),
      f1Nome: _text(map['f1Nome']),
      f1Cnpj: _text(map['f1Cnpj']),
      f1Valor: _text(map['f1Valor']),
      f1DataRecebimento: _text(map['f1DataRecebimento']),
      f1LinkProposta: _text(map['f1LinkProposta']),
      f2Nome: _text(map['f2Nome']),
      f2Cnpj: _text(map['f2Cnpj']),
      f2Valor: _text(map['f2Valor']),
      f2DataRecebimento: _text(map['f2DataRecebimento']),
      f2LinkProposta: _text(map['f2LinkProposta']),
      f3Nome: _text(map['f3Nome']),
      f3Cnpj: _text(map['f3Cnpj']),
      f3Valor: _text(map['f3Valor']),
      f3DataRecebimento: _text(map['f3DataRecebimento']),
      f3LinkProposta: _text(map['f3LinkProposta']),
      empresaLider: _text(map['empresaLider']),
      consorcioEnvolvidas: _text(map['consorcioEnvolvidas']),
      criterioConsolidacao: _text(map['criterioConsolidacao']),
      valorConsolidado: _text(map['valorConsolidado']),
      observacoes: _text(map['observacoes']),
      linksAnexos: _text(map['linksAnexos']),
    );
  }

  factory CotacaoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final meta =
        sections[sectionMetadados] ?? const <String, dynamic>{};

    final obj =
        sections[sectionObjetoItens] ?? const <String, dynamic>{};

    final conv =
        sections[sectionConviteDivulgacao] ?? const <String, dynamic>{};

    final resp =
        sections[sectionRespostasFornecedores] ??
            const <String, dynamic>{};

    final venc =
        sections[sectionVencedora] ?? const <String, dynamic>{};

    final cons =
        sections[sectionConsolidacaoResultado] ??
            const <String, dynamic>{};

    final anex =
        sections[sectionAnexosEvidencias] ??
            const <String, dynamic>{};

    return CotacaoData(
      numero: _text(meta['numero']),
      dataAbertura: _text(meta['dataAbertura']),
      dataEncerramento: _text(meta['dataEncerramento']),
      responsavelNome: _text(meta['responsavelNome']),
      responsavelUserId: meta['responsavelUserId']?.toString(),
      metodologia: _text(meta['metodologia']),
      objeto: _text(obj['objeto']),
      unidadeMedida: _text(obj['unidadeMedida']),
      quantidade: _text(obj['quantidade']),
      especificacoes: _text(obj['especificacoes']),
      meioDivulgacao: _text(conv['meioDivulgacao']),
      fornecedoresConvidados: _text(conv['fornecedoresConvidados']),
      prazoResposta: _text(conv['prazoResposta']),
      f1Nome: _text(resp['f1Nome']),
      f1Cnpj: _text(resp['f1Cnpj']),
      f1Valor: _text(resp['f1Valor']),
      f1DataRecebimento: _text(resp['f1DataRecebimento']),
      f1LinkProposta: _text(resp['f1LinkProposta']),
      f2Nome: _text(resp['f2Nome']),
      f2Cnpj: _text(resp['f2Cnpj']),
      f2Valor: _text(resp['f2Valor']),
      f2DataRecebimento: _text(resp['f2DataRecebimento']),
      f2LinkProposta: _text(resp['f2LinkProposta']),
      f3Nome: _text(resp['f3Nome']),
      f3Cnpj: _text(resp['f3Cnpj']),
      f3Valor: _text(resp['f3Valor']),
      f3DataRecebimento: _text(resp['f3DataRecebimento']),
      f3LinkProposta: _text(resp['f3LinkProposta']),
      empresaLider: _text(venc['empresaLider']),
      consorcioEnvolvidas: _text(venc['consorcioEnvolvidas']),
      criterioConsolidacao: _text(cons['criterioConsolidacao']),
      valorConsolidado: _text(cons['valorConsolidado']),
      observacoes: _text(cons['observacoes']),
      linksAnexos: _text(anex['linksAnexos']),
    );
  }

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionMetadados: <String, dynamic>{
        'numero': numero,
        'dataAbertura': dataAbertura,
        'dataEncerramento': dataEncerramento,
        'responsavelNome': responsavelNome,
        'responsavelUserId': responsavelUserId,
        'metodologia': metodologia,
      },
      sectionObjetoItens: <String, dynamic>{
        'objeto': objeto,
        'unidadeMedida': unidadeMedida,
        'quantidade': quantidade,
        'especificacoes': especificacoes,
      },
      sectionConviteDivulgacao: <String, dynamic>{
        'meioDivulgacao': meioDivulgacao,
        'fornecedoresConvidados': fornecedoresConvidados,
        'prazoResposta': prazoResposta,
      },
      sectionRespostasFornecedores: <String, dynamic>{
        'f1Nome': f1Nome,
        'f1Cnpj': f1Cnpj,
        'f1Valor': f1Valor,
        'f1DataRecebimento': f1DataRecebimento,
        'f1LinkProposta': f1LinkProposta,
        'f2Nome': f2Nome,
        'f2Cnpj': f2Cnpj,
        'f2Valor': f2Valor,
        'f2DataRecebimento': f2DataRecebimento,
        'f2LinkProposta': f2LinkProposta,
        'f3Nome': f3Nome,
        'f3Cnpj': f3Cnpj,
        'f3Valor': f3Valor,
        'f3DataRecebimento': f3DataRecebimento,
        'f3LinkProposta': f3LinkProposta,
      },
      sectionVencedora: <String, dynamic>{
        'empresaLider': empresaLider,
        'consorcioEnvolvidas': consorcioEnvolvidas,
      },
      sectionConsolidacaoResultado: <String, dynamic>{
        'criterioConsolidacao': criterioConsolidacao,
        'valorConsolidado': valorConsolidado,
        'observacoes': observacoes,
      },
      sectionAnexosEvidencias: <String, dynamic>{
        'linksAnexos': linksAnexos,
      },
    };
  }

  CotacaoData copyWith({
    String? numero,
    String? dataAbertura,
    String? dataEncerramento,
    String? responsavelNome,
    String? responsavelUserId,
    String? metodologia,
    String? objeto,
    String? unidadeMedida,
    String? quantidade,
    String? especificacoes,
    String? meioDivulgacao,
    String? fornecedoresConvidados,
    String? prazoResposta,
    String? f1Nome,
    String? f1Cnpj,
    String? f1Valor,
    String? f1DataRecebimento,
    String? f1LinkProposta,
    String? f2Nome,
    String? f2Cnpj,
    String? f2Valor,
    String? f2DataRecebimento,
    String? f2LinkProposta,
    String? f3Nome,
    String? f3Cnpj,
    String? f3Valor,
    String? f3DataRecebimento,
    String? f3LinkProposta,
    String? empresaLider,
    String? consorcioEnvolvidas,
    String? criterioConsolidacao,
    String? valorConsolidado,
    String? observacoes,
    String? linksAnexos,
  }) {
    return CotacaoData(
      numero: numero ?? this.numero,
      dataAbertura: dataAbertura ?? this.dataAbertura,
      dataEncerramento: dataEncerramento ?? this.dataEncerramento,
      responsavelNome: responsavelNome ?? this.responsavelNome,
      responsavelUserId: responsavelUserId ?? this.responsavelUserId,
      metodologia: metodologia ?? this.metodologia,
      objeto: objeto ?? this.objeto,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      quantidade: quantidade ?? this.quantidade,
      especificacoes: especificacoes ?? this.especificacoes,
      meioDivulgacao: meioDivulgacao ?? this.meioDivulgacao,
      fornecedoresConvidados:
      fornecedoresConvidados ?? this.fornecedoresConvidados,
      prazoResposta: prazoResposta ?? this.prazoResposta,
      f1Nome: f1Nome ?? this.f1Nome,
      f1Cnpj: f1Cnpj ?? this.f1Cnpj,
      f1Valor: f1Valor ?? this.f1Valor,
      f1DataRecebimento: f1DataRecebimento ?? this.f1DataRecebimento,
      f1LinkProposta: f1LinkProposta ?? this.f1LinkProposta,
      f2Nome: f2Nome ?? this.f2Nome,
      f2Cnpj: f2Cnpj ?? this.f2Cnpj,
      f2Valor: f2Valor ?? this.f2Valor,
      f2DataRecebimento: f2DataRecebimento ?? this.f2DataRecebimento,
      f2LinkProposta: f2LinkProposta ?? this.f2LinkProposta,
      f3Nome: f3Nome ?? this.f3Nome,
      f3Cnpj: f3Cnpj ?? this.f3Cnpj,
      f3Valor: f3Valor ?? this.f3Valor,
      f3DataRecebimento: f3DataRecebimento ?? this.f3DataRecebimento,
      f3LinkProposta: f3LinkProposta ?? this.f3LinkProposta,
      empresaLider: empresaLider ?? this.empresaLider,
      consorcioEnvolvidas: consorcioEnvolvidas ?? this.consorcioEnvolvidas,
      criterioConsolidacao:
      criterioConsolidacao ?? this.criterioConsolidacao,
      valorConsolidado: valorConsolidado ?? this.valorConsolidado,
      observacoes: observacoes ?? this.observacoes,
      linksAnexos: linksAnexos ?? this.linksAnexos,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    numero,
    dataAbertura,
    dataEncerramento,
    responsavelNome,
    responsavelUserId,
    metodologia,
    objeto,
    unidadeMedida,
    quantidade,
    especificacoes,
    meioDivulgacao,
    fornecedoresConvidados,
    prazoResposta,
    f1Nome,
    f1Cnpj,
    f1Valor,
    f1DataRecebimento,
    f1LinkProposta,
    f2Nome,
    f2Cnpj,
    f2Valor,
    f2DataRecebimento,
    f2LinkProposta,
    f3Nome,
    f3Cnpj,
    f3Valor,
    f3DataRecebimento,
    f3LinkProposta,
    empresaLider,
    consorcioEnvolvidas,
    criterioConsolidacao,
    valorConsolidado,
    observacoes,
    linksAnexos,
  ];
}