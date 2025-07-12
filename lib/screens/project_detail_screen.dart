import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../providers/project_provider.dart';
import '../providers/user_provider.dart';
import '../utils/excel_exporter.dart';
import '../utils/database_helper.dart';
import '../models/enums.dart'; // Para StatusProjeto
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
  bool _isDeleting = false;
  bool _isUpdatingStatus = false; // NOVO
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Projeto _projeto; // NOVO - para atualizar o status localmente

  @override
  void initState() {
    super.initState();
    _projeto = widget.projeto; // NOVO
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
    await projectProvider.loadPontosByProjeto(_projeto.id!);
  }

  @override
  Widget build(BuildContext context) {
    final isAberto = _projeto.status == StatusProjeto.aberto;

    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      body: CustomScrollView(
        slivers: [
          // AppBar moderna com gradiente baseado no status
          SliverAppBar(
            expandedHeight: 140, // AUMENTADO para caber o status
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isAberto
                        ? [Colors.green, Colors.green.shade700]
                        : [Colors.grey.shade600, Colors.grey.shade800],
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
                    _projeto.nome,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _projeto.grupoBiologico.displayName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // NOVO - Badge de status
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          _projeto.status.value.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              // NOVO - Botão de status rápido
              if (!_isUpdatingStatus)
                IconButton(
                  onPressed: () => _toggleStatusProjeto(),
                  icon: Icon(
                    isAberto ? Icons.lock_open : Icons.lock,
                    color: Colors.white,
                  ),
                  tooltip: isAberto ? 'Fechar Projeto' : 'Abrir Projeto',
                )
              else
                Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Menu de ações expandido
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value),
                icon: Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  // NOVA SEÇÃO - Status
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        _isUpdatingStatus
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isAberto ? Colors.red : Colors.green,
                          ),
                        )
                            : Icon(
                          isAberto ? Icons.lock : Icons.lock_open,
                          color: isAberto ? Colors.red : Colors.green,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          isAberto ? 'Fechar Projeto' : 'Abrir Projeto',
                          style: TextStyle(
                            color: isAberto ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),

                  // Outras opções
                  PopupMenuItem(
                    value: 'metodologias',
                    enabled: isAberto, // SÓ DISPONÍVEL SE ABERTO
                    child: Row(
                      children: [
                        Icon(
                          Icons.science,
                          color: isAberto ? Color(0xFF8D6E63) : Colors.grey,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Gerenciar Métodos',
                          style: TextStyle(
                            color: isAberto ? null : Colors.grey,
                          ),
                        ),
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

          // Conteúdo principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // NOVO - Card de status se fechado
                  if (!isAberto) _buildClosedProjectCard(),

                  // Card de estatísticas
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
      floatingActionButton: isAberto
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreatePontoScreen(projeto: _projeto),
            ),
          ).then((_) => _loadPontos());
        },
        label: Text('Novo Ponto'),
        icon: Icon(Icons.add_location),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      )
          : null, // SEM FAB SE PROJETO FECHADO
    );
  }

  // NOVO - Card para projeto fechado
  Widget _buildClosedProjectCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lock,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projeto Fechado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  'Não é possível adicionar novos pontos ou modificar dados',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_projeto.dataFechamento != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Fechado em ${_projeto.dataFechamento!.day}/${_projeto.dataFechamento!.month}/${_projeto.dataFechamento!.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _toggleStatusProjeto(),
            icon: Icon(Icons.lock_open, size: 16),
            label: Text('Reabrir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // NOVA FUNÇÃO - Toggle status do projeto
  Future<void> _toggleStatusProjeto() async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      final novoStatus = _projeto.status == StatusProjeto.aberto
          ? StatusProjeto.fechado
          : StatusProjeto.aberto;

      final dataFechamento = novoStatus == StatusProjeto.fechado
          ? DateTime.now()
          : null;

      await db.update(
        'projetos',
        {
          'status': novoStatus.value,
          'data_fechamento': dataFechamento?.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [_projeto.id],
      );

      // Atualizar objeto local
      setState(() {
        _projeto = Projeto(
          id: _projeto.id,
          nome: _projeto.nome,
          grupoBiologico: _projeto.grupoBiologico,
          campanha: _projeto.campanha,
          periodo: _projeto.periodo,
          municipio: _projeto.municipio,
          usuarioId: _projeto.usuarioId,
          dataInicio: _projeto.dataInicio,
          status: novoStatus,
          dataFechamento: dataFechamento,
        );
      });

      // Recarregar lista de projetos
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.loadProjetos();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                novoStatus == StatusProjeto.fechado ? Icons.lock : Icons.lock_open,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Projeto ${novoStatus == StatusProjeto.fechado ? "fechado" : "reaberto"}',
              ),
            ],
          ),
          backgroundColor: novoStatus == StatusProjeto.fechado ? Colors.orange : Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

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
                      'Status',
                      _projeto.status.value,
                      _projeto.status == StatusProjeto.aberto ? Icons.lock_open : Icons.lock,
                      _projeto.status == StatusProjeto.aberto ? Colors.green : Colors.grey,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Criado em',
                      '${_projeto.dataInicio.day}/${_projeto.dataInicio.month}/${_projeto.dataInicio.year}',
                      Icons.calendar_today,
                      Color(0xFF8D6E63),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
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
    final isAberto = _projeto.status == StatusProjeto.aberto;

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
            isAberto
                ? 'Toque em "Novo Ponto" para criar\no primeiro ponto de coleta'
                : 'Este projeto está fechado.\nReabra para adicionar pontos.',
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
                  projeto: _projeto,
                ),
              ),
            ).then((_) => _loadPontos());
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone de localização
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF8D6E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Color(0xFF8D6E63),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),

                // Conteúdo principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ponto.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF5D4037),
                        ),
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'toggle_status':
        _toggleStatusProjeto();
        break;
      case 'metodologias':
        if (_projeto.status == StatusProjeto.aberto) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ManageMetodologiasScreen(projeto: _projeto),
            ),
          );
        }
        break;
      case 'mapa':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectMapScreen(projeto: _projeto),
          ),
        );
        break;
      case 'export':
        if (!_isExporting) _exportToExcel();
        break;
      case 'info':
        _showProjectInfo();
        break;
      case 'delete':
        if (!_isDeleting) _confirmarDeleteProjeto();
        break;
    }
  }

  // Continuar com o resto dos métodos...
  Future<void> _confirmarDeleteProjeto() async {
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
      ''', [_projeto.id]);

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
                      Expanded(child: Text('1 projeto: ${_projeto.nome}')),
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

      await db.rawDelete('''
        DELETE FROM coletas 
        WHERE ponto_coleta_id IN (
          SELECT id FROM pontos_coleta WHERE projeto_id = ?
        )
      ''', [_projeto.id]);

      await db.delete(
        'pontos_coleta',
        where: 'projeto_id = ?',
        whereArgs: [_projeto.id],
      );

      await db.delete(
        'projetos',
        where: 'id = ?',
        whereArgs: [_projeto.id],
      );

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
              Text('Projeto "${_projeto.nome}" excluído'),
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

      final filePath = await ExcelExporter.exportProject(_projeto, user);

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
            _buildInfoRow('Nome', _projeto.nome),
            _buildInfoRow('Grupo', _projeto.grupoBiologico.displayName),
            _buildInfoRow('Campanha', _projeto.campanha),
            _buildInfoRow('Período', _projeto.periodo),
            _buildInfoRow('Município', _projeto.municipio),
            _buildInfoRow('Status', _projeto.status.value.toUpperCase()),
            _buildInfoRow(
              'Criado',
              '${_projeto.dataInicio.day}/${_projeto.dataInicio.month}/${_projeto.dataInicio.year}',
            ),
            if (_projeto.dataFechamento != null)
              _buildInfoRow(
                'Fechado',
                '${_projeto.dataFechamento!.day}/${_projeto.dataFechamento!.month}/${_projeto.dataFechamento!.year}',
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