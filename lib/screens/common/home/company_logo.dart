import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

class CompanyLogo extends StatelessWidget {
  const CompanyLogo({super.key,
    required this.logoUrl,
  });

  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: 88,
          height: 88,
          child: CachedNetworkImage(
            imageUrl: logoUrl,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) {
              return _fallbackLogo(borderRadius);
            },
            placeholder: (context, url) {
              return const SizedBox(
                width: 88,
                height: 88,
                child: LoadingTreeDots(
                  message: Text('Carregando logo'),
                ),
              );
            },
          ),
        ),
      );
    }

    return _fallbackLogo(borderRadius);
  }

  Widget _fallbackLogo(BorderRadius borderRadius) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        'assets/logos/sipged/sipged.png',
        height: 88,
        width: 88,
        fit: BoxFit.contain,
      ),
    );
  }
}