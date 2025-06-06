import 'package:flutter/material.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import '../../../_datas/user/user_data.dart';
import '../../../_widgets/background/background_cleaner.dart';
import '../../../_widgets/charts/charts_class.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.userData});
  final UserData? userData;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  ContractsBloc contractsBloc = ContractsBloc();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        BackgroundCleaner(),
        SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.count(
                  crossAxisCount: screenWidth > 800 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3,
                  children: [
                    FutureBuilder<double>(
                    future: contractsBloc.getAllContractsfilterStatus('EM ANDAMENTO'),
                      builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                        return SummaryCard(title: 'Contratos em Andamento', value: '${priceToString(snapshot.data)}');
                      }
                    ),
                    FutureBuilder<double>(
                        future: contractsBloc.getAllContractsfilterStatus('CONCLUÍDO'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        return SummaryCard(title: 'Contratos Concluídos', value: '${priceToString(snapshot.data)}');
                      }
                    ),
                    FutureBuilder(
                        future: contractsBloc.getAllContractsfilterStatus('EM PROJETO'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        return SummaryCard(title: 'Demandas em Projeto', value: '${priceToString(snapshot.data)}');
                      }
                    ),
                    FutureBuilder(
                        future: contractsBloc.getAllContractsfilterStatus('PARALISADO'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          return SummaryCard(title: 'Demandas Paralisadas', value: '${priceToString(snapshot.data)}');
                        }
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


