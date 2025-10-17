import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/projeto.dart';
import '../models/enums.dart';

class CreateGrupoFaunaScreen extends StatefulWidget {
  final Projeto projeto;

  CreateGrupoFaunaScreen({required this.projeto});

  @override
  _CreateGrupoFaunaScreenState createState() => _CreateGrupoFaunaScreenState();
}

class _CreateGrupoFaunaScreenState extends State<CreateGrupoFaunaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCustomizadoController = TextEditingController();
  final _descricaoController = TextEditingController();

  GrupoBiologico? _tipoSelecionado;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      appBar: AppBar(
        title: Text('Novo Grupo de Fauna'),
        backgroundColor: Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Card de informações
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF8D6E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF8D6E63).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF8D6E63),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Projeto: ${widget.projeto.nome ?? "Sem nome"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Text(
                      'Adicione grupos de fauna para organizar suas campanhas',
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Tipo de Grupo Biológico
            Text(
              'Tipo de Grupo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonFormField<GrupoBiologico>(
                decoration: InputDecoration(
                  hintText: 'Selecione o grupo biológico',
                  prefixIcon: Icon(
                    _tipoSelecionado != null
                        ? _getIconForGrupo(_tipoSelecionado!)
                        : Icons.science,
                    color: _tipoSelecionado != null
                        ? _getColorForGrupo(_tipoSelecionado!)
                        : Color(0xFF8D6E63),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                value: _tipoSelecionado,
                items: GrupoBiologico.values.map((grupo) {
                  return DropdownMenuItem(
                    value: grupo,
                    child: Row(
                      children: [
                        Icon(
                          _getIconForGrupo(grupo),
                          size: 20,
                          color: _getColorForGrupo(grupo),
                        ),
                        SizedBox(width: 12),
                        Text(
                          grupo.displayName,
                          style: TextStyle(
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoSelecionado = value;
                  });
                },
              ),
            ),

            SizedBox(height: 16),

            // Nome Customizado (Opcional)
            Text(
              'Nome Customizado (opcional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _nomeCustomizadoController,
              decoration: InputDecoration(
                hintText: 'Ex: Herpetofauna - Área Sul',
                prefixIcon: Icon(Icons.edit, color: Color(0xFF8D6E63)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF8D6E63), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            SizedBox(height: 16),

            // Descrição (Opcional)
            Text(
              'Descrição (opcional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _descricaoController,
              decoration: InputDecoration(
                hintText: 'Adicione observações ou detalhes...',
                prefixIcon: Icon(Icons.description, color: Color(0xFF8D6E63)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF8D6E63), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            SizedBox(height: 32),

            // Preview Card
            if (_tipoSelecionado != null || _nomeCustomizadoController.text.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _tipoSelecionado != null
                        ? _getColorForGrupo(_tipoSelecionado!).withOpacity(0.3)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _tipoSelecionado != null
                            ? _getColorForGrupo(_tipoSelecionado!).withOpacity(0.1)
                            : Color(0xFF8D6E63).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _tipoSelecionado != null
                            ? _getIconForGrupo(_tipoSelecionado!)
                            : Icons.science,
                        color: _tipoSelecionado != null
                            ? _getColorForGrupo(_tipoSelecionado!)
                            : Color(0xFF8D6E63),
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preview:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _nomeCustomizadoController.text.isNotEmpty
                                ? _nomeCustomizadoController.text
                                : _tipoSelecionado?.displayName ?? 'Sem nome',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                          if (_descricaoController.text.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              _descricaoController.text,
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
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Botão Criar
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _criarGrupo,
                icon: _isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(Icons.check, size: 24),
                label: Text(
                  _isLoading ? 'Criando...' : 'Criar Grupo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8D6E63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            SizedBox(height: 16),

            // Texto de ajuda
            Center(
              child: Text(
                'Todos os campos são opcionais',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _criarGrupo() async {
    setState(() => _isLoading = true);

    try {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

      final id = await projectProvider.createGrupoFauna(
        projetoId: widget.projeto.id!,
        tipo: _tipoSelecionado,
        nomeCustomizado: _nomeCustomizadoController.text.isEmpty
            ? null
            : _nomeCustomizadoController.text,
        descricao: _descricaoController.text.isEmpty
            ? null
            : _descricaoController.text,
      );

      if (id != null && mounted) {
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Grupo criado! Adicione campanhas agora.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Erro ao criar grupo'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Erro ao criar grupo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getColorForGrupo(GrupoBiologico tipo) {
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

  IconData _getIconForGrupo(GrupoBiologico tipo) {
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

  @override
  void dispose() {
    _nomeCustomizadoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }
}