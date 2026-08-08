// lib/_blocs/system/connectivity/connectivity_cubit.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/connectivity/connectivity_platform.dart';
import 'package:sipged/_blocs/system/notification/global/global_banner_cubit.dart';
import 'package:sipged/_blocs/system/notification/global/global_banner_data.dart';
import 'package:sipged/_blocs/system/notification/global/global_banner_type.dart';

class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit({
    required this._globalBannerCubit,
  })  : super(true) {
    _start();
  }

  static const String offlineBannerId = 'system_offline_banner';

  final Connectivity _connectivity = Connectivity();
  final GlobalBannerCubit _globalBannerCubit;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<bool>? _browserSubscription;

  Timer? _probeTimer;

  bool? _lastOnlineState;

  Future<void> _start() async {
    _globalBannerCubit.hide(offlineBannerId);

    await checkNow();

    if (kIsWeb) {
      _browserSubscription = browserOnlineChanges().listen((isOnline) {
        _applyConnectivityState(isOnline);
      });
    } else {
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen((_) async {
            await checkNow();
          });
    }

    _probeTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) async {
        await checkNow();
      },
    );
  }

  Future<void> checkNow() async {
    try {
      if (kIsWeb) {
        final browserStatus = await browserOnlineStatus();

        if (browserStatus != null) {
          _applyConnectivityState(browserStatus);
          return;
        }
      }

      final results = await _connectivity.checkConnectivity();

      final hasNetworkAdapter = results.isNotEmpty &&
          results.any((item) => item != ConnectivityResult.none);

      _applyConnectivityState(hasNetworkAdapter);
    } catch (e, s) {
      debugPrint('[ConnectivityCubit] Erro ao verificar conexão: $e');
      debugPrintStack(stackTrace: s);

      if (kIsWeb) {
        _applyConnectivityState(true);
        return;
      }

      _applyConnectivityState(false);
    }
  }

  /// Mantido para compatibilidade com chamadas antigas.
  ///
  /// Falha de Firebase, Firestore, timeout ou startup não deve forçar
  /// o app inteiro a ficar offline.
  void markOfflineFromFailure({
    String reason = 'unknown',
  }) {
    debugPrint(
      '[ConnectivityCubit] Falha externa registrada sem forçar offline. reason=$reason',
    );

    unawaited(checkNow());
  }

  /// Mantido para compatibilidade com chamadas antigas.
  Future<void> markOnlineAfterSuccess({
    String reason = 'unknown',
  }) async {
    debugPrint(
      '[ConnectivityCubit] Sucesso externo registrado. reason=$reason',
    );

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
    _connectivitySubscription?.cancel();
    _browserSubscription?.cancel();
    _probeTimer?.cancel();

    return super.close();
  }
}