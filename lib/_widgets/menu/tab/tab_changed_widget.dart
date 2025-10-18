import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_blocs/process/contracts/contract_bloc.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/contracts/contract_store.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/menu/pop_up/pup_up_photo_menu.dart';
import 'package:siged/_widgets/list/search/search_user_permission_widget.dart';

// permissões globais & por documento
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_widgets/menu/tab/tab_blocked.dart';

import 'tab_banner.dart';

/// Descriptor de cada aba (rótulo + builder da página)
class ContractTabDescriptor {
  final String label;
  final Widget Function(ContractData? contract) builder;

  /// Se true, a aba mostra um bloqueio quando o contrato não foi salvo (id == null)
  final bool requireSavedContract;

  const ContractTabDescriptor({
    required this.label,
    required this.builder,
    this.requireSavedContract = false,
  });
}

/// Scaffold reutilizável de abas para contratos.
/// - Renderiza UpBar com TabBar
/// - Mostra banner com resumo/participantes (clicável p/ gerenciar)
/// - Bloqueia abas que exigem contrato salvo
/// - Mantém o ContractData local atualizado após editar participantes
// ... imports iguais

class TabChangedWidget extends StatefulWidget {
  final UserData? userData;
  final ContractData? contractData;
  final ContractBloc? contractsBloc;
  final int initialTabIndex;
  final List<ContractTabDescriptor> tabs;
  final String Function(ContractData c)? bannerTitleBuilder;
  final String blockedMessage;

  const TabChangedWidget({
    super.key,
    this.userData,
    this.contractData,
    this.contractsBloc,
    this.initialTabIndex = 0,
    required this.tabs,
    this.bannerTitleBuilder,
    this.blockedMessage =
    '⚠️ Para acessar esta aba, salve primeiro as informações principais do contrato.',
  });

  @override
  State<TabChangedWidget> createState() => _TabChangedWidgetState();
}

class _TabChangedWidgetState extends State<TabChangedWidget> {
  late ContractData? _contractData;

  @override
  void initState() {
    super.initState();
    _contractData = widget.contractData;
  }

  @override
  Widget build(BuildContext context) {
    final double safeTop = MediaQuery.of(context).padding.top;
    const double barHeight = 72.0;
    final double topBarTotal = safeTop + barHeight;

    final tabs = widget.tabs;
    final labels = tabs.map((t) => t.label).toList();

    return DefaultTabController(
      length: tabs.length,
      initialIndex:
      widget.initialTabIndex.clamp(0, tabs.length - 1).toInt(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const BackgroundClean(),
            Padding(
              padding: EdgeInsets.only(top: topBarTotal),
              child: Column(
                children: [
                  if (_contractData != null)
                    TabBanner(
                      contract: _contractData!,
                      titleBuilder: widget.bannerTitleBuilder,
                    ),
                  Expanded(
                    child: TabBarView(
                      physics:
                      const NeverScrollableScrollPhysics(),
                      children: [
                        for (final t in tabs)
                          t.requireSavedContract && (_contractData?.id == null)
                              ? TabBlocked(message: widget.blockedMessage)
                              : t.builder(_contractData),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // UpBar com TabBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: topBarTotal,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B2031), Color(0xFF1B2039)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 1),
                  ),
                ),
                padding: EdgeInsets.only(top: safeTop),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const BackCircleButton(),
                    Expanded(
                      child: TabBar(
                        isScrollable: true,
                        dividerHeight: 0,
                        tabAlignment: TabAlignment.start,
                        labelColor: Colors.white,
                        indicatorColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        tabs: [for (final l in labels) Tab(text: l)],
                      ),
                    ),
                    const PopUpPhotoMenu(),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

