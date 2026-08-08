// lib/screens/modules/actives/roads/network/active_roads_network_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_repository.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
 import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'active_roads_map.dart';
import 'active_roads_panel.dart';

class ActiveRoadsNetworkPage extends StatefulWidget {
  const ActiveRoadsNetworkPage({super.key});

  @override
  State<ActiveRoadsNetworkPage> createState() => _ActiveRoadsNetworkPageState();
}

class _ActiveRoadsNetworkPageState extends State<ActiveRoadsNetworkPage> {
  late final ActiveRoadsCubit _cubit;

  String? _lastTenantId;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();

    _cubit = ActiveRoadsCubit(
      repository: ActiveRoadsRepository(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final tenantState = context.read<TenantCubit>().state;
    final tenantId = _tenantIdFromTenantState(tenantState);

    _syncTenantAndWarmup(tenantId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String? _cleanId(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;
    if (text.toLowerCase() == 'null') return null;

    return text;
  }

  String? _idFromObject(dynamic object) {
    if (object == null) return null;

    try {
      final value = object.id;
      final clean = _cleanId(value);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final value = object.tenantId;
      final clean = _cleanId(value);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final value = object.companyId;
      final clean = _cleanId(value);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final value = object.uid;
      final clean = _cleanId(value);
      if (clean != null) return clean;
    } catch (_) {}

    return null;
  }

  String? _tenantIdFromTenantState(TenantState state) {
    final dynamic s = state;

    try {
      final clean = _cleanId(s.activeTenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.currentTenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.tenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.companyId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.current);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.tenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.currentTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.activeTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.selectedTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.company);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.selectedCompany);
      if (clean != null) return clean;
    } catch (_) {}

    return null;
  }

  void _syncTenantAndWarmup(String? tenantId) {
    final cleanTenantId = tenantId?.trim();

    if (_lastTenantId == cleanTenantId) return;

    _lastTenantId = cleanTenantId;

    _cubit.setActiveTenantId(cleanTenantId);

    if (cleanTenantId == null || cleanTenantId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cubit.warmup();
    });
  }

  void _togglePanel() {
    setState(() {
      _showPanel = !_showPanel;
    });
  }

  Widget _buildPanelToggleButton() {
    final active = _showPanel;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: active ? 1.0 : 0.58,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ]
              : const [],
        ),
        child: CircleButtonChange(
          tooltip: active ? 'Ocultar painel' : 'Mostrar painel',
          icon: active
              ? Icons.view_sidebar_rounded
              : Icons.view_sidebar_outlined,
          onPressed: _togglePanel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActiveRoadsCubit>.value(
      value: _cubit,
      child: BlocListener<TenantCubit, TenantState>(
        listener: (context, tenantState) {
          final tenantId = _tenantIdFromTenantState(tenantState);
          _syncTenantAndWarmup(tenantId);
        },
        child: Builder(
          builder: (context) {
            final tenantState = context.watch<TenantCubit>().state;
            final tenantId = _tenantIdFromTenantState(tenantState);

            if (tenantId == null || tenantId.isEmpty) {
              return Scaffold(
                appBar: const UpBar(showPhotoMenu: true),
                body: const Center(
                  child: Text(
                    'Selecione uma empresa para visualizar as rodovias.',
                  ),
                ),
              );
            }

            return Scaffold(
              appBar: UpBar(
                showPhotoMenu: true,
                actions: [
                  _buildPanelToggleButton(),
                ],
              ),
              body: BlocBuilder<ActiveRoadsCubit, ActiveRoadsState>(
                builder: (context, state) {
                  return SplitLayout(
                    left: const ActiveRoadsMap(),
                    right: const ActiveRoadsPanel(),
                    showRightPanel: _showPanel,
                    breakpoint: 980.0,
                    rightPanelWidth: 580.0,
                    bottomPanelHeight: 420.0,
                    showDividers: true,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}