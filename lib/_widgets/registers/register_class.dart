import 'package:cloud_firestore/cloud_firestore.dart';
import '../../_datas/documents/contracts/additive/additive_data.dart';
import '../../_datas/documents/contracts/apostilles/apostilles_data.dart';
import '../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../_datas/documents/contracts/validity/validity_data.dart';
import '../../_datas/documents/measurement/measurement_data.dart';

class Registro {
  final String? id;
  final String tipo;
  final DateTime data;
  final dynamic original;
  final ContractData? contractData;
  final String? contractId;
  final String? measurementId;
  final bool seen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Registro({
    this.id,
    required this.tipo,
    required this.data,
    this.original,
    this.contractData,
    this.contractId,
    this.measurementId,
    this.seen = false,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  String get dataFormatada =>
      '${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/'
          '${data.year}';

  String get titulo {
    if (original is ReportData) {
      final m = original as ReportData;
      return '${m.orderReportMeasurement}ª Medição';
    } else if (original is AdditiveData) {
      final a = original as AdditiveData;
      return '${a.additiveOrder}° Aditivo';
    } else if (original is ApostillesData) {
      final a = original as ApostillesData;
      return '${a.apostilleOrder}° Apostilamento';
    } else if (original is ValidityData) {
      final v = original as ValidityData;
      return v.ordertype ?? 'Ordem';
    } else {
      return tipoFormatado;
    }
  }

  String get tipoFormatado {
    if (tipo.isEmpty) return '';
    return tipo[0].toUpperCase() + tipo.substring(1);
  }

  String get subtitulo {
    return contractData?.summarySubjectContract ??
        contractData?.contractNumber ??
        '';
  }

  factory Registro.fromNotificationDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Registro(
      id: doc.id,
      tipo: data['tipo'] ?? 'Desconhecido',
      contractId: data['contractId'],
      measurementId: data['measurementId'],
      data: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime(2000),
      seen: data['seen'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'contractId': contractId,
      'measurementId': measurementId,
      'createdAt': Timestamp.fromDate(data),
      'seen': seen,
    };
  }

}