import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../providers/project_provider.dart';
import '../utils/database_helper.dart';
import '../models/enums.dart';
import 'create_grupo_fauna_screen.dart';
import 'campanha_list_screen.dart'; // VAMOS CRIAR

class ProjectDetailScreen extends StatefulWidget {
  final Projeto projeto;

  ProjectDetailScreen({required this.projeto});

  @override
  _ProjectDetailScreenState createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isDeleting = false;
  bool _isUpdatingStatus = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Projeto _projeto;

  @override
  void initState() {
    super.initState();
    _projeto = widget.projeto;
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadGrupos();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGrupos() async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    await projectProvider.loadGruposByProjeto(_projeto.id!);
  }

  @override
  Widget build(BuildContext context) {
    final isAberto = _projeto.status == StatusProjeto.aberto;

    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isAberto
                        ? [Color(0xFF8D6E63), Color(0xFF6D4C41)]
                        : [Colors.grey.shade600, Colors.grey.shade800],
                  ),
                ),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _projeto.nome ?? 'Sem nome',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (_projeto.municipio != null && _projeto.municipio!.isNotEmpty)
                    Text(
                      _projeto.municipio!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
              // Botão de status
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

              // Menu
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value),
                icon: Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
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

          // Conteúdo
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  if (!isAberto) _buildClosedProjectCard(),
                  _buildStatsCard(),
                  _buildSectionHeader(),
                ],
              ),
            ),
          ),

          // Lista de grupos
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

              if (projectProvider.gruposFauna.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final grupo = projectProvider.gruposFauna[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _buildGrupoCard(grupo),
                      ),
                    );
                  },
                  childCount: projectProvider.gruposFauna.length,
                ),
              );
            },
          ),

          SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: isAberto
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateGrupoFaunaScreen(projeto: _projeto),
            ),
          ).then((_) => _loadGrupos());
        },
        label: Text('Novo Grupo'),
        icon: Icon(Icons.add),
        backgroundColor: Color(0xFF8D6E63),
        foregroundColor: Colors.white,
      )
          : null,
    );
  }

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
            child: Icon(Icons.lock, color: Colors.grey.shade600, size: 20),
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
                  'Não é possível adicionar novos grupos ou campanhas',
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

  Future<void> _toggleStatusProjeto() async {
    setState(() => _isUpdatingStatus = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final novoStatus = _projeto.status == StatusProjeto.aberto
          ? StatusProjeto.fechado
          : StatusProjeto.aberto;
      final dataFechamento = novoStatus == StatusProjeto.fechado ? DateTime.now() : null;

      await db.update(
        'projetos',
        {
          'status': novoStatus.value,
          'data_fechamento': dataFechamento?.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [_projeto.id],
      );

      setState(() {
        _projeto = _projeto.copyWith(
          status: novoStatus,
          dataFechamento: dataFechamento,
        );
      });

      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.loadProjetos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  novoStatus == StatusProjeto.fechado ? Icons.lock : Icons.lock_open,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text('Projeto ${novoStatus == StatusProjeto.fechado ? "fechado" : "reaberto"}'),
              ],
            ),
            backgroundColor: novoStatus == StatusProjeto.fechado ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
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
          final totalGrupos = projectProvider.gruposFauna.length;

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
                    child: Icon(Icons.analytics, color: Color(0xFF8D6E63), size: 20),
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
                      'Grupos',
                      totalGrupos.toString(),
                      Icons.category,
                      Color(0xFF8D6E63),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  Expanded(
                    child: _buildStatItem(
                      'Status',
                      _projeto.status.value,
                      _projeto.status == StatusProjeto.aberto ? Icons.lock_open : Icons.lock,
                      _projeto.status == StatusProjeto.aberto ? Colors.green : Colors.grey,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  Expanded(
                    child: _buildStatItem(
                      'Criado',
                      '${_projeto.dataInicio.day}/${_projeto.dataInicio.month}',
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          Icon(Icons.category, color: Color(0xFF8D6E63), size: 20),
          SizedBox(width: 8),
          Text(
            'Grupos de Fauna',
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
            child: Icon(Icons.category, size: 60, color: Colors.grey[400]),
          ),
          SizedBox(height: 20),
          Text(
            'Nenhum grupo de fauna',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            isAberto
                ? 'Toque em "Novo Grupo" para adicionar\num grupo de fauna ao projeto'
                : 'Este projeto está fechado.\nReabra para adicionar grupos.',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrupoCard(GrupoFauna grupo) {
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
                builder: (_) => CampanhaListScreen(
                  projeto: _projeto,
                  grupoFauna: grupo,
                ),
              ),
            ).then((_) => _loadGrupos());
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getColorForGrupo(grupo.tipo).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForGrupo(grupo.tipo),
                    color: _getColorForGrupo(grupo.tipo),
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grupo.nomeExibicao,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      if (grupo.descricao != null && grupo.descricao!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          grupo.descricao!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForGrupo(GrupoBiologico? tipo) {
    if (tipo == null) return Color(0xFF8D6E63);

    switch (tipo.code) {
      case 'ICTIOFAUNA':
        return Color(0xFF1976D2);
      case 'HERPETOFAUNA':
        return Color(0xFF8D6E63);
      case 'AVIFAUNA':
        return Color(0xFF388E3C);
      case 'MASTOFAUNA':
        return Color(0xFF7B1FA2);
      case 'ENTOMOFAUNA':
        return Color(0xFFFF8F00);
      default:
        return Color(0xFF8D6E63);
    }
  }

  IconData _getIconForGrupo(GrupoBiologico? tipo) {
    if (tipo == null) return Icons.science;

    switch (tipo.code) {
      case 'ICTIOFAUNA':
        return Icons.waves;
      case 'HERPETOFAUNA':
        return Icons.water_drop;
      case 'AVIFAUNA':
        return Icons.flutter_dash;
      case 'MASTOFAUNA':
        return Icons.pets;
      case 'ENTOMOFAUNA':
        return Icons.bug_report;
      default:
        return Icons.science;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'toggle_status':
        _toggleStatusProjeto();
        break;
      case 'info':
        _showProjectInfo();
        break;
      case 'delete':
        if (!_isDeleting) _confirmarDeleteProjeto();
        break;
    }
  }

  Future<void> _confirmarDeleteProjeto() async {
    // Implementar delete
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Projeto'),
        content: Text('Tem certeza que deseja excluir este projeto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Deletar projeto
              await DatabaseHelper.instance.database.then((db) async {
                await db.delete('projetos', where: 'id = ?', whereArgs: [_projeto.id]);
              });
              Navigator.pop(context);
            },
            child: Text('Excluir'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            _buildInfoRow('Nome', _projeto.nome ?? 'Sem nome'),
            _buildInfoRow('Município', _projeto.municipio ?? 'Não informado'),
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
            style: TextButton.styleFrom(foregroundColor: Color(0xFF8D6E63)),
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
              style: TextStyle(color: Color(0xFF5D4037)),
            ),
          ),
        ],
      ),
    );
  }
}