// screens/excel_template_editor_screen.dart
import 'package:flutter/material.dart';
import '../models/excel_template.dart';
import '../utils/database_helper.dart';

class ExcelTemplateEditorScreen extends StatefulWidget {
  final ExcelTemplate? template;
  final String grupoBiologico;

  const ExcelTemplateEditorScreen({
    Key? key,
    this.template,
    required this.grupoBiologico,
  }) : super(key: key);

  @override
  State<ExcelTemplateEditorScreen> createState() => _ExcelTemplateEditorScreenState();
}

class _ExcelTemplateEditorScreenState extends State<ExcelTemplateEditorScreen> {
  final TextEditingController _nomeController = TextEditingController();
  List<ExcelColumn> _colunas = [];
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeTemplate();
  }

  void _initializeTemplate() {
    if (widget.template != null) {
      // Editando template existente
      _nomeController.text = widget.template!.nome;
      _isDefault = widget.template!.isDefault;
      _colunas = widget.template!.colunas
          .map((c) => ExcelColumn(
        campoOriginal: c.campoOriginal,
        nomeExibicao: c.nomeExibicao,
        ativo: c.ativo,
        ordem: c.ordem,
        formato: c.formato,
      ))
          .toList();
    } else {
      // Criando novo template
      _nomeController.text = 'Novo Template ${widget.grupoBiologico.capitalize()}';
      _colunas = ColunasDisponiveis.todas
          .asMap()
          .entries
          .map((entry) => ExcelColumn(
        campoOriginal: entry.value['campo'],
        nomeExibicao: entry.value['nome'],
        ativo: entry.value['obrigatorio'] == true,
        ordem: entry.key,
        formato: entry.value['tipo'],
      ))
          .toList();
    }

    // Ordenar colunas por ordem
    _colunas.sort((a, b) => a.ordem.compareTo(b.ordem));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? 'Editar Template' : 'Novo Template'),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveTemplate,
              child: const Text(
                'Salvar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Configurações básicas
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações do Template',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Template',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Peixes - Relatório Completo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isDefault,
                          onChanged: (value) {
                            setState(() => _isDefault = value ?? false);
                          },
                        ),
                        const Text('Definir como template padrão'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Cabeçalho da lista de colunas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.reorder, color: Color(0xFF8D6E63)),
                const SizedBox(width: 8),
                const Text(
                  'Colunas do Excel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_colunas.where((c) => c.ativo).length}/${_colunas.length} ativas',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista reordenável de colunas
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _colunas.length,
              onReorder: _reorderColumns,
              itemBuilder: (context, index) {
                final coluna = _colunas[index];
                return _buildColumnCard(coluna, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnCard(ExcelColumn coluna, int index) {
    return Card(
      key: ValueKey(coluna.campoOriginal),
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: coluna.ativo ? const Color(0xFF8D6E63) : Colors.grey[300]!,
            width: coluna.ativo ? 2 : 1,
          ),
        ),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle para arrastar
              Icon(
                Icons.drag_handle,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              // Checkbox ativo/inativo
              Checkbox(
                value: coluna.ativo,
                onChanged: (value) {
                  setState(() {
                    coluna.ativo = value ?? false;
                  });
                },
                activeColor: const Color(0xFF8D6E63),
              ),
            ],
          ),
          title: TextField(
            controller: TextEditingController(text: coluna.nomeExibicao),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Nome da coluna no Excel',
            ),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: coluna.ativo ? Colors.black : Colors.grey,
            ),
            onChanged: (value) {
              coluna.nomeExibicao = value;
            },
          ),
          subtitle: Row(
            children: [
              Text(
                'Campo: ${coluna.campoOriginal}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(coluna.formato),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  coluna.formato ?? 'texto',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          trailing: Text(
            '${index + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8D6E63),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String? tipo) {
    switch (tipo) {
      case 'data':
        return Colors.blue;
      case 'numero':
        return Colors.green;
      case 'coordenada':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _reorderColumns(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final ExcelColumn item = _colunas.removeAt(oldIndex);
      _colunas.insert(newIndex, item);

      // Atualizar ordem
      for (int i = 0; i < _colunas.length; i++) {
        _colunas[i].ordem = i;
      }
    });
  }

  Future<void> _saveTemplate() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite um nome para o template')),
      );
      return;
    }

    if (_colunas.where((c) => c.ativo).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma coluna')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final template = ExcelTemplate(
        id: widget.template?.id,
        nome: _nomeController.text.trim(),
        grupoBiologico: widget.grupoBiologico,
        colunas: _colunas,
        isDefault: _isDefault,
        criadoEm: widget.template?.criadoEm ?? DateTime.now(),
        atualizadoEm: widget.template != null ? DateTime.now() : null,
      );

      if (widget.template != null) {
        await DatabaseHelper.instance.updateTemplate(template);
      } else {
        await DatabaseHelper.instance.insertTemplate(template);
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template salvo com sucesso!')),
      );
    } catch (e) {
      print('Erro ao salvar template: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar template: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }
}

// Extension para capitalize (se não tiver ainda)
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}