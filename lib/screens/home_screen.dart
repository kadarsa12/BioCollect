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
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildProjectCard(Projeto projeto) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(
            _getIconForGroup(projeto.grupoBiologico),
            color: Colors.white,
          ),
        ),
        title: Text(
          projeto.nome,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${projeto.grupoBiologico.displayName} - Campanha ${projeto.campanha}'),
            Text('${projeto.municipio} - ${projeto.periodo}'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(projeto: projeto),
            ),
          ).then((_) => _loadProjetos());
        },
      ),
    );
  }

  IconData _getIconForGroup(grupoBiologico) {
    switch (grupoBiologico.code) {
      case 'PEIXES':
        return Icons.set_meal;
      case 'AVES':
        return Icons.flutter_dash;
      case 'FELINOS':
        return Icons.pets;
      case 'PLANTAS':
        return Icons.local_florist;
      case 'REPTEIS':
        return Icons.dangerous;
      case 'MAMIFEROS':
        return Icons.cruelty_free;
      default:
        return Icons.science;
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