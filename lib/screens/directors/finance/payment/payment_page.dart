import 'package:flutter/cupertino.dart';
import '../../../../_widgets/input/custom_text_field.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
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
