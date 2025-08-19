import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ScheduleData extends ChangeNotifier {
  ///Informações de memoria
  final int? numero;
  final int? faixaIndex;
  final String? tipo;
  final String? status;
  final DateTime? timestamp;
  final String? comentario;
  final String key;
  final String label;
  final IconData? icon;
  final Color color;


  ScheduleData({
    this.numero,
    this.faixaIndex,
    this.tipo,
    this.status,
    this.timestamp,
    this.comentario,
    required this.key,
    required this.label,
    this.icon,
    required this.color,
});

  ///Recuperando informações no banco de dados

  factory ScheduleData.fromMap(Map<String, dynamic> map) {
    return ScheduleData(
      numero: map['numero'],
      faixaIndex: map['faixa_index'],
      tipo: map['tipo'],
      status: map['status'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      comentario: map['comentario'],
      key: map['key'],
      label: map['label'],
      icon: map['icon'],
      color: map['color'],
    );
  }

}
