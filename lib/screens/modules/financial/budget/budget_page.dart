import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/financial/budget/budget_cubit.dart';
import 'package:siged/_blocs/modules/financial/budget/budget_state.dart';

import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/screens/modules/financial/budget/budget_form_section.dart';

import 'budget_table_section.dart';

class BudgetPage extends StatefulWidget {
  final ProcessData? contractData;

  const BudgetPage({
    super.key,
    required this.contractData,
  });

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final NumberFormat _currency =
  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final contractId = widget.contractData?.id?.trim();
      final cubit = context.read<BudgetCubit>();

      if (contractId != null && contractId.isNotEmpty) {
        await cubit.loadByContract(contractId);
      } else {
        await cubit.loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, st) {
        final isLoading = st.status == BudgetStatus.loading;

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
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: BudgetFormSection(currency: _currency),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: BudgetTableSection(
                            items: st.items,
                            selected: st.selected,
                            currency: _currency,
                            onSelect: (e) =>
                                context.read<BudgetCubit>().select(e),

                            // ✅ ISSO AQUI faz aparecer a coluna "APAGAR"
                            onDelete: (e) async {
                              context.read<BudgetCubit>().select(e);
                              await context.read<BudgetCubit>().deleteSelected();
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

            // overlay “carregando”
            if (isLoading)
              const Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: SizedBox.shrink(),
                ),
              ),
          ],
        );
      },
    );
  }
}
