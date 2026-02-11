// lib/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:siged/_utils/formats/sipged_format_firestore.dart';
import 'package:siged/_utils/formats/sipged_format_numbers.dart';
import 'publicacao_extrato_sections.dart';

class PublicacaoExtratoData extends Equatable {
  // 1) Metadados
  final String? tipoExtrato;
  final String? numeroContrato;
  final String? processo;
  final String? objetoResumo;

  // 2) Partes / Valores / Vigência
  final String? contratadaRazao;
  final String? contratadaCnpj;
  final double? valor;      // ex.: 12345.67
  final int? vigencia;      // ex.: 12 (meses ou dias, conforme uso)
  final String? cnoRef;

  // 3) Veículo
  final String? veiculo;
  final String? edicaoNumero;
  final DateTime? dataEnvio;
  final DateTime? dataPublicacao;
  final String? linkPublicacao;

  // 4) Status / Prazos
  final String? status;
  final String? prazoLegal;
  final String? observacoes;

  // 5) Responsável
  final String? responsavelUserId;

  const PublicacaoExtratoData({
    this.tipoExtrato,
    this.numeroContrato,
    this.processo,
    this.objetoResumo,
    this.contratadaRazao,
    this.contratadaCnpj,
    this.valor,
    this.vigencia,
    this.cnoRef,
    this.veiculo,
    this.edicaoNumero,
    this.dataEnvio,
    this.dataPublicacao,
    this.linkPublicacao,
    this.status,
    this.prazoLegal,
    this.observacoes,
    this.responsavelUserId,
  });

  /// Construtor "vazio" para formulários
  const PublicacaoExtratoData.empty()
      : tipoExtrato = null,
        numeroContrato = null,
        processo = null,
        objetoResumo = null,
        contratadaRazao = null,
        contratadaCnpj = null,
        valor = null,
        vigencia = null,
        cnoRef = null,
        veiculo = null,
        edicaoNumero = null,
        dataEnvio = null,
        dataPublicacao = null,
        linkPublicacao = null,
        status = null,
        prazoLegal = null,
        observacoes = null,
        responsavelUserId = null;

  // ---------------------------------------------------------------------------
  // Map simples (sem seções)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toFlatMap() => {
    // metadados
    'tipoExtrato': tipoExtrato,
    'numeroContrato': numeroContrato,
    'processo': processo,
    'objetoResumo': objetoResumo,

    // partes/valores
    'contratadaRazao': contratadaRazao,
    'contratadaCnpj': contratadaCnpj,
    'valor': valor, // double -> number
    'vigencia': vigencia, // int -> number
    'cnoRef': cnoRef,

    // veículo
    'veiculo': veiculo,
    'edicaoNumero': edicaoNumero,
    'dataEnvio':
    dataEnvio != null ? Timestamp.fromDate(dataEnvio!) : null,
    'dataPublicacao':
    dataPublicacao != null ? Timestamp.fromDate(dataPublicacao!) : null,
    'linkPublicacao': linkPublicacao,

    // status
    'status': status,
    'prazoLegal': prazoLegal,
    'observacoes': observacoes,

    // responsável
    'responsavelUserId': responsavelUserId,
  };

  factory PublicacaoExtratoData.fromFlatMap(Map<String, dynamic>? map) {
    if (map == null) return const PublicacaoExtratoData.empty();
    return PublicacaoExtratoData(
      tipoExtrato: map['tipoExtrato'] as String?,
      numeroContrato: map['numeroContrato'] as String?,
      processo: map['processo'] as String?,
      objetoResumo: map['objetoResumo'] as String?,
      contratadaRazao: map['contratadaRazao'] as String?,
      contratadaCnpj: map['contratadaCnpj'] as String?,
      valor: SipGedFormatNumbers.toDouble(map['valor']),
      vigencia: SipGedFormatNumbers.toInt(map['vigencia']),
      cnoRef: map['cnoRef'] as String?,
      veiculo: map['veiculo'] as String?,
      edicaoNumero: map['edicaoNumero'] as String?,
      dataEnvio: SipGedFormatFirestore.toDate(map['dataEnvio']),
      dataPublicacao: SipGedFormatFirestore.toDate(map['dataPublicacao']),
      linkPublicacao: map['linkPublicacao'] as String?,
      status: map['status'] as String?,
      prazoLegal: map['prazoLegal'] as String?,
      observacoes: map['observacoes'] as String?,
      responsavelUserId: map['responsavelUserId'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Seções (metadados/partes/veiculo/status/responsavel)
  // ---------------------------------------------------------------------------

  factory PublicacaoExtratoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final m =
        sections[PublicacaoExtratoSections.metadados] ?? const <String, dynamic>{};
    final p =
        sections[PublicacaoExtratoSections.partes] ?? const <String, dynamic>{};
    final v =
        sections[PublicacaoExtratoSections.veiculo] ?? const <String, dynamic>{};
    final s =
        sections[PublicacaoExtratoSections.status] ?? const <String, dynamic>{};
    final r = sections[PublicacaoExtratoSections.responsavel] ??
        const <String, dynamic>{};

    return PublicacaoExtratoData(
      tipoExtrato: m['tipoExtrato'] as String?,
      numeroContrato: m['numeroContrato'] as String?,
      processo: m['processo'] as String?,
      objetoResumo: m['objetoResumo'] as String?,

      contratadaRazao: p['contratadaRazao'] as String?,
      contratadaCnpj: p['contratadaCnpj'] as String?,
      valor: SipGedFormatNumbers.toDouble(p['valor']),
      vigencia: SipGedFormatNumbers.toInt(p['vigencia']),
      cnoRef: p['cnoRef'] as String?,

      veiculo: v['veiculo'] as String?,
      edicaoNumero: v['edicaoNumero'] as String?,
      dataEnvio: SipGedFormatFirestore.toDate(v['dataEnvio']),
      dataPublicacao: SipGedFormatFirestore.toDate(v['dataPublicacao']),
      linkPublicacao: v['linkPublicacao'] as String?,

      status: s['status'] as String?,
      prazoLegal: s['prazoLegal'] as String?,
      observacoes: s['observacoes'] as String?,

      responsavelUserId: r['responsavelUserId'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  PublicacaoExtratoData copyWith({
    String? tipoExtrato,
    String? numeroContrato,
    String? processo,
    String? objetoResumo,
    String? contratadaRazao,
    String? contratadaCnpj,
    double? valor,
    int? vigencia,
    String? cnoRef,
    String? veiculo,
    String? edicaoNumero,
    DateTime? dataEnvio,
    DateTime? dataPublicacao,
    String? linkPublicacao,
    String? status,
    String? prazoLegal,
    String? observacoes,
    String? responsavelUserId,
  }) {
    return PublicacaoExtratoData(
      tipoExtrato: tipoExtrato ?? this.tipoExtrato,
      numeroContrato: numeroContrato ?? this.numeroContrato,
      processo: processo ?? this.processo,
      objetoResumo: objetoResumo ?? this.objetoResumo,
      contratadaRazao: contratadaRazao ?? this.contratadaRazao,
      contratadaCnpj: contratadaCnpj ?? this.contratadaCnpj,
      valor: valor ?? this.valor,
      vigencia: vigencia ?? this.vigencia,
      cnoRef: cnoRef ?? this.cnoRef,
      veiculo: veiculo ?? this.veiculo,
      edicaoNumero: edicaoNumero ?? this.edicaoNumero,
      dataEnvio: dataEnvio ?? this.dataEnvio,
      dataPublicacao: dataPublicacao ?? this.dataPublicacao,
      linkPublicacao: linkPublicacao ?? this.linkPublicacao,
      status: status ?? this.status,
      prazoLegal: prazoLegal ?? this.prazoLegal,
      observacoes: observacoes ?? this.observacoes,
      responsavelUserId: responsavelUserId ?? this.responsavelUserId,
    );
  }

  @override
  List<Object?> get props => [
    tipoExtrato,
    numeroContrato,
    processo,
    objetoResumo,
    contratadaRazao,
    contratadaCnpj,
    valor,
    vigencia,
    cnoRef,
    veiculo,
    edicaoNumero,
    dataEnvio,
    dataPublicacao,
    linkPublicacao,
    status,
    prazoLegal,
    observacoes,
    responsavelUserId,
  ];
}

// -----------------------------------------------------------------------------
// Mapeamento p/ estrutura em seções (mesma usada no Firestore)
// -----------------------------------------------------------------------------
extension PublicacaoExtratoDataSections on PublicacaoExtratoData {
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      PublicacaoExtratoSections.metadados: {
        'tipoExtrato': tipoExtrato,
        'numeroContrato': numeroContrato,
        'processo': processo,
        'objetoResumo': objetoResumo,
      },
      PublicacaoExtratoSections.partes: {
        'contratadaRazao': contratadaRazao,
        'contratadaCnpj': contratadaCnpj,
        'valor': valor,
        'vigencia': vigencia,
        'cnoRef': cnoRef,
      },
      PublicacaoExtratoSections.veiculo: {
        'veiculo': veiculo,
        'edicaoNumero': edicaoNumero,
        'dataEnvio':
        dataEnvio != null ? Timestamp.fromDate(dataEnvio!) : null,
        'dataPublicacao':
        dataPublicacao != null ? Timestamp.fromDate(dataPublicacao!) : null,
        'linkPublicacao': linkPublicacao,
      },
      PublicacaoExtratoSections.status: {
        'status': status,
        'prazoLegal': prazoLegal,
        'observacoes': observacoes,
      },
      PublicacaoExtratoSections.responsavel: {
        'responsavelUserId': responsavelUserId,
      },
    };
  }
}
