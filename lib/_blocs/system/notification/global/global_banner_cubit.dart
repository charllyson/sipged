// lib/_blocs/system/notification/global/global_banner_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'global_banner_data.dart';
import 'global_banner_type.dart';

class GlobalBannerCubit extends Cubit<List<GlobalBannerData>> {
  GlobalBannerCubit() : super(const []);

  void show(GlobalBannerData banner) {
    final updated = <GlobalBannerData>[
      ...state.where((item) => item.id != banner.id),
      banner,
    ];

    emit(updated);
  }

  void hide(String id) {
    emit(
      state.where((item) => item.id != id).toList(),
    );
  }

  void clear() {
    emit(const []);
  }

  GlobalBannerData? get currentBanner {
    if (state.isEmpty) return null;

    final ordered = [...state];

    ordered.sort((a, b) {
      return _priority(b.type).compareTo(_priority(a.type));
    });

    return ordered.first;
  }

  int _priority(GlobalBannerType type) {
    switch (type) {
      case GlobalBannerType.critical:
        return 4;
      case GlobalBannerType.offline:
        return 3;
      case GlobalBannerType.warning:
        return 2;
      case GlobalBannerType.info:
        return 1;
    }
  }
}