import 'package:equatable/equatable.dart';

import 'cotacao_sections.dart';

class CotacaoData extends Equatable {
  // ===== 1) Metadados =====
  final String? numero;
  final String? dataAbertura;
  final String? dataEncerramento;
  final String? responsavelNome;
  final String? responsavelUserId;
  final String? metodologia;

  // ===== 2) Objeto/Itens (resumo) =====
  final String? objeto;
  final String? unidadeMedida;
  final String? quantidade;
  final String? especificacoes;

  // ===== 3) Convite/Divulgação =====
  final String? meioDivulgacao;
  final String? fornecedoresConvidados;
  final String? prazoResposta;

  // ===== 4) Respostas dos Fornecedores (até 3) =====
  // fornecedor 1
  final String? f1Nome;
  final String? f1Cnpj;
  final String? f1Valor;
  final String? f1DataRecebimento;
  final String? f1LinkProposta;

  // fornecedor 2
  final String? f2Nome;
  final String? f2Cnpj;
  final String? f2Valor;
  final String? f2DataRecebimento;
  final String? f2LinkProposta;

  // fornecedor 3
  final String? f3Nome;
  final String? f3Cnpj;
  final String? f3Valor;
  final String? f3DataRecebimento;
  final String? f3LinkProposta;

  // ===== Empresa vencedora =====
  final String? empresaLider;
  final String? consorcioEnvolvidas;

  // ===== 5) Consolidação/Resultado =====
  final String? criterioConsolidacao;
  final String? valorConsolidado;
  final String? observacoes;

  // ===== 6) Anexos/Evidências =====
  final String? linksAnexos;

  const CotacaoData({
    // 1) Metadados
    this.numero,
    this.dataAbertura,
    this.dataEncerramento,
    this.responsavelNome,
    this.responsavelUserId,
    this.metodologia,

    // 2) Objeto/Itens (resumo)
    this.objeto,
    this.unidadeMedida,
    this.quantidade,
    this.especificacoes,

    // 3) Convite/Divulgação
    this.meioDivulgacao,
    this.fornecedoresConvidados,
    this.prazoResposta,

    // 4) Respostas dos Fornecedores
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

    // Empresa vencedora
    this.empresaLider,
    this.consorcioEnvolvidas,

    // 5) Consolidação/Resultado
    this.criterioConsolidacao,
    this.valorConsolidado,
    this.observacoes,

    // 6) Anexos/Evidências
    this.linksAnexos,
  });

  /// Construtor "vazio" no mesmo padrão dos outros Data
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

  // ---------------------------------------------------------------------------
  // Map "flat" (sem seções) — compat direto com Firestore se salvar tudo junto
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() => {
    // 1) Metadados
    'numero': numero,
    'dataAbertura': dataAbertura,
    'dataEncerramento': dataEncerramento,
    'responsavelNome': responsavelNome,
    'responsavelUserId': responsavelUserId,
    'metodologia': metodologia,

    // 2) Objeto/Itens (resumo)
    'objeto': objeto,
    'unidadeMedida': unidadeMedida,
    'quantidade': quantidade,
    'especificacoes': especificacoes,

    // 3) Convite/Divulgação
    'meioDivulgacao': meioDivulgacao,
    'fornecedoresConvidados': fornecedoresConvidados,
    'prazoResposta': prazoResposta,

    // 4) Respostas dos Fornecedores
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

    // Empresa vencedora
    'empresaLider': empresaLider,
    'consorcioEnvolvidas': consorcioEnvolvidas,

    // 5) Consolidação/Resultado
    'criterioConsolidacao': criterioConsolidacao,
    'valorConsolidado': valorConsolidado,
    'observacoes': observacoes,

    // 6) Anexos/Evidências
    'linksAnexos': linksAnexos,
  };

  factory CotacaoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CotacaoData.empty();

    return CotacaoData(
      // 1) Metadados
      numero: (map['numero'] ?? '').toString(),
      dataAbertura: (map['dataAbertura'] ?? '').toString(),
      dataEncerramento:
      (map['dataEncerramento'] ?? '').toString(),
      responsavelNome:
      (map['responsavelNome'] ?? '').toString(),
      responsavelUserId:
      map['responsavelUserId']?.toString(),
      metodologia: (map['metodologia'] ?? '').toString(),

      // 2) Objeto/Itens (resumo)
      objeto: (map['objeto'] ?? '').toString(),
      unidadeMedida:
      (map['unidadeMedida'] ?? '').toString(),
      quantidade: (map['quantidade'] ?? '').toString(),
      especificacoes:
      (map['especificacoes'] ?? '').toString(),

      // 3) Convite/Divulgação
      meioDivulgacao:
      (map['meioDivulgacao'] ?? '').toString(),
      fornecedoresConvidados:
      (map['fornecedoresConvidados'] ?? '').toString(),
      prazoResposta:
      (map['prazoResposta'] ?? '').toString(),

      // 4) Respostas dos Fornecedores
      f1Nome: (map['f1Nome'] ?? '').toString(),
      f1Cnpj: (map['f1Cnpj'] ?? '').toString(),
      f1Valor: (map['f1Valor'] ?? '').toString(),
      f1DataRecebimento:
      (map['f1DataRecebimento'] ?? '').toString(),
      f1LinkProposta:
      (map['f1LinkProposta'] ?? '').toString(),

      f2Nome: (map['f2Nome'] ?? '').toString(),
      f2Cnpj: (map['f2Cnpj'] ?? '').toString(),
      f2Valor: (map['f2Valor'] ?? '').toString(),
      f2DataRecebimento:
      (map['f2DataRecebimento'] ?? '').toString(),
      f2LinkProposta:
      (map['f2LinkProposta'] ?? '').toString(),

      f3Nome: (map['f3Nome'] ?? '').toString(),
      f3Cnpj: (map['f3Cnpj'] ?? '').toString(),
      f3Valor: (map['f3Valor'] ?? '').toString(),
      f3DataRecebimento:
      (map['f3DataRecebimento'] ?? '').toString(),
      f3LinkProposta:
      (map['f3LinkProposta'] ?? '').toString(),

      // Empresa vencedora
      empresaLider:
      (map['empresaLider'] ?? '').toString(),
      consorcioEnvolvidas:
      (map['consorcioEnvolvidas'] ?? '').toString(),

      // 5) Consolidação/Resultado
      criterioConsolidacao:
      (map['criterioConsolidacao'] ?? '').toString(),
      valorConsolidado:
      (map['valorConsolidado'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),

      // 6) Anexos/Evidências
      linksAnexos: (map['linksAnexos'] ?? '').toString(),
    );
  }

  /// Mesmo padrão dos outros: monta a partir da estrutura em seções
  factory CotacaoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final meta = sections[CotacaoSections.metadados] ??
        const <String, dynamic>{};
    final obj = sections[CotacaoSections.objetoItens] ??
        const <String, dynamic>{};
    final conv = sections[CotacaoSections.conviteDivulgacao] ??
        const <String, dynamic>{};
    final resp =
        sections[CotacaoSections.respostasFornecedores] ??
            const <String, dynamic>{};
    final venc = sections[CotacaoSections.vencedora] ??
        const <String, dynamic>{};
    final cons = sections[
    CotacaoSections.consolidacaoResultado] ??
        const <String, dynamic>{};
    final anex = sections[
    CotacaoSections.anexosEvidencias] ??
        const <String, dynamic>{};

    return CotacaoData(
      // 1) Metadados
      numero: (meta['numero'] ?? '').toString(),
      dataAbertura:
      (meta['dataAbertura'] ?? '').toString(),
      dataEncerramento:
      (meta['dataEncerramento'] ?? '').toString(),
      responsavelNome:
      (meta['responsavelNome'] ?? '').toString(),
      responsavelUserId:
      meta['responsavelUserId']?.toString(),
      metodologia:
      (meta['metodologia'] ?? '').toString(),

      // 2) Objeto/Itens
      objeto: (obj['objeto'] ?? '').toString(),
      unidadeMedida:
      (obj['unidadeMedida'] ?? '').toString(),
      quantidade:
      (obj['quantidade'] ?? '').toString(),
      especificacoes:
      (obj['especificacoes'] ?? '').toString(),

      // 3) Convite/Divulgação
      meioDivulgacao:
      (conv['meioDivulgacao'] ?? '').toString(),
      fornecedoresConvidados:
      (conv['fornecedoresConvidados'] ?? '').toString(),
      prazoResposta:
      (conv['prazoResposta'] ?? '').toString(),

      // 4) Respostas dos Fornecedores
      f1Nome: (resp['f1Nome'] ?? '').toString(),
      f1Cnpj: (resp['f1Cnpj'] ?? '').toString(),
      f1Valor: (resp['f1Valor'] ?? '').toString(),
      f1DataRecebimento:
      (resp['f1DataRecebimento'] ?? '').toString(),
      f1LinkProposta:
      (resp['f1LinkProposta'] ?? '').toString(),

      f2Nome: (resp['f2Nome'] ?? '').toString(),
      f2Cnpj: (resp['f2Cnpj'] ?? '').toString(),
      f2Valor: (resp['f2Valor'] ?? '').toString(),
      f2DataRecebimento:
      (resp['f2DataRecebimento'] ?? '').toString(),
      f2LinkProposta:
      (resp['f2LinkProposta'] ?? '').toString(),

      f3Nome: (resp['f3Nome'] ?? '').toString(),
      f3Cnpj: (resp['f3Cnpj'] ?? '').toString(),
      f3Valor: (resp['f3Valor'] ?? '').toString(),
      f3DataRecebimento:
      (resp['f3DataRecebimento'] ?? '').toString(),
      f3LinkProposta:
      (resp['f3LinkProposta'] ?? '').toString(),

      // Vencedora
      empresaLider:
      (venc['empresaLider'] ?? '').toString(),
      consorcioEnvolvidas:
      (venc['consorcioEnvolvidas'] ?? '').toString(),

      // Consolidação/Resultado
      criterioConsolidacao:
      (cons['criterioConsolidacao'] ?? '').toString(),
      valorConsolidado:
      (cons['valorConsolidado'] ?? '').toString(),
      observacoes:
      (cons['observacoes'] ?? '').toString(),

      // Anexos/Evidências
      linksAnexos:
      (anex['linksAnexos'] ?? '').toString(),
    );
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
      dataEncerramento:
      dataEncerramento ?? this.dataEncerramento,
      responsavelNome:
      responsavelNome ?? this.responsavelNome,
      responsavelUserId:
      responsavelUserId ?? this.responsavelUserId,
      metodologia: metodologia ?? this.metodologia,
      objeto: objeto ?? this.objeto,
      unidadeMedida:
      unidadeMedida ?? this.unidadeMedida,
      quantidade: quantidade ?? this.quantidade,
      especificacoes:
      especificacoes ?? this.especificacoes,
      meioDivulgacao:
      meioDivulgacao ?? this.meioDivulgacao,
      fornecedoresConvidados:
      fornecedoresConvidados ??
          this.fornecedoresConvidados,
      prazoResposta: prazoResposta ?? this.prazoResposta,
      f1Nome: f1Nome ?? this.f1Nome,
      f1Cnpj: f1Cnpj ?? this.f1Cnpj,
      f1Valor: f1Valor ?? this.f1Valor,
      f1DataRecebimento:
      f1DataRecebimento ?? this.f1DataRecebimento,
      f1LinkProposta:
      f1LinkProposta ?? this.f1LinkProposta,
      f2Nome: f2Nome ?? this.f2Nome,
      f2Cnpj: f2Cnpj ?? this.f2Cnpj,
      f2Valor: f2Valor ?? this.f2Valor,
      f2DataRecebimento:
      f2DataRecebimento ?? this.f2DataRecebimento,
      f2LinkProposta:
      f2LinkProposta ?? this.f2LinkProposta,
      f3Nome: f3Nome ?? this.f3Nome,
      f3Cnpj: f3Cnpj ?? this.f3Cnpj,
      f3Valor: f3Valor ?? this.f3Valor,
      f3DataRecebimento:
      f3DataRecebimento ?? this.f3DataRecebimento,
      f3LinkProposta:
      f3LinkProposta ?? this.f3LinkProposta,
      empresaLider:
      empresaLider ?? this.empresaLider,
      consorcioEnvolvidas:
      consorcioEnvolvidas ??
          this.consorcioEnvolvidas,
      criterioConsolidacao:
      criterioConsolidacao ??
          this.criterioConsolidacao,
      valorConsolidado:
      valorConsolidado ?? this.valorConsolidado,
      observacoes: observacoes ?? this.observacoes,
      linksAnexos: linksAnexos ?? this.linksAnexos,
    );
  }

  @override
  List<Object?> get props => [
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

// -----------------------------------------------------------------------------
// Mapeamento p/ estrutura em seções (mesma usada no Firestore)
// -----------------------------------------------------------------------------
extension CotacaoDataSections on CotacaoData {
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      CotacaoSections.metadados: {
        'numero': numero,
        'dataAbertura': dataAbertura,
        'dataEncerramento': dataEncerramento,
        'responsavelNome': responsavelNome,
        'responsavelUserId': responsavelUserId,
        'metodologia': metodologia,
      },
      CotacaoSections.objetoItens: {
        'objeto': objeto,
        'unidadeMedida': unidadeMedida,
        'quantidade': quantidade,
        'especificacoes': especificacoes,
      },
      CotacaoSections.conviteDivulgacao: {
        'meioDivulgacao': meioDivulgacao,
        'fornecedoresConvidados': fornecedoresConvidados,
        'prazoResposta': prazoResposta,
      },
      CotacaoSections.respostasFornecedores: {
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
      CotacaoSections.vencedora: {
        'empresaLider': empresaLider,
        'consorcioEnvolvidas': consorcioEnvolvidas,
      },
      CotacaoSections.consolidacaoResultado: {
        'criterioConsolidacao': criterioConsolidacao,
        'valorConsolidado': valorConsolidado,
        'observacoes': observacoes,
      },
      CotacaoSections.anexosEvidencias: {
        'linksAnexos': linksAnexos,
      },
    };
  }
}
