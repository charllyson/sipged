import 'package:equatable/equatable.dart';

class MinutaContratoData extends Equatable {
  final String? numero;
  final String? versao;
  final String? dataElaboracao;

  final String? contratante;
  final String? contratadaRazao;
  final String? contratadaCnpj;
  final String? objetoResumo;

  final String? valorGlobal;

  final String? gestorUserId;
  final String? gestorNome;
  final String? fiscalUserId;
  final String? fiscalNome;
  final String? linksAnexos;
  final String? regimeExecucaoRef;
  final String? prazosRef;

  const MinutaContratoData({
    this.numero,
    this.versao,
    this.dataElaboracao,
    this.contratante,
    this.contratadaRazao,
    this.contratadaCnpj,
    this.objetoResumo,
    this.valorGlobal,
    this.gestorUserId,
    this.gestorNome,
    this.fiscalUserId,
    this.fiscalNome,
    this.linksAnexos,
    this.regimeExecucaoRef,
    this.prazosRef,
  });

  Map<String, dynamic> toMap() => {
    'numero': numero,
    'versao': versao,
    'dataElaboracao': dataElaboracao,
    'contratante': contratante,
    'contratadaRazao': contratadaRazao,
    'contratadaCnpj': contratadaCnpj,
    'objetoResumo': objetoResumo,
    'valorGlobal': valorGlobal,
    'gestorUserId': gestorUserId,
    'gestorNome': gestorNome,
    'fiscalUserId': fiscalUserId,
    'fiscalNome': fiscalNome,
    'linksAnexos': linksAnexos,
    'regimeExecucaoRef': regimeExecucaoRef,
    'prazosRef': prazosRef,
  };

  factory MinutaContratoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const MinutaContratoData();
    return MinutaContratoData(
      numero: map['numero'],
      versao: map['versao'],
      dataElaboracao: map['dataElaboracao'],
      contratante: map['contratante'],
      contratadaRazao: map['contratadaRazao'],
      contratadaCnpj: map['contratadaCnpj'],
      objetoResumo: map['objetoResumo'],
      valorGlobal: map['valorGlobal'],
      gestorUserId: map['gestorUserId'],
      gestorNome: map['gestorNome'],
      fiscalUserId: map['fiscalUserId'],
      fiscalNome: map['fiscalNome'],
      linksAnexos: map['linksAnexos'],
      regimeExecucaoRef: map['regimeExecucaoRef'],
      prazosRef: map['prazosRef'],
    );
  }

  @override
  List<Object?> get props => [
    numero, versao, dataElaboracao,
    contratante, contratadaRazao, contratadaCnpj, objetoResumo,
    valorGlobal,
    gestorUserId, gestorNome, fiscalUserId, fiscalNome,
    linksAnexos, regimeExecucaoRef, prazosRef,
  ];
}
