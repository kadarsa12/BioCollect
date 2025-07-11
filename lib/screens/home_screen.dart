import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/project_provider.dart';
import '../models/projeto.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadProjetos();
  }

  Future<void> _loadProjetos() async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    await projectProvider.loadProjetos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Projetos'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              _showUserInfo(context);
            },
          ),
        ],
      ),
      body: Consumer2<UserProvider, ProjectProvider>(
        builder: (context, userProvider, projectProvider, child) {
          if (projectProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (projectProvider.projetos.isEmpty) {
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
                    'Toque no + para criar seu primeiro projeto',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadProjetos,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: projectProvider.projetos.length,
              itemBuilder: (context, index) {
                final projeto = projectProvider.projetos[index];
                return _buildProjectCard(projeto);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CreateProjectScreen()),
          ).then((_) => _loadProjetos());
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF8D6E63),
      ),
    );
  }

  // NOVA FUNÇÃO - SUBSTITUI A ANTIGA _buildProjectCard
  Widget _buildProjectCard(Projeto projeto) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAF8F6), // Bege muito claro
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8D6E63).withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Color(0xFFD7CCC8).withOpacity(0.3),
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
                // Header com ícone e título
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone do grupo biológico
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getGroupColor(projeto.grupoBiologico),
                            _getGroupColor(projeto.grupoBiologico).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getGroupColor(projeto.grupoBiologico).withOpacity(0.3),
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
                          Text(
                            projeto.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF3E2723),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 4),

                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getGroupColor(projeto.grupoBiologico).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              projeto.grupoBiologico.displayName,
                              style: TextStyle(
                                color: _getGroupColor(projeto.grupoBiologico),
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
                        color: Color(0xFFEFEBE9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Informações detalhadas
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFAF8F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(0xFFEFEBE9),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.campaign, 'Campanha', projeto.campanha),
                      SizedBox(height: 8),
                      _buildInfoRow(Icons.water_drop, 'Período', projeto.periodo),
                      SizedBox(height: 8),
                      _buildInfoRow(Icons.location_city, 'Município', projeto.municipio),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Footer com data
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Color(0xFF8D6E63),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Criado em ${projeto.dataInicio.day}/${projeto.dataInicio.month}/${projeto.dataInicio.year}',
                          style: TextStyle(
                            color: Color(0xFF8D6E63),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF8D6E63).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Toque para abrir',
                        style: TextStyle(
                          color: Color(0xFF8D6E63),
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

  // NOVA FUNÇÃO
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Color(0xFF8D6E63),
        ),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Color(0xFF3E2723),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // NOVA FUNÇÃO
  Color _getGroupColor(grupoBiologico) {
    switch (grupoBiologico.code) {
      case 'ICTIOFAUNA':
        return Color(0xFF1976D2); // Azul oceano
      case 'AVIFAUNA':
        return Color(0xFF388E3C); // Verde floresta
      case 'HERPETOFAUNA':
        return Color(0xFF8D6E63); // Marrom terra
      case 'REPTEIS':
        return Color(0xFF6D4C41); // Marrom escuro
      case 'ANFIBIOS':
        return Color(0xFF00796B); // Verde água
      case 'MASTOFAUNA':
        return Color(0xFF7B1FA2); // Roxo
      case 'ENTOMOFAUNA':
        return Color(0xFFFF8F00); // Laranja
      case 'MACROINVERTEBRADOS':
        return Color(0xFF455A64); // Azul cinza
      case 'FLORA':
        return Color(0xFF689F38); // Verde planta
      case 'ZOOPLANCTON':
        return Color(0xFF0277BD); // Azul claro
      case 'FITOPLANCTON':
        return Color(0xFF558B2F); // Verde musgo
      default:
        return Color(0xFF8D6E63); // Marrom padrão
    }
  }

  // FUNÇÃO ATUALIZADA
  IconData _getIconForGroup(grupoBiologico) {
    switch (grupoBiologico.code) {
      case 'ICTIOFAUNA':
        return Icons.waves; // Peixes/água
      case 'AVIFAUNA':
        return Icons.flutter_dash; // Aves
      case 'HERPETOFAUNA':
        return Icons.psychology; // Anfíbios e répteis
      case 'REPTEIS':
        return Icons.psychology; // Répteis
      case 'ANFIBIOS':
        return Icons.water_drop; // Anfíbios
      case 'MASTOFAUNA':
        return Icons.pets; // Mamíferos
      case 'ENTOMOFAUNA':
        return Icons.bug_report; // Insetos
      case 'MACROINVERTEBRADOS':
        return Icons.scatter_plot; // Invertebrados
      case 'FLORA':
        return Icons.local_florist; // Plantas
      case 'ZOOPLANCTON':
        return Icons.bubble_chart; // Plâncton animal
      case 'FITOPLANCTON':
        return Icons.grain; // Plâncton vegetal
      default:
        return Icons.science; // Padrão
    }
  }

  void _showUserInfo(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Usuário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nome: ${user?.nome ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Criado em: ${user?.dataCriacao.day}/${user?.dataCriacao.month}/${user?.dataCriacao.year}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}