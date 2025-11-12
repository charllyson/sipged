import 'package:equatable/equatable.dart';

class PublicacaoExtratoData extends Equatable {
  // 1) Metadados
  final String? tipoExtrato;
  final String? numeroContrato;
  final String? processo;
  final String? objetoResumo;

  // 2) Partes / Valores / Vigência
  final String? contratadaRazao;
  final String? contratadaCnpj;
  final String? valor;
  final String? vigencia;
  final String? cnoRef;

  // 3) Veículo
  final String? veiculo;
  final String? edicaoNumero;
  final String? dataEnvio;
  final String? dataPublicacao;
  final String? linkPublicacao;

  // 4) Status / Prazos
  final String? status;
  final String? prazoLegal;
  final String? observacoes;

  // 5) Responsável
  final String? responsavelNome;
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
    this.responsavelNome,
    this.responsavelUserId,
  });

  Map<String, dynamic> toFlatMap() => {
    // metadados
    'tipoExtrato': tipoExtrato,
    'numeroContrato': numeroContrato,
    'processo': processo,
    'objetoResumo': objetoResumo,
    // partes/valores
    'contratadaRazao': contratadaRazao,
    'contratadaCnpj': contratadaCnpj,
    'valor': valor,
    'vigencia': vigencia,
    'cnoRef': cnoRef,
    // veículo
    'veiculo': veiculo,
    'edicaoNumero': edicaoNumero,
    'dataEnvio': dataEnvio,
    'dataPublicacao': dataPublicacao,
    'linkPublicacao': linkPublicacao,
    // status
    'status': status,
    'prazoLegal': prazoLegal,
    'observacoes': observacoes,
    // responsável
    'responsavelNome': responsavelNome,
    'responsavelUserId': responsavelUserId,
  };

  factory PublicacaoExtratoData.fromFlatMap(Map<String, dynamic>? map) {
    if (map == null) return const PublicacaoExtratoData();
    return PublicacaoExtratoData(
      tipoExtrato: map['tipoExtrato'],
      numeroContrato: map['numeroContrato'],
      processo: map['processo'],
      objetoResumo: map['objetoResumo'],
      contratadaRazao: map['contratadaRazao'],
      contratadaCnpj: map['contratadaCnpj'],
      valor: map['valor'],
      vigencia: map['vigencia'],
      cnoRef: map['cnoRef'],
      veiculo: map['veiculo'],
      edicaoNumero: map['edicaoNumero'],
      dataEnvio: map['dataEnvio'],
      dataPublicacao: map['dataPublicacao'],
      linkPublicacao: map['linkPublicacao'],
      status: map['status'],
      prazoLegal: map['prazoLegal'],
      observacoes: map['observacoes'],
      responsavelNome: map['responsavelNome'],
      responsavelUserId: map['responsavelUserId'],
    );
  }

  PublicacaoExtratoData copyWith({
    String? tipoExtrato,
    String? numeroContrato,
    String? processo,
    String? objetoResumo,
    String? contratadaRazao,
    String? contratadaCnpj,
    String? valor,
    String? vigencia,
    String? cnoRef,
    String? veiculo,
    String? edicaoNumero,
    String? dataEnvio,
    String? dataPublicacao,
    String? linkPublicacao,
    String? status,
    String? prazoLegal,
    String? observacoes,
    String? responsavelNome,
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
      responsavelNome: responsavelNome ?? this.responsavelNome,
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
    responsavelNome,
    responsavelUserId,
  ];
}
