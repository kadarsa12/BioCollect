import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../models/enums.dart';

class CreateCampanhaScreen extends StatefulWidget {
  final Projeto projeto;
  final GrupoFauna grupoFauna;

  CreateCampanhaScreen({
    required this.projeto,
    required this.grupoFauna,
  });

  @override
  _CreateCampanhaScreenState createState() => _CreateCampanhaScreenState();
}

class _CreateCampanhaScreenState extends State<CreateCampanhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _observacoesController = TextEditingController();

  String? _periodoSelecionado;
  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;
  bool _isLoading = false;

  final List<String> _periodos = ['Seca', 'Cheia', 'Transição'];

  Color get _grupoColor => _getColorForGrupo(widget.grupoFauna.tipo);
  IconData get _grupoIcon => _getIconForGrupo(widget.grupoFauna.tipo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      appBar: AppBar(
        title: Text('Nova Campanha'),
        backgroundColor: _grupoColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Card de contexto
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _grupoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _grupoColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_grupoIcon, color: _grupoColor, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.grupoFauna.nomeExibicao,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Text(
                      'Projeto: ${widget.projeto.nome ?? "Sem nome"}',
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

            // Nome da Campanha
            Text(
              'Nome da Campanha (opcional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(
                hintText: 'Ex: Campanha 1, Primeira Coleta...',
                prefixIcon: Icon(Icons.campaign, color: _grupoColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _grupoColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            SizedBox(height: 16),

            // Período
            Text(
              'Período (opcional)',
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
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Selecione o período',
                  prefixIcon: Icon(Icons.water_drop, color: _grupoColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                value: _periodoSelecionado,
                items: _periodos.map((periodo) {
                  return DropdownMenuItem(
                    value: periodo,
                    child: Text(periodo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _periodoSelecionado = value;
                  });
                },
              ),
            ),

            SizedBox(height: 16),

            // Data de Início
            Text(
              'Data de Início',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: () => _selecionarDataInicio(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: _grupoColor, size: 20),
                    SizedBox(width: 16),
                    Text(
                      '${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.edit_calendar, color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Data de Fim
            Text(
              'Data de Fim (opcional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: () => _selecionarDataFim(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      color: _dataFim != null ? _grupoColor : Colors.grey[400],
                      size: 20,
                    ),
                    SizedBox(width: 16),
                    Text(
                      _dataFim != null
                          ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}'
                          : 'Selecione a data de fim',
                      style: TextStyle(
                        fontSize: 16,
                        color: _dataFim != null ? Color(0xFF5D4037) : Colors.grey[500],
                      ),
                    ),
                    Spacer(),
                    if (_dataFim != null)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                        onPressed: () {
                          setState(() {
                            _dataFim = null;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      )
                    else
                      Icon(Icons.edit_calendar, color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Observações
            Text(
              'Observações (opcional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _observacoesController,
              decoration: InputDecoration(
                hintText: 'Adicione observações sobre a campanha...',
                prefixIcon: Icon(Icons.notes, color: _grupoColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _grupoColor, width: 2),
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
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _grupoColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Preview:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ATIVA',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.play_circle, color: Colors.green, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nomeController.text.isNotEmpty
                                  ? _nomeController.text
                                  : _periodoSelecionado != null
                                  ? '$_periodoSelecionado ${_dataInicio.year}'
                                  : 'Campanha ${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                            SizedBox(height: 4),
                            if (_periodoSelecionado != null)
                              Row(
                                children: [
                                  Icon(Icons.water_drop, size: 12, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    _periodoSelecionado!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  '${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                                if (_dataFim != null) ...[
                                  Text(' • ', style: TextStyle(color: Colors.grey[600])),
                                  Text(
                                    '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Botão Criar
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _criarCampanha,
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
                  _isLoading ? 'Criando...' : 'Criar Campanha',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _grupoColor,
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
                'Todos os campos são opcionais (exceto data de início)',
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

  Future<void> _selecionarDataInicio() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _grupoColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF5D4037),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dataInicio) {
      setState(() {
        _dataInicio = picked;
        // Se data fim for anterior à nova data início, limpar data fim
        if (_dataFim != null && _dataFim!.isBefore(_dataInicio)) {
          _dataFim = null;
        }
      });
    }
  }

  Future<void> _selecionarDataFim() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? _dataInicio.add(Duration(days: 30)),
      firstDate: _dataInicio,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _grupoColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF5D4037),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataFim = picked;
      });
    }
  }

  Future<void> _criarCampanha() async {
    setState(() => _isLoading = true);

    try {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

      final id = await projectProvider.createCampanha(
        grupoFaunaId: widget.grupoFauna.id!,
        nome: _nomeController.text.isEmpty ? null : _nomeController.text,
        periodo: _periodoSelecionado,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
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
                  child: Text('Campanha criada! Adicione pontos de coleta agora.'),
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
                Text('Erro ao criar campanha'),
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
      print('Erro ao criar campanha: $e');
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
    _nomeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}