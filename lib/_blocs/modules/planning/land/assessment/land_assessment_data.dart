import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class LandAssessmentData {
  static const Object _unset = Object();

  final String? id;
  final String contractId;

  final String appraisalNumber;
  final String appraiserName;
  final String appraisalMethod;
  final DateTime? inspectionDate;
  final DateTime? appraisalDate;

  final double appraisalValue;
  final String indemnityType;
  final double indemnityValue;
  final double ownerCounterValue;
  final double govProposalValue;
  final String notes;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const LandAssessmentData({
    this.id,
    required this.contractId,
    this.appraisalNumber = '',
    this.appraiserName = '',
    this.appraisalMethod = '',
    this.inspectionDate,
    this.appraisalDate,
    this.appraisalValue = 0,
    this.indemnityType = '',
    this.indemnityValue = 0,
    this.ownerCounterValue = 0,
    this.govProposalValue = 0,
    this.notes = '',
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory LandAssessmentData.empty({
    required String contractId,
    String? id,
  }) {
    return LandAssessmentData(
      id: id,
      contractId: contractId,
    );
  }

  factory LandAssessmentData.fromMap(
      Map<String, dynamic> map, {
        required String id,
        required String contractId,
      }) {
    return LandAssessmentData(
      id: id,
      contractId: contractId,
      appraisalNumber: _readString(map['appraisalNumber']),
      appraiserName: _readString(map['appraiserName']),
      appraisalMethod: _readString(map['appraisalMethod']),
      inspectionDate: _readDate(map['inspectionDate']),
      appraisalDate: _readDate(map['appraisalDate']),
      appraisalValue: _readDouble(map['appraisalValue']),
      indemnityType: _readString(map['indemnityType']),
      indemnityValue: _readDouble(map['indemnityValue']),
      ownerCounterValue: _readDouble(map['ownerCounterValue']),
      govProposalValue: _readDouble(map['govProposalValue']),
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
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
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
      'appraisalNumber': appraisalNumber,
      'appraiserName': appraiserName,
      'appraisalMethod': appraisalMethod,
      'inspectionDate':
      inspectionDate == null ? null : Timestamp.fromDate(inspectionDate!),
      'appraisalDate':
      appraisalDate == null ? null : Timestamp.fromDate(appraisalDate!),
      'appraisalValue': appraisalValue,
      'indemnityType': indemnityType,
      'indemnityValue': indemnityValue,
      'ownerCounterValue': ownerCounterValue,
      'govProposalValue': govProposalValue,
      'notes': notes,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'createdBy': createdBy,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'updatedBy': updatedBy,
    };
  }

  LandAssessmentData copyWith({
    Object? id = _unset,
    String? contractId,
    String? appraisalNumber,
    String? appraiserName,
    String? appraisalMethod,
    Object? inspectionDate = _unset,
    Object? appraisalDate = _unset,
    double? appraisalValue,
    String? indemnityType,
    double? indemnityValue,
    double? ownerCounterValue,
    double? govProposalValue,
    String? notes,
    Object? createdAt = _unset,
    Object? createdBy = _unset,
    Object? updatedAt = _unset,
    Object? updatedBy = _unset,
  }) {
    return LandAssessmentData(
      id: identical(id, _unset) ? this.id : id as String?,
      contractId: contractId ?? this.contractId,
      appraisalNumber: appraisalNumber ?? this.appraisalNumber,
      appraiserName: appraiserName ?? this.appraiserName,
      appraisalMethod: appraisalMethod ?? this.appraisalMethod,
      inspectionDate: identical(inspectionDate, _unset)
          ? this.inspectionDate
          : inspectionDate as DateTime?,
      appraisalDate: identical(appraisalDate, _unset)
          ? this.appraisalDate
          : appraisalDate as DateTime?,
      appraisalValue: appraisalValue ?? this.appraisalValue,
      indemnityType: indemnityType ?? this.indemnityType,
      indemnityValue: indemnityValue ?? this.indemnityValue,
      ownerCounterValue: ownerCounterValue ?? this.ownerCounterValue,
      govProposalValue: govProposalValue ?? this.govProposalValue,
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
        (other is LandAssessmentData &&
            other.id == id &&
            other.contractId == contractId &&
            other.appraisalNumber == appraisalNumber &&
            other.appraiserName == appraiserName &&
            other.appraisalMethod == appraisalMethod &&
            other.inspectionDate == inspectionDate &&
            other.appraisalDate == appraisalDate &&
            other.appraisalValue == appraisalValue &&
            other.indemnityType == indemnityType &&
            other.indemnityValue == indemnityValue &&
            other.ownerCounterValue == ownerCounterValue &&
            other.govProposalValue == govProposalValue &&
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
      appraisalNumber,
      appraiserName,
      appraisalMethod,
      inspectionDate,
      appraisalDate,
      appraisalValue,
      indemnityType,
      indemnityValue,
      ownerCounterValue,
      govProposalValue,
      notes,
      createdAt,
      createdBy,
      updatedAt,
      updatedBy,
    );
  }
}