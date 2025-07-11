import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../providers/project_provider.dart';
import '../utils/database_helper.dart';

class EditPontoScreen extends StatefulWidget {
  final PontoColeta ponto;
  final Projeto projeto;

  EditPontoScreen({required this.ponto, required this.projeto});

  @override
  _EditPontoScreenState createState() => _EditPontoScreenState();
}

class _EditPontoScreenState extends State<EditPontoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _observacoesController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  bool _isLoadingLocation = false;
  bool _useManualCoordinates = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controllers com dados atuais
    _nomeController = TextEditingController(text: widget.ponto.nome);
    _observacoesController = TextEditingController(text: widget.ponto.observacoes ?? '');

    // Coordenadas (se não são 0,0)
    if (widget.ponto.latitude != 0.0 && widget.ponto.longitude != 0.0) {
      _latitudeController = TextEditingController(text: widget.ponto.latitude.toStringAsFixed(6));
      _longitudeController = TextEditingController(text: widget.ponto.longitude.toStringAsFixed(6));
    } else {
      _latitudeController = TextEditingController();
      _longitudeController = TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Ponto'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmarDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Ponto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o nome do ponto';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Card de localização
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.gps_fixed, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Coordenadas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Botões GPS e Manual
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                              icon: _isLoadingLocation
                                  ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : Icon(Icons.gps_fixed),
                              label: Text(_isLoadingLocation ? 'Obtendo...' : 'Atualizar GPS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _useManualCoordinates = !_useManualCoordinates;
                                });
                              },
                              icon: Icon(Icons.edit),
                              label: Text(_useManualCoordinates ? 'Cancelar' : 'Editar Manual'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Campos de coordenadas
                      if (_useManualCoordinates) ...[
                        Text(
                          'Editar coordenadas:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 8),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                                hintText: '-15.123456',
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              readOnly: !_useManualCoordinates,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                                hintText: '-60.123456',
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              readOnly: !_useManualCoordinates,
                            ),
                          ),
                        ],
                      ),

                      if (!_useManualCoordinates &&
                          _latitudeController.text.isNotEmpty &&
                          _longitudeController.text.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '📍 ${_latitudeController.text}, ${_longitudeController.text}',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _observacoesController,
                decoration: InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvarAlteracoes,
                      child: Text('Salvar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final permission = await Permission.location.request();

      if (permission.isGranted) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('GPS desativado. Ative nas configurações.')),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _latitudeController.text = position.latitude.toStringAsFixed(6);
          _longitudeController.text = position.longitude.toStringAsFixed(6);
          _isLoadingLocation = false;
          _useManualCoordinates = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coordenadas atualizadas!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permissão de localização negada.')),
        );
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e')),
      );
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (_formKey.currentState!.validate()) {
      try {
        double latitude = 0.0;
        double longitude = 0.0;

        if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty) {
          latitude = double.parse(_latitudeController.text);
          longitude = double.parse(_longitudeController.text);
        }

        // Atualizar no banco
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'pontos_coleta',
          {
            'nome': _nomeController.text,
            'latitude': latitude,
            'longitude': longitude,
            'observacoes': _observacoesController.text.isEmpty ? null : _observacoesController.text,
          },
          where: 'id = ?',
          whereArgs: [widget.ponto.id],
        );

        // Recarregar lista
        final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
        await projectProvider.loadPontosByProjeto(widget.projeto.id!);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ponto atualizado com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  void _confirmarDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Ponto'),
        content: Text('Tem certeza que deseja excluir este ponto?\n\nTodas as coletas associadas também serão removidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: _deletePonto,
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePonto() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Deletar coletas do ponto primeiro
      await db.delete('coletas', where: 'ponto_coleta_id = ?', whereArgs: [widget.ponto.id]);

      // Deletar o ponto
      await db.delete('pontos_coleta', where: 'id = ?', whereArgs: [widget.ponto.id]);

      // Recarregar lista
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.loadPontosByProjeto(widget.projeto.id!);

      Navigator.pop(context); // Fechar dialog
      Navigator.pop(context); // Voltar para lista de pontos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ponto excluído com sucesso!')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _observacoesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}