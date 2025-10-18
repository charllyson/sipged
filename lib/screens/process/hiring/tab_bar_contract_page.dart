import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';
import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/contracts/contract_bloc.dart';
import 'package:siged/_widgets/schedule/physical_financial/schedule_physical_financial_widget.dart';
import 'package:siged/screens/process/hiring/0.resume/main_manager_section.dart';
import 'package:siged/screens/process/hiring/1.dfd/dfd_page.dart';
import 'package:siged/screens/process/hiring/8.juridico/parecer_juridico_controller.dart';
import 'package:siged/screens/process/hiring/2.etp/etp_controller.dart';
import 'package:siged/screens/process/hiring/9.publication/publicacao_extrato_controller.dart';
import 'package:siged/screens/process/hiring/10.finish/termo_arquivamento_controller.dart';
import 'package:siged/screens/process/hiring/3.tr/tr_controller.dart';
import 'package:siged/screens/process/hiring/4.cotacao/cotacao_page.dart';
import 'package:siged/screens/process/hiring/4.cotacao/cotacao_controller.dart';
import 'package:siged/screens/process/hiring/5.regularidade/regularidade_controller.dart';
import 'package:siged/screens/process/hiring/5.regularidade/regularidade_page.dart';
import 'package:siged/screens/process/hiring/6.dotacao/dotacao_controller.dart';
import 'package:siged/screens/process/hiring/6.dotacao/dotacao_page.dart';
import 'package:siged/screens/process/hiring/2.etp/etp_page.dart';
import 'package:siged/screens/process/hiring/7.minuta/minuta_contrato_page.dart';
import 'package:siged/screens/process/hiring/7.minuta/minuta_contrato_controller.dart';
import 'package:siged/screens/process/hiring/8.juridico/parecer_juridico_page.dart';
import 'package:siged/screens/process/hiring/9.publication/publicacao_extrato_page.dart';
import 'package:siged/screens/process/hiring/10.finish/termo_arquivamento_page.dart';
import 'package:siged/screens/process/hiring/1.dfd/dfd_controller.dart';
import 'package:siged/screens/process/hiring/3.tr/tr_page.dart';
import 'package:siged/screens/process/hiring/budget/budget_page.dart';

class TabBarHiringPage extends StatelessWidget {
  final ContractData? contractData;
  final ContractBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarHiringPage({
    super.key,
    this.contractData,
    this.contractsBloc,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TabChangedWidget(
      contractData: contractData,
      contractsBloc: contractsBloc,
      initialTabIndex: initialTabIndex,
      tabs: [
        ContractTabDescriptor(
          label: 'Resumo',
          builder: (c) => MainManagerSection(contractData: c),
        ),
        ContractTabDescriptor(
          label: 'Demanda',
          requireSavedContract: true,
          builder: (c) => ChangeNotifierProvider(
            create: (_) => DfdController()..initWithMock(),
            builder: (context, _) {
              final df = context.watch<DfdController>();
              return DfdPage(controller: df);
            },
          ),
        ),
        ContractTabDescriptor(
          label: 'Estudo Preliminar',
          requireSavedContract: true,
          builder: (c) => ChangeNotifierProvider(
            create: (_) => EtpController()..initWithMock(),
            builder: (context, _) {
              final etp = context.watch<EtpController>();
              return EtpPage(controller: etp);
            },
          ),
        ),
        ContractTabDescriptor(
          label: 'Termo de Referência',
          requireSavedContract: true,
          builder: (c) => ChangeNotifierProvider(
            create: (_) => TrController()..initWithMock(),
            builder: (context, _) {
              final tr = context.watch<TrController>();
              return TermoReferenciaPage(controller: tr, readOnly: false);
            },
          ),
        ),
        ContractTabDescriptor(
          label: 'Cotação',
          requireSavedContract: true,
          builder: (c) => ChangeNotifierProvider(
            create: (_) => CotacaoController()..initWithMock(),
            builder: (context, _) {
              final ct = context.watch<CotacaoController>();
              return CotacaoPage(controller: ct, readOnly: false);
            },
          ),
        ),
        ContractTabDescriptor(
          label: 'Orçamento',
          requireSavedContract: true,
          builder: (c) => BudgetPage(contractData: c!),
        ),
        ContractTabDescriptor(
          label: 'Cronograma',
          requireSavedContract: true,
          builder: (c) => BlocProvider(
            create: (_) => ScheduleRoadBloc()
              ..add(ScheduleWarmupRequested(
                contractId: c.id!,
                initialServiceKey: 'geral',
              )),
            child: SchedulePhysicalFinancialWidget(
              contractData: c!,
              chronogramMode: false,
              // sem additiveController aqui (somente leitura / contratado)
            ),
          ),
        ),
        ContractTabDescriptor(
          label: 'Habilitação',
          requireSavedContract: true,
          builder: (c) => ChangeNotifierProvider(
            create: (_) => RegularidadeController()..initWithMock(),
            builder: (context, _) {
              final dg = context.watch<RegularidadeController>();
              return RegularidadePage(controller: dg, readOnly: false);
            },
          ),
        ),
        ContractTabDescriptor(
          label: 'Dotação Orçamentária',
          requireSavedContract: true,
          builder: (c) => ChangeNotifierProvider(
            create: (_) => DotacaoController()..initWithMock(),
            builder: (context, _) {
              final d = context.watch<DotacaoController>();
              return DotacaoPage(controller: d);
            },
          ),
        ),
        ContractTabDescriptor(
          label: 'Minuta do Contrato',
          requireSavedContract: true,
          builder: (c) => ChangeNotifierProvider(
            create: (_) => MinutaContratoController()..initWithMock(),
            builder: (context, _) {
              final mc = context.watch<MinutaContratoController>();
              return MinutaContratoPage(controller: mc);
            },
          ),
        ),
        ContractTabDescriptor(
          label: 'Parecer Jurídico',
          requireSavedContract: true,
          builder: (c) => ChangeNotifierProvider(
            create: (_) => ParecerJuridicoController()..initWithMock(),
            builder: (context, _) {
              final pj = context.watch<ParecerJuridicoController>();
              return ParecerJuridicoPage(controller: pj);
            },
          ),
        ),
        ContractTabDescriptor(
          label: 'Publicação do Extrato',
          requireSavedContract: true,
          builder: (c) => ChangeNotifierProvider(
            create: (_) => PublicacaoExtratoController()..initWithMock(),
            builder: (context, _) {
              final pe = context.watch<PublicacaoExtratoController>();
              return PublicacaoExtratoPage(controller: pe);
            },
          ),
        ),
        ContractTabDescriptor(
          label: 'Termo de Arquivamento',
          requireSavedContract: true,
          builder: (c) => ChangeNotifierProvider(
            create: (_) => TermoArquivamentoController()..initWithMock(),
            builder: (context, _) {
              final ta = context.watch<TermoArquivamentoController>();
              return TermoArquivamentoPage(controller: ta);
            },
          ),
        ),
      ],
    );
  }
}
