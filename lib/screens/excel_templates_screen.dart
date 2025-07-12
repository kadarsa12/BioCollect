// screens/excel_templates_screen.dart
import 'package:flutter/material.dart';
import '../models/excel_template.dart';
import '../utils/database_helper.dart';
import 'excel_template_editor_screen.dart';

class ExcelTemplatesScreen extends StatefulWidget {
  final String? grupoBiologico;

  const ExcelTemplatesScreen({Key? key, this.grupoBiologico}) : super(key: key);

  @override
  State<ExcelTemplatesScreen> createState() => _ExcelTemplatesScreenState();
}

class _ExcelTemplatesScreenState extends State<ExcelTemplatesScreen> {
  List<ExcelTemplate> _templates = [];
  String _selectedGrupo = 'ICTIOFAUNA';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedGrupo = widget.grupoBiologico ?? 'ICTIOFAUNA';
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    try {
      final templates = await DatabaseHelper.instance.getTemplatesByGrupo(_selectedGrupo);
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar templates: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates Excel'),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewTemplate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de Grupo Biológico
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grupo Biológico',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGrupo,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ICTIOFAUNA', child: Text('Ictiofauna')),
                        DropdownMenuItem(value: 'HERPETOFAUNA', child: Text('Herpetofauna')),
                        DropdownMenuItem(value: 'AVIFAUNA', child: Text('Avifauna')),
                        DropdownMenuItem(value: 'MASTOFAUNA', child: Text('Mastofauna')),
                        DropdownMenuItem(value: 'ENTOMOFAUNA', child: Text('Entomofauna')),
                        DropdownMenuItem(value: 'MACROINVERTEBRADOS', child: Text('Macroinvertebrados Bentônicos')),
                        DropdownMenuItem(value: 'FLORA', child: Text('Flora / Fitossociologia')),
                        DropdownMenuItem(value: 'ZOOPLANCTON', child: Text('Zooplâncton')),
                        DropdownMenuItem(value: 'FITOPLANCTON', child: Text('Fitoplâncton')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGrupo = value);
                          _loadTemplates();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de Templates
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _templates.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return _buildTemplateCard(template);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum template encontrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro template personalizado',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewTemplate,
            icon: const Icon(Icons.add),
            label: const Text('Criar Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8D6E63),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ExcelTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: template.isDefault
              ? Colors.green[100]
              : Colors.blue[100],
          child: Icon(
            template.isDefault ? Icons.star : Icons.table_chart,
            color: template.isDefault ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          template.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${template.colunas.where((c) => c.ativo).length} colunas ativas'),
            if (template.isDefault)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Padrão',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, template),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Duplicar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!template.isDefault)
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Excluir', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        onTap: () => _editTemplate(template),
      ),
    );
  }

  void _handleMenuAction(String action, ExcelTemplate template) {
    switch (action) {
      case 'edit':
        _editTemplate(template);
        break;
      case 'duplicate':
        _duplicateTemplate(template);
        break;
      case 'delete':
        _deleteTemplate(template);
        break;
    }
  }

  void _createNewTemplate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExcelTemplateEditorScreen(
          grupoBiologico: _selectedGrupo,
        ),
      ),
    ).then((_) => _loadTemplates());
  }

  void _editTemplate(ExcelTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExcelTemplateEditorScreen(
          template: template,
          grupoBiologico: _selectedGrupo,
        ),
      ),
    ).then((_) => _loadTemplates());
  }

  void _duplicateTemplate(ExcelTemplate template) {
    final newTemplate = ExcelTemplate(
      nome: '${template.nome} (Cópia)',
      grupoBiologico: template.grupoBiologico,
      colunas: template.colunas.map((c) => ExcelColumn(
        campoOriginal: c.campoOriginal,
        nomeExibicao: c.nomeExibicao,
        ativo: c.ativo,
        ordem: c.ordem,
        formato: c.formato,
      )).toList(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExcelTemplateEditorScreen(
          template: newTemplate,
          grupoBiologico: _selectedGrupo,
        ),
      ),
    ).then((_) => _loadTemplates());
  }

  void _deleteTemplate(ExcelTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o template "${template.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseHelper.instance.deleteTemplate(template.id!);
                _loadTemplates();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Template excluído com sucesso')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir template: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}