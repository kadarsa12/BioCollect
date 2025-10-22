import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../models/campanha.dart';
import '../models/ponto_coleta.dart';
import '../models/enums.dart';
import '../providers/project_provider.dart';
import 'ponto_detail_screen.dart';
import 'create_ponto_screen.dart';

class CampanhaDetailScreen extends StatefulWidget {
  final Projeto projeto;
  final GrupoFauna grupoFauna;
  final Campanha campanha;

  CampanhaDetailScreen({
    required this.projeto,
    required this.grupoFauna,
    required this.campanha,
  });

  @override
  _CampanhaDetailScreenState createState() => _CampanhaDetailScreenState();
}

class _CampanhaDetailScreenState extends State<CampanhaDetailScreen>
    with SingleTickerProviderStateMixin {
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
    _loadPontos();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColorForGrupo(GrupoBiologico? tipo) {
    if (tipo == null) return Color(0xFF8D6E63);

    switch (tipo) {
      case GrupoBiologico.ictiofauna:
        return Color(0xFF1976D2);
      case GrupoBiologico.herpetofauna:
        return Color(0xFF8D6E63);
      case GrupoBiologico.avifauna:
        return Color(0xFF388E3C);
      case GrupoBiologico.mastofauna:
        return Color(0xFF7B1FA2);
      case GrupoBiologico.entomofauna:
        return Color(0xFFFF8F00);
      case GrupoBiologico.macroinvertebrados:
        return Color(0xFF00796B);
      case GrupoBiologico.flora:
        return Color(0xFF558B2F);
      case GrupoBiologico.zooplancton:
        return Color(0xFF0097A7);
      case GrupoBiologico.fitoplancton:
        return Color(0xFF43A047);
    }
  }

  Color _getStatusColor(StatusCampanha? status) {
    if (status == null) return Colors.grey;

    switch (status) {
      case StatusCampanha.planejada:
        return Colors.orange;
      case StatusCampanha.ativa:
        return Colors.green;
      case StatusCampanha.concluida:
        return Colors.blue;
    }
  }

  Future<void> _loadPontos() async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    await projectProvider.loadPontosByCampanha(widget.campanha.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      body: CustomScrollView(
        slivers: [
          // AppBar com gradiente da cor do grupo
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _grupoColor,
                      _grupoColor.withOpacity(0.8),
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
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.campanha.nomeExibicao,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    widget.grupoFauna.nomeExibicao,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              // Badge com status da campanha
              Container(
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.campanha.status).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(widget.campanha.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.campanha.status?.value.toUpperCase() ?? 'N/A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Conteúdo principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Card de informações da campanha
                  _buildCampanhaInfoCard(),

                  // Header da lista de pontos
                  _buildSectionHeader(),
                ],
              ),
            ),
          ),

          // Lista de pontos
          Consumer<ProjectProvider>(
            builder: (context, projectProvider, child) {
              if (projectProvider.isLoading) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: _grupoColor,
                      ),
                    ),
                  ),
                );
              }

              if (projectProvider.pontosColeta.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final ponto = projectProvider.pontosColeta[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _buildPontoCard(ponto),
                      ),
                    );
                  },
                  childCount: projectProvider.pontosColeta.length,
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
        onPressed: _navigateToCreatePonto,
        label: Text('Novo Ponto'),
        icon: Icon(Icons.add_location),
        backgroundColor: _grupoColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCampanhaInfoCard() {
    return Container(
      margin: EdgeInsets.all(16),
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
                child: Icon(
                  Icons.calendar_month,
                  color: _grupoColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Informações da Campanha',
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

          // Informações
          _buildInfoRow(
            Icons.event,
            'Período',
            widget.campanha.periodo ?? 'Não informado',
          ),
          if (widget.campanha.dataInicio != null)
            _buildInfoRow(
              Icons.calendar_today,
              'Data Início',
              '${widget.campanha.dataInicio!.day}/${widget.campanha.dataInicio!.month}/${widget.campanha.dataInicio!.year}',
            ),
          if (widget.campanha.dataFim != null)
            _buildInfoRow(
              Icons.event_available,
              'Data Fim',
              '${widget.campanha.dataFim!.day}/${widget.campanha.dataFim!.month}/${widget.campanha.dataFim!.year}',
            ),
          if (widget.campanha.observacoes != null && widget.campanha.observacoes!.isNotEmpty)
            _buildInfoRow(
              Icons.note,
              'Observações',
              widget.campanha.observacoes!,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _grupoColor),
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
      ),
    );
  }

  Widget _buildSectionHeader() {
    final totalPontos = Provider.of<ProjectProvider>(context).pontosColeta.length;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: _grupoColor,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pontos de Coleta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          if (totalPontos > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _grupoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalPontos ${totalPontos == 1 ? 'ponto' : 'pontos'}',
                style: TextStyle(
                  fontSize: 12,
                  color: _grupoColor,
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
              Icons.location_off,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Nenhum ponto cadastrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Toque em "Novo Ponto" para adicionar\no primeiro ponto de coleta desta campanha',
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

  Widget _buildPontoCard(PontoColeta ponto) {
    final hasCoordinates = ponto.latitude != null &&
        ponto.longitude != null &&
        ponto.latitude != 0.0 &&
        ponto.longitude != 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToPontoDetail(ponto),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone de localização
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _grupoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasCoordinates ? Icons.location_on : Icons.location_off,
                  color: hasCoordinates ? _grupoColor : Colors.orange,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),

              // Info do ponto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ponto.nome ?? 'Ponto sem nome',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    SizedBox(height: 4),
                    if (hasCoordinates)
                      Text(
                        '${ponto.latitude!.toStringAsFixed(6)}, ${ponto.longitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        'Coordenadas não informadas',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    if (ponto.dataHora != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Text(
                            '${ponto.dataHora!.day}/${ponto.dataHora!.month}/${ponto.dataHora!.year}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Seta
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPontoDetail(PontoColeta ponto) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PontoDetailScreen(
          ponto: ponto,
          projeto: widget.projeto,
          grupoFauna: widget.grupoFauna,
          campanha: widget.campanha,
        ),
      ),
    ).then((_) => _loadPontos());
  }

  void _navigateToCreatePonto() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePontoScreen(
          projeto: widget.projeto,
          grupoFauna: widget.grupoFauna,
          campanha: widget.campanha,
        ),
      ),
    ).then((_) => _loadPontos());
  }
}