// lib/screens/panels/specific-dashboard/specific_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ===== SIGED: Models / Stores / Blocs / Cubits =====
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';

// Cubit específico do dashboard detalhado
import 'package:siged/_blocs/panels/specific_dashboard/specific_dashboard_cubit.dart';
import 'package:siged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';
import 'package:siged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_repository.dart';
import 'package:siged/_blocs/modules/contracts/measurement/report/report_measurement_repository.dart';
import 'package:siged/_blocs/modules/contracts/measurement/revision/revision_measurement_repository.dart';

// Validity
import 'package:siged/_blocs/modules/contracts/validity/validity_cubit.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_repository.dart';

// DFD Repo (usado pelo SpecificDashboardCubit)
import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

// ===== Widgets / Seções auxiliares =====
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/menu/upBar/up_bar.dart';
import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/screens/panels/specific-dashboard/specific_dashboard_apostilles.dart';
import 'package:siged/screens/panels/specific-dashboard/specific_dashboard_contract.dart';
import 'package:siged/screens/panels/specific-dashboard/specific_dashboard_metrics.dart';

// Linha de charts de acompanhamento físico
import 'package:siged/screens/panels/specific-dashboard/specific_dashboard_schedules.dart';

// Timeline
import 'package:siged/_widgets/timeline/timeline_class.dart';

class SpecificDashboardPage extends StatefulWidget {
  const SpecificDashboardPage({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  State<SpecificDashboardPage> createState() => _SpecificDashboardPageState();
}

class _SpecificDashboardPageState extends State<SpecificDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final contractId = widget.contractData.id ?? '';

    return MultiBlocProvider(
      providers: [
        BlocProvider<SpecificDashboardCubit>(
          create: (_) => SpecificDashboardCubit(
            dfdRepository: DfdRepository(),
            additivesRepository: AdditivesRepository(),
            apostillesRepository: ApostillesRepository(),
            reportRepository: ReportMeasurementRepository(),
            adjustmentRepository: AdjustmentMeasurementRepository(),
            revisionRepository: RevisionMeasurementRepository(),
          )..loadForContract(contractId),
        ),
        BlocProvider<ValidityCubit>(
          create: (_) => ValidityCubit(
            repository: ValidityRepository(),
          )..loadForContract(contractId),
        ),
      ],
      child: Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(72),
          child: UpBar(
            leading: Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: BackCircleButton(),
            ),
          ),
        ),
        body: Stack(
          children: [
            const BackgroundClean(),
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const TimelineClass(dfdStatus: null),

                  const SectionTitle(text: 'Resumo do Geral do contrato'),
                  const SpecificDashboardContractSummary(),
                  const SizedBox(height: 12),
                  const SpecificDashboardApostillesSummary(),

                  const SectionTitle(text: 'Acompanhamento físico'),
                  SpecificDashboardSchedules(contract: widget.contractData),

                  const SectionTitle(text: 'Métricas'),
                  SpecificDashboardMetrics(), // ✅ aqui
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const FootBar(),
      ),
    );
  }
}
