import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../providers/project_provider.dart';
import 'create_coleta_screen.dart';
import 'edit_ponto_screen.dart';
import 'edit_coleta_screen.dart'; // Nova importação
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

class _PontoDetailScreenState extends State<PontoDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadColetas();
  }

  Future<void> _loadColetas() async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    await projectProvider.loadColetasByPonto(widget.ponto.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ponto.nome),
        actions: [
          // Botão de editar ponto
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditPontoScreen(
                    ponto: widget.ponto,
                    projeto: widget.projeto,
                  ),
                ),
              ).then((_) => _loadColetas());
            },
            tooltip: 'Editar Ponto',
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showPontoInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Card com informações do ponto
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Informações do Ponto',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (widget.ponto.latitude != 0.0 && widget.ponto.longitude != 0.0)
                    Text('Coordenadas: ${widget.ponto.latitude.toStringAsFixed(6)}, ${widget.ponto.longitude.toStringAsFixed(6)}')
                  else
                    Text('Coordenadas: Não informadas', style: TextStyle(color: Colors.orange)),
                  Text('Status: ${widget.ponto.status.value}'),
                  Text('Data/Hora: ${widget.ponto.dataHora.day}/${widget.ponto.dataHora.month}/${widget.ponto.dataHora.year} ${widget.ponto.dataHora.hour}:${widget.ponto.dataHora.minute.toString().padLeft(2, '0')}'),
                  if (widget.ponto.observacoes != null && widget.ponto.observacoes!.isNotEmpty)
                    Text('Observações: ${widget.ponto.observacoes}'),
                ],
              ),
            ),
          ),

          // Lista de coletas
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, projectProvider, child) {
                if (projectProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (projectProvider.coletas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma coleta registrada',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Toque no + para registrar uma coleta',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadColetas,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: projectProvider.coletas.length,
                    itemBuilder: (context, index) {
                      final coleta = projectProvider.coletas[index];
                      return _buildColetaCard(coleta);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildColetaCard(Coleta coleta) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            // Primeira linha - Info principal
            Row(
              children: [
                // Foto ou número
                _buildColetaLeading(coleta),
                SizedBox(width: 12),

                // Info da espécie
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coleta.especie,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (coleta.nomePopular != null && coleta.nomePopular!.isNotEmpty)
                        Text(
                          coleta.nomePopular!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      Text(
                        '${coleta.metodologia} • Qtd: ${coleta.quantidade}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botões de ação
                Column(
                  children: [
                    // Botão quantidade rápida
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.exposure, color: Colors.white, size: 20),
                        onPressed: () => _editarQuantidadeRapida(coleta),
                        tooltip: 'Alterar Quantidade',
                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ),
                    SizedBox(height: 4),
                    // Botão editar completo
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditColetaScreen(
                                coleta: coleta,
                                ponto: widget.ponto,
                                projeto: widget.projeto,
                              ),
                            ),
                          ).then((_) => _loadColetas());
                        },
                        tooltip: 'Editar Completo',
                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Segunda linha - Data e visualizar
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${coleta.dataHora.day}/${coleta.dataHora.month}/${coleta.dataHora.year} ${coleta.dataHora.hour}:${coleta.dataHora.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showColetaDetail(coleta),
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('Ver Detalhes', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void _editarQuantidadeRapida(Coleta coleta) {
    final _quantidadeController = TextEditingController(text: coleta.quantidade.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            Text(
              'Espécie: ${coleta.especie}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _quantidadeController,
              decoration: InputDecoration(
                labelText: 'Nova Quantidade',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
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
          ),
          ElevatedButton(
            onPressed: () async {
              final novaQuantidade = int.tryParse(_quantidadeController.text);
              if (novaQuantidade != null && novaQuantidade > 0) {
                await _salvarNovaQuantidade(coleta, novaQuantidade);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Digite um número válido maior que 0')),
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

      // Recarregar lista
      await _loadColetas();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quantidade alterada para $novaQuantidade'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao alterar quantidade: $e')),
      );
    }
  }

  Widget _buildColetaLeading(Coleta coleta) {
    if (coleta.caminhoFoto != null && coleta.caminhoFoto!.isNotEmpty) {
      // Se tem foto, mostrar thumbnail
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(coleta.caminhoFoto!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Se erro ao carregar foto, mostrar ícone
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
      );
    } else {
      // Se não tem foto, mostrar número da quantidade
      return CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          coleta.quantidade.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  void _showPontoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes do Ponto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${widget.ponto.nome}'),
            SizedBox(height: 8),
            Text('Projeto: ${widget.projeto.nome}'),
            SizedBox(height: 8),
            Text('Grupo: ${widget.projeto.grupoBiologico.displayName}'),
            SizedBox(height: 8),
            if (widget.ponto.latitude != 0.0 && widget.ponto.longitude != 0.0) ...[
              Text('Latitude: ${widget.ponto.latitude.toStringAsFixed(8)}'),
              SizedBox(height: 8),
              Text('Longitude: ${widget.ponto.longitude.toStringAsFixed(8)}'),
            ] else ...[
              Text('Coordenadas: Não informadas', style: TextStyle(color: Colors.orange)),
            ],
            SizedBox(height: 8),
            Text('Status: ${widget.ponto.status.value}'),
            if (widget.ponto.observacoes != null && widget.ponto.observacoes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Observações: ${widget.ponto.observacoes}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showColetaDetail(Coleta coleta) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header com botão de editar
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.science, color: Colors.white),
                    SizedBox(width: 8),
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
                        Navigator.pop(context); // Fechar dialog
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditColetaScreen(
                              coleta: coleta,
                              ponto: widget.ponto,
                              projeto: widget.projeto,
                            ),
                          ),
                        ).then((_) => _loadColetas());
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
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto (se houver)
                      if (coleta.caminhoFoto != null && coleta.caminhoFoto!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          height: 200,
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                      Text('Foto não encontrada', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      // Informações
                      _buildDetailRow('Espécie', coleta.especie),
                      if (coleta.nomePopular != null && coleta.nomePopular!.isNotEmpty)
                        _buildDetailRow('Nome popular', coleta.nomePopular!),
                      _buildDetailRow('Metodologia', coleta.metodologia),
                      _buildDetailRow('Quantidade', coleta.quantidade.toString()),
                      _buildDetailRow('Data/Hora', '${coleta.dataHora.day}/${coleta.dataHora.month}/${coleta.dataHora.year} ${coleta.dataHora.hour}:${coleta.dataHora.minute.toString().padLeft(2, '0')}'),
                      if (coleta.observacoes != null && coleta.observacoes!.isNotEmpty)
                        _buildDetailRow('Observações', coleta.observacoes!),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}