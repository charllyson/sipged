import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class LandPaymentData {
  static const Object _unset = Object();

  final String? id;
  final String contractId;

  final String paymentStatus;
  final String paymentType;
  final DateTime? paymentRequestDate;
  final DateTime? paymentAuthorizationDate;
  final DateTime? paymentDate;

  final double paidValue;
  final String accountingCommitment;
  final String accountingLiquidation;
  final String bankOrder;
  final String notes;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const LandPaymentData({
    this.id,
    required this.contractId,
    this.paymentStatus = '',
    this.paymentType = '',
    this.paymentRequestDate,
    this.paymentAuthorizationDate,
    this.paymentDate,
    this.paidValue = 0,
    this.accountingCommitment = '',
    this.accountingLiquidation = '',
    this.bankOrder = '',
    this.notes = '',
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory LandPaymentData.empty({
    required String contractId,
    String? id,
  }) {
    return LandPaymentData(
      id: id,
      contractId: contractId,
    );
  }

  factory LandPaymentData.fromMap(
      Map<String, dynamic> map, {
        required String id,
        required String contractId,
      }) {
    return LandPaymentData(
      id: id,
      contractId: contractId,
      paymentStatus: _readString(map['paymentStatus']),
      paymentType: _readString(map['paymentType']),
      paymentRequestDate: _readDate(map['paymentRequestDate']),
      paymentAuthorizationDate: _readDate(map['paymentAuthorizationDate']),
      paymentDate: _readDate(map['paymentDate']),
      paidValue: _readDouble(map['paidValue']),
      accountingCommitment: _readString(map['accountingCommitment']),
      accountingLiquidation: _readString(map['accountingLiquidation']),
      bankOrder: _readString(map['bankOrder']),
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

  static double _readDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
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
      'paymentStatus': paymentStatus,
      'paymentType': paymentType,
      'paymentRequestDate': paymentRequestDate == null
          ? null
          : Timestamp.fromDate(paymentRequestDate!),
      'paymentAuthorizationDate': paymentAuthorizationDate == null
          ? null
          : Timestamp.fromDate(paymentAuthorizationDate!),
      'paymentDate': paymentDate == null ? null : Timestamp.fromDate(paymentDate!),
      'paidValue': paidValue,
      'accountingCommitment': accountingCommitment,
      'accountingLiquidation': accountingLiquidation,
      'bankOrder': bankOrder,
      'notes': notes,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'createdBy': createdBy,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'updatedBy': updatedBy,
    };
  }

  LandPaymentData copyWith({
    Object? id = _unset,
    String? contractId,
    String? paymentStatus,
    String? paymentType,
    Object? paymentRequestDate = _unset,
    Object? paymentAuthorizationDate = _unset,
    Object? paymentDate = _unset,
    double? paidValue,
    String? accountingCommitment,
    String? accountingLiquidation,
    String? bankOrder,
    String? notes,
    Object? createdAt = _unset,
    Object? createdBy = _unset,
    Object? updatedAt = _unset,
    Object? updatedBy = _unset,
  }) {
    return LandPaymentData(
      id: identical(id, _unset) ? this.id : id as String?,
      contractId: contractId ?? this.contractId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentType: paymentType ?? this.paymentType,
      paymentRequestDate: identical(paymentRequestDate, _unset)
          ? this.paymentRequestDate
          : paymentRequestDate as DateTime?,
      paymentAuthorizationDate: identical(paymentAuthorizationDate, _unset)
          ? this.paymentAuthorizationDate
          : paymentAuthorizationDate as DateTime?,
      paymentDate: identical(paymentDate, _unset)
          ? this.paymentDate
          : paymentDate as DateTime?,
      paidValue: paidValue ?? this.paidValue,
      accountingCommitment: accountingCommitment ?? this.accountingCommitment,
      accountingLiquidation: accountingLiquidation ?? this.accountingLiquidation,
      bankOrder: bankOrder ?? this.bankOrder,
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
        (other is LandPaymentData &&
            other.id == id &&
            other.contractId == contractId &&
            other.paymentStatus == paymentStatus &&
            other.paymentType == paymentType &&
            other.paymentRequestDate == paymentRequestDate &&
            other.paymentAuthorizationDate == paymentAuthorizationDate &&
            other.paymentDate == paymentDate &&
            other.paidValue == paidValue &&
            other.accountingCommitment == accountingCommitment &&
            other.accountingLiquidation == accountingLiquidation &&
            other.bankOrder == bankOrder &&
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
      paymentStatus,
      paymentType,
      paymentRequestDate,
      paymentAuthorizationDate,
      paymentDate,
      paidValue,
      accountingCommitment,
      accountingLiquidation,
      bankOrder,
      notes,
      createdAt,
      createdBy,
      updatedAt,
      updatedBy,
    );
  }
}