import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../models/campanha.dart';
import '../models/ponto_coleta.dart';
import '../models/enums.dart';
import '../models/metodologia.dart';
import '../providers/project_provider.dart';
import '../providers/user_provider.dart';
import '../utils/database_helper.dart';

class ColetaRapida {
  String especie;
  int quantidade;
  bool selecionada;

  ColetaRapida({
    required this.especie,
    required this.quantidade,
    this.selecionada = true,
  });

  Map<String, dynamic> toJson() => {
    'especie': especie,
    'quantidade': quantidade,
    'selecionada': selecionada,
  };

  factory ColetaRapida.fromJson(Map<String, dynamic> json) => ColetaRapida(
    especie: json['especie'],
    quantidade: json['quantidade'],
    selecionada: json['selecionada'] ?? true,
  );
}

class ColetaRapidaScreen extends StatefulWidget {
  final PontoColeta ponto;
  final Projeto projeto;
  final GrupoFauna grupoFauna;
  final Campanha campanha;

  ColetaRapidaScreen({
    required this.ponto,
    required this.projeto,
    required this.grupoFauna,
    required this.campanha,
  });

  @override
  _ColetaRapidaScreenState createState() => _ColetaRapidaScreenState();
}

class _ColetaRapidaScreenState extends State<ColetaRapidaScreen> {
  final _textController = TextEditingController();
  String? _metodologiaSelecionada;
  List<Metodologia> _metodologiasCadastradas = [];
  List<ColetaRapida> _coletasProcessadas = [];
  bool _isProcessado = false;
  bool _isLoadingMetodologias = false;
  bool _isSaving = false;

  Color get _grupoColor => _getColorForGrupo(widget.grupoFauna.tipo);
  String get _storageKey => 'rascunho_ponto_${widget.ponto.id}';

  @override
  void initState() {
    super.initState();
    _loadMetodologias();
    _loadRascunho();
  }

  Color _getColorForGrupo(GrupoBiologico? tipo) {
    if (tipo == null) return Color(0xFF8D6E63);
    switch (tipo) {
      case GrupoBiologico.ictiofauna: return Color(0xFF1976D2);
      case GrupoBiologico.herpetofauna: return Color(0xFF8D6E63);
      case GrupoBiologico.avifauna: return Color(0xFF388E3C);
      case GrupoBiologico.mastofauna: return Color(0xFF7B1FA2);
      case GrupoBiologico.entomofauna: return Color(0xFFFF8F00);
      case GrupoBiologico.macroinvertebrados: return Color(0xFF00796B);
      case GrupoBiologico.flora: return Color(0xFF558B2F);
      case GrupoBiologico.zooplancton: return Color(0xFF0097A7);
      case GrupoBiologico.fitoplancton: return Color(0xFF43A047);
    }
  }

  Future<void> _loadMetodologias() async {
    setState(() => _isLoadingMetodologias = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;
      if (userId != null && widget.grupoFauna.tipo != null) {
        final metodologias = await DatabaseHelper.instance.getMetodologiasByGrupo(
          widget.grupoFauna.tipo!.code,
          userId,
        );
        setState(() => _metodologiasCadastradas = metodologias);
      }
    } catch (e) {
      print('Erro ao carregar metodologias: $e');
    }
    setState(() => _isLoadingMetodologias = false);
  }

  Future<void> _loadRascunho() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rascunhoTexto = prefs.getString(_storageKey);
      if (rascunhoTexto != null && rascunhoTexto.isNotEmpty) {
        setState(() => _textController.text = rascunhoTexto);
      }
    } catch (e) {
      print('Erro ao carregar rascunho: $e');
    }
  }

  Future<void> _saveRascunho() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _textController.text);
    } catch (e) {
      print('Erro ao salvar rascunho: $e');
    }
  }

  Future<void> _clearRascunho() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Erro ao limpar rascunho: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isProcessado) {
          await _saveRascunho();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF8F6F4),
        appBar: AppBar(
          title: Text(_isProcessado ? 'Selecionar Coletas' : 'Bloco de Notas'),
          backgroundColor: _grupoColor,
          foregroundColor: Colors.white,
          actions: [
            if (!_isProcessado)
              IconButton(
                onPressed: _confirmarLimpar,
                icon: Icon(Icons.delete_outline),
                tooltip: 'Limpar tudo',
              ),
            if (_isProcessado)
              IconButton(
                onPressed: () {
                  setState(() {
                    _isProcessado = false;
                    _coletasProcessadas.clear();
                  });
                },
                icon: Icon(Icons.edit),
                tooltip: 'Voltar ao bloco',
              ),
          ],
        ),
        body: _isProcessado ? _buildSelecaoView() : _buildBlocoNotasView(),
      ),
    );
  }

  Widget _buildBlocoNotasView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 Bloco salvo automaticamente',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Suas anotações não serão perdidas ao sair',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Contexto
          Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: _grupoColor, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.ponto.nome ?? 'Ponto sem nome',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('${widget.grupoFauna.nomeExibicao} • ${widget.campanha.nomeExibicao}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Bloco de notas
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note, color: _grupoColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Suas Anotações',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Digite livremente suas observações...\n\nExemplo:\nTangara cayana 3\nTurdus leucomelas 2\nThraupis sayaca 5\n\nVocê pode processar quando quiser!',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _grupoColor, width: 2),
                      ),
                    ),
                    maxLines: 15,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 14),
                    onChanged: (_) => _saveRascunho(),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 16, color: Colors.grey[700]),
                            SizedBox(width: 8),
                            Text(
                              'Formatos reconhecidos:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• Tangara cayana 3\n'
                              '• Tangara cayana - 3\n'
                              '• 3 Tangara cayana\n'
                              '• Sabiá-laranjeira 2',
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Botão processar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _textController.text.trim().isEmpty ? null : _processar,
              icon: Icon(Icons.checklist),
              label: Text('Processar e Selecionar', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _grupoColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelecaoView() {
    final selecionadas = _coletasProcessadas.where((c) => c.selecionada).length;
    final total = _coletasProcessadas.length;

    return Column(
      children: [
        // Metodologia
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _grupoColor.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.science, color: _grupoColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Metodologia (opcional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _grupoColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.settings, color: _grupoColor),
                ),
                value: _metodologiaSelecionada,
                hint: Text('Preencher depois'),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Nenhuma (preencher depois)', style: TextStyle(fontStyle: FontStyle.italic)),
                  ),
                  ..._metodologiasCadastradas.map((m) {
                    return DropdownMenuItem(value: m.nome, child: Text(m.nome));
                  }).toList(),
                ],
                onChanged: (value) => setState(() => _metodologiaSelecionada = value),
              ),
            ],
          ),
        ),

        // Resumo
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _grupoColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selecione o que deseja salvar:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _grupoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$selecionadas de $total',
                  style: TextStyle(
                    color: _grupoColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),

        // Lista com checkboxes
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _coletasProcessadas.length,
            itemBuilder: (context, index) {
              final coleta = _coletasProcessadas[index];
              return _buildColetaCheckItem(coleta, index);
            },
          ),
        ),

        // Botão salvar
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: selecionadas == 0 || _isSaving ? null : _salvarSelecionados,
                  icon: _isSaving
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(Icons.check_circle),
                  label: Text(
                    _isSaving ? 'Salvando...' : 'Salvar Selecionados ($selecionadas)',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (selecionadas < total) ...[
                SizedBox(height: 8),
                Text(
                  '${total - selecionadas} não selecionadas permanecerão no bloco',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColetaCheckItem(ColetaRapida coleta, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: coleta.selecionada ? Colors.white : Colors.grey.shade50,
      child: CheckboxListTile(
        value: coleta.selecionada,
        onChanged: (value) {
          setState(() => coleta.selecionada = value ?? false);
        },
        title: Text(
          coleta.especie,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: coleta.selecionada ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: Text('Quantidade: ${coleta.quantidade}'),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: coleta.selecionada ? _grupoColor : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              coleta.quantidade.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        activeColor: _grupoColor,
      ),
    );
  }

  void _processar() {
    final coletas = _parseTexto(_textController.text);

    if (coletas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhuma espécie reconhecida. Verifique o formato.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _coletasProcessadas = coletas;
      _isProcessado = true;
    });
  }

  List<ColetaRapida> _parseTexto(String texto) {
    final linhas = texto.split('\n');
    final coletas = <ColetaRapida>[];

    for (final linha in linhas) {
      final limpa = linha.trim();
      if (limpa.isEmpty) continue;

      // "Nome 3" ou "Nome - 3" ou "Nome: 3"
      var match = RegExp(r'^(.+?)[:\-]?\s+(\d+)$').firstMatch(limpa);

      if (match != null) {
        coletas.add(ColetaRapida(
          especie: match.group(1)!.trim(),
          quantidade: int.parse(match.group(2)!),
          selecionada: true,
        ));
        continue;
      }

      // "3 Nome" ou "3x Nome"
      match = RegExp(r'^(\d+)x?\s+(.+)$').firstMatch(limpa);
      if (match != null) {
        coletas.add(ColetaRapida(
          especie: match.group(2)!.trim(),
          quantidade: int.parse(match.group(1)!),
          selecionada: true,
        ));
      }
    }

    return coletas;
  }

  Future<void> _salvarSelecionados() async {
    final selecionadas = _coletasProcessadas.where((c) => c.selecionada).toList();

    if (selecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione pelo menos uma espécie'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final dataHora = DateTime.now();

      for (final coleta in selecionadas) {
        await db.insert('coletas', {
          'ponto_coleta_id': widget.ponto.id,
          'metodologia': _metodologiaSelecionada,
          'especie': coleta.especie,
          'nome_popular': null,
          'quantidade': coleta.quantidade,
          'caminho_foto': null,
          'data_hora': dataHora.toIso8601String(),
          'observacoes': null,
        });
      }

      // Recarregar coletas
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.loadColetasByPonto(widget.ponto.id!);

      // Remover selecionadas do texto
      final naoSelecionadas = _coletasProcessadas.where((c) => !c.selecionada).toList();

      if (naoSelecionadas.isEmpty) {
        // Tudo foi salvo - limpar bloco
        _textController.clear();
        await _clearRascunho();

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selecionadas.length} coletas salvas! Bloco limpo.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Reconstruir texto só com não selecionadas
        final novoTexto = naoSelecionadas.map((c) => '${c.especie} ${c.quantidade}').join('\n');
        _textController.text = novoTexto;
        await _saveRascunho();

        setState(() {
          _isProcessado = false;
          _coletasProcessadas.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selecionadas.length} salvas! ${naoSelecionadas.length} ficaram no bloco.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isSaving = false);
  }

  void _confirmarLimpar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Limpar Bloco'),
          ],
        ),
        content: Text('Tem certeza que deseja limpar todas as anotações?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              _textController.clear();
              await _clearRascunho();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bloco limpo!'), backgroundColor: Colors.orange),
              );
            },
            child: Text('Limpar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}