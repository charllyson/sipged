import 'package:flutter/cupertino.dart';
import '../../../../_widgets/input/custom_text_field.dart';

class DashboardFinancialPage extends StatefulWidget {
  const DashboardFinancialPage({super.key});

  @override
  State<DashboardFinancialPage> createState() => _DashboardFinancialPageState();
}

class _DashboardFinancialPageState extends State<DashboardFinancialPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: const [
          CustomTextField(labelText: 'Vigência inicial do contrato'),
          CustomTextField(labelText: 'Em dias'),
          CustomTextField(labelText: 'Vigência inicial de execução'),
          CustomTextField(labelText: 'Em dias'),
          CustomTextField(labelText: 'Vigência do contrato pós aditivos'),
          CustomTextField(labelText: 'Em dias'),
          CustomTextField(labelText: 'Vigência de execução pós aditivos'),
          CustomTextField(labelText: 'Em dias'),
        ],
      ),
    );
  }
}
