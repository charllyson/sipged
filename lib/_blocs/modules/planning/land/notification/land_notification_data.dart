import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class LandNotificationData {
  static const Object _unset = Object();

  final String? id;
  final String contractId;

  final String processNumber;
  final String dupNumber;
  final DateTime? dupDate;
  final String doPublication;
  final DateTime? doPublicationDate;
  final String notificationAR;
  final DateTime? notificationDate;
  final DateTime? agreementDate;
  final DateTime? possessionDate;
  final DateTime? evictionDate;
  final DateTime? registryUpdateDate;
  final String negotiationStatus;
  final String notes;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const LandNotificationData({
    this.id,
    required this.contractId,
    this.processNumber = '',
    this.dupNumber = '',
    this.dupDate,
    this.doPublication = '',
    this.doPublicationDate,
    this.notificationAR = '',
    this.notificationDate,
    this.agreementDate,
    this.possessionDate,
    this.evictionDate,
    this.registryUpdateDate,
    this.negotiationStatus = '',
    this.notes = '',
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory LandNotificationData.empty({
    required String contractId,
    String? id,
  }) {
    return LandNotificationData(
      id: id,
      contractId: contractId,
    );
  }

  factory LandNotificationData.fromMap(
      Map<String, dynamic> map, {
        required String id,
        required String contractId,
      }) {
    return LandNotificationData(
      id: id,
      contractId: contractId,
      processNumber: _readString(map['processNumber']),
      dupNumber: _readString(map['dupNumber']),
      dupDate: _readDate(map['dupDate']),
      doPublication: _readString(map['doPublication']),
      doPublicationDate: _readDate(map['doPublicationDate']),
      notificationAR: _readString(map['notificationAR']),
      notificationDate: _readDate(map['notificationDate']),
      agreementDate: _readDate(map['agreementDate']),
      possessionDate: _readDate(map['possessionDate']),
      evictionDate: _readDate(map['evictionDate']),
      registryUpdateDate: _readDate(map['registryUpdateDate']),
      negotiationStatus: _readString(map['negotiationStatus']),
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
      'processNumber': processNumber,
      'dupNumber': dupNumber,
      'dupDate': dupDate == null ? null : Timestamp.fromDate(dupDate!),
      'doPublication': doPublication,
      'doPublicationDate': doPublicationDate == null
          ? null
          : Timestamp.fromDate(doPublicationDate!),
      'notificationAR': notificationAR,
      'notificationDate': notificationDate == null
          ? null
          : Timestamp.fromDate(notificationDate!),
      'agreementDate':
      agreementDate == null ? null : Timestamp.fromDate(agreementDate!),
      'possessionDate':
      possessionDate == null ? null : Timestamp.fromDate(possessionDate!),
      'evictionDate':
      evictionDate == null ? null : Timestamp.fromDate(evictionDate!),
      'registryUpdateDate': registryUpdateDate == null
          ? null
          : Timestamp.fromDate(registryUpdateDate!),
      'negotiationStatus': negotiationStatus,
      'notes': notes,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'createdBy': createdBy,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'updatedBy': updatedBy,
    };
  }

  LandNotificationData copyWith({
    Object? id = _unset,
    String? contractId,
    String? processNumber,
    String? dupNumber,
    Object? dupDate = _unset,
    String? doPublication,
    Object? doPublicationDate = _unset,
    String? notificationAR,
    Object? notificationDate = _unset,
    Object? agreementDate = _unset,
    Object? possessionDate = _unset,
    Object? evictionDate = _unset,
    Object? registryUpdateDate = _unset,
    String? negotiationStatus,
    String? notes,
    Object? createdAt = _unset,
    Object? createdBy = _unset,
    Object? updatedAt = _unset,
    Object? updatedBy = _unset,
  }) {
    return LandNotificationData(
      id: identical(id, _unset) ? this.id : id as String?,
      contractId: contractId ?? this.contractId,
      processNumber: processNumber ?? this.processNumber,
      dupNumber: dupNumber ?? this.dupNumber,
      dupDate: identical(dupDate, _unset) ? this.dupDate : dupDate as DateTime?,
      doPublication: doPublication ?? this.doPublication,
      doPublicationDate: identical(doPublicationDate, _unset)
          ? this.doPublicationDate
          : doPublicationDate as DateTime?,
      notificationAR: notificationAR ?? this.notificationAR,
      notificationDate: identical(notificationDate, _unset)
          ? this.notificationDate
          : notificationDate as DateTime?,
      agreementDate: identical(agreementDate, _unset)
          ? this.agreementDate
          : agreementDate as DateTime?,
      possessionDate: identical(possessionDate, _unset)
          ? this.possessionDate
          : possessionDate as DateTime?,
      evictionDate: identical(evictionDate, _unset)
          ? this.evictionDate
          : evictionDate as DateTime?,
      registryUpdateDate: identical(registryUpdateDate, _unset)
          ? this.registryUpdateDate
          : registryUpdateDate as DateTime?,
      negotiationStatus: negotiationStatus ?? this.negotiationStatus,
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
        (other is LandNotificationData &&
            other.id == id &&
            other.contractId == contractId &&
            other.processNumber == processNumber &&
            other.dupNumber == dupNumber &&
            other.dupDate == dupDate &&
            other.doPublication == doPublication &&
            other.doPublicationDate == doPublicationDate &&
            other.notificationAR == notificationAR &&
            other.notificationDate == notificationDate &&
            other.agreementDate == agreementDate &&
            other.possessionDate == possessionDate &&
            other.evictionDate == evictionDate &&
            other.registryUpdateDate == registryUpdateDate &&
            other.negotiationStatus == negotiationStatus &&
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
      processNumber,
      dupNumber,
      dupDate,
      doPublication,
      doPublicationDate,
      notificationAR,
      notificationDate,
      agreementDate,
      possessionDate,
      evictionDate,
      registryUpdateDate,
      negotiationStatus,
      notes,
      createdAt,
      createdBy,
      updatedAt,
      updatedBy,
    );
  }
}