import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_state.dart';
import 'package:sipged/_widgets/overlays/progress_card.dart';

class AttributeOverlay extends StatelessWidget {
  const AttributeOverlay({
    super.key,
    required this.status,
    required this.progress,
  });

  final FeatureImportStatus status;
  final double progress;

  bool get _isDeleting => status == FeatureImportStatus.deleting;

  bool get _isIndeterminate => progress <= 0.0;

  String get _message {
    if (_isDeleting) {
      return 'Excluindo no Firebase...';
    }
    return 'Salvando no Firebase...';
  }

  String get _details {
    if (_isDeleting) {
      return 'Os registros selecionados estão sendo removidos.';
    }
    return 'As feições importadas estão sendo enviadas para o Firebase.';
  }

  IconData get _icon {
    if (_isDeleting) {
      return Icons.delete_outline;
    }
    return Icons.cloud_upload_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: ProgressCard(
            icon: _icon,
            message: _message,
            details: _details,
            progress: _isIndeterminate ? null : progress.clamp(0.0, 1.0),
            width: 340,
          ),
        ),
      ),
    );
  }
}