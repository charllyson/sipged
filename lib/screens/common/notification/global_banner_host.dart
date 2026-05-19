// lib/screens/common/notification/global_banner_host.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/global/global_banner_cubit.dart';
import 'package:sipged/_blocs/system/notification/global/global_banner_data.dart';
import 'package:sipged/_blocs/system/notification/global/global_banner_type.dart';

class GlobalBannerHost extends StatelessWidget {
  const GlobalBannerHost({
    super.key,
    required this.child,
  });

  final Widget child;

  GlobalBannerData? _resolveCurrentBanner(List<GlobalBannerData> banners) {
    if (banners.isEmpty) return null;

    final ordered = [...banners];

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlobalBannerCubit, List<GlobalBannerData>>(
      builder: (context, banners) {
        final banner = _resolveCurrentBanner(banners);
        final hasBanner = banner != null;

        return Column(
          children: [
            if (hasBanner)
              _GlobalBannerView(
                banner: banner,
              ),

            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: hasBanner,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlobalBannerView extends StatelessWidget {
  const _GlobalBannerView({
    required this.banner,
  });

  final GlobalBannerData banner;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsByType(banner.type);

    return Material(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                banner.icon,
                color: colors.icon,
                size: 10,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  banner.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (banner.dismissible) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    context.read<GlobalBannerCubit>().hide(banner.id);
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: colors.text,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _BannerColors _colorsByType(GlobalBannerType type) {
    switch (type) {
      case GlobalBannerType.offline:
        return const _BannerColors(
          background: Colors.black,
          text: Colors.white,
          icon: Colors.deepOrangeAccent,
        );
      case GlobalBannerType.critical:
        return const _BannerColors(
          background: Color(0xFF7F1D1D),
          text: Colors.white,
          icon: Colors.white,
        );
      case GlobalBannerType.warning:
        return const _BannerColors(
          background: Color(0xFFFFF3CD),
          text: Color(0xFF664D03),
          icon: Color(0xFFB45309),
        );
      case GlobalBannerType.info:
        return const _BannerColors(
          background: Color(0xFFE0F2FE),
          text: Color(0xFF075985),
          icon: Color(0xFF0284C7),
        );
    }
  }
}

class _BannerColors {
  const _BannerColors({
    required this.background,
    required this.text,
    required this.icon,
  });

  final Color background;
  final Color text;
  final Color icon;
}