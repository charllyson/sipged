import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/global/global_banner_cubit.dart';
import 'package:sipged/_blocs/system/notification/global/global_banner_data.dart';
import 'package:sipged/_blocs/system/notification/global/global_banner_type.dart';

class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit({
    required GlobalBannerCubit globalBannerCubit,
  })  : _globalBannerCubit = globalBannerCubit,
        super(true) {
    _start();
  }

  static const String offlineBannerId = 'system_offline_banner';

  final Connectivity _connectivity = Connectivity();
  final GlobalBannerCubit _globalBannerCubit;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _probeTimer;

  bool? _lastOnlineState;

  final Set<String> _forcedOfflineReasons = <String>{};

  Future<void> _start() async {
    await checkNow();

    _subscription = _connectivity.onConnectivityChanged.listen((_) async {
      await checkNow();
    });

    _probeTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) async {
        await checkNow();
      },
    );
  }

  Future<void> checkNow() async {
    try {
      final results = await _connectivity.checkConnectivity();

      final hasNetworkAdapter = results.isNotEmpty &&
          results.any((item) => item != ConnectivityResult.none);

      if (!hasNetworkAdapter) {
        _applyConnectivityState(false);
        return;
      }

      if (_forcedOfflineReasons.isNotEmpty) {
        _applyConnectivityState(false);
        return;
      }

      _applyConnectivityState(true);
    } catch (e, s) {
      debugPrint('[ConnectivityCubit] Erro ao verificar conexão: $e');
      debugPrintStack(stackTrace: s);

      _applyConnectivityState(false);
    }
  }

  void markOfflineFromFailure({
    String reason = 'unknown',
  }) {
    final cleanReason = reason.trim().isEmpty ? 'unknown' : reason.trim();

    _forcedOfflineReasons.add(cleanReason);
    _applyConnectivityState(false);
  }

  Future<void> markOnlineAfterSuccess({
    String reason = 'unknown',
  }) async {
    final cleanReason = reason.trim().isEmpty ? 'unknown' : reason.trim();

    _forcedOfflineReasons.remove(cleanReason);

    await checkNow();
  }

  void _applyConnectivityState(bool isOnline) {
    final changed = _lastOnlineState != isOnline;

    _lastOnlineState = isOnline;

    if (changed && !isClosed) {
      emit(isOnline);
    }

    if (isOnline) {
      _globalBannerCubit.hide(offlineBannerId);
      return;
    }

    _globalBannerCubit.show(
      const GlobalBannerData(
        id: offlineBannerId,
        type: GlobalBannerType.offline,
        message: 'Seu dispositivo está offline.',
        icon: Icons.wifi_off_rounded,
        dismissible: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _probeTimer?.cancel();
    return super.close();
  }
}