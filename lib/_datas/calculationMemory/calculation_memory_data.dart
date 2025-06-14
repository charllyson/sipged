import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class CalculationMemoryData extends ChangeNotifier {
  ///Informações de memoria
  final int? numero;
  final int? faixaIndex;
  final String? tipo;
  final String? status;
  final DateTime? timestamp;
  final String? comentario;



  CalculationMemoryData({
    this.numero,
    this.faixaIndex,
    this.tipo,
    this.status,
    this.timestamp,
    this.comentario,
});

  ///Recuperando informações no banco de dados

  factory CalculationMemoryData.fromMap(Map<String, dynamic> map) {
    return CalculationMemoryData(
      numero: map['numero'],
      faixaIndex: map['faixa_index'],
      tipo: map['tipo'],
      status: map['status'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      comentario: map['comentario'],
    );
  }

}
