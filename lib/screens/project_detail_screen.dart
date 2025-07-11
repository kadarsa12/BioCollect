import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../providers/project_provider.dart';
import '../providers/user_provider.dart';
import '../utils/excel_exporter.dart';
import '../utils/database_helper.dart';
import 'create_ponto_screen.dart';
import 'ponto_detail_screen.dart';
import 'project_map_screen.dart';
import 'manage_metodologias_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Projeto projeto;

  ProjectDetailScreen({required this.projeto});

  @override
  _ProjectDetailScreenState createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isExporting = false;
  bool _isDeleting = false; // Nova variável
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadPontos();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPontos() async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    await projectProvider.loadPontosByProjeto(widget.projeto.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4), // Fundo mais suave
      body: CustomScrollView(
        slivers: [
          // AppBar moderna com gradiente
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8D6E63),
                      Color(0xFF5D4037),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.projeto.nome,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    widget.projeto.grupoBiologico.displayName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              // Menu de ações expandido com exclusão
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value),
                icon: Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'metodologias',
                    child: Row(
                      children: [
                        Icon(Icons.science, color: Color(0xFF8D6E63), size: 20),
                        SizedBox(width: 12),
                        Text('Gerenciar Métodos'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'mapa',
                    child: Row(
                      children: [
                        Icon(Icons.map, color: Color(0xFF8D6E63), size: 20),
                        SizedBox(width: 12),
                        Text('Ver Mapa'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        _isExporting
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF8D6E63),
                          ),
                        )
                            : Icon(Icons.table_chart, color: Color(0xFF8D6E63), size: 20),
                        SizedBox(width: 12),
                        Text(_isExporting ? 'Exportando...' : 'Exportar Excel'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF8D6E63), size: 20),
                        SizedBox(width: 12),
                        Text('Informações'),
                      ],
                    ),
                  ),
                  // NOVA SEÇÃO - Divisor e exclusão
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        _isDeleting
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                            : Icon(Icons.delete_forever, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text(
                          _isDeleting ? 'Excluindo...' : 'Excluir Projeto',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Resto do build continua igual...
          // Conteúdo principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Card de estatísticas melhorado
                  _buildStatsCard(),

                  // Header da lista de pontos
                  _buildSectionHeader(),
                ],
              ),
            ),
          ),

          // Lista de pontos
          Consumer<ProjectProvider>(
            builder: (context, projectProvider, child) {
              if (projectProvider.isLoading) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                  ),
                );
              }

              if (projectProvider.pontosColeta.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final ponto = projectProvider.pontosColeta[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _buildPontoCard(ponto, index),
                      ),
                    );
                  },
                  childCount: projectProvider.pontosColeta.length,
                ),
              );
            },
          ),

          // Espaçamento para o FAB
          SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreatePontoScreen(projeto: widget.projeto),
            ),
          ).then((_) => _loadPontos());
        },
        label: Text('Novo Ponto'),
        icon: Icon(Icons.add_location),
        backgroundColor: Color(0xFF5D4037),
        foregroundColor: Colors.white,
      ),
    );
  }
  // Continuação da Parte 1...

  Widget _buildStatsCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8D6E63).withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          final totalPontos = projectProvider.pontosColeta.length;
          int pontosAbertos = 0;
          int totalColetas = 0;

          for (final ponto in projectProvider.pontosColeta) {
            if (ponto.status.value == 'ABERTO') pontosAbertos++;
            // Aqui você pode adicionar a lógica para contar coletas se necessário
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF8D6E63).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: Color(0xFF8D6E63),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Estatísticas do Projeto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total de Pontos',
                      totalPontos.toString(),
                      Icons.location_on,
                      Color(0xFF8D6E63),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Abertos',
                      pontosAbertos.toString(),
                      Icons.radio_button_checked,
                      Colors.green,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Fechados',
                      (totalPontos - pontosAbertos).toString(),
                      Icons.radio_button_unchecked,
                      Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Color(0xFF8D6E63),
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Pontos de Coleta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Nenhum ponto de coleta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Toque em "Novo Ponto" para criar\no primeiro ponto de coleta',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPontoCard(PontoColeta ponto, int index) {
    final isAberto = ponto.status.value == 'ABERTO';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8D6E63).withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de status
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isAberto ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isAberto ? Colors.green : Colors.grey).withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),

                // Conteúdo principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ponto.nome,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAberto ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ponto.status.value,
                              style: TextStyle(
                                color: isAberto ? Colors.green : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Coordenadas
                      if (ponto.latitude != 0.0 && ponto.longitude != 0.0)
                        Row(
                          children: [
                            Icon(Icons.my_location, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              '${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.location_off, size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'Coordenadas não informadas',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: 4),

                      // Data
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            '${ponto.dataHora.day}/${ponto.dataHora.month}/${ponto.dataHora.year}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Seta
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Continuação da Parte 2...

  void _handleMenuAction(String action) {
    switch (action) {
      case 'metodologias':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ManageMetodologiasScreen(projeto: widget.projeto),
          ),
        );
        break;
      case 'mapa':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectMapScreen(projeto: widget.projeto),
          ),
        );
        break;
      case 'export':
        if (!_isExporting) _exportToExcel();
        break;
      case 'info':
        _showProjectInfo();
        break;
      case 'delete': // NOVA AÇÃO
        if (!_isDeleting) _confirmarDeleteProjeto();
        break;
    }
  }

  // NOVA FUNÇÃO - Confirmação de exclusão
  Future<void> _confirmarDeleteProjeto() async {
    // Contar pontos e coletas
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final totalPontos = projectProvider.pontosColeta.length;

    int totalColetas = 0;
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM coletas c
        INNER JOIN pontos_coleta p ON c.ponto_coleta_id = p.id
        WHERE p.projeto_id = ?
      ''', [widget.projeto.id]);

      totalColetas = result.first['count'] as int;
    } catch (e) {
      print('Erro ao contar coletas: $e');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Excluir Projeto',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta ação NÃO pode ser desfeita!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Será excluído permanentemente:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.folder, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(child: Text('1 projeto: ${widget.projeto.nome}')),
                    ],
                  ),
                  if (totalPontos > 0) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('$totalPontos pontos de coleta'),
                      ],
                    ),
                  ],
                  if (totalColetas > 0) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.science, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('$totalColetas coletas registradas'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (totalColetas > 0) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recomendamos exportar os dados para Excel antes de excluir.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
          if (totalColetas > 0)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _exportToExcel();
              },
              icon: Icon(Icons.table_chart, size: 16),
              label: Text('Exportar Primeiro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ElevatedButton.icon(
            onPressed: () => _executarDeleteProjeto(context),
            icon: Icon(Icons.delete_forever, size: 16),
            label: Text('Excluir Tudo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // NOVA FUNÇÃO - Execução da exclusão
  Future<void> _executarDeleteProjeto(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);

    setState(() {
      _isDeleting = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Excluindo projeto...'),
          ],
        ),
      ),
    );

    try {
      final db = await DatabaseHelper.instance.database;

      // Excluir em cascata
      await db.rawDelete('''
        DELETE FROM coletas 
        WHERE ponto_coleta_id IN (
          SELECT id FROM pontos_coleta WHERE projeto_id = ?
        )
      ''', [widget.projeto.id]);

      await db.delete(
        'pontos_coleta',
        where: 'projeto_id = ?',
        whereArgs: [widget.projeto.id],
      );

      await db.delete(
        'projetos',
        where: 'id = ?',
        whereArgs: [widget.projeto.id],
      );

      // Recarregar lista de projetos
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.loadProjetos();

      Navigator.pop(context); // Fechar loading
      Navigator.pop(context); // Voltar para lista

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Projeto "${widget.projeto.nome}" excluído'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir projeto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Continuação da Parte 3...

  Future<void> _exportToExcel() async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

    if (projectProvider.pontosColeta.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Projeto Vazio'),
            ],
          ),
          content: Text(
            'Este projeto não possui pontos de coleta para exportar.\n\nCrie pelo menos um ponto antes de exportar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF8D6E63),
              ),
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
          SnackBar(
            content: Text('Erro: usuário não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final filePath = await ExcelExporter.exportProject(widget.projeto, user);

      if (filePath != null) {
        _showExportSuccessDialog(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar arquivo Excel'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erro no export: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar: $e'),
          backgroundColor: Colors.red,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                filePath.split('/').last,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF8D6E63)),
            SizedBox(width: 8),
            Text('Informações do Projeto'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Nome', widget.projeto.nome),
            _buildInfoRow('Grupo', widget.projeto.grupoBiologico.displayName),
            _buildInfoRow('Campanha', widget.projeto.campanha),
            _buildInfoRow('Período', widget.projeto.periodo),
            _buildInfoRow('Município', widget.projeto.municipio),
            _buildInfoRow(
              'Criado',
              '${widget.projeto.dataInicio.day}/${widget.projeto.dataInicio.month}/${widget.projeto.dataInicio.year}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF8D6E63),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Color(0xFF5D4037),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// FIM DA CLASSE