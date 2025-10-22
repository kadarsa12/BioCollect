import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../models/campanha.dart';
import '../models/ponto_coleta.dart';
import '../models/enums.dart';
import '../providers/project_provider.dart';
import '../providers/user_provider.dart';
import '../models/metodologia.dart';
import '../utils/database_helper.dart';

// CLASSE EspecieColetada
class EspecieColetada {
  final String especie;
  final String? nomePopular;
  final int quantidade;
  final String? caminhoFoto;
  final String? observacoes;

  EspecieColetada({
    required this.especie,
    this.nomePopular,
    required this.quantidade,
    this.caminhoFoto,
    this.observacoes,
  });
}

class CreateColetaScreen extends StatefulWidget {
  final PontoColeta ponto;
  final Projeto projeto;
  final GrupoFauna grupoFauna;
  final Campanha campanha;

  CreateColetaScreen({
    required this.ponto,
    required this.projeto,
    required this.grupoFauna,
    required this.campanha,
  });

  @override
  _CreateColetaScreenState createState() => _CreateColetaScreenState();
}

class _CreateColetaScreenState extends State<CreateColetaScreen>
    with SingleTickerProviderStateMixin {

  final _especieController = TextEditingController();
  final _nomePopularController = TextEditingController();
  final _quantidadeController = TextEditingController(text: '1');
  final _observacoesController = TextEditingController();

  String? _metodologiaSelecionada;
  List<Metodologia> _metodologiasCadastradas = [];
  bool _isLoadingMetodologias = false;

  List<EspecieColetada> _especiesColetadas = [];

  File? _imagemCapturada;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Color get _grupoColor => _getColorForGrupo(widget.grupoFauna.tipo);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadMetodologias();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _especieController.dispose();
    _nomePopularController.dispose();
    _quantidadeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  // MÉTODO _getColorForGrupo
  Color _getColorForGrupo(GrupoBiologico? tipo) {
    if (tipo == null) return Color(0xFF8D6E63); // Marrom padrão

    switch (tipo) {
      case GrupoBiologico.ictiofauna: // ✅ Lowercase
        return Color(0xFF1976D2); // Azul
      case GrupoBiologico.herpetofauna: // ✅ Lowercase
        return Color(0xFF8D6E63); // Marrom
      case GrupoBiologico.avifauna: // ✅ Lowercase
        return Color(0xFF388E3C); // Verde
      case GrupoBiologico.mastofauna: // ✅ Lowercase
        return Color(0xFF7B1FA2); // Roxo
      case GrupoBiologico.entomofauna: // ✅ Lowercase
        return Color(0xFFFF8F00); // Laranja
      case GrupoBiologico.macroinvertebrados:
        return Color(0xFF00796B); // Verde água
      case GrupoBiologico.flora:
        return Color(0xFF558B2F); // Verde escuro
      case GrupoBiologico.zooplancton:
        return Color(0xFF0097A7); // Ciano
      case GrupoBiologico.fitoplancton:
        return Color(0xFF43A047); // Verde claro
    }
  }

  Future<void> _loadMetodologias() async {
    setState(() => _isLoadingMetodologias = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;

      if (userId != null && widget.grupoFauna.tipo != null) {
        final metodologias = await DatabaseHelper.instance
            .getMetodologiasByGrupo(
          widget.grupoFauna.tipo!.code,
          userId,
        );

        setState(() {
          _metodologiasCadastradas = metodologias;
        });
      }
    } catch (e) {
      print('Erro ao carregar metodologias: $e');
    }

    setState(() => _isLoadingMetodologias = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_grupoColor, _grupoColor.withOpacity(0.8)],
                  ),
                ),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nova Coleta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${widget.ponto.nome ?? "Ponto"} • ${widget.grupoFauna
                        .nomeExibicao}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    widget.campanha.nomeExibicao,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              if (_especiesColetadas.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_especiesColetadas.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                onPressed: _especiesColetadas.isNotEmpty
                    ? _finalizarColetas
                    : null,
                icon: Icon(Icons.check, color: Colors.white),
                tooltip: 'Finalizar',
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMetodologiaCard(),
                    SizedBox(height: 16),

                    if (_especiesColetadas.isNotEmpty) ...[
                      _buildEspeciesColetadasCard(),
                      SizedBox(height: 16),
                    ],

                    if (_metodologiaSelecionada != null) ...[
                      _buildFormularioEspecieCard(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodologiaCard() {
    return Container(
      padding: EdgeInsets.all(20),
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _grupoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.science, color: _grupoColor, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Metodologia de Coleta',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Selecione a metodologia',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _grupoColor, width: 2),
              ),
              prefixIcon: Icon(Icons.settings, color: _grupoColor),
            ),
            value: _metodologiaSelecionada,
            items: [
              ..._metodologiasCadastradas.map((metodologia) {
                return DropdownMenuItem(
                  value: metodologia.nome,
                  child: Text(metodologia.nome),
                );
              }).toList(),
              DropdownMenuItem(
                value: "CRIAR_NOVO",
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: _grupoColor),
                    SizedBox(width: 8),
                    Text(
                      'Criar novo método...',
                      style: TextStyle(
                        color: _grupoColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value == "CRIAR_NOVO") {
                _showCreateMetodologiaDialog();
              } else {
                setState(() => _metodologiaSelecionada = value);
              }
            },
          ),

          if (_metodologiasCadastradas.isEmpty && !_isLoadingMetodologias)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Nenhuma metodologia cadastrada para ${widget.grupoFauna
                    .nomeExibicao}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEspeciesColetadasCard() {
    return Container(
      padding: EdgeInsets.all(20),
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Espécies Coletadas (${_especiesColetadas.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
              Text(
                'Total: ${_especiesColetadas.fold<int>(
                    0, (sum, e) => sum + e.quantidade)}',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          ...(_especiesColetadas
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final especie = entry.value;
            return _buildEspecieColetadaItem(especie, index);
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildEspecieColetadaItem(EspecieColetada especie, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          if (especie.caminhoFoto != null)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                    File(especie.caminhoFoto!), fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _grupoColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    especie.quantidade.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'QTD',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  especie.especie,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                if (especie.nomePopular != null &&
                    especie.nomePopular!.isNotEmpty)
                  Text(
                    especie.nomePopular!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                Text(
                  'Qtd: ${especie.quantidade}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),

          Row(
            children: [
              IconButton(
                onPressed: () => _editarEspecie(index),
                icon: Icon(Icons.edit, size: 18),
                color: Colors.blue,
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: () => _removerEspecie(index),
                icon: Icon(Icons.delete, size: 18),
                color: Colors.red,
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioEspecieCard() {
    return Container(
      padding: EdgeInsets.all(20),
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add, color: Colors.blue, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Adicionar Espécie',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _especieController,
            decoration: InputDecoration(
              labelText: 'Espécie (nome científico)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _grupoColor, width: 2),
              ),
              prefixIcon: Icon(Icons.pets, color: _grupoColor),
              hintText: 'Ex: Astyanax lacustris',
            ),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _nomePopularController,
                  decoration: InputDecoration(
                    labelText: 'Nome popular',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _grupoColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.label, color: _grupoColor),
                    hintText: 'Ex: lambari',
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _quantidadeController,
                  decoration: InputDecoration(
                    labelText: 'Qtd',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _grupoColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.numbers, color: _grupoColor),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          _buildCapturaFotoSection(),
          SizedBox(height: 16),

          TextFormField(
            controller: _observacoesController,
            decoration: InputDecoration(
              labelText: 'Observações (opcional)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _grupoColor, width: 2),
              ),
              prefixIcon: Icon(Icons.note, color: _grupoColor),
            ),
            maxLines: 2,
          ),
          SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _limparFormulario,
                  icon: Icon(Icons.clear),
                  label: Text('Limpar'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600]),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _adicionarEspecie,
                  icon: Icon(Icons.add),
                  label: Text('Adicionar Espécie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _grupoColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapturaFotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto do Exemplar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D4037),
          ),
        ),
        SizedBox(height: 8),

        if (_imagemCapturada != null) ...[
          Container(
            height: 120,
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_imagemCapturada!, fit: BoxFit.cover),
            ),
          ),
        ],

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _capturarFoto(ImageSource.camera),
                icon: Icon(Icons.camera, size: 18),
                label: Text('Câmera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _grupoColor,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _capturarFoto(ImageSource.gallery),
                icon: Icon(Icons.photo_library, size: 18),
                label: Text('Galeria'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _grupoColor,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            if (_imagemCapturada != null) ...[
              SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => setState(() => _imagemCapturada = null),
                child: Icon(Icons.delete, color: Colors.red, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _adicionarEspecie() {
    if (_especieController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Digite o nome da espécie'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final quantidade = int.tryParse(_quantidadeController.text);
    if (quantidade == null || quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Digite uma quantidade válida'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final novaEspecie = EspecieColetada(
      especie: _especieController.text.trim(),
      nomePopular: _nomePopularController.text
          .trim()
          .isEmpty ? null : _nomePopularController.text.trim(),
      quantidade: quantidade,
      caminhoFoto: _imagemCapturada?.path,
      observacoes: _observacoesController.text
          .trim()
          .isEmpty ? null : _observacoesController.text.trim(),
    );

    setState(() => _especiesColetadas.add(novaEspecie));
    _limparFormulario();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${novaEspecie.especie} adicionada!'),
          backgroundColor: Colors.green),
    );
  }

  void _limparFormulario() {
    _especieController.clear();
    _nomePopularController.clear();
    _quantidadeController.text = '1';
    _observacoesController.clear();
    setState(() => _imagemCapturada = null);
  }

  void _editarEspecie(int index) {
    final especie = _especiesColetadas[index];
    _especieController.text = especie.especie;
    _nomePopularController.text = especie.nomePopular ?? '';
    _quantidadeController.text = especie.quantidade.toString();
    _observacoesController.text = especie.observacoes ?? '';

    if (especie.caminhoFoto != null) {
      _imagemCapturada = File(especie.caminhoFoto!);
    }

    setState(() => _especiesColetadas.removeAt(index));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${especie.especie} carregada para edição'),
          backgroundColor: Colors.blue),
    );
  }

  void _removerEspecie(int index) {
    final especie = _especiesColetadas[index];

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: Text('Remover Espécie'),
            content: Text('Deseja remover "${especie.especie}" da lista?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  setState(() => _especiesColetadas.removeAt(index));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${especie.especie} removida'),
                        backgroundColor: Colors.orange),
                  );
                },
                child: Text('Remover'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
              ),
            ],
          ),
    );
  }

  Future<void> _capturarFoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _imagemCapturada = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar foto: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showCreateMetodologiaDialog() {
    final nomeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: Text('Nova Metodologia'),
            content: TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome da metodologia',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                hintText: 'Ex: Puçá malha 5mm',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (nomeController.text
                      .trim()
                      .isNotEmpty) {
                    await _createMetodologiaRapida(nomeController.text.trim());
                    Navigator.pop(context);
                  }
                },
                child: Text('Criar'),
                style: ElevatedButton.styleFrom(backgroundColor: _grupoColor,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
    );
  }
  Future<void> _createMetodologiaRapida(String nomeMetodologia) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;

      if (userId == null || widget.grupoFauna.tipo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: Usuário ou grupo não identificado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Criar metodologia no banco
      final novaMetodologia = Metodologia(
        nome: nomeMetodologia,
        descricao: null, // ✅ Opcional
        grupoBiologico: widget.grupoFauna.tipo!.code,
        usuarioId: userId, // ✅ Nome correto
        dataCriacao: DateTime.now(), // ✅ Adicionado
      );

      await DatabaseHelper.instance.insertMetodologia(novaMetodologia);

      // Recarregar lista
      await _loadMetodologias();

      // Selecionar automaticamente
      setState(() {
        _metodologiaSelecionada = nomeMetodologia;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Metodologia "$nomeMetodologia" criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar metodologia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _finalizarColetas() async {
    if (_especiesColetadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adicione pelo menos uma espécie'),
            backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                Icon(Icons.save, color: Colors.green),
                SizedBox(width: 8),
                Text('Finalizar Coleta'), // Completed the title text
              ],
            ),
            content: Text(
              'Confirma o registro de ${_especiesColetadas
                  .length} espécies coletadas com a metodologia "${_metodologiaSelecionada}" neste ponto?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog

                  // TODO: Logic to save the collections (EspecieColetada list, methodology, point, etc.)
                  // This is where you would call your DatabaseHelper or API to persist the data.

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                        'Coletas finalizadas e salvas! (Implementação pendente)'),
                        backgroundColor: Colors.green),
                  );

                  // Optionally, navigate back after saving
                  // Navigator.of(context).pop();
                },
                child: Text('Salvar Coletas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }
}