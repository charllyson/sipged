import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/financial/budget/budget_cubit.dart';
import 'package:sipged/_blocs/modules/financial/budget/budget_state.dart';

import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'package:sipged/screens/modules/financial/budget/budget_form_section.dart';
import 'package:sipged/screens/modules/financial/budget/budget_table_section.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({
    super.key,
    this.contractData,
  });

  final ContractData? contractData;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
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
  void didUpdateWidget(covariant BudgetPage oldWidget) {
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

      final cubit = context.read<BudgetCubit>();

      if (_contractId != null) {
        await cubit.loadByContract(_contractId!);
      } else {
        await cubit.loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, st) {
        final isInitialLoading =
            st.status == BudgetStatus.loading && st.items.isEmpty;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(text: 'Cadastrar orçamento'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: BudgetFormSection(
                            currency: _currency,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: BudgetTableSection(
                            items: st.items,
                            selected: st.selected,
                            currency: _currency,
                            onSelect: (e) {
                              context.read<BudgetCubit>().select(e);
                            },
                            onDelete: (e) async {
                              final cubit = context.read<BudgetCubit>();

                              cubit.select(e);
                              await cubit.deleteSelected();
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                const FootBar(),
              ],
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
    );
  }
}