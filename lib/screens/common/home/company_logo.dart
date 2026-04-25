import 'package:flutter/material.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';

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
          child: Image.network(
            logoUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) {
              return _fallbackLogo(borderRadius);
            },
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;

              return const SizedBox(
                width: 88,
                height: 88,
                child: LoadingTreeDotsGrey(
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