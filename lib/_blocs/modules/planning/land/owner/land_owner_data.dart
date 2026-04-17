import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class LandOwnerData {
  static const Object _unset = Object();

  final String? id;
  final String contractId;

  final String ownerName;
  final String cpfCnpj;
  final String phone;
  final String email;
  final String documentNumber;
  final String maritalStatus;
  final String spouseName;
  final String notes;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const LandOwnerData({
    this.id,
    required this.contractId,
    this.ownerName = '',
    this.cpfCnpj = '',
    this.phone = '',
    this.email = '',
    this.documentNumber = '',
    this.maritalStatus = '',
    this.spouseName = '',
    this.notes = '',
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory LandOwnerData.empty({
    required String contractId,
    String? id,
  }) {
    return LandOwnerData(
      id: id,
      contractId: contractId,
    );
  }

  factory LandOwnerData.fromMap(
      Map<String, dynamic> map, {
        required String id,
        required String contractId,
      }) {
    return LandOwnerData(
      id: id,
      contractId: contractId,
      ownerName: _readString(map['ownerName']),
      cpfCnpj: _readString(map['cpfCnpj']),
      phone: _readString(map['phone']),
      email: _readString(map['email']),
      documentNumber: _readString(map['documentNumber']),
      maritalStatus: _readString(map['maritalStatus']),
      spouseName: _readString(map['spouseName']),
      notes: _readString(map['notes']),
      createdAt: _readDate(map['createdAt']),
      createdBy: _readNullableString(map['createdBy']),
      updatedAt: _readDate(map['updatedAt']),
      updatedBy: _readNullableString(map['updatedBy']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId,
      'ownerName': ownerName,
      'cpfCnpj': cpfCnpj,
      'phone': phone,
      'email': email,
      'documentNumber': documentNumber,
      'maritalStatus': maritalStatus,
      'spouseName': spouseName,
      'notes': notes,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'createdBy': createdBy,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'updatedBy': updatedBy,
    };
  }

  LandOwnerData copyWith({
    Object? id = _unset,
    String? contractId,
    String? ownerName,
    String? cpfCnpj,
    String? phone,
    String? email,
    String? documentNumber,
    String? maritalStatus,
    String? spouseName,
    String? notes,
    Object? createdAt = _unset,
    Object? createdBy = _unset,
    Object? updatedAt = _unset,
    Object? updatedBy = _unset,
  }) {
    return LandOwnerData(
      id: identical(id, _unset) ? this.id : id as String?,
      contractId: contractId ?? this.contractId,
      ownerName: ownerName ?? this.ownerName,
      cpfCnpj: cpfCnpj ?? this.cpfCnpj,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      documentNumber: documentNumber ?? this.documentNumber,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      spouseName: spouseName ?? this.spouseName,
      notes: notes ?? this.notes,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime?,
      createdBy: identical(createdBy, _unset)
          ? this.createdBy
          : createdBy as String?,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
      updatedBy: identical(updatedBy, _unset)
          ? this.updatedBy
          : updatedBy as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LandOwnerData &&
            other.id == id &&
            other.contractId == contractId &&
            other.ownerName == ownerName &&
            other.cpfCnpj == cpfCnpj &&
            other.phone == phone &&
            other.email == email &&
            other.documentNumber == documentNumber &&
            other.maritalStatus == maritalStatus &&
            other.spouseName == spouseName &&
            other.notes == notes &&
            other.createdAt == createdAt &&
            other.createdBy == createdBy &&
            other.updatedAt == updatedAt &&
            other.updatedBy == updatedBy);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      contractId,
      ownerName,
      cpfCnpj,
      phone,
      email,
      documentNumber,
      maritalStatus,
      spouseName,
      notes,
      createdAt,
      createdBy,
      updatedAt,
      updatedBy,
    );
  }
}