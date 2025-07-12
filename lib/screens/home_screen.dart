import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/project_provider.dart';
import '../models/projeto.dart';
import '../utils/database_helper.dart';
import '../models/enums.dart'; // Para StatusProjeto
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StatusProjeto? _filtroStatus; // null = todos, StatusProjeto.aberto = só abertos, etc.
  bool _mostrarFechados = true; // Controle rápido

  @override
  void initState() {
    super.initState();
    _loadProjetos();
    _initializeTemplates();
  }

  Future<void> _loadProjetos() async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    await projectProvider.loadProjetos();
  }

  Future<void> _initializeTemplates() async {
    try {
      await DatabaseHelper.instance.createDefaultTemplates();
      print('Templates padrão inicializados');
    } catch (e) {
      print('Erro ao inicializar templates: $e');
    }
  }

  List<Projeto> _getFilteredProjects(List<Projeto> projetos) {
    if (_filtroStatus != null) {
      return projetos.where((p) => p.status == _filtroStatus).toList();
    }

    if (!_mostrarFechados) {
      return projetos.where((p) => p.status == StatusProjeto.aberto).toList();
    }

    return projetos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      appBar: AppBar(
        title: Text('Meus Projetos'),
        backgroundColor: Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 2,
        actions: [
          // Filtro rápido
          IconButton(
            icon: Icon(_mostrarFechados ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _mostrarFechados = !_mostrarFechados;
                _filtroStatus = null; // Reset filtro específico
              });
            },
            tooltip: _mostrarFechados ? 'Ocultar fechados' : 'Mostrar fechados',
          ),

          // Filtro avançado
          PopupMenuButton<StatusProjeto?>(
            icon: Icon(_filtroStatus != null ? Icons.filter_alt : Icons.filter_list),
            onSelected: (status) {
              setState(() {
                _filtroStatus = status;
                if (status != null) _mostrarFechados = true; // Reset filtro rápido
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.list, size: 16),
                    SizedBox(width: 8),
                    Text('Todos os projetos'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: StatusProjeto.aberto,
                child: Row(
                  children: [
                    Icon(Icons.lock_open, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Apenas abertos'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: StatusProjeto.fechado,
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text('Apenas fechados'),
                  ],
                ),
              ),
            ],
          ),

          // Botão de adicionar projeto
          Container(
            margin: EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CreateProjectScreen()),
                  ).then((_) => _loadProjetos());
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<UserProvider, ProjectProvider>(
        builder: (context, userProvider, projectProvider, child) {
          if (projectProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8D6E63),
              ),
            );
          }

          final todosProjetos = projectProvider.projetos;
          final projetosFiltrados = _getFilteredProjects(todosProjetos);

          // Contadores para estatísticas
          final totalAbertos = todosProjetos.where((p) => p.status == StatusProjeto.aberto).length;
          final totalFechados = todosProjetos.where((p) => p.status == StatusProjeto.fechado).length;

          return Column(
            children: [
              // Header com estatísticas e filtros
              if (todosProjetos.isNotEmpty) _buildStatsHeader(totalAbertos, totalFechados, projetosFiltrados.length),

              // Lista de projetos
              Expanded(
                child: projetosFiltrados.isEmpty
                    ? _buildEmptyState(todosProjetos.isEmpty)
                    : RefreshIndicator(
                  color: Color(0xFF8D6E63),
                  onRefresh: _loadProjetos,
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    itemCount: projetosFiltrados.length,
                    itemBuilder: (context, index) {
                      final projeto = projetosFiltrados[index];
                      return _buildProjectCard(projeto);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(int abertos, int fechados, int filtrados) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8D6E63).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Estatísticas
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Abertos',
                  abertos.toString(),
                  Icons.lock_open,
                  Colors.green,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              Expanded(
                child: _buildStatItem(
                  'Fechados',
                  fechados.toString(),
                  Icons.lock,
                  Colors.grey,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              Expanded(
                child: _buildStatItem(
                  'Total',
                  (abertos + fechados).toString(),
                  Icons.folder,
                  Color(0xFF8D6E63),
                ),
              ),
            ],
          ),

          // Filtro ativo
          if (_filtroStatus != null || !_mostrarFechados) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF8D6E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt, size: 14, color: Color(0xFF8D6E63)),
                  SizedBox(width: 4),
                  Text(
                    _filtroStatus != null
                        ? 'Mostrando: ${_filtroStatus!.value.toLowerCase()}'
                        : 'Ocultando: fechados',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D6E63),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '($filtrados)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filtroStatus = null;
                        _mostrarFechados = true;
                      });
                    },
                    child: Icon(Icons.close, size: 14, color: Color(0xFF8D6E63)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    if (isCompletelyEmpty) {
      // Sem projetos
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum projeto criado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Toque no + no canto superior para criar',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 24),
            Container(
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: Color(0xFF8D6E63),
                    size: 32,
                  ),
                  Text(
                    'Clique aqui',
                    style: TextStyle(
                      color: Color(0xFF8D6E63),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Tem projetos, mas filtro não mostra nenhum
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum projeto encontrado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _filtroStatus != null
                  ? 'Não há projetos ${_filtroStatus!.value.toLowerCase()}'
                  : 'Todos os projetos estão fechados',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _filtroStatus = null;
                  _mostrarFechados = true;
                });
              },
              icon: Icon(Icons.clear_all),
              label: Text('Mostrar todos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8D6E63),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProjectCard(Projeto projeto) {
    final isAberto = projeto.status == StatusProjeto.aberto;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAberto
              ? [Colors.white, Color(0xFFFAF8F6)]
              : [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isAberto
                ? Color(0xFF8D6E63).withOpacity(0.08)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isAberto
              ? Color(0xFFD7CCC8).withOpacity(0.3)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(projeto: projeto),
              ),
            ).then((_) => _loadProjetos());
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com ícone, título e status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone do grupo biológico
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isAberto
                              ? [
                            _getGroupColor(projeto.grupoBiologico),
                            _getGroupColor(projeto.grupoBiologico).withOpacity(0.8),
                          ]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isAberto
                                ? _getGroupColor(projeto.grupoBiologico).withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconForGroup(projeto.grupoBiologico),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    SizedBox(width: 16),

                    // Informações do projeto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  projeto.nome,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isAberto ? Color(0xFF3E2723) : Colors.grey.shade600,
                                    height: 1.2,
                                    decoration: isAberto ? null : TextDecoration.lineThrough,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Badge de status
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAberto
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAberto ? Icons.lock_open : Icons.lock,
                                      color: isAberto ? Colors.green : Colors.grey,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      projeto.status.value.toUpperCase(),
                                      style: TextStyle(
                                        color: isAberto ? Colors.green : Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4),

                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAberto
                                  ? _getGroupColor(projeto.grupoBiologico).withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              projeto.grupoBiologico.displayName,
                              style: TextStyle(
                                color: isAberto
                                    ? _getGroupColor(projeto.grupoBiologico)
                                    : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Seta indicativa
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isAberto ? Color(0xFFEFEBE9) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: isAberto ? Color(0xFF8D6E63) : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Informações detalhadas
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAberto ? Color(0xFFFAF8F6) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAberto ? Color(0xFFEFEBE9) : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.campaign, 'Campanha', projeto.campanha, isAberto),
                      SizedBox(height: 8),
                      _buildInfoRow(Icons.water_drop, 'Período', projeto.periodo, isAberto),
                      SizedBox(height: 8),
                      _buildInfoRow(Icons.location_city, 'Município', projeto.municipio, isAberto),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Footer com data e status adicional
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isAberto ? Color(0xFF8D6E63) : Colors.grey.shade500,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Criado em ${projeto.dataInicio.day}/${projeto.dataInicio.month}/${projeto.dataInicio.year}',
                          style: TextStyle(
                            color: isAberto ? Color(0xFF8D6E63) : Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    if (!isAberto && projeto.dataFechamento != null)
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Fechado em ${projeto.dataFechamento!.day}/${projeto.dataFechamento!.month}/${projeto.dataFechamento!.year}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAberto
                              ? Color(0xFF8D6E63).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Toque para abrir',
                          style: TextStyle(
                            color: isAberto ? Color(0xFF8D6E63) : Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isAberto) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isAberto ? Color(0xFF8D6E63) : Colors.grey.shade500,
        ),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: isAberto ? Color(0xFF5D4037) : Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isAberto ? Color(0xFF3E2723) : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Color _getGroupColor(grupoBiologico) {
    switch (grupoBiologico.code) {
      case 'ICTIOFAUNA':
        return Color(0xFF1976D2);
      case 'AVIFAUNA':
        return Color(0xFF388E3C);
      case 'HERPETOFAUNA':
        return Color(0xFF8D6E63);
      case 'REPTEIS':
        return Color(0xFF6D4C41);
      case 'ANFIBIOS':
        return Color(0xFF00796B);
      case 'MASTOFAUNA':
        return Color(0xFF7B1FA2);
      case 'ENTOMOFAUNA':
        return Color(0xFFFF8F00);
      case 'MACROINVERTEBRADOS':
        return Color(0xFF455A64);
      case 'FLORA':
        return Color(0xFF689F38);
      case 'ZOOPLANCTON':
        return Color(0xFF0277BD);
      case 'FITOPLANCTON':
        return Color(0xFF558B2F);
      default:
        return Color(0xFF8D6E63);
    }
  }

  IconData _getIconForGroup(grupoBiologico) {
    switch (grupoBiologico.code) {
      case 'ICTIOFAUNA':
        return Icons.waves;
      case 'AVIFAUNA':
        return Icons.flutter_dash;
      case 'HERPETOFAUNA':
        return Icons.water_drop;
      case 'MASTOFAUNA':
        return Icons.pets;
      case 'ENTOMOFAUNA':
        return Icons.bug_report;
      case 'MACROINVERTEBRADOS':
        return Icons.scatter_plot;
      case 'FLORA':
        return Icons.local_florist;
      case 'ZOOPLANCTON':
        return Icons.bubble_chart;
      case 'FITOPLANCTON':
        return Icons.grain;
      default:
        return Icons.science;
    }
  }
}