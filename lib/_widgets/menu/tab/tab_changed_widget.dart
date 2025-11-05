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

/// Scaffold reutilizável de abas para contratos com barra superior customizável.
class TabChangedWidget extends StatefulWidget {
  final UserData? userData;
  final ContractData? contractData;
  final ContractBloc? contractsBloc;
  final int initialTabIndex;
  final List<ContractTabDescriptor> tabs;
  final String Function(ContractData c)? bannerTitleBuilder;
  final String blockedMessage;

  // ======== NOVOS PARÂMETROS DE ESTILO DA BARRA SUPERIOR ========
  /// Altura da barra (sem considerar o safeTop).
  final double topBarHeight;

  /// Gradient da barra. Se fornecido, tem prioridade sobre [topBarColor].
  final List<Color>? topBarColors;

  /// Cor sólida da barra (usada se [topBarColors] for null).
  final Color? topBarColor;

  /// Direção do gradient (se [topBarColors] for usado).
  final Alignment topBarBegin;
  final Alignment topBarEnd;

  /// Cor da borda inferior da barra.
  final Color topBarBorderColor;

  /// Cores do TabBar
  final Color labelColor;
  final Color unselectedLabelColor;
  final Color indicatorColor;

  /// Espessura do indicador
  final double indicatorWeight;

  /// Se as abas são roláveis
  final bool tabsIsScrollable;

  /// Alinhamento das abas
  final TabAlignment tabAlignment;

  /// Widget à direita na barra (ex.: foto, menu, etc.)
  final Widget? trailing;

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

    // ======== defaults (mantêm aparência atual) ========
    this.topBarHeight = 72.0,
    this.topBarColors = const [Color(0xFF1B2031), Color(0xFF1B2039)],
    this.topBarColor,
    this.topBarBegin = Alignment.topCenter,
    this.topBarEnd = Alignment.bottomCenter,
    this.topBarBorderColor = Colors.white,
    this.labelColor = Colors.white,
    this.unselectedLabelColor = Colors.grey,
    this.indicatorColor = Colors.white,
    this.indicatorWeight = 2.0,
    this.tabsIsScrollable = true,
    this.tabAlignment = TabAlignment.start,
    this.trailing = const PopUpPhotoMenu(),
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
    final double topBarTotal = safeTop + widget.topBarHeight;

    final tabs = widget.tabs;
    final labels = tabs.map((t) => t.label).toList();

    return DefaultTabController(
      length: tabs.length,
      initialIndex: widget.initialTabIndex.clamp(0, tabs.length - 1).toInt(),
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
                      physics: const NeverScrollableScrollPhysics(),
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
                decoration: BoxDecoration(
                  gradient: (widget.topBarColors != null &&
                      widget.topBarColors!.isNotEmpty)
                      ? LinearGradient(
                    colors: widget.topBarColors!,
                    begin: widget.topBarBegin,
                    end: widget.topBarEnd,
                  )
                      : null,
                  color: (widget.topBarColors == null ||
                      widget.topBarColors!.isEmpty)
                      ? (widget.topBarColor ?? const Color(0xFF1B2031))
                      : null,
                  border: Border(
                    bottom: BorderSide(
                      color: widget.topBarBorderColor,
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.only(top: safeTop),
                child: Row(
                  children: [
                    const SizedBox(width: 60),
                    Expanded(
                      child: TabBar(
                        isScrollable: widget.tabsIsScrollable,
                        dividerHeight: 0,
                        tabAlignment: widget.tabAlignment,
                        labelColor: widget.labelColor,
                        indicatorColor: widget.indicatorColor,
                        unselectedLabelColor: widget.unselectedLabelColor,
                        indicatorWeight: widget.indicatorWeight,
                        tabs: [for (final l in labels) Tab(text: l)],
                      ),
                    ),
                    if (widget.trailing != null) widget.trailing!,
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
