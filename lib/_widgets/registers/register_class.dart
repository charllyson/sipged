import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_data.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:siged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';

class Registro {
  final String? id;
  final String tipo;
  final DateTime data;
  final dynamic original;
  final ProcessData? contractData;
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
    if (original is ReportMeasurementData) {
      final m = original as ReportMeasurementData;
      return '${m.order}ª Medição';
    } else if (original is AdditivesData) {
      final a = original as AdditivesData;
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

  /// Subtítulo simples baseado apenas no ID do contrato.
  /// O rótulo amigável (nº contrato + descrição) deve ser montado
  /// externamente usando DfdData/PublicacaoExtratoData.
  String get subtitulo {
    return contractId ?? '';
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
