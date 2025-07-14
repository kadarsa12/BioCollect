import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../utils/database_helper.dart';

class ProjectStatsScreen extends StatefulWidget {
  final Projeto projeto;
  const ProjectStatsScreen({super.key, required this.projeto});

  @override
  State<ProjectStatsScreen> createState() => _ProjectStatsScreenState();
}

class _ProjectStatsScreenState extends State<ProjectStatsScreen> {
  bool _loading = true;
  Map<String, int> _metodoCounts = {};
  Map<String, int> _especieCounts = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final pontos = await DatabaseHelper.instance.getPontosByProjeto(widget.projeto.id!);
    Map<String, int> metodoCounts = {};
    Map<String, int> especieCounts = {};

    for (PontoColeta ponto in pontos) {
      final coletas = await DatabaseHelper.instance.getColetasByPonto(ponto.id!);
      for (Coleta coleta in coletas) {
        metodoCounts[coleta.metodologia] = (metodoCounts[coleta.metodologia] ?? 0) + coleta.quantidade;
        especieCounts[coleta.especie] = (especieCounts[coleta.especie] ?? 0) + coleta.quantidade;
      }
    }

    setState(() {
      _metodoCounts = metodoCounts;
      _especieCounts = especieCounts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_metodoCounts.isNotEmpty)
                    _buildBarChart(_metodoCounts, 'Coletas por Metodologia'),
                  if (_especieCounts.isNotEmpty)
                    _buildPieChart(_especieCounts, 'Coletas por Espécie'),
                  if (_metodoCounts.isEmpty && _especieCounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('Nenhum dado coletado'),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildBarChart(Map<String, int> data, String title) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<BarChartGroupData> groups = [];
    for (int i = 0; i < entries.length; i++) {
      groups.add(
        BarChartGroupData(x: i, barRods: [BarChartRodData(toY: entries[i].value.toDouble(), color: Theme.of(context).primaryColor)]),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: groups,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < entries.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(entries[index].key, style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data, String title) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    for (int i = 0; i < entries.length; i++) {
      final color = Colors.primaries[i % Colors.primaries.length];
      sections.add(
        PieChartSectionData(
          value: entries[i].value.toDouble(),
          color: color,
          title: entries[i].key,
          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
