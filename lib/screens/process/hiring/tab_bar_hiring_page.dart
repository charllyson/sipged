// lib/screens/process/hiring/tab_bar_hiring_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_repository.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

// === Pipeline (habilitação de etapas) ===
import 'package:siged/_blocs/process/hiring/0Stages/pipeline_progress.dart';
import 'package:siged/_blocs/process/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_repository.dart';

// === Componentes ===
import 'package:siged/_widgets/gates/stage_gate.dart';
import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:siged/_widgets/overlays/screen_lock.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_stages.dart';

// === BLOCs e Controllers globais ===
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/_process/process_bloc.dart';

// DFD
import 'package:siged/screens/process/hiring/1Dfd/dfd_page.dart';

// ETP
import 'package:siged/screens/process/hiring/2Etp/etp_page.dart';

// TR
import 'package:siged/screens/process/hiring/3Tr/tr_page.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

// Cotação
import 'package:siged/screens/process/hiring/4Cotacao/cotacao_page.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';

// Edital
import 'package:siged/screens/process/hiring/5Edital/edital_julgamento_page.dart';

// Habilitação
import 'package:siged/screens/process/hiring/6Habilitacao/habilitacao_page.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';

// Dotação
import 'package:siged/screens/process/hiring/7Dotacao/dotacao_page.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

// Minuta
import 'package:siged/screens/process/hiring/8Minuta/minuta_contrato_page.dart';
import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_controller.dart';

// Jurídico
import 'package:siged/screens/process/hiring/9Juridico/parecer_juridico_page.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

// Publicação
import 'package:siged/screens/process/hiring/10Publicacao/publicacao_extrato_page.dart';

// Arquivamento
import 'package:siged/screens/process/hiring/11Arquivamento/termo_arquivamento_page.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_controller.dart';

class TabBarHiringPage extends StatefulWidget {
  final ProcessData? contractData;
  final ProcessBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarHiringPage({
    super.key,
    this.contractData,
    this.contractsBloc,
    this.initialTabIndex = 0,
  });

  @override
  State<TabBarHiringPage> createState() => _TabBarHiringPageState();
}

class _TabBarHiringPageState extends State<TabBarHiringPage>
    with AutomaticKeepAliveClientMixin {

  final Map<String, EtpController> _etpControllers = {};
  EtpController _getEtpController(String id) =>
      _etpControllers.putIfAbsent(id, () => EtpController());

  // TR
  final Map<String, TrController> _trControllers = {};
  TrController _getTrControllers(String id) =>
      _trControllers.putIfAbsent(id, () => TrController());

// Cotação
  final Map<String, CotacaoController> _cotacaoControllers = {};
  CotacaoController _getCotacaoController(String id) =>
      _cotacaoControllers.putIfAbsent(id, () => CotacaoController());

// Habilitação
  final Map<String, HabilitacaoController> _habilitacaoControllers = {};
  HabilitacaoController _getHabilitacaoController(String id) =>
      _habilitacaoControllers.putIfAbsent(id, () => HabilitacaoController());

// Dotação Orçamentária
  final Map<String, DotacaoController> _dotacaoControllers = {};
  DotacaoController _getDotacaoController(String id) =>
      _dotacaoControllers.putIfAbsent(id, () => DotacaoController());

// Minuta do Contrato
  final Map<String, MinutaContratoController> _minutaControllers = {};
  MinutaContratoController _getMinutaController(String id) =>
      _minutaControllers.putIfAbsent(id, () => MinutaContratoController());

// Parecer Jurídico
  final Map<String, ParecerJuridicoController> _juridicoControllers = {};
  ParecerJuridicoController _getJuridicoController(String id) =>
      _juridicoControllers.putIfAbsent(id, () => ParecerJuridicoController());

// Arquivamento
  final Map<String, TermoArquivamentoController> _arquivamentoControllers = {};
  TermoArquivamentoController _getArquivamentoController(String id) =>
      _arquivamentoControllers.putIfAbsent(id, () => TermoArquivamentoController());

  late final PipelineProgressCubit _pipelineCubit;
  final _progressRepo = ProgressRepository();

  String get _contractId => widget.contractData?.id ?? '';

  String? _dfdDescricaoObjeto;
  bool _loadingDfd = false;

  @override
  void initState() {
    super.initState();

    _pipelineCubit = PipelineProgressCubit(
      service: PipelineProgressService(),
      contractId: _contractId,
      progressRepo: _progressRepo,
    );
    _loadDfdDescricao(); // 👈 carrega DFD assim que abrir as abas
    _pipelineCubit.refresh();
    _pipelineCubit.watchChain();
  }

  @override
  void dispose() {
    _pipelineCubit.close();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  /// Mapeia o índice da aba ao stageKey correspondente no pipeline.
  /// Índices:
  /// 0 Resumo (sem selo)
  /// 1 DFD, 2 ETP, 3 TR, 4 Cotação, 5 Edital, 6 Orçamento, 7 Cronograma,
  /// 8 Habilitação, 9 Dotação, 10 Minuta, 11 Jurídico, 12 Publicação, 13 Arquivamento
  String? _stageKeyForTabIndex(int index) {
    switch (index) {
      case 1:  return HiringStageKey.dfd;
      case 2:  return HiringStageKey.etp;
      case 3:  return HiringStageKey.tr;
      case 4:  return HiringStageKey.cotacao;
      case 5:  return HiringStageKey.edital;
      case 6:  return HiringStageKey.habilitacao;
      case 7:  return HiringStageKey.dotacao;
      case 8:  return HiringStageKey.minuta;
      case 9:  return HiringStageKey.parecer;
      case 10: return HiringStageKey.publicacao;
      case 11: return HiringStageKey.arquivamento;
      default: return null; // 0 (Resumo) não tem stageKey
    }
  }

  Future<void> _loadDfdDescricao() async {
    final id = _contractId;
    if (id.isEmpty) return;

    setState(() => _loadingDfd = true);

    try {
      final repo = DfdRepository();
      final dfd = await repo.readDataForContract(id);

      if (!mounted) return;

      setState(() {
        _dfdDescricaoObjeto = dfd?.descricaoObjeto; // 👈 aqui!
        _loadingDfd = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDfd = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = widget.contractData;
    final contractId = c?.id ?? '';

    return BlocProvider.value(
      value: _pipelineCubit,
      child: Builder(
        builder: (ctx) {
          final pipeline = ctx.watch<PipelineProgressCubit>().state;

          // ======== Usa o mapa 'completed' do pipeline ========
          bool isApprovedForTab(int index) {
            final key = _stageKeyForTabIndex(index);
            if (key == null) return false;
            return pipeline.completed[key] == true;
          }

          // ======== Configurar selo (por etapa) ========
          StampConfig makeConfig({
            required int idx,
            required bool approved,
          }) {
            final stageKey = _stageKeyForTabIndex(idx);

            if (stageKey == null) {
              return StampConfig(
                show: false,
                approved: false,
                approvedLabel: '',
                pendingLabel: '',
                approvedIcon: Icons.verified_outlined,
                pendingIcon: Icons.verified_outlined,
                approvedColor: Colors.transparent,
                pendingColor: Colors.transparent,
              );
            }

            // Especiais por etapa (sem depender do índice)
            if (stageKey == HiringStageKey.cotacao) {
              return StampConfig(
                show: true,
                approved: approved,
                approvedLabel: 'Vencedor definido',
                pendingLabel: 'Definir vencedor',
                approvedIcon: Icons.emoji_events_outlined,
                pendingIcon: Icons.emoji_events_outlined,
                approvedColor: Colors.teal,
                pendingColor: Colors.grey,
              );
            }

            if (stageKey == HiringStageKey.edital) {
              return StampConfig(
                show: true,
                approved: approved,
                approvedLabel: 'Julgado',
                pendingLabel: 'Aguardando julgamento',
                approvedIcon: Icons.gavel_outlined,
                pendingIcon: Icons.gavel_outlined,
                approvedColor: Colors.teal,
                pendingColor: Colors.grey,
              );
            }

            // Demais etapas (inclui Habilitação e Dotação)
            return StampConfig(
              show: true,
              approved: approved,
              approvedLabel: 'Aprovado',
              pendingLabel: 'Pendente',
              approvedIcon: Icons.verified_outlined,
              pendingIcon: Icons.verified_user_outlined,
              approvedColor: Colors.teal,
              pendingColor: Colors.grey,
            );
          }

          return TabChangedWidget(
            contractData: widget.contractData,
            contractsBloc: widget.contractsBloc,
            initialTabIndex: widget.initialTabIndex,
            textBanner: _dfdDescricaoObjeto,
            // <<< resolver do selo >>>
            resolveStampForTab: ({
              required int tabIndex,
              required ProcessData contract,
            }) {
              final ok = isApprovedForTab(tabIndex);
              return makeConfig(idx: tabIndex, approved: ok);
            },

            tabs: [
              // === DFD ===
              ContractTabDescriptor(
                label: 'Demanda',
                requireSavedContract: true,
                builder: (_) {
                  return DfdPage(
                    key: PageStorageKey('dfd-page-$contractId'),
                    contractId: contractId,
                  );
                },
              ),

              // === ETP ===
              ContractTabDescriptor(
                label: 'Estudo Preliminar',
                requireSavedContract: true,
                builder: (_) {
                  final etpCtrl = _getEtpController(contractId);
                  return ChangeNotifierProvider.value(
                    value: etpCtrl,
                    child: StageGate(
                      stageKey: HiringStageKey.etp,
                      child: EtpPage(
                        key: PageStorageKey('etp-page-$contractId'),
                        controller: etpCtrl,
                        contractId: contractId,
                      ),
                    ),
                  );
                },
              ),
              // === TR ===
              ContractTabDescriptor(
                label: 'Termo de Referência',
                requireSavedContract: true,
                builder: (_) {
                  final trCtrl = _getTrControllers(contractId);
                  return ChangeNotifierProvider.value(
                    value: trCtrl,
                    child: StageGate(
                      stageKey: HiringStageKey.tr,
                      child: TermoReferenciaPage(
                        key: PageStorageKey('tr-page-$contractId'),
                        controller: trCtrl,
                        contractId: contractId,
                      ),
                    ),
                  );
                },
              ),
              // === Cotação ===
              ContractTabDescriptor(
                label: 'Cotação',
                requireSavedContract: true,
                builder: (_) {
                  final cotCtrl = _getCotacaoController(contractId);
                  return ChangeNotifierProvider.value(
                    value: cotCtrl,
                    child: StageGate(
                      stageKey: HiringStageKey.cotacao,
                      child: CotacaoPage(
                        controller: cotCtrl,
                        contractId: contractId,
                      ),
                    ),
                  );
                },
              ),

              // === Edital ===
              ContractTabDescriptor(
                label: 'Edital',
                requireSavedContract: true,
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.edital,
                    child: EditalJulgamentoPage(
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // === Habilitação ===
              ContractTabDescriptor(
                label: 'Habilitação',
                requireSavedContract: true,
                builder: (_) {
                  final regCtrl = _getHabilitacaoController(contractId);
                  return ChangeNotifierProvider.value(
                    value: regCtrl,
                    child: StageGate(
                      stageKey: HiringStageKey.habilitacao,
                      child: HabilitacaoPage(
                        controller: regCtrl,
                        contractId: contractId,
                      ),
                    ),
                  );
                },
              ),

              // === Dotação ===
              ContractTabDescriptor(
                label: 'Dotação Orçamentária',
                requireSavedContract: true,
                builder: (_) {
                  final dotCtrl = _getDotacaoController(contractId);
                  return ChangeNotifierProvider.value(
                    value: dotCtrl,
                    child: StageGate(
                      stageKey: HiringStageKey.dotacao,
                      child: DotacaoPage(
                        controller: dotCtrl,
                        contractId: contractId,
                      ),
                    ),
                  );
                },
              ),

              // === Minuta ===
              ContractTabDescriptor(
                label: 'Minuta do Contrato',
                requireSavedContract: true,
                builder: (_) {
                  final minCtrl = _getMinutaController(contractId);
                  return ChangeNotifierProvider.value(
                    value: minCtrl,
                    child: StageGate(
                      stageKey: HiringStageKey.minuta,
                      child: MinutaContratoPage(
                        controller: minCtrl,
                        contractId: contractId,
                      ),
                    ),
                  );
                },
              ),

              // === Jurídico ===
              ContractTabDescriptor(
                label: 'Parecer Jurídico',
                requireSavedContract: true,
                builder: (_) {
                  final jurCtrl = _getJuridicoController(contractId);
                  return ChangeNotifierProvider.value(
                    value: jurCtrl,
                    child: StageGate(
                      stageKey: HiringStageKey.parecer,
                      child: ParecerJuridicoPage(
                        controller: jurCtrl,
                        contractId: contractId,
                      ),
                    ),
                  );
                },
              ),

              // === Publicação ===
              ContractTabDescriptor(
                label: 'Publicação do Extrato',
                requireSavedContract: true,
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.publicacao,
                    child: PublicacaoExtratoPage(
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // === Arquivamento ===
              ContractTabDescriptor(
                label: 'Arquivamento',
                requireSavedContract: true,
                builder: (_) {
                  final arqCtrl = _getArquivamentoController(contractId);
                  return ChangeNotifierProvider.value(
                    value: arqCtrl,
                    child: StageGate(
                      stageKey: HiringStageKey.arquivamento,
                      child: TermoArquivamentoPage(
                        controller: arqCtrl,
                        contractId: contractId,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
