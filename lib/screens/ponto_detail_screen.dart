import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../models/campanha.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../models/enums.dart';
import '../providers/project_provider.dart';
import 'create_coleta_screen.dart';
import 'edit_ponto_screen.dart';
import 'edit_coleta_screen.dart';
import '../utils/database_helper.dart';
import 'dart:io';
import 'coleta_rapida_screen.dart';

class PontoDetailScreen extends StatefulWidget {
  final PontoColeta ponto;
  final Projeto projeto;
  final GrupoFauna grupoFauna;
  final Campanha campanha;

  const PontoDetailScreen({
    required this.ponto,
    required this.projeto,
    required this.grupoFauna,
    required this.campanha,
  });

  @override
  State<PontoDetailScreen> createState() => _PontoDetailScreenState();
}

class _PontoDetailScreenState extends State<PontoDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<String, List<Coleta>> _coletasAgrupadas = {};

  Color get _grupoColor => _getColorForGrupo(widget.grupoFauna.tipo);

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _loadColetas();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColorForGrupo(GrupoBiologico? tipo) {
    switch (tipo) {
      case GrupoBiologico.ictiofauna:
        return const Color(0xFF1976D2);
      case GrupoBiologico.herpetofauna:
        return const Color(0xFF8D6E63);
      case GrupoBiologico.avifauna:
        return const Color(0xFF388E3C);
      case GrupoBiologico.mastofauna:
        return const Color(0xFF7B1FA2);
      case GrupoBiologico.entomofauna:
        return const Color(0xFFFF8F00);
      case GrupoBiologico.macroinvertebrados:
        return const Color(0xFF00796B);
      case GrupoBiologico.flora:
        return const Color(0xFF558B2F);
      case GrupoBiologico.zooplancton:
        return const Color(0xFF0097A7);
      case GrupoBiologico.fitoplancton:
        return const Color(0xFF43A047);
      default:
        return const Color(0xFF546E7A);
    }
  }

  Future<void> _loadColetas() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    await provider.loadColetasByPonto(widget.ponto.id!);

    _coletasAgrupadas.clear();
    for (var coleta in provider.coletas) {
      final key = coleta.metodologia ?? "Sem metodologia";
      _coletasAgrupadas.putIfAbsent(key, () => []).add(coleta);
    }

    _coletasAgrupadas.forEach((_, lista) {
      lista.sort((a, b) => (a.especie ?? '').compareTo(b.especie ?? ''));
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F4),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text("Nova Coleta"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateColetaScreen(
                ponto: widget.ponto,
                projeto: widget.projeto,
                grupoFauna: widget.grupoFauna,
                campanha: widget.campanha,
              ),
            ),
          ).then((_) => _loadColetas());
        },
      ),
      body: CustomScrollView(
        slivers: [
          // --- AppBar ---
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: _grupoColor,
            automaticallyImplyLeading: true,
            leading: const BackButton(color: Colors.white),
            title: Text(
              widget.ponto.nome ?? 'Ponto',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_grupoColor, _grupoColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bolt, color: Colors.white),
                tooltip: 'Coleta Rápida',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ColetaRapidaScreen(
                        ponto: widget.ponto,
                        projeto: widget.projeto,
                        grupoFauna: widget.grupoFauna,
                        campanha: widget.campanha,
                      ),
                    ),
                  ).then((_) => _loadColetas());
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPontoScreen(
                          ponto: widget.ponto,
                          projeto: widget.projeto,
                        ),
                      ),
                    ).then((_) => _loadColetas());
                  }
                  if (value == 'info') _showPontoInfo();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: _grupoColor),
                        const SizedBox(width: 8),
                        const Text("Editar ponto"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _grupoColor),
                        const SizedBox(width: 8),
                        const Text("Informações"),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),

          // --- Info Card ---
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildInfoCard(),
              ),
            ),
          ),

          // --- Cabeçalho de seção ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.science, color: _grupoColor),
                  const SizedBox(width: 8),
                  const Text("Coletas por Metodologia",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),

          // --- Lista ---
          Consumer<ProjectProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      )),
                );
              }

              if (_coletasAgrupadas.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyState());
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final metodologia = _coletasAgrupadas.keys.elementAt(i);
                    final coletas = _coletasAgrupadas[metodologia]!;
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMetodologiaCard(metodologia, coletas),
                    );
                  },
                  childCount: _coletasAgrupadas.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // --- Card de informações ---
  Widget _buildInfoCard() {
    final p = widget.ponto;
    final c = widget.campanha;
    final hasCoord = (p.latitude != 0.0 && p.longitude != 0.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _grupoColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Icon(Icons.location_on, color: _grupoColor),
            const SizedBox(width: 8),
            const Text("Informações do Ponto",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 16),
        _infoItem(Icons.my_location, "Coordenadas",
            hasCoord ? "${p.latitude}, ${p.longitude}" : "Não informadas"),
        _infoItem(Icons.access_time, "Data/Hora",
            p.dataHora?.toString() ?? "Sem data"),
        _infoItem(Icons.science, "Grupo", widget.grupoFauna.nomeExibicao),
        _infoItem(Icons.calendar_today, "Campanha", c.nomeExibicao),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.bolt),
          label: const Text('Coleta Rápida'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ColetaRapidaScreen(
                  ponto: widget.ponto,
                  projeto: widget.projeto,
                  grupoFauna: widget.grupoFauna,
                  campanha: widget.campanha,
                ),
              ),
            ).then((_) => _loadColetas());
          },
        ),
      ]),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: _grupoColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 12)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5D4037))),
              ]),
        ),
      ],
    ),
  );

  // --- Cada metodologia ---
  Widget _buildMetodologiaCard(String metodologia, List<Coleta> coletas) {
    final totalExemplares =
    coletas.fold(0, (sum, coleta) => sum + (coleta.quantidade ?? 0));
    final totalEspecies = coletas.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          collapsedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _grupoColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metodologia.isNotEmpty ? metodologia : "Sem metodologia",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _grupoColor,
                      ),
                    ),
                    Text(
                      '$totalEspecies espécies · $totalExemplares exemplares',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.add_circle, color: _grupoColor),
            tooltip: 'Adicionar espécie',
            onPressed: () => _adicionarNovaEspecieNaMetodologia(metodologia),
          ),
          children: coletas.map((coleta) {
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  // --- Foto ou ícone ---
                  if (coleta.caminhoFoto != null &&
                      coleta.caminhoFoto!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(coleta.caminhoFoto!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _grupoColor.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.image, color: Colors.grey[400]),
                    ),
                  const SizedBox(width: 12),

                  // --- Nome + quantidade ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(coleta.especie ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF5D4037))),
                        if (coleta.nomePopular != null &&
                            coleta.nomePopular!.isNotEmpty)
                          Text(coleta.nomePopular!,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 13)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.numbers,
                                size: 13, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${coleta.quantidade ?? 0} exemplares',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Botões ---
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.exposure, color: Colors.orange),
                        tooltip: 'Alterar quantidade',
                        onPressed: () => _editarQuantidadeRapida(coleta),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar espécie',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditColetaScreen(
                                coleta: coleta,
                                ponto: widget.ponto,
                                projeto: widget.projeto,
                                grupoFauna: widget.grupoFauna,
                                campanha: widget.campanha,
                              ),
                            ),
                          ).then((_) => _loadColetas());
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- Estado vazio ---
  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(Icons.science_outlined, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        const Text("Nenhuma coleta registrada",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          "Toque em 'Nova Coleta' para registrar a primeira coleta neste ponto.",
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  // --- Auxiliares ---
  void _adicionarNovaEspecieNaMetodologia(String metodologia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateColetaScreen(
          ponto: widget.ponto,
          projeto: widget.projeto,
          grupoFauna: widget.grupoFauna,
          campanha: widget.campanha,
        ),
      ),
    ).then((_) => _loadColetas());
  }

  void _showPontoInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: _grupoColor),
            const SizedBox(width: 8),
            const Text("Detalhes do Ponto"),
          ],
        ),
        content: Text(
            "Nome: ${widget.ponto.nome}\nProjeto: ${widget.projeto.nome}\nGrupo: ${widget.grupoFauna.nomeExibicao}\nCampanha: ${widget.campanha.nomeExibicao}"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fechar"))
        ],
      ),
    );
  }

  void _editarQuantidadeRapida(Coleta coleta) async {
    final controller =
    TextEditingController(text: coleta.quantidade?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar Quantidade'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nova Quantidade'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final novaQtd = int.tryParse(controller.text);
              if (novaQtd != null && novaQtd > 0) {
                final db = await DatabaseHelper.instance.database;
                await db.update('coletas', {'quantidade': novaQtd},
                    where: 'id = ?', whereArgs: [coleta.id]);
                Navigator.pop(context);
                _loadColetas();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
