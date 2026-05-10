import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_cubit.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_state.dart';
import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/screens/modules/financial/empenhos/empenho_form_section.dart';
import 'package:sipged/screens/modules/financial/empenhos/empenho_table_section.dart';

class EmpenhoPage extends StatefulWidget {
  const EmpenhoPage({
    super.key,
    this.contractData,
  });

  final ContractData? contractData;

  @override
  State<EmpenhoPage> createState() => _EmpenhoPageState();
}

class _EmpenhoPageState extends State<EmpenhoPage> {
  final NumberFormat _currency =
  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool _initialized = false;

  String? get _contractId {
    final value = widget.contractData?.id?.trim();

    if (value == null || value.isEmpty) return null;

    return value;
  }

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  @override
  void didUpdateWidget(covariant EmpenhoPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.contractData?.id?.trim() ?? '';
    final newId = widget.contractData?.id?.trim() ?? '';

    if (oldId != newId) {
      _initialized = false;
      _initLoad();
    }
  }

  void _initLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _initialized) return;

      _initialized = true;

      final permissionState = context.read<PermissionCubit>().state;

      await context.read<EmpenhoCubit>().updatePermissions(
        permissions: permissionState.current,
        tenantId: permissionState.activeTenantId,
        reload: false,
      );

      if (!mounted) return;

      await context.read<EmpenhoCubit>().init(
        contractId: _contractId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PermissionCubit, PermissionState>(
      listenWhen: (previous, current) {
        return previous.current != current.current ||
            previous.activeTenantId != current.activeTenantId;
      },
      listener: (context, permissionState) {
        context.read<EmpenhoCubit>().updatePermissions(
          permissions: permissionState.current,
          tenantId: permissionState.activeTenantId,
          reload: true,
        );
      },
      child: BlocBuilder<EmpenhoCubit, EmpenhoState>(
        builder: (context, st) {
          final isInitialLoading =
              st.status == EmpenhoStatus.loading && st.items.isEmpty;

          return Stack(
            children: [
              const BackgroundChange(),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (st.error != null && st.error!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Material(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    st.error!,
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: EmpenhoFormSection(
                        currency: _currency,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: EmpenhoTableSection(
                        items: st.items,
                        selected: st.selected,
                        currency: _currency,
                        onSelect: (e) {
                          context.read<EmpenhoCubit>().select(e);
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              if (isInitialLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x11FFFFFF),
                    child: Center(
                      child: LoadingTreeDots(size: 90),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}