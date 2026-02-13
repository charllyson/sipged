/*

// CIVIL
import 'package:sipged/_blocs/modules/operation/operation/civil/civil_schedule_bloc.dart';
import 'package:sipged/_blocs/modules/operation/operation/civil/civil_schedule_event.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_bloc.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_event.dart';

/// Adaptador para reutilizar o ScheduleModalSquare no fluxo CIVIL.
/// Não registra handlers; intercepta `add` e faz forward para o CivilScheduleBloc.
class ScheduleBlocAdapterForCivil extends ScheduleRoadBloc {
  final CivilScheduleBloc civilBloc;
  final String polygonId;
  final String currentUserId;

  ScheduleBlocAdapterForCivil({
    required this.civilBloc,
    required this.polygonId,
    required this.currentUserId,
  }) : super();

  @override
  void add(ScheduleRoadEvent event) {
    if (event is ScheduleSquareApplyRequested) {
      civilBloc.add(CivilPolygonApplyRequested(
        polygonId: polygonId,
        status: event.status,
        comentario: event.comentario,
        takenAtMs: event.takenAt?.millisecondsSinceEpoch,
        finalPhotoUrls: event.finalPhotoUrls,
        newFilesBytes: event.newFilesBytes,
        newFileNames: event.newFileNames,
        newPhotoMetas: event.newPhotoMetas,
        currentUserId: currentUserId,
      ));
      // ❌ refresh extra removido (Apply já recarrega)
      // civilBloc.add(const CivilRefreshRequested());
      return; // não repassa para o ScheduleBloc base
    }
    super.add(event);
  }
}
*/
