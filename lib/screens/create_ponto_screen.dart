import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../models/campanha.dart';
import '../models/enums.dart';
import '../providers/project_provider.dart';

class CreatePontoScreen extends StatefulWidget {
  final Projeto projeto;
  final GrupoFauna grupoFauna;
  final Campanha campanha;

  CreatePontoScreen({
    required this.projeto,
    required this.grupoFauna,
    required this.campanha,
  });

  @override
  _CreatePontoScreenState createState() => _CreatePontoScreenState();
}

class _CreatePontoScreenState extends State<CreatePontoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isLoadingLocation = false;
  bool _useManualCoordinates = false;

  Color get _grupoColor => _getColorForGrupo(widget.grupoFauna.tipo);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Novo Ponto de Coleta'),
        backgroundColor: _grupoColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Card de informações da campanha
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: _grupoColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Campanha: ${widget.campanha.nomeExibicao}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Grupo: ${widget.grupoFauna.nomeExibicao}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Ponto (ex: P1, P2...)',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _grupoColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.location_on, color: _grupoColor),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o nome do ponto';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Card de localização - Agora opcional
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
                            'Localização (Opcional)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Opção: GPS automático ou manual
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                              icon: _isLoadingLocation
                                  ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Icon(Icons.gps_fixed),
                              label: Text(_isLoadingLocation ? 'Obtendo...' : 'GPS Atual'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _grupoColor,
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
                                  if (!_useManualCoordinates) {
                                    _latitudeController.clear();
                                    _longitudeController.clear();
                                  }
                                });
                              },
                              icon: Icon(Icons.edit),
                              label: Text(_useManualCoordinates ? 'Cancelar' : 'Manual'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _grupoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Mostrar coordenadas obtidas ou campos manuais
                      if (_useManualCoordinates) ...[
                        Text(
                          'Digite as coordenadas manualmente:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latitudeController,
                                decoration: InputDecoration(
                                  labelText: 'Latitude',
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: _grupoColor, width: 2),
                                  ),
                                  hintText: '-15.123456',
                                  helperText: 'Negativo no Brasil',
                                  prefixText: '-',
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    String fullValue = value.startsWith('-') ? value : '-$value';
                                    final lat = double.tryParse(fullValue);
                                    if (lat == null) {
                                      return 'Digite um número válido';
                                    }
                                    if (lat < -90 || lat > 90) {
                                      return 'Latitude deve estar entre -90 e 90';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _longitudeController,
                                decoration: InputDecoration(
                                  labelText: 'Longitude',
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: _grupoColor, width: 2),
                                  ),
                                  hintText: '-60.123456',
                                  helperText: 'Negativo no Brasil',
                                  prefixText: '-',
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    String fullValue = value.startsWith('-') ? value : '-$value';
                                    final lng = double.tryParse(fullValue);
                                    if (lng == null) {
                                      return 'Digite um número válido';
                                    }
                                    if (lng < -180 || lng > 180) {
                                      return 'Longitude deve estar entre -180 e 180';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _latitudeController.text = '-15.794229';
                                  _longitudeController.text = '-47.882166';
                                });
                              },
                              icon: Icon(Icons.location_city, size: 16, color: _grupoColor),
                              label: Text('Brasília', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(foregroundColor: _grupoColor),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _latitudeController.text = '-15.601411';
                                  _longitudeController.text = '-56.097889';
                                });
                              },
                              icon: Icon(Icons.nature, size: 16, color: _grupoColor),
                              label: Text('Cuiabá', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(foregroundColor: _grupoColor),
                            ),
                          ],
                        ),
                      ] else if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📍 Coordenadas obtidas:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text('Latitude: ${_latitudeController.text}'),
                              Text('Longitude: ${_longitudeController.text}'),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.location_off, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Coordenadas não informadas',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                'Você pode adicionar depois se necessário',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                  labelText: 'Observações (opcional)',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _grupoColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.note, color: _grupoColor),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _criarPonto,
                  child: Text('Criar Ponto de Coleta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _grupoColor,
                    foregroundColor: Colors.white,
                  ),
                ),
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
          _showLocationServiceDialog();
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
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Localização obtida com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showPermissionDialog();
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Erro ao obter localização: $e');
      setState(() {
        _isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao obter localização. Tente novamente ou digite manualmente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('GPS Desativado'),
        content: Text('Para obter a localização automaticamente, ative o GPS nas configurações do celular.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
            style: TextButton.styleFrom(foregroundColor: _grupoColor),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissão Necessária'),
        content: Text('Para obter a localização automaticamente, permita o acesso à localização.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
            style: TextButton.styleFrom(foregroundColor: _grupoColor),
          ),
        ],
      ),
    );
  }

  Future<void> _criarPonto() async {
    if (_formKey.currentState!.validate()) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

      double? latitude;
      double? longitude;

      if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty) {
        try {
          String latText = _latitudeController.text.startsWith('-')
              ? _latitudeController.text
              : '-${_latitudeController.text}';
          String lngText = _longitudeController.text.startsWith('-')
              ? _longitudeController.text
              : '-${_longitudeController.text}';

          latitude = double.parse(latText);
          longitude = double.parse(lngText);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Coordenadas inválidas. Digite números válidos.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final id = await projectProvider.createPontoColeta(
        campanhaId: widget.campanha.id!, // ✅ MUDOU: usa campanhaId
        nome: _nomeController.text,
        latitude: latitude,
        longitude: longitude,
        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
      );

      if (id != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ponto criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar ponto'),
            backgroundColor: Colors.red,
          ),
        );
      }
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