// lib/screens/panels/specific-dashboard/specific_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ===== SIGED: Models / Stores / Blocs / Cubits =====
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

// Cubit específico do dashboard detalhado
import 'package:sipged/_blocs/panels/specific_dashboard/specific_dashboard_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_repository.dart';

// Validity
import 'package:sipged/_blocs/modules/contracts/validity/validity_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_repository.dart';

// DFD Repo usado pelo SpecificDashboardCubit
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

// Permission / Tenant ativo
import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

// ===== Widgets / Seções auxiliares =====
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/screens/panels/specific-dashboard/specific_dashboard_apostilles.dart';
import 'package:sipged/screens/panels/specific-dashboard/specific_dashboard_contract.dart';
import 'package:sipged/screens/panels/specific-dashboard/specific_dashboard_metrics.dart';

// Linha de charts de acompanhamento físico
import 'package:sipged/screens/panels/specific-dashboard/specific_dashboard_schedules.dart';

// Timeline
import 'package:sipged/screens/modules/contracts/validity/timeline_class.dart';

class SpecificDashboardPage extends StatefulWidget {
  const SpecificDashboardPage({
    super.key,
    required this.contractData,
  });

  final ContractData contractData;

  @override
  State<SpecificDashboardPage> createState() => _SpecificDashboardPageState();
}

class _SpecificDashboardPageState extends State<SpecificDashboardPage> {
  String _resolveRequiredTenantId(PermissionState permissionState) {
    final tenantId = permissionState.activeTenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório para SpecificDashboardPage.',
      );
    }

    return tenantId;
  }

  String _resolveRequiredContractId() {
    final contractId = widget.contractData.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw ArgumentError(
        'contractId é obrigatório para SpecificDashboardPage.',
      );
    }

    return contractId;
  }

  @override
  Widget build(BuildContext context) {
    final contractId = _resolveRequiredContractId();

    return BlocBuilder<PermissionCubit, PermissionState>(
      buildWhen: (previous, current) {
        return previous.activeTenantId != current.activeTenantId;
      },
      builder: (context, permissionState) {
        final tenantId = _resolveRequiredTenantId(permissionState);

        return MultiBlocProvider(
          key: ValueKey<String>('specific-dashboard-$tenantId-$contractId'),
          providers: [
            BlocProvider<SpecificDashboardCubit>(
              create: (_) {
                return SpecificDashboardCubit(
                  dfdRepository: DfdRepository(
                    tenantId: tenantId,
                  ),
                  additivesRepository: AdditivesRepository(
                    tenantId: tenantId,
                  ),
                  apostillesRepository: ApostillesRepository(
                    tenantId: tenantId,
                  ),
                  reportRepository: ReportExecutedRepository(
                    tenantId: tenantId,
                  ),
                  adjustmentRepository: AdjustmentMeasurementRepository(
                    tenantId: tenantId,
                  ),
                  revisionRepository: RevisionMeasurementRepository(
                    tenantId: tenantId,
                  ),
                )..loadForContract(contractId);
              },
            ),
            BlocProvider<ValidityCubit>(
              create: (_) {
                return ValidityCubit(
                  repository: ValidityRepository(
                    tenantId: tenantId,
                  ),
                  initialTenantId: tenantId
                )..loadForContract(
                    contractId,
                );
              },
            ),
          ],
          child: Scaffold(
            appBar: const UpBar(
              leading: Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: CircleButtonChange(),
              ),
            ),
            body: Stack(
              children: [
                const Positioned.fill(
                  child: BackgroundChange(),
                ),
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
                      SpecificDashboardSchedules(
                        contract: widget.contractData,
                        tenantId: tenantId,
                      ),

                      const SectionTitle(text: 'Métricas'),
                      const SpecificDashboardMetrics(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const FootBar(),
          ),
        );
      },
    );
  }
}