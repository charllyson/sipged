// lib/screens/crm/precatorios/tab_bar_crm_precatory_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';

import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/_process/process_bloc.dart';

// Página genérica + base/controller e helpers
import 'package:siged/screens-legal/crm/crm_step_controllers.dart';
import 'package:siged/screens-legal/crm/crm_step_page.dart';

// 👇 bloc/user + palette
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

class TabBarCrmPrecatoryPage extends StatelessWidget {
  final ProcessData? contractData;
  final ProcessBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarCrmPrecatoryPage({
    super.key,
    this.contractData,
    this.contractsBloc,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (a, b) => a.current != b.current || a.isLoadingUsers != b.isLoadingUsers,
      builder: (context, state) {
        final userData = state.current;
        final palette = UserData.drawerPaletteForUser(userData);

        // 🔹 queremos a barra com a MESMA cor de fundo do Drawer:
        final Color topBarColor = palette.background;

        return Stack(
          children: [
            const BackgroundClean(),
            TabChangedWidget(
              contractData: contractData,
              contractsBloc: contractsBloc,
              initialTabIndex: initialTabIndex,

              // ======== pinta a barra igual ao menu ========
              topBarColors: const [], // força modo cor sólida
              topBarColor: topBarColor,
              topBarBorderColor: Colors.white, // mantém sua borda
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              // =============================================

              tabs: [
                ContractTabDescriptor(
                  label: 'Captação',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmCaptacaoController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmCaptacaoController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Qualificação',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmQualificacaoController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmQualificacaoController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Contato Inicial',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmContatoInicialController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmContatoInicialController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Documentos',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmDocumentosController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmDocumentosController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Valuation',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmValuationController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmValuationController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Proposta',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmPropostaController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmPropostaController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Due Diligence',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmDueDiligenceController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmDueDiligenceController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Aprovação Jurídica',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmAprovacaoJuridicaController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmAprovacaoJuridicaController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Assinaturas',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmAssinaturasController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmAssinaturasController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Registro',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmRegistroCessaoController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmRegistroCessaoController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Pagamento',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmPagamentoController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmPagamentoController>(),
                      readOnly: false,
                    ),
                  ),
                ),
                ContractTabDescriptor(
                  label: 'Pós-Venda',
                  builder: (c) => ChangeNotifierProvider(
                    create: (_) => CrmPosVendaController()..initWithMock(),
                    builder: (context, _) => CrmStepPage(
                      controller: context.watch<CrmPosVendaController>(),
                      readOnly: false,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
