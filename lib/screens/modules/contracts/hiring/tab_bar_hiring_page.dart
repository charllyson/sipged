import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:sipged/screens/modules/contracts/hiring/progress_stage.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_cubit.dart';

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
  const TabBarHiringPage({
    super.key,
    this.contractData,
    this.contractsCubit,
    this.initialTabIndex = 0,
  });

  final ContractData? contractData;
  final ContractCubit? contractsCubit;
  final int initialTabIndex;

  @override
  State<TabBarHiringPage> createState() => _TabBarHiringPageState();
}

class _TabBarHiringPageState extends State<TabBarHiringPage>
    with AutomaticKeepAliveClientMixin {
  String get _contractId => widget.contractData?.id?.trim() ?? '';

  late final String _pageInstanceKey;
  late final ProgressRepository _progressRepo;
  late final ProgressCubit _progressCubit;

  String? _dfdDescricaoObjeto;
  String? _dfdProcessoAdministrativo;

  @override
  void initState() {
    super.initState();

    final rawId = _contractId;

    if (rawId.isNotEmpty) {
      _pageInstanceKey = 'C_$rawId';
    } else {
      _pageInstanceKey = 'NEW_${DateTime.now().microsecondsSinceEpoch}';
    }

    _progressRepo = ProgressRepository();
    _progressCubit = ProgressCubit(repo: _progressRepo);

    if (rawId.isNotEmpty) {
      _progressCubit.setContractForPipeline(rawId);
    }

    _loadDfdDisplayData();
  }

  @override
  void didUpdateWidget(covariant TabBarHiringPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldContractId = oldWidget.contractData?.id?.trim() ?? '';
    final newContractId = widget.contractData?.id?.trim() ?? '';

    if (oldContractId != newContractId) {
      if (newContractId.isNotEmpty) {
        _progressCubit.setContractForPipeline(newContractId);
        _loadDfdDisplayData();
      } else {
        _progressCubit.setContractForPipeline('');
      }
    }
  }

  @override
  void dispose() {
    _progressCubit.close();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  String? _stageKeyForTabIndex(int index) {
    switch (index) {
      case 0:
        return ProgressData.dfd;
      case 1:
        return ProgressData.etp;
      case 2:
        return ProgressData.tr;
      case 3:
        return ProgressData.cotacao;
      case 4:
        return ProgressData.edital;
      case 5:
        return ProgressData.habilitacao;
      case 6:
        return ProgressData.dotacao;
      case 7:
        return ProgressData.minuta;
      case 8:
        return ProgressData.parecer;
      case 9:
        return ProgressData.publicacao;
      case 10:
        return ProgressData.arquivamento;
      default:
        return null;
    }
  }

  Future<void> _loadDfdDisplayData() async {
    final id = _contractId;

    if (id.isEmpty) return;

    try {
      final repo = DfdRepository();
      final dfd = await repo.readDataForContract(id);

      if (!mounted) return;

      setState(() {
        _dfdDescricaoObjeto = dfd?.descricaoObjeto;
        _dfdProcessoAdministrativo = dfd?.processoAdministrativo;
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  String _buildContractNumber(ContractData contract) {
    final processo = _dfdProcessoAdministrativo?.trim();

    if (processo != null && processo.isNotEmpty) {
      return 'Processo nº $processo';
    }

    final id = contract.id?.trim();

    if (id != null && id.isNotEmpty) {
      return 'Contrato $id';
    }

    return '';
  }

  StampConfig _buildStampConfig({
    required String? stageKey,
    required bool approved,
  }) {
    if (stageKey == null) {
      return const StampConfig(
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

    if (stageKey == ProgressData.cotacao) {
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

    if (stageKey == ProgressData.edital) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final contract = widget.contractData;
    final contractId = _contractId;
    final pageKey = _pageInstanceKey;

    return BlocProvider<ProgressCubit>.value(
      value: _progressCubit,
      child: BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, progressState) {
          bool isApprovedForTab(int index) {
            final stageKey = _stageKeyForTabIndex(index);

            if (stageKey == null) return false;

            return progressState.completedByStage[stageKey] == true;
          }

          return TabChanged(
            contractData: contract,
            contractsCubit: widget.contractsCubit,
            initialTabIndex: widget.initialTabIndex,
            textBanner: _dfdDescricaoObjeto,
            contractNumberBuilder: _buildContractNumber,
            resolveStampForTab: ({
              required int tabIndex,
              required ContractData contract,
            }) {
              final stageKey = _stageKeyForTabIndex(tabIndex);
              final approved = isApprovedForTab(tabIndex);

              return _buildStampConfig(
                stageKey: stageKey,
                approved: approved,
              );
            },
            tabs: <ContractTabDescriptor>[
              ContractTabDescriptor(
                label: 'Demanda',
                builder: (_) {
                  return DfdPage(
                    key: PageStorageKey<String>('dfd-page-$pageKey'),
                    contractId: contractId,
                  );
                },
              ),
              ContractTabDescriptor(
                label: 'Estudo Preliminar',
                builder: (_) {
                  return ProgressStage(
                    stageKey: ProgressData.etp,
                    child: EtpPage(
                      key: PageStorageKey<String>('etp-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),
              ContractTabDescriptor(
                label: 'Termo de Referência',
                builder: (_) {
                  return ProgressStage(
                    stageKey: ProgressData.tr,
                    child: TermoReferenciaPage(
                      key: PageStorageKey<String>('tr-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),
              ContractTabDescriptor(
                label: 'Cotação',
                builder: (_) {
                  return ProgressStage(
                    stageKey: ProgressData.cotacao,
                    child: CotacaoPage(
                      key: PageStorageKey<String>('cotacao-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),
              ContractTabDescriptor(
                label: 'Edital',
                builder: (_) {
                  return ProgressStage(
                    stageKey: ProgressData.edital,
                    child: EditalJulgamentoPage(
                      key: PageStorageKey<String>('edital-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),
              ContractTabDescriptor(
                label: 'Habilitação',
                builder: (_) {
                  return ProgressStage(
                    stageKey: ProgressData.habilitacao,
                    child: HabilitacaoPage(
                      key: PageStorageKey<String>('habilitacao-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),
              ContractTabDescriptor(
                label: 'Dotação Orçamentária',
                builder: (_) {
                  return ProgressStage(
                    stageKey: ProgressData.dotacao,
                    child: DotacaoPage(
                      key: PageStorageKey<String>('dotacao-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),
              ContractTabDescriptor(
                label: 'Minuta do Contrato',
                builder: (_) {
                  return ProgressStage(
                    stageKey: ProgressData.minuta,
                    child: MinutaContratoPage(
                      key: PageStorageKey<String>('minuta-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),
              ContractTabDescriptor(
                label: 'Parecer Jurídico',
                builder: (_) {
                  return ProgressStage(
                    stageKey: ProgressData.parecer,
                    child: ParecerJuridicoPage(
                      key: PageStorageKey<String>('parecer-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),
              ContractTabDescriptor(
                label: 'Publicação do Extrato',
                builder: (_) {
                  return ProgressStage(
                    stageKey: ProgressData.publicacao,
                    child: PublicacaoExtratoPage(
                      key: PageStorageKey<String>('publicacao-page-$pageKey'),
                      contractId: contractId,
                    ),
                  );
                },
              ),
              ContractTabDescriptor(
                label: 'Arquivamento',
                builder: (_) {
                  return ProgressStage(
                    stageKey: ProgressData.arquivamento,
                    child: TermoArquivamentoPage(
                      key: PageStorageKey<String>('arquivamento-page-$pageKey'),
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