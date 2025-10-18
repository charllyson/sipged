import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_state.dart';

// Partes da UI do modal
import 'package:siged/_widgets/modals/actions_row.dart';
import 'package:siged/_widgets/modals/comment_field.dart';
import 'package:siged/_widgets/modals/date_row.dart';
import 'package:siged/_widgets/modals/header.dart';
import 'package:siged/_widgets/modals/photo_section.dart';
import 'package:siged/_widgets/modals/status_row.dart';

// Controller / tipos
import 'package:siged/_blocs/sectors/operation/road/schedule_modal_controller.dart';
import 'package:siged/_widgets/modals/type.dart';

// Status (para default)
import 'package:siged/_widgets/schedule/linear/schedule_status.dart';

class ScheduleModalSquare extends StatelessWidget {
  final String currentUserId;
  final String tipoLabel;

  /// Tipo do cronograma (rodoviário/civil)
  final ScheduleType type;

  /// Alvos de aplicação (um ou vários). Para unitário, passe 1 item.
  final List<ScheduleApplyTarget> targets;

  // ===== Estados iniciais comuns à UI =====
  final String? initialName;
  final ScheduleStatus initialStatus;
  final DateTime? initialTakenAt;
  final String? initialComment;
  final double? initialProgress;

  /// Callback disparado pelo botão "Apagar área"
  final VoidCallback? onDelete;

  /// Callback para fechar o bottom sheet (fornecido pelo showModalBottomSheet)
  final VoidCallback? onClose;

  const ScheduleModalSquare({
    super.key,
    required this.currentUserId,
    required this.tipoLabel,
    required this.type,
    required this.targets,
    this.initialName,
    this.initialStatus = ScheduleStatus.aIniciar,
    this.initialTakenAt,
    this.initialComment,
    this.initialProgress,
    this.onDelete,
    this.onClose,
  });

  int get _applyCount => targets.length;

  String _confirmLabel() {
    if (_applyCount <= 1) return 'Salvar';
    final unit = _applyCount == 1 ? type.singularUnit : type.pluralUnit;
    return 'Aplicar em $_applyCount $unit';
  }

  IconData _confirmIcon() => _applyCount <= 1 ? Icons.done : Icons.done_all;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ScheduleRoadBloc>();

    return ChangeNotifierProvider(
      create: (_) => ScheduleModalController(
        bloc: bloc,
        targets: targets,
        currentUserId: currentUserId,
        tipoLabel: tipoLabel,
        initialName: initialName,
        initialStatus: initialStatus,
        initialTakenAt: initialTakenAt,
        initialComment: initialComment,
        initialProgress: initialProgress,
      ),
      builder: (ctx, _) {
        final controller = ctx.watch<ScheduleModalController>();

        return BlocListener<ScheduleRoadBloc, ScheduleRoadState>(
          listenWhen: (prev, curr) =>
          prev.loadingExecucoes != curr.loadingExecucoes || prev.error != curr.error,
          listener: (bctx, state) {
            controller.onBlocStateChanged(
              bctx,
              loadingExecucoes: state.loadingExecucoes,
              error: state.error,
            );
          },
          child: WillPopScope(
            onWillPop: () async => true, // ajuste se quiser bloquear durante upload
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header (varia label conforme tipo/seleção)
                    ScheduleHeaderEditable(type: type),

                    const SizedBox(height: 8),

                    // Status + slider
                    const ScheduleStatusRow(showSlider: true),

                    const SizedBox(height: 12),

                    // Data
                    const ScheduleDateRow(labelPrefix: 'Data do serviço:'),

                    const SizedBox(height: 12),

                    // Fotos
                    const SchedulePhotoSection(),

                    const SizedBox(height: 12),

                    // Comentário
                    const ScheduleCommentField(),

                    const SizedBox(height: 12),

                    // Ações (label/ícone variam conforme quantidade de alvos)
                    ScheduleActionsRow(
                      confirmLabel: _confirmLabel(),
                      confirmIcon: _confirmIcon(),
                      onDelete: onDelete,
                      onClose: onClose, // 👈 repassa para a row
                      type: type,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
