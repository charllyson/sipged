// lib/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:sipged/_utils/formatters/sipged_format_firestore.dart';
import 'package:sipged/_utils/formatters/sipged_format_numbers.dart';

class PublicacaoExtratoData extends Equatable {
  /// Chaves estáveis das seções da Publicação do Extrato.
  /// Substitui o antigo arquivo publicacao_extrato_sections.dart.
  static const sectionMetadados = 'metadados';
  static const sectionPartes = 'partes';
  static const sectionVeiculo = 'veiculo';
  static const sectionStatus = 'status';
  static const sectionResponsavel = 'responsavel';

  static const sectionKeys = <String>[
    sectionMetadados,
    sectionPartes,
    sectionVeiculo,
    sectionStatus,
    sectionResponsavel,
  ];

  // 1) Metadados
  final String? tipoExtrato;
  final String? numeroContrato;
  final String? processo;
  final String? objetoResumo;

  // 2) Partes / Valores
  final String? contratadaRazao;
  final String? contratadaCnpj;
  final double? valor;
  final int? vigencia;
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

  static String? _string(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toFlatMap() {
    return <String, dynamic>{
      'tipoExtrato': tipoExtrato,
      'numeroContrato': numeroContrato,
      'processo': processo,
      'objetoResumo': objetoResumo,
      'contratadaRazao': contratadaRazao,
      'contratadaCnpj': contratadaCnpj,
      'valor': valor,
      'vigencia': vigencia,
      'cnoRef': cnoRef,
      'veiculo': veiculo,
      'edicaoNumero': edicaoNumero,
      'dataEnvio': dataEnvio != null ? Timestamp.fromDate(dataEnvio!) : null,
      'dataPublicacao':
      dataPublicacao != null ? Timestamp.fromDate(dataPublicacao!) : null,
      'linkPublicacao': linkPublicacao,
      'status': status,
      'prazoLegal': prazoLegal,
      'observacoes': observacoes,
      'responsavelUserId': responsavelUserId,
    };
  }

  Map<String, dynamic> toMap() => toFlatMap();

  factory PublicacaoExtratoData.fromFlatMap(Map<String, dynamic>? map) {
    if (map == null) return const PublicacaoExtratoData.empty();

    return PublicacaoExtratoData(
      tipoExtrato: _string(map['tipoExtrato']),
      numeroContrato: _string(map['numeroContrato']),
      processo: _string(map['processo']),
      objetoResumo: _string(map['objetoResumo']),
      contratadaRazao: _string(map['contratadaRazao']),
      contratadaCnpj: _string(map['contratadaCnpj']),
      valor: SipGedFormatNumbers.toDouble(map['valor']),
      vigencia: SipGedFormatNumbers.toInt(map['vigencia']),
      cnoRef: _string(map['cnoRef']),
      veiculo: _string(map['veiculo']),
      edicaoNumero: _string(map['edicaoNumero']),
      dataEnvio: SipGedFormatFirestore.toDate(map['dataEnvio']),
      dataPublicacao: SipGedFormatFirestore.toDate(map['dataPublicacao']),
      linkPublicacao: _string(map['linkPublicacao']),
      status: _string(map['status']),
      prazoLegal: _string(map['prazoLegal']),
      observacoes: _string(map['observacoes']),
      responsavelUserId: _string(map['responsavelUserId']),
    );
  }

  factory PublicacaoExtratoData.fromMap(Map<String, dynamic>? map) {
    return PublicacaoExtratoData.fromFlatMap(map);
  }

  factory PublicacaoExtratoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final m = sections[sectionMetadados] ?? const <String, dynamic>{};
    final p = sections[sectionPartes] ?? const <String, dynamic>{};
    final v = sections[sectionVeiculo] ?? const <String, dynamic>{};
    final s = sections[sectionStatus] ?? const <String, dynamic>{};
    final r = sections[sectionResponsavel] ?? const <String, dynamic>{};

    return PublicacaoExtratoData(
      tipoExtrato: _string(m['tipoExtrato']),
      numeroContrato: _string(m['numeroContrato']),
      processo: _string(m['processo']),
      objetoResumo: _string(m['objetoResumo']),
      contratadaRazao: _string(p['contratadaRazao']),
      contratadaCnpj: _string(p['contratadaCnpj']),
      valor: SipGedFormatNumbers.toDouble(p['valor']),
      vigencia: SipGedFormatNumbers.toInt(p['vigencia']),
      cnoRef: _string(p['cnoRef']),
      veiculo: _string(v['veiculo']),
      edicaoNumero: _string(v['edicaoNumero']),
      dataEnvio: SipGedFormatFirestore.toDate(v['dataEnvio']),
      dataPublicacao: SipGedFormatFirestore.toDate(v['dataPublicacao']),
      linkPublicacao: _string(v['linkPublicacao']),
      status: _string(s['status']),
      prazoLegal: _string(s['prazoLegal']),
      observacoes: _string(s['observacoes']),
      responsavelUserId: _string(r['responsavelUserId']),
    );
  }

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

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionMetadados: <String, dynamic>{
        'tipoExtrato': tipoExtrato,
        'numeroContrato': numeroContrato,
        'processo': processo,
        'objetoResumo': objetoResumo,
      },
      sectionPartes: <String, dynamic>{
        'contratadaRazao': contratadaRazao,
        'contratadaCnpj': contratadaCnpj,
        'valor': valor,
        'vigencia': vigencia,
        'cnoRef': cnoRef,
      },
      sectionVeiculo: <String, dynamic>{
        'veiculo': veiculo,
        'edicaoNumero': edicaoNumero,
        'dataEnvio': dataEnvio != null ? Timestamp.fromDate(dataEnvio!) : null,
        'dataPublicacao':
        dataPublicacao != null ? Timestamp.fromDate(dataPublicacao!) : null,
        'linkPublicacao': linkPublicacao,
      },
      sectionStatus: <String, dynamic>{
        'status': status,
        'prazoLegal': prazoLegal,
        'observacoes': observacoes,
      },
      sectionResponsavel: <String, dynamic>{
        'responsavelUserId': responsavelUserId,
      },
    };
  }

  @override
  List<Object?> get props => <Object?>[
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