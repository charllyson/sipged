import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_cubit.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_state.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

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

  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _initialized) return;

      _initialized = true;

      final contractId = widget.contractData?.id?.trim();

      await context.read<EmpenhoCubit>().init(
        contractId:
        contractId == null || contractId.isEmpty ? null : contractId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UpBar(),
      body: BlocBuilder<EmpenhoCubit, EmpenhoState>(
        builder: (context, st) {
          return Stack(
            children: [
              BackgroundChange(),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: EmpenhoFormSection(currency: _currency),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: EmpenhoTableSection(
                        items: st.items,
                        selected: st.selected,
                        currency: _currency,
                        onSelect: (e) {
                          context.read<EmpenhoCubit>().select(e);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}