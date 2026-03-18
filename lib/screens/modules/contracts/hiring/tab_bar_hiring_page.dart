import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

// === Pipeline (habilitação de etapas) ===
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';

// === Componentes ===
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';
import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

// === BLOCs e Controllers globais ===
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_bloc.dart';

import 'package:sipged/screens/modules/contracts/hiring/1Dfd/dfd_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/2Etp/etp_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/tr_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/cotacao_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/5Edital/edital_julgamento_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/habilitacao_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/7Dotacao/dotacao_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/8Minuta/minuta_contrato_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/parecer_juridico_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/publicacao_extrato_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/11Arquivamento/termo_arquivamento_page.dart';

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
  // 🔑 ID REAL DO CONTRATO (para Firestore)
  String get _contractId => widget.contractData?.id ?? '';

  // 🔑 ID LOCAL DA PÁGINA (para controllers / PageStorage / estado de UI)
  late final String _pageInstanceKey;

  late final PipelineProgressCubit _pipelineCubit;
  final _progressRepo = ProgressRepository();

  String? _dfdDescricaoObjeto;

  @override
  void initState() {
    super.initState();

    // 🔑 Gera um ID local único para esta instância de tela
    // - Se tiver id de contrato, "C_<id>"
    // - Se for novo (id vazio), "NEW_<timestamp>"
    final rawId = _contractId;
    if (rawId.isNotEmpty) {
      _pageInstanceKey = 'C_$rawId';
    } else {
      _pageInstanceKey = 'NEW_${DateTime.now().microsecondsSinceEpoch}';
    }

    _pipelineCubit = PipelineProgressCubit(
      service: PipelineProgressService(),
      contractId: _contractId,
      progressRepo: _progressRepo,
    );

    _loadDfdDescricao();
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
  ///
  /// Importante: o índice 0 é usado pelo "Resumo" no TabChangedWidget.
  String? _stageKeyForTabIndex(int index) {
    switch (index) {
      case 1:
        return HiringStageKey.dfd;
      case 2:
        return HiringStageKey.etp;
      case 3:
        return HiringStageKey.tr;
      case 4:
        return HiringStageKey.cotacao;
      case 5:
        return HiringStageKey.edital;
      case 6:
        return HiringStageKey.habilitacao;
      case 7:
        return HiringStageKey.dotacao;
      case 8:
        return HiringStageKey.minuta;
      case 9:
        return HiringStageKey.parecer;
      case 10:
        return HiringStageKey.publicacao;
      case 11:
        return HiringStageKey.arquivamento;
      default:
        return null; // 0 (Resumo) não tem stageKey
    }
  }

  Future<void> _loadDfdDescricao() async {
    final id = _contractId;
    if (id.isEmpty) return;


    try {
      final repo = DfdRepository();
      final dfd = await repo.readDataForContract(id);

      if (!mounted) return;

      setState(() {
        _dfdDescricaoObjeto = dfd?.descricaoObjeto;
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = widget.contractData;
    final contractId = _contractId;
    final pageKey = _pageInstanceKey;

    return BlocProvider.value(
      value: _pipelineCubit,
      child: Builder(
        builder: (ctx) {
          final pipeline = ctx.watch<PipelineProgressCubit>().state;

          bool isApprovedForTab(int index) {
            final key = _stageKeyForTabIndex(index);
            if (key == null) return false;
            return pipeline.completed[key] == true;
          }

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
            contractData: c,
            contractsBloc: widget.contractsBloc,
            initialTabIndex: widget.initialTabIndex,
            textBanner: _dfdDescricaoObjeto,
            resolveStampForTab: ({
              required int tabIndex,
              required ProcessData contract,
            }) {
              final ok = isApprovedForTab(tabIndex);
              return makeConfig(idx: tabIndex, approved: ok);
            },
            tabs: [
              // DFD
              ContractTabDescriptor(
                label: 'Demanda',
                builder: (_) {
                  return DfdPage(
                    key: PageStorageKey('dfd-page-$pageKey'),
                    contractId: contractId,
                  );
                },
              ),

              // ETP
              ContractTabDescriptor(
                label: 'Estudo Preliminar',
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.etp,
                    child: EtpPage(
                      key: PageStorageKey('etp-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // TR
              ContractTabDescriptor(
                label: 'Termo de Referência',
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.tr,
                    child: TermoReferenciaPage(
                      key: PageStorageKey('tr-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // Cotação
              ContractTabDescriptor(
                label: 'Cotação',
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.cotacao,
                    child: CotacaoPage(
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // Edital
              ContractTabDescriptor(
                label: 'Edital',
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.edital,
                    child: EditalJulgamentoPage(
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // Habilitação
              ContractTabDescriptor(
                label: 'Habilitação',
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.habilitacao,
                    child: HabilitacaoPage(
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // Dotação
              ContractTabDescriptor(
                label: 'Dotação Orçamentária',
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.dotacao,
                    child: DotacaoPage(
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // Minuta
              ContractTabDescriptor(
                label: 'Minuta do Contrato',
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.minuta,
                    child: MinutaContratoPage(
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // Jurídico
              ContractTabDescriptor(
                label: 'Parecer Jurídico',
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.parecer,
                    child: ParecerJuridicoPage(
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // Publicação
              ContractTabDescriptor(
                label: 'Publicação do Extrato',
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.publicacao,
                    child: PublicacaoExtratoPage(
                      contractId: contractId,
                    ),
                  );
                },
              ),

              // Arquivamento
              ContractTabDescriptor(
                label: 'Arquivamento',
                builder: (_) {
                  return StageGate(
                    stageKey: HiringStageKey.arquivamento,
                    child: TermoArquivamentoPage(
                      contractId: contractId,
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
