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
  int _currentIndex = 0;
  bool _loading = true;

  // Dados gerais
  Map<String, int> _metodoCounts = {};
  Map<String, int> _especieCounts = {};
  List<PontoColeta> _pontos = [];
  List<Coleta> _todasColetas = [];
  int _totalColetas = 0;
  int _totalPontos = 0;
  int _totalQuantidade = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final pontos = await DatabaseHelper.instance.getPontosByProjeto(widget.projeto.id!);
    Map<String, int> metodoCounts = {};
    Map<String, int> especieCounts = {};
    List<Coleta> todasColetas = [];
    int totalColetas = 0;
    int totalQuantidade = 0;

    for (PontoColeta ponto in pontos) {
      final coletas = await DatabaseHelper.instance.getColetasByPonto(ponto.id!);
      for (Coleta coleta in coletas) {
        // Tratar campos opcionais com valores padrão
        final metodologia = coleta.metodologia ?? 'Metodologia não informada';
        final especie = coleta.especie ?? 'Não identificada';

        metodoCounts[metodologia] = (metodoCounts[metodologia] ?? 0) + coleta.quantidade;
        especieCounts[especie] = (especieCounts[especie] ?? 0) + coleta.quantidade;
        totalColetas++;
        totalQuantidade += coleta.quantidade;
        todasColetas.add(coleta);
      }
    }

    setState(() {
      _metodoCounts = metodoCounts;
      _especieCounts = especieCounts;
      _pontos = pontos;
      _todasColetas = todasColetas;
      _totalColetas = totalColetas;
      _totalPontos = pontos.length;
      _totalQuantidade = totalQuantidade;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
      appBar: AppBar(
        title: const Text('Estatísticas do Projeto'),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF8D6E63)),
      )
          : IndexedStack(
        index: _currentIndex,
        children: [
          _buildOverviewTab(),
          _buildChartsTab(),
          _buildReportsTab(),
          _buildPointsTab(),
          _buildTimelineTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8D6E63),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Resumo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Gráficos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'Relatórios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Pontos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
        ],
      ),
    );
  }

  // ABA 1: RESUMO GERAL
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          if (_metodoCounts.isNotEmpty) _buildQuickBarChart(),
          const SizedBox(height: 16),
          _buildQuickInsights(),
          if (_metodoCounts.isEmpty && _especieCounts.isEmpty) _buildEmptyState(),
        ],
      ),
    );
  }

  // ABA 2: GRÁFICOS DETALHADOS
  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_metodoCounts.isNotEmpty) _buildBarChart(_metodoCounts, 'Quantidade por Metodologia'),
          if (_especieCounts.isNotEmpty) _buildPieChart(_especieCounts, 'Distribuição por Espécie'),
          if (_metodoCounts.isEmpty && _especieCounts.isEmpty) _buildEmptyState(),
        ],
      ),
    );
  }

  // ABA 3: RELATÓRIOS
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReportCard(
            'Resumo por Metodologia',
            Icons.science,
            _buildMethodologyReport(),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            'Top 10 Espécies',
            Icons.pets,
            _buildSpeciesReport(),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            'Estatísticas Gerais',
            Icons.analytics,
            _buildGeneralStats(),
          ),
        ],
      ),
    );
  }

  // ABA 4: POR PONTOS
  Widget _buildPointsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Análise por Ponto de Coleta',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 16),
          ..._pontos.map((ponto) => _buildPointCard(ponto)).toList(),
          if (_pontos.isEmpty) _buildEmptyState(),
        ],
      ),
    );
  }

  // ABA 5: TIMELINE
  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimelineChart(),
          const SizedBox(height: 16),
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Total de Pontos', _totalPontos.toString(), Icons.location_on, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard('Total de Coletas', _totalColetas.toString(), Icons.science, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard('Quantidade Total', _totalQuantidade.toString(), Icons.numbers, const Color(0xFF8D6E63))),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Gráfico de barras simplificado para a aba resumo
  Widget _buildQuickBarChart() {
    final top5 = _metodoCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final limitedData = Map.fromEntries(top5.take(5));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bar_chart, color: Color(0xFF8D6E63), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Top 5 Metodologias',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...limitedData.entries.map((entry) {
              final percentage = (entry.value / _totalQuantidade * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8D6E63)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8D6E63)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    final topEspecie = _especieCounts.entries.isNotEmpty
        ? _especieCounts.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;
    final topMetodo = _metodoCounts.entries.isNotEmpty
        ? _metodoCounts.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insights, color: Color(0xFF8D6E63), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Insights Rápidos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topEspecie != null)
              _buildInsightItem(
                'Espécie mais coletada',
                '${topEspecie.key} (${topEspecie.value} unidades)',
                Icons.pets,
              ),
            if (topMetodo != null)
              _buildInsightItem(
                'Método mais utilizado',
                '${topMetodo.key} (${topMetodo.value} coletas)',
                Icons.science,
              ),
            if (_totalPontos > 0)
              _buildInsightItem(
                'Média por ponto',
                '${(_totalColetas / _totalPontos).toStringAsFixed(1)} coletas/ponto',
                Icons.location_on,
              ),
            _buildInsightItem(
              'Diversidade',
              '${_especieCounts.length} espécies diferentes',
              Icons.diversity_3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8D6E63)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Gráfico de pizza melhorado com layout responsivo
  Widget _buildPieChart(Map<String, int> data, String title) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Cores vibrantes para o gráfico de pizza
    final colors = [
      const Color(0xFF8D6E63),
      const Color(0xFF1976D2),
      const Color(0xFF388E3C),
      const Color(0xFFFF8F00),
      const Color(0xFF7B1FA2),
      const Color(0xFF00796B),
      const Color(0xFFD32F2F),
      const Color(0xFF455A64),
      const Color(0xFF689F38),
      const Color(0xFFF57C00),
    ];

    List<PieChartSectionData> sections = [];
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);

    for (int i = 0; i < entries.length && i < 10; i++) {
      final percentage = (entries[i].value / total * 100);
      sections.add(
        PieChartSectionData(
          value: entries[i].value.toDouble(),
          color: colors[i % colors.length],
          title: percentage >= 3 ? '${percentage.toStringAsFixed(1)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          radius: 80,
          titlePositionPercentageOffset: 0.8,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Color(0xFF8D6E63),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Layout melhorado para o gráfico de pizza
            Column(
              children: [
                // Gráfico centralizado
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Legenda abaixo do gráfico
                _buildPieChartLegend(entries, colors, total),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartLegend(List<MapEntry<String, int>> entries, List<Color> colors, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Legenda',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Grid de legendas para melhor uso do espaço
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: entries.take(10).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final percentage = (data.value / total * 100);

            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.key,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${data.value} (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (entries.length > 10)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${entries.length - 10} outras espécies',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReportCard(String title, IconData icon, Widget content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF8D6E63), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildMethodologyReport() {
    final sorted = _metodoCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((entry) {
        final percentage = (_metodoCounts[entry.key]! / _totalQuantidade * 100);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.value} unidades',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpeciesReport() {
    final sorted = _especieCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sorted.take(10).toList();

    return Column(
      children: top10.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final data = entry.value;
        final percentage = (data.value / _totalQuantidade * 100);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.key,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${data.value}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGeneralStats() {
    return Column(
      children: [
        _buildStatRow('Total de Pontos', _totalPontos.toString()),
        _buildStatRow('Total de Coletas', _totalColetas.toString()),
        _buildStatRow('Quantidade Total', _totalQuantidade.toString()),
        _buildStatRow('Espécies Diferentes', _especieCounts.length.toString()),
        _buildStatRow('Metodologias Usadas', _metodoCounts.length.toString()),
        if (_totalPontos > 0)
          _buildStatRow('Média por Ponto', (_totalColetas / _totalPontos).toStringAsFixed(1)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8D6E63))),
        ],
      ),
    );
  }

  Widget _buildPointCard(PontoColeta ponto) {
    return FutureBuilder<List<Coleta>>(
      future: DatabaseHelper.instance.getColetasByPonto(ponto.id!),
      builder: (context, snapshot) {
        final coletas = snapshot.data ?? [];
        final totalQuantidade = coletas.fold<int>(0, (sum, c) => sum + c.quantidade);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: const Color(0xFF8D6E63)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ponto.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPointStat('Coletas', coletas.length.toString()),
                    _buildPointStat('Quantidade', totalQuantidade.toString()),
                    _buildPointStat('Espécies', coletas.map((c) => c.especie ?? 'Não identificada').toSet().length.toString()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPointStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8D6E63),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineChart() {
    // Agrupar coletas por data
    Map<DateTime, int> coletasPorData = {};
    for (final coleta in _todasColetas) {
      final data = DateTime(coleta.dataHora.year, coleta.dataHora.month, coleta.dataHora.day);
      coletasPorData[data] = (coletasPorData[data] ?? 0) + 1;
    }

    final sortedDates = coletasPorData.keys.toList()..sort();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timeline, color: Color(0xFF8D6E63), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Atividade ao Longo do Tempo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (sortedDates.isNotEmpty)
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: sortedDates.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), coletasPorData[entry.value]!.toDouble());
                        }).toList(),
                        isCurved: true,
                        color: const Color(0xFF8D6E63),
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF8D6E63).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(
                child: Text('Nenhum dado temporal disponível'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final sortedColetas = List<Coleta>.from(_todasColetas)
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final recent = sortedColetas.take(10).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: Color(0xFF8D6E63), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Atividades Recentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recent.map((coleta) => _buildActivityItem(coleta)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Coleta coleta) {
    // Tratar campos opcionais
    final especie = coleta.especie ?? 'Não identificada';
    final metodologia = coleta.metodologia ?? 'Não informada';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF8D6E63),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  especie,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${coleta.quantidade} unidades - $metodologia',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${coleta.dataHora.day}/${coleta.dataHora.month}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Gráfico de barras para a aba de gráficos detalhados
  Widget _buildBarChart(Map<String, int> data, String title) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Cores personalizadas para o gráfico de barras
    final colors = [
      const Color(0xFF8D6E63),
      const Color(0xFF5D4037),
      const Color(0xFFA1887F),
      const Color(0xFF6D4C41),
      const Color(0xFF795548),
    ];

    List<BarChartGroupData> groups = [];
    for (int i = 0; i < entries.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entries[i].value.toDouble(),
              color: colors[i % colors.length],
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            )
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Color(0xFF8D6E63),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: entries.isNotEmpty ? entries.first.value.toDouble() * 1.2 : 0,
                  barGroups: groups,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: entries.isNotEmpty ? entries.first.value / 5 : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < entries.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                entries[index].key,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legenda
            _buildBarChartLegend(entries, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartLegend(List<MapEntry<String, int>> entries, List<Color> colors) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${data.key}: ${data.value}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum dado coletado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione coletas aos pontos para\nvisualizar as estatísticas',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}