import 'package:sipged/_blocs/system/adm/firebase_admin_data.dart';

class FirebaseAdminState {
  const FirebaseAdminState({
    this.status = FirebaseAdminStatus.initial,
    this.message,
    this.result,
    this.progressCurrent = 0,
    this.progressTotal = 0,
    this.progressLabel,
    this.progressDetail,
  });

  final FirebaseAdminStatus status;
  final String? message;
  final FirebaseOperationResultData? result;

  final int progressCurrent;
  final int progressTotal;
  final String? progressLabel;
  final String? progressDetail;

  bool get isLoading => status == FirebaseAdminStatus.loading;

  bool get hasProgress => progressTotal > 0;

  double get progressValue {
    if (progressTotal <= 0) return 0;

    final value = progressCurrent / progressTotal;

    if (value < 0) return 0;
    if (value > 1) return 1;

    return value;
  }

  FirebaseAdminState copyWith({
    FirebaseAdminStatus? status,
    String? message,
    FirebaseOperationResultData? result,
    int? progressCurrent,
    int? progressTotal,
    String? progressLabel,
    String? progressDetail,
    bool clearMessage = false,
    bool clearResult = false,
    bool clearProgress = false,
  }) {
    return FirebaseAdminState(
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
      result: clearResult ? null : result ?? this.result,
      progressCurrent:
      clearProgress ? 0 : progressCurrent ?? this.progressCurrent,
      progressTotal: clearProgress ? 0 : progressTotal ?? this.progressTotal,
      progressLabel: clearProgress ? null : progressLabel ?? this.progressLabel,
      progressDetail:
      clearProgress ? null : progressDetail ?? this.progressDetail,
    );
  }

  factory FirebaseAdminState.initial() {
    return const FirebaseAdminState();
  }
}