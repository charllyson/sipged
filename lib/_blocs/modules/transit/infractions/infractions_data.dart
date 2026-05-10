import 'package:cloud_firestore/cloud_firestore.dart';

class InfractionsData {
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

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is int) {
      final String raw = value.toString();

      return DateTime.fromMillisecondsSinceEpoch(
        raw.length <= 10 ? value * 1000 : value,
      );
    }

    if (value is String) {
      final String raw = value.trim();

      if (raw.isEmpty) return null;

      final matchBr = RegExp(
        r'^(\d{2})/(\d{2})/(\d{4})(?:\s+(\d{2}):(\d{2})(?::(\d{2}))?)?$',
      ).firstMatch(raw);

      if (matchBr != null) {
        final int day = int.parse(matchBr.group(1)!);
        final int month = int.parse(matchBr.group(2)!);
        final int year = int.parse(matchBr.group(3)!);
        final int hour = int.tryParse(matchBr.group(4) ?? '0') ?? 0;
        final int minute = int.tryParse(matchBr.group(5) ?? '0') ?? 0;
        final int second = int.tryParse(matchBr.group(6) ?? '0') ?? 0;

        return DateTime(year, month, day, hour, minute, second);
      }

      return DateTime.tryParse(raw);
    }

    return null;
  }

  static DateTime? _readDate(Map<String, dynamic> data) {
    for (final key in const <String>[
      'dateInfraction',
      'datainfraction',
      'dataInfraction',
    ]) {
      final DateTime? date = _asDate(data[key]);

      if (date != null) return date;
    }

    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString().trim());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    final String raw = value.toString().trim();

    if (raw.isEmpty) return null;

    final String normalized =
    raw.contains(',') ? raw.replaceAll('.', '').replaceAll(',', '.') : raw;

    return double.tryParse(normalized);
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  factory InfractionsData.fromDocument({
    required DocumentSnapshot snapshot,
  }) {
    if (!snapshot.exists) {
      throw Exception('Infração não encontrada');
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Dados vazios');
    }

    return InfractionsData.fromMap(
      data,
      id: snapshot.id,
    );
  }

  factory InfractionsData.fromMap(
      Map<String, dynamic> map, {
        String? id,
      }) {
    return InfractionsData(
      id: id ?? _asString(map['id']),
      contractId: _asString(map['contractId']),
      orderInfraction: _asInt(map['orderInfraction']),
      aitNumber: _asString(map['aitNumber']),
      dateInfraction: _readDate(map),
      codeInfraction: _asString(map['codeInfraction']),
      descriptionInfraction: _asString(map['descriptionInfraction']),
      organCode: _asString(map['organCode']),
      organAuthority: _asString(map['organAuthority']),
      addressInfraction: _asString(map['addressInfraction']),
      bairro: _asString(map['Bairro'] ?? map['bairro']),
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      createdAt: _asDate(map['createdAt']),
      createdBy: _asString(map['createdBy']),
      updatedAt: _asDate(map['updatedAt']),
      updatedBy: _asString(map['updatedBy']),
      deletedAt: _asDate(map['deletedAt']),
      deletedBy: _asString(map['deletedBy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? '',
      'contractId': contractId ?? '',
      'orderInfraction': orderInfraction ?? 0,
      'aitNumber': aitNumber ?? '',
      'dateInfraction':
      dateInfraction != null ? Timestamp.fromDate(dateInfraction!) : null,
      'codeInfraction': codeInfraction ?? '',
      'descriptionInfraction': descriptionInfraction ?? '',
      'organCode': organCode ?? '',
      'organAuthority': organAuthority ?? '',
      'addressInfraction': addressInfraction ?? '',
      'Bairro': bairro ?? '',
      'bairro': bairro ?? '',
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  InfractionsData copyWith({
    String? id,
    String? contractId,
    int? orderInfraction,
    String? aitNumber,
    DateTime? dateInfraction,
    String? codeInfraction,
    String? descriptionInfraction,
    String? organCode,
    String? organAuthority,
    String? addressInfraction,
    String? bairro,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return InfractionsData(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      orderInfraction: orderInfraction ?? this.orderInfraction,
      aitNumber: aitNumber ?? this.aitNumber,
      dateInfraction: dateInfraction ?? this.dateInfraction,
      codeInfraction: codeInfraction ?? this.codeInfraction,
      descriptionInfraction:
      descriptionInfraction ?? this.descriptionInfraction,
      organCode: organCode ?? this.organCode,
      organAuthority: organAuthority ?? this.organAuthority,
      addressInfraction: addressInfraction ?? this.addressInfraction,
      bairro: bairro ?? this.bairro,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}