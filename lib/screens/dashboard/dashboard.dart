import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import '../../_datas/user/user_data.dart';
import '../../_widgets/background/backgroundCleaner.dart';
import '../networkOfRoads/charts/barChartSample.dart';
import '../networkOfRoads/charts/pieChartSample.dart';

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
                    future: contractsBloc.getAllContractsValue(),
                      builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                        return SummaryCard(title: 'Contratos em Andamento', value: 'R\$ ${snapshot.data.toString()}');
                      }
                    ),
                    FutureBuilder<double>(
                        future: contractsBloc.getAllContractsValue(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        return SummaryCard(title: 'Contratos Concluídos', value: 'R\$ ${snapshot.data.toString()}');
                      }
                    ),
                    FutureBuilder(
                        future: contractsBloc.getAllContractsValue(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        return SummaryCard(title: 'Demandas em Projeto', value: 'R\$ ${snapshot.data.toString()}');
                      }
                    ),
                    FutureBuilder(
                        future: contractsBloc.getAllContractsValue(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          return SummaryCard(title: 'Demandas Críticas', value: 'R\$ ${snapshot.data.toString()}');
                        }
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Gráficos de Pizza
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(3, (index) {
                    return SizedBox(
                      width: screenWidth >= 1200
                          ? screenWidth / 3 - 32
                          : screenWidth > 800
                          ? screenWidth / 2 - 24
                          : screenWidth - 32,
                      child: const Card(
                        color: Colors.white,
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 200,
                            child: PieChartSample(),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Gráfico de Barras

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(2, (index) {
                    return SizedBox(
                      width: screenWidth >= 1200
                          ? screenWidth / 2 - 32
                          : screenWidth > 800
                          ? screenWidth / 1 - 24
                          : screenWidth - 32,
                      child: const Card(
                        color: Colors.white,
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 200,
                            child: BarChartSample(),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Gráfico de Linha
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: const Card(
                  color: Colors.white,
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 200,
                      child: LineChartSample(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const SummaryCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

class LineChartSample extends StatelessWidget {
  const LineChartSample({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 1),
              const FlSpot(1, 3),
              const FlSpot(2, 10),
              const FlSpot(3, 7),
              const FlSpot(4, 12),
              const FlSpot(5, 13),
            ],
            isCurved: true,
            barWidth: 3,
            color: Colors.blue,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
