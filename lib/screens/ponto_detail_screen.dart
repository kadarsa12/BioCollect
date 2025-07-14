import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../providers/project_provider.dart';
import 'create_coleta_screen.dart';
import 'edit_ponto_screen.dart';
import 'edit_coleta_screen.dart';
import 'dart:io';
import '../utils/database_helper.dart';

class PontoDetailScreen extends StatefulWidget {
  final PontoColeta ponto;
  final Projeto projeto;

  PontoDetailScreen({
    required this.ponto,
    required this.projeto,
  });

  @override
  _PontoDetailScreenState createState() => _PontoDetailScreenState();
}

class _PontoDetailScreenState extends State<PontoDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Map para agrupar coletas por metodologia
  Map<String, List<Coleta>> _coletasAgrupadas = {};

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
    _loadColetas();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadColetas() async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    await projectProvider.loadColetasByPonto(widget.ponto.id!);

    // Agrupar coletas por metodologia
    _agruparColetasPorMetodologia(projectProvider.coletas);
  }

  void _agruparColetasPorMetodologia(List<Coleta> coletas) {
    _coletasAgrupadas.clear();

    for (final coleta in coletas) {
      // Tratar metodologia como opcional
      final metodologia = coleta.metodologia ?? 'Metodologia não informada';

      if (_coletasAgrupadas.containsKey(metodologia)) {
        _coletasAgrupadas[metodologia]!.add(coleta);
      } else {
        _coletasAgrupadas[metodologia] = [coleta];
      }
    }

    // Ordenar as espécies dentro de cada metodologia - CORRIGIDO para campos opcionais
    _coletasAgrupadas.forEach((metodologia, especies) {
      especies.sort((a, b) {
        final especieA = a.especie ?? 'Não identificada';
        final especieB = b.especie ?? 'Não identificada';
        return especieA.compareTo(especieB);
      });
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      body: CustomScrollView(
        slivers: [
          // AppBar moderna com gradiente
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8D6E63),
                      Color(0xFF5D4037),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(
                widget.ponto.nome,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value),
                icon: Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Color(0xFF8D6E63), size: 20),
                        SizedBox(width: 12),
                        Text('Editar Ponto'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF8D6E63), size: 20),
                        SizedBox(width: 12),
                        Text('Informações'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Conteúdo principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Card de informações do ponto
                  _buildPontoInfoCard(),

                  // Header da lista de coletas
                  _buildSectionHeader(),
                ],
              ),
            ),
          ),

          // Lista de metodologias agrupadas
          Consumer<ProjectProvider>(
            builder: (context, projectProvider, child) {
              if (projectProvider.isLoading) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                  ),
                );
              }

              if (_coletasAgrupadas.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final metodologia = _coletasAgrupadas.keys.elementAt(index);
                    final coletas = _coletasAgrupadas[metodologia]!;

                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildMetodologiaCard(metodologia, coletas),
                      ),
                    );
                  },
                  childCount: _coletasAgrupadas.length,
                ),
              );
            },
          ),

          // Espaçamento para o FAB
          SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateColetaScreen(
                ponto: widget.ponto,
                projeto: widget.projeto,
              ),
            ),
          ).then((_) => _loadColetas());
        },
        label: Text('Nova Coleta'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildPontoInfoCard() {
    final hasCoordinates = widget.ponto.latitude != 0.0 && widget.ponto.longitude != 0.0;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8D6E63).withOpacity(0.1),
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
                  color: Color(0xFF8D6E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Color(0xFF8D6E63),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Informações do Ponto',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Informações organizadas
          _buildInfoSection([
            _buildInfoItem(
              Icons.my_location,
              'Coordenadas',
              hasCoordinates
                  ? '${widget.ponto.latitude.toStringAsFixed(6)}, ${widget.ponto.longitude.toStringAsFixed(6)}'
                  : 'Não informadas',
              hasCoordinates ? Color(0xFF8D6E63) : Colors.orange,
            ),
            _buildInfoItem(
              Icons.access_time,
              'Data/Hora',
              '${widget.ponto.dataHora.day}/${widget.ponto.dataHora.month}/${widget.ponto.dataHora.year} ${widget.ponto.dataHora.hour}:${widget.ponto.dataHora.minute.toString().padLeft(2, '0')}',
              Color(0xFF8D6E63),
            ),
            _buildInfoItem(
              Icons.science,
              'Projeto',
              '${widget.projeto.nome} (${widget.projeto.grupoBiologico.displayName})',
              Color(0xFF8D6E63),
            ),
            if (widget.ponto.observacoes != null && widget.ponto.observacoes!.isNotEmpty)
              _buildInfoItem(
                Icons.note,
                'Observações',
                widget.ponto.observacoes!,
                Color(0xFF8D6E63),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoSection(List<Widget> items) {
    return Column(
      children: items.map((item) => Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: item,
      )).toList(),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    final totalMetodologias = _coletasAgrupadas.length;
    final totalColetas = _coletasAgrupadas.values
        .expand((coletas) => coletas)
        .fold(0, (sum, coleta) => sum + coleta.quantidade);

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.science,
            color: Color(0xFF8D6E63),
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Coletas por Metodologia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          if (totalMetodologias > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF8D6E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalMetodologias métodos • $totalColetas exemplares',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8D6E63),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.science,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Nenhuma coleta registrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Toque em "Nova Coleta" para registrar\na primeira coleta neste ponto',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetodologiaCard(String metodologia, List<Coleta> coletas) {
    final totalExemplares = coletas.fold(0, (sum, coleta) => sum + coleta.quantidade);
    final totalEspecies = coletas.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8D6E63).withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header da metodologia
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.science,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metodologia,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$totalEspecies espécies • $totalExemplares exemplares',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _adicionarNovaEspecieNaMetodologia(metodologia),
                  icon: Icon(Icons.add, color: Colors.white),
                  tooltip: 'Adicionar espécie',
                ),
              ],
            ),
          ),

          // Lista de espécies desta metodologia
          ...coletas.asMap().entries.map((entry) {
            final index = entry.key;
            final coleta = entry.value;
            final isLast = index == coletas.length - 1;

            return _buildEspecieItem(coleta, isLast);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEspecieItem(Coleta coleta, bool isLast) {
    // Tratar campos opcionais
    final especie = coleta.especie ?? 'Não identificada';
    final nomePopular = coleta.nomePopular ?? '';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        borderRadius: isLast ? BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ) : null,
      ),
      child: Row(
        children: [
          // Foto ou avatar com quantidade
          _buildColetaLeading(coleta),
          SizedBox(width: 16),

          // Info da espécie
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  especie,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF5D4037),
                  ),
                ),
                if (nomePopular.isNotEmpty)
                  Text(
                    nomePopular,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      '${coleta.dataHora.day}/${coleta.dataHora.month}/${coleta.dataHora.year} ${coleta.dataHora.hour}:${coleta.dataHora.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botões de ação horizontais
          Row(
            children: [
              _buildActionButton(
                Icons.exposure,
                Colors.orange,
                'Qtd',
                    () => _editarQuantidadeRapida(coleta),
              ),
              SizedBox(width: 8),
              _buildActionButton(
                Icons.edit,
                Colors.blue,
                'Edit',
                    () => _navigateToEdit(coleta),
              ),
              SizedBox(width: 8),
              _buildActionButton(
                Icons.visibility,
                Color(0xFF8D6E63),
                'Ver',
                    () => _showColetaDetail(coleta),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String tooltip, VoidCallback onPressed) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildColetaLeading(Coleta coleta) {
    if (coleta.caminhoFoto != null && coleta.caminhoFoto!.isNotEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(coleta.caminhoFoto!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey, size: 24),
              );
            },
          ),
        ),
      );
    } else {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              coleta.quantidade.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'QTD',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _adicionarNovaEspecieNaMetodologia(String metodologia) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateColetaScreen(
          ponto: widget.ponto,
          projeto: widget.projeto,
        ),
      ),
    ).then((_) => _loadColetas());
  }

  void _navigateToEdit(Coleta coleta) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditColetaScreen(
          coleta: coleta,
          ponto: widget.ponto,
          projeto: widget.projeto,
        ),
      ),
    ).then((_) => _loadColetas());
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditPontoScreen(
              ponto: widget.ponto,
              projeto: widget.projeto,
            ),
          ),
        ).then((_) => _loadColetas());
        break;
      case 'info':
        _showPontoInfo();
        break;
    }
  }

  void _editarQuantidadeRapida(Coleta coleta) {
    final _quantidadeController = TextEditingController(text: coleta.quantidade.toString());
    final especie = coleta.especie ?? 'Não identificada';
    final metodologia = coleta.metodologia ?? 'Não informada';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.exposure, color: Colors.orange),
            SizedBox(width: 8),
            Text('Alterar Quantidade'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Color(0xFF8D6E63), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          especie,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        Text(
                          'Metodologia: $metodologia',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _quantidadeController,
              decoration: InputDecoration(
                labelText: 'Nova Quantidade',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
                prefixIcon: Icon(Icons.numbers, color: Colors.orange),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final novaQuantidade = int.tryParse(_quantidadeController.text);
              if (novaQuantidade != null && novaQuantidade > 0) {
                await _salvarNovaQuantidade(coleta, novaQuantidade);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Digite um número válido maior que 0'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Salvar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarNovaQuantidade(Coleta coleta, int novaQuantidade) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'coletas',
        {'quantidade': novaQuantidade},
        where: 'id = ?',
        whereArgs: [coleta.id],
      );

      await _loadColetas();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quantidade alterada para $novaQuantidade'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar quantidade: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPontoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF8D6E63)),
            SizedBox(width: 8),
            Text('Detalhes do Ponto'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogInfoRow('Nome', widget.ponto.nome),
            _buildDialogInfoRow('Projeto', widget.projeto.nome),
            _buildDialogInfoRow('Grupo', widget.projeto.grupoBiologico.displayName),
            if (widget.ponto.latitude != 0.0 && widget.ponto.longitude != 0.0) ...[
              _buildDialogInfoRow('Latitude', widget.ponto.latitude.toStringAsFixed(8)),
              _buildDialogInfoRow('Longitude', widget.ponto.longitude.toStringAsFixed(8)),
            ] else ...[
              _buildDialogInfoRow('Coordenadas', 'Não informadas', isWarning: true),
            ],
            if (widget.ponto.observacoes != null && widget.ponto.observacoes!.isNotEmpty)
              _buildDialogInfoRow('Observações', widget.ponto.observacoes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF8D6E63),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isWarning ? Colors.orange : Color(0xFF5D4037),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColetaDetail(Coleta coleta) {
    // Tratar campos opcionais
    final especie = coleta.especie ?? 'Não identificada';
    final nomePopular = coleta.nomePopular ?? '';
    final metodologia = coleta.metodologia ?? 'Não informada';
    final observacoes = coleta.observacoes ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header moderno
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.science, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Detalhes da Coleta',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToEdit(coleta);
                      },
                      icon: Icon(Icons.edit, color: Colors.white),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Conteúdo
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto (se houver)
                      if (coleta.caminhoFoto != null && coleta.caminhoFoto!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          height: 200,
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(coleta.caminhoFoto!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'Foto não encontrada',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      // Informações organizadas em cards
                      _buildDetailCard('Identificação', [
                        _buildDetailRow('Espécie', especie),
                        if (nomePopular.isNotEmpty)
                          _buildDetailRow('Nome popular', nomePopular),
                      ]),

                      SizedBox(height: 16),

                      _buildDetailCard('Coleta', [
                        _buildDetailRow('Metodologia', metodologia),
                        _buildDetailRow('Quantidade', coleta.quantidade.toString()),
                        _buildDetailRow(
                          'Data/Hora',
                          '${coleta.dataHora.day}/${coleta.dataHora.month}/${coleta.dataHora.year} ${coleta.dataHora.hour}:${coleta.dataHora.minute.toString().padLeft(2, '0')}',
                        ),
                      ]),

                      if (observacoes.isNotEmpty) ...[
                        SizedBox(height: 16),
                        _buildDetailCard('Observações', [
                          Text(
                            observacoes,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5D4037),
                              height: 1.4,
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8D6E63),
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
        ],
      ),
    );
  }
}