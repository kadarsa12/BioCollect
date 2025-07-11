import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../providers/project_provider.dart';
import '../providers/user_provider.dart';
import '../utils/excel_exporter.dart';
import 'create_ponto_screen.dart';
import 'ponto_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Projeto projeto;

  ProjectDetailScreen({required this.projeto});

  @override
  _ProjectDetailScreenState createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadPontos();
  }

  Future<void> _loadPontos() async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    await projectProvider.loadPontosByProjeto(widget.projeto.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projeto.nome),
        actions: [
          // Botão de Export Excel
          IconButton(
            icon: _isExporting
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Icon(Icons.table_chart),
            onPressed: _isExporting ? null : _exportToExcel,
            tooltip: 'Exportar Excel',
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showProjectInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Card com estatísticas do projeto
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Consumer<ProjectProvider>(
                builder: (context, projectProvider, child) {
                  final totalPontos = projectProvider.pontosColeta.length;
                  int totalColetas = 0;
                  int pontosAbertos = 0;

                  for (final ponto in projectProvider.pontosColeta) {
                    if (ponto.status.value == 'ABERTO') pontosAbertos++;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Estatísticas do Projeto',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard('Pontos', totalPontos.toString(), Icons.location_on),
                          _buildStatCard('Abertos', pontosAbertos.toString(), Icons.circle, Colors.green),
                          _buildStatCard('Fechados', (totalPontos - pontosAbertos).toString(), Icons.circle, Colors.grey),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Lista de pontos
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, projectProvider, child) {
                if (projectProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (projectProvider.pontosColeta.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum ponto de coleta',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Toque no + para criar o primeiro ponto',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadPontos,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: projectProvider.pontosColeta.length,
                    itemBuilder: (context, index) {
                      final ponto = projectProvider.pontosColeta[index];
                      return _buildPontoCard(ponto);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreatePontoScreen(projeto: widget.projeto),
            ),
          ).then((_) => _loadPontos());
        },
        child: Icon(Icons.add_location),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.blue,
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

  Widget _buildPontoCard(PontoColeta ponto) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ponto.status.value == 'ABERTO' ? Colors.green : Colors.grey,
          child: Icon(
            Icons.location_on,
            color: Colors.white,
          ),
        ),
        title: Text(
          ponto.nome,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ponto.latitude != 0.0 && ponto.longitude != 0.0)
              Text('${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}')
            else
              Text('Coordenadas não informadas', style: TextStyle(color: Colors.orange)),
            Text('${ponto.dataHora.day}/${ponto.dataHora.month}/${ponto.dataHora.year} - ${ponto.status.value}'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PontoDetailScreen(
                ponto: ponto,
                projeto: widget.projeto,
              ),
            ),
          ).then((_) => _loadPontos());
        },
      ),
    );
  }

  Future<void> _exportToExcel() async {
    // Verificar se tem dados para exportar
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

    if (projectProvider.pontosColeta.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Projeto Vazio'),
            ],
          ),
          content: Text('Este projeto não possui pontos de coleta para exportar.\n\nCrie pelo menos um ponto antes de exportar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: usuário não encontrado')),
        );
        return;
      }

      final filePath = await ExcelExporter.exportProject(widget.projeto, user);

      if (filePath != null) {
        _showExportSuccessDialog(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar arquivo Excel')),
        );
      }
    } catch (e) {
      print('Erro no export: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar: $e')),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showExportSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Concluído'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arquivo Excel gerado com sucesso!'),
            SizedBox(height: 8),
            Text(
              'Nome: ${filePath.split('/').last}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ExcelExporter.shareFile(filePath);
            },
            icon: Icon(Icons.share),
            label: Text('Compartilhar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Informações do Projeto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${widget.projeto.nome}'),
            SizedBox(height: 8),
            Text('Grupo: ${widget.projeto.grupoBiologico.displayName}'),
            SizedBox(height: 8),
            Text('Campanha: ${widget.projeto.campanha}'),
            SizedBox(height: 8),
            Text('Período: ${widget.projeto.periodo}'),
            SizedBox(height: 8),
            Text('Município: ${widget.projeto.municipio}'),
            SizedBox(height: 8),
            Text('Criado: ${widget.projeto.dataInicio.day}/${widget.projeto.dataInicio.month}/${widget.projeto.dataInicio.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }
}