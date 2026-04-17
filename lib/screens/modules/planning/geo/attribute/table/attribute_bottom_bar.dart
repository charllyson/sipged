import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_state.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_page.dart';

class AttributeBottomBar extends StatelessWidget {
  final AttributeMode mode;
  final String collectionPath;
  final FeatureState state;
  final int filteredTotal;
  final int visibleRows;
  final int totalRows;

  const AttributeBottomBar({
    super.key,
    required this.mode,
    required this.collectionPath,
    required this.state,
    required this.filteredTotal,
    required this.visibleRows,
    required this.totalRows,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeatureCubit>();

    final isBusy = state.importStatus == FeatureImportStatus.saving ||
        state.importStatus == FeatureImportStatus.deleting ||
        state.importStatus == FeatureImportStatus.loadingFirestore ||
        state.importStatus == FeatureImportStatus.pickingFile;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          if (mode == AttributeMode.firestore)
            FilledButton.icon(
              onPressed: isBusy ? null : cubit.saveImportedFeatures,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                isBusy ? 'Processando...' : 'Salvar alterações',
              ),
              style: FilledButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: isBusy ? null : cubit.saveImportedFeatures,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Importar para o Firebase'),
              style: FilledButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}