import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/metodologia.dart';
import '../models/projeto.dart';
import '../models/enums.dart';
import '../providers/user_provider.dart';
import '../utils/database_helper.dart';

class ManageMetodologiasScreen extends StatefulWidget {
  final Projeto projeto;

  ManageMetodologiasScreen({required this.projeto});

  @override
  _ManageMetodologiasScreenState createState() => _ManageMetodologiasScreenState();
}

class _ManageMetodologiasScreenState extends State<ManageMetodologiasScreen> {
  List<Metodologia> _metodologias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetodologias();
  }

  Future<void> _loadMetodologias() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;

      if (userId != null) {
        final metodologias = await DatabaseHelper.instance.getMetodologiasByGrupo(
          widget.projeto.grupoBiologico.code,
          userId,
        );

        setState(() {
          _metodologias = metodologias;
        });
      }
    } catch (e) {
      print('Erro ao carregar metodologias: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Métodos - ${widget.projeto.grupoBiologico.displayName}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _metodologias.isEmpty
          ? _buildEmptyState()
          : _buildMetodologiasList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMetodologiaDialog,
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF8D6E63),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Nenhum método cadastrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Toque no + para criar o primeiro método',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          _buildSuggestionCard(),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard() {
    final sugestoes = widget.projeto.grupoBiologico.getMetodologias();

    // Filtrar sugestões que já foram criadas
    final sugestoesDisponiveis = sugestoes.where((sugestao) {
      return !_metodologias.any((metodologia) => metodologia.nome == sugestao);
    }).toList();

    // Se não há sugestões disponíveis, não mostrar card
    if (sugestoesDisponiveis.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFAF8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFD7CCC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFF8D6E63)),
              SizedBox(width: 8),
              Text(
                'Sugestões para ${widget.projeto.grupoBiologico.displayName}:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sugestoesDisponiveis.map((metodo) {
              return ActionChip(
                label: Text(metodo),
                onPressed: () => _createSuggestedMethod(metodo),
                backgroundColor: Color(0xFFEFEBE9),
                labelStyle: TextStyle(
                  color: Color(0xFF8D6E63),
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 8),
          Text(
            'Toque para adicionar rapidamente',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodologiasList() {
    return Column(
      children: [
        // Chips de sugestão sempre visíveis
        _buildSuggestionCard(),

        // Lista de metodologias
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _metodologias.length,
            itemBuilder: (context, index) {
              final metodologia = _metodologias[index];
              return _buildMetodologiaCard(metodologia);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetodologiaCard(Metodologia metodologia) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF8D6E63),
          child: Icon(
            Icons.science,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          metodologia.nome,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: metodologia.descricao != null && metodologia.descricao!.isNotEmpty
            ? Text(metodologia.descricao!)
            : null,
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(metodologia),
        ),
      ),
    );
  }

  void _showCreateMetodologiaDialog() {
    final nomeController = TextEditingController();
    final descricaoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Metodologia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome da metodologia',
                border: OutlineInputBorder(),
                hintText: 'Ex: Puçá malha 5mm',
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: descricaoController,
              decoration: InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Detalhes sobre a metodologia',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.trim().isNotEmpty) {
                await _createMetodologia(
                  nomeController.text.trim(),
                  descricaoController.text.trim().isEmpty
                      ? null
                      : descricaoController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: Text('Criar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8D6E63),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createSuggestedMethod(String nome) async {
    await _createMetodologia(nome, null);
  }

  Future<void> _createMetodologia(String nome, String? descricao) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;

      if (userId != null) {
        final metodologia = Metodologia(
          nome: nome,
          descricao: descricao,
          grupoBiologico: widget.projeto.grupoBiologico.code,
          usuarioId: userId,
          dataCriacao: DateTime.now(),
        );

        await DatabaseHelper.instance.insertMetodologia(metodologia);
        await _loadMetodologias();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Metodologia "$nome" criada com sucesso!'),
            backgroundColor: Color(0xFF8D6E63),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar metodologia: $e')),
      );
    }
  }

  void _confirmDelete(Metodologia metodologia) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Metodologia'),
        content: Text('Tem certeza que deseja excluir "${metodologia.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMetodologia(metodologia);
            },
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMetodologia(Metodologia metodologia) async {
    try {
      await DatabaseHelper.instance.deleteMetodologia(metodologia.id!);
      await _loadMetodologias();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Metodologia excluída com sucesso!'),
          backgroundColor: Color(0xFF8D6E63),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir metodologia: $e')),
      );
    }
  }
}