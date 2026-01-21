import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/financial/empenhos/empenho_cubit.dart';
import 'package:siged/_blocs/modules/financial/empenhos/empenho_state.dart';

import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'empenho_form_section.dart';
import 'empenho_table_section.dart';

class EmpenhoPage extends StatefulWidget {
  final ProcessData? contractData;

  const EmpenhoPage({
    super.key,
    required this.contractData,
  });

  @override
  State<EmpenhoPage> createState() => _EmpenhoPageState();
}

class _EmpenhoPageState extends State<EmpenhoPage> {
  final NumberFormat _currency =
  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final contractId = widget.contractData?.id?.trim();
      final cubit = context.read<EmpenhoCubit>();

      if (contractId != null && contractId.isNotEmpty) {
        await cubit.loadByContract(contractId);
      } else {
        await cubit.loadAll();
      }

      // Se quiser pré-definir companyId/companyLabel pelo contrato, faça aqui:
      // final companyId = widget.contractData?.companyId;
      // final companyLabel = widget.contractData?.companyName;
      // if ((companyId ?? '').trim().isNotEmpty) {
      //   cubit.setCompanyId(companyId!.trim());
      //   cubit.setCompanyLabel((companyLabel ?? '').trim());
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpenhoCubit, EmpenhoState>(
      builder: (context, st) {
        final isLoading = st.status == EmpenhoStatus.loading;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(text: 'Cadastrar empenho'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: EmpenhoFormSection(currency: _currency),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: EmpenhoTableSection(
                            items: st.items,
                            selected: st.selected,
                            currency: _currency,
                            onSelect: (e) =>
                                context.read<EmpenhoCubit>().select(e),
                            // se quiser deletar por linha:
                            // onDelete: (e) async {
                            //   context.read<EmpenhoCubit>().select(e);
                            //   await context.read<EmpenhoCubit>().deleteSelected();
                            // },
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
