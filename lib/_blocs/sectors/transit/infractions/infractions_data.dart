import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class InfractionsData extends ChangeNotifier {
  String? id;
  String? contractId;

  int? orderInfraction;
  String? aitNumber;
  DateTime? dateInfraction;
  String? codeInfraction;
  String? descriptionInfraction;
  String? organCode;
  String? organAuthority;
  String? addressInfraction;

  String? bairro;
  double? latitude;
  double? longitude;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  InfractionsData({
    this.id,
    this.contractId,
    this.orderInfraction,
    this.aitNumber,
    this.dateInfraction,
    this.codeInfraction,
    this.descriptionInfraction,
    this.organCode,
    this.organAuthority,
    this.addressInfraction,
    this.bairro,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  // ------------ Helpers ------------
  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;

    if (v is int) {
      // epoch em segundos (10 dígitos) ou milissegundos
      final s = v.toString();
      return DateTime.fromMillisecondsSinceEpoch(s.length <= 10 ? v * 1000 : v);
    }

    if (v is String) {
      final s = v.trim();
      // dd/MM/yyyy [HH:mm[:ss]]
      final m = RegExp(
        r'^(\d{2})/(\d{2})/(\d{4})(?:\s+(\d{2}):(\d{2})(?::(\d{2}))?)?$',
      ).firstMatch(s);
      if (m != null) {
        final d = int.parse(m.group(1)!);
        final mo = int.parse(m.group(2)!);
        final y = int.parse(m.group(3)!);
        final hh = int.tryParse(m.group(4) ?? '0') ?? 0;
        final mm = int.tryParse(m.group(5) ?? '0') ?? 0;
        final ss = int.tryParse(m.group(6) ?? '0') ?? 0;
        return DateTime(y, mo, d, hh, mm, ss);
      }
      // ISO
      final iso = DateTime.tryParse(s);
      if (iso != null) return iso;
    }
    return null;
  }

  static DateTime? _readDate(Map<String, dynamic> data) {
    for (final key in const ['dateInfraction', 'datainfraction', 'dataInfraction']) {
      final dt = _asDate(data[key]);
      if (dt != null) return dt;
    }
    return null;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s);
  }

  // ------------ Factories ------------
  factory InfractionsData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) throw Exception('Infração não encontrada');
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) throw Exception('Dados vazios');

    return InfractionsData(
      id: snapshot.id,
      contractId: data['contractId'],
      orderInfraction: _asInt(data['orderInfraction']),
      aitNumber: data['aitNumber'],
      dateInfraction: _readDate(data),
      codeInfraction: data['codeInfraction'],
      descriptionInfraction: data['descriptionInfraction'],
      organCode: data['organCode'],
      organAuthority: data['organAuthority'],
      addressInfraction: data['addressInfraction'],
      bairro: data['Bairro'],
      latitude: _asDouble(data['latitude']),
      longitude: _asDouble(data['longitude']),
      createdAt: _asDate(data['createdAt']),
      createdBy: data['createdBy'],
      updatedAt: _asDate(data['updatedAt']),
      updatedBy: data['updatedBy'],
      deletedAt: _asDate(data['deletedAt']),
      deletedBy: data['deletedBy'],
    );
  }

  factory InfractionsData.fromMap(Map<String, dynamic> map, {String? id}) {
    return InfractionsData(
      id: id ?? map['id'],
      contractId: map['contractId'],
      orderInfraction: _asInt(map['orderInfraction']),
      aitNumber: map['aitNumber'],
      dateInfraction: _readDate(map),
      codeInfraction: map['codeInfraction'],
      descriptionInfraction: map['descriptionInfraction'],
      organCode: map['organCode'],
      organAuthority: map['organAuthority'],
      addressInfraction: map['addressInfraction'],
      bairro: map['Bairro'],
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      createdAt: _asDate(map['createdAt']),
      createdBy: map['createdBy'],
      updatedAt: _asDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
      deletedAt: _asDate(map['deletedAt']),
      deletedBy: map['deletedBy'],
    );
  }

  // ------------ Serialization ------------
  Map<String, dynamic> toJson() {
    return {
      'id': id ?? '',
      'contractId': contractId ?? '',
      'orderInfraction': orderInfraction ?? 0,
      'aitNumber': aitNumber ?? '',
      // grava sempre como Timestamp pra manter consistência
      'dateInfraction': dateInfraction != null ? Timestamp.fromDate(dateInfraction!) : null,
      'codeInfraction': codeInfraction ?? '',
      'descriptionInfraction': descriptionInfraction ?? '',
      'organCode': organCode ?? '',
      'organAuthority': organAuthority ?? '',
      'addressInfraction': addressInfraction ?? '',
      'Bairro': bairro ?? '',
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
