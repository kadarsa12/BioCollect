import 'package:flutter/material.dart';
import '../models/excel_template.dart';
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../models/campanha.dart';
import '../utils/database_helper.dart';
import '../screens/excel_templates_screen.dart';

class TemplateSelectionDialog extends StatefulWidget {
  final Projeto projeto;
  final GrupoFauna grupoFauna;
  final Campanha campanha;

  const TemplateSelectionDialog({
    Key? key,
    required this.projeto,
    required this.grupoFauna,
    required this.campanha,
  }) : super(key: key);

  @override
  State<TemplateSelectionDialog> createState() => _TemplateSelectionDialogState();
}

class _TemplateSelectionDialogState extends State<TemplateSelectionDialog> {
  List<ExcelTemplate> _templates = [];
  ExcelTemplate? _selectedTemplate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    try {
      final grupoCodigo = widget.grupoFauna.tipo?.code ?? 'GERAL';
      final templates = await DatabaseHelper.instance.getTemplatesByGrupo(grupoCodigo);

      setState(() {
        _templates = templates;
        // Selecionar template padrão automaticamente
        _selectedTemplate = templates.firstWhere(
              (t) => t.isDefault,
          orElse: () => templates.isNotEmpty ? templates.first : _createEmptyTemplate(),
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar templates: $e');
      setState(() {
        _selectedTemplate = _createEmptyTemplate();
        _isLoading = false;
      });
    }
  }

  ExcelTemplate _createEmptyTemplate() {
    // Template básico caso não exista nenhum
    final grupoCodigo = widget.grupoFauna.tipo?.code ?? 'GERAL';

    return ExcelTemplate(
      nome: 'Template Básico',
      grupoBiologico: grupoCodigo,
      colunas: [
        ExcelColumn(campoOriginal: 'projeto', nomeExibicao: 'Projeto', ordem: 0),
        ExcelColumn(campoOriginal: 'grupoBiologico', nomeExibicao: 'Grupo', ordem: 1),
        ExcelColumn(campoOriginal: 'campanha', nomeExibicao: 'Campanha', ordem: 2),
        ExcelColumn(campoOriginal: 'data', nomeExibicao: 'Data', ordem: 3),
        ExcelColumn(campoOriginal: 'ponto', nomeExibicao: 'Ponto', ordem: 4),
        ExcelColumn(campoOriginal: 'especie', nomeExibicao: 'Espécie', ordem: 5),
        ExcelColumn(campoOriginal: 'tecnicoResponsavel', nomeExibicao: 'Técnico', ordem: 6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF8D6E63),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.table_chart, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Selecionar Template Excel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Conteúdo
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8D6E63),
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Info do projeto/grupo/campanha
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[50],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Projeto
                          Row(
                            children: [
                              Icon(Icons.folder, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.projeto.nome ?? 'Sem nome',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Grupo + Campanha
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8D6E63).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.grupoFauna.nomeExibicao,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8D6E63),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: Colors.grey)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.campanha.nomeExibicao,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Lista de templates
                    Expanded(
                      child: _templates.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _templates.length,
                        itemBuilder: (context, index) {
                          final template = _templates[index];
                          return _buildTemplateOption(template);
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Botões de ação
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _openTemplatesManager,
                    icon: const Icon(Icons.settings),
                    label: const Text('Gerenciar'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8D6E63),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton.icon(
                      onPressed: _selectedTemplate != null ? _exportWithTemplate : null,
                      icon: const Icon(Icons.file_download),
                      label: const Text('Exportar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8D6E63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          const Text(
            'Nenhum template encontrado',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um template para personalizar seu Excel',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openTemplatesManager,
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

  Widget _buildTemplateOption(ExcelTemplate template) {
    final isSelected = _selectedTemplate?.id == template.id;
    final activeCols = template.colunas.where((c) => c.ativo).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF8D6E63), width: 2)
              : null,
        ),
        child: ListTile(
          leading: Radio<ExcelTemplate>(
            value: template,
            groupValue: _selectedTemplate,
            onChanged: (value) {
              setState(() => _selectedTemplate = value);
            },
            activeColor: const Color(0xFF8D6E63),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  template.nome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (template.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Padrão',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$activeCols colunas ativas'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  ...template.colunas
                      .where((c) => c.ativo)
                      .take(4)
                      .map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D6E63).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.nomeExibicao,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                  )),
                  if (activeCols > 4)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${activeCols - 4}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          onTap: () {
            setState(() => _selectedTemplate = template);
          },
        ),
      ),
    );
  }

  void _openTemplatesManager() async {
    final grupoCodigo = widget.grupoFauna.tipo?.code ?? 'GERAL';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExcelTemplatesScreen(
          grupoBiologico: grupoCodigo,
        ),
      ),
    );

    // Recarregar templates quando voltar
    if (result != null) {
      _loadTemplates();
    }
  }

  void _exportWithTemplate() {
    Navigator.pop(context, _selectedTemplate);
  }
}