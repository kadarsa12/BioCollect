import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/projeto.dart';
import '../providers/project_provider.dart';

class CreatePontoScreen extends StatefulWidget {
  final Projeto projeto;

  CreatePontoScreen({required this.projeto});

  @override
  _CreatePontoScreenState createState() => _CreatePontoScreenState();
}

class _CreatePontoScreenState extends State<CreatePontoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _observacoesController = TextEditingController();

  // Controllers para coordenadas tradicionais
  final _latGrausController = TextEditingController();
  final _latMinutosController = TextEditingController();
  final _latSegundosController = TextEditingController();
  final _lngGrausController = TextEditingController();
  final _lngMinutosController = TextEditingController();
  final _lngSegundosController = TextEditingController();

  String _latHemisferio = 'S';
  String _lngHemisferio = 'W';

  bool _isLoadingLocation = false;
  bool _useManualCoordinates = false;

  // Valores decimais para salvar no banco
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      appBar: AppBar(
        title: Text('Novo Ponto de Coleta'),
        backgroundColor: Color(0xFF8D6E63),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Campo nome
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8D6E63).withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Ponto (ex: P1, P2...)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF8D6E63), width: 2),
                    ),
                    prefixIcon: Icon(Icons.location_on, color: Color(0xFF8D6E63)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite o nome do ponto';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),

              // Card de coordenadas (opcional)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8D6E63).withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
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
                          child: Icon(Icons.gps_fixed, color: Colors.green, size: 20),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Coordenadas GPS (Opcional)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        ),
                        Text(
                          'Formato: °\'"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Botões de ação
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
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _useManualCoordinates = !_useManualCoordinates;
                                if (!_useManualCoordinates) {
                                  _clearCoordinates();
                                }
                              });
                            },
                            icon: Icon(Icons.edit),
                            label: Text(_useManualCoordinates ? 'Cancelar' : 'Manual'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF8D6E63),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Campos de coordenadas tradicionais - só aparecem no modo manual
                    if (_useManualCoordinates) ...[
                      SizedBox(height: 16),
                      _buildTraditionalCoordinateInputs(),
                    ],

                    // Preview das coordenadas ou estado vazio
                    SizedBox(height: 12),
                    if (_hasCoordinates())
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
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Coordenadas informadas:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Lat: ${_formatTraditionalCoordinate(_latGrausController.text, _latMinutosController.text, _latSegundosController.text, _latHemisferio)}',
                              style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                            ),
                            Text(
                              'Lng: ${_formatTraditionalCoordinate(_lngGrausController.text, _lngMinutosController.text, _lngSegundosController.text, _lngHemisferio)}',
                              style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else if (!_useManualCoordinates)
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
                              'Use GPS atual ou clique em Manual para inserir',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Campo observações
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8D6E63).withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _observacoesController,
                  decoration: InputDecoration(
                    labelText: 'Observações (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF8D6E63), width: 2),
                    ),
                    prefixIcon: Icon(Icons.note, color: Color(0xFF8D6E63)),
                  ),
                  maxLines: 3,
                ),
              ),
              SizedBox(height: 24),

              // Botão de ação
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _criarPonto,
                  child: Text('Criar Ponto de Coleta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTraditionalCoordinateInputs() {
    return Column(
      children: [
        // Latitude
        Row(
          children: [
            Icon(Icons.north, color: Color(0xFF8D6E63), size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Latitude',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF8D6E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _latHemisferio,
                items: ['N', 'S'].map((h) => DropdownMenuItem(
                  value: h,
                  child: Text(h, style: TextStyle(fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: _useManualCoordinates ? (value) {
                  setState(() {
                    _latHemisferio = value!;
                  });
                } : null,
                underline: SizedBox(),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _latGrausController,
                decoration: InputDecoration(
                  labelText: 'Graus',
                  border: OutlineInputBorder(),
                  suffixText: '°',
                ),
                keyboardType: TextInputType.number,
                readOnly: !_useManualCoordinates,
                validator: (value) => _validateCoordinate(value, 0, 90, 'graus de latitude'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _latMinutosController,
                decoration: InputDecoration(
                  labelText: 'Min',
                  border: OutlineInputBorder(),
                  suffixText: '\'',
                ),
                keyboardType: TextInputType.number,
                readOnly: !_useManualCoordinates,
                validator: (value) => _validateCoordinate(value, 0, 59, 'minutos'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _latSegundosController,
                decoration: InputDecoration(
                  labelText: 'Seg',
                  border: OutlineInputBorder(),
                  suffixText: '"',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                readOnly: !_useManualCoordinates,
                validator: (value) => _validateCoordinate(value, 0, 59.99, 'segundos'),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Longitude
        Row(
          children: [
            Icon(Icons.east, color: Color(0xFF8D6E63), size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Longitude',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF8D6E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _lngHemisferio,
                items: ['E', 'W'].map((h) => DropdownMenuItem(
                  value: h,
                  child: Text(h, style: TextStyle(fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: _useManualCoordinates ? (value) {
                  setState(() {
                    _lngHemisferio = value!;
                  });
                } : null,
                underline: SizedBox(),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _lngGrausController,
                decoration: InputDecoration(
                  labelText: 'Graus',
                  border: OutlineInputBorder(),
                  suffixText: '°',
                ),
                keyboardType: TextInputType.number,
                readOnly: !_useManualCoordinates,
                validator: (value) => _validateCoordinate(value, 0, 180, 'graus de longitude'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _lngMinutosController,
                decoration: InputDecoration(
                  labelText: 'Min',
                  border: OutlineInputBorder(),
                  suffixText: '\'',
                ),
                keyboardType: TextInputType.number,
                readOnly: !_useManualCoordinates,
                validator: (value) => _validateCoordinate(value, 0, 59, 'minutos'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _lngSegundosController,
                decoration: InputDecoration(
                  labelText: 'Seg',
                  border: OutlineInputBorder(),
                  suffixText: '"',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                readOnly: !_useManualCoordinates,
                validator: (value) => _validateCoordinate(value, 0, 59.99, 'segundos'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _validateCoordinate(String? value, double min, double max, String fieldName) {
    if (_useManualCoordinates && (value == null || value.isEmpty)) {
      return 'Digite $fieldName';
    }

    if (value != null && value.isNotEmpty) {
      final num = double.tryParse(value);
      if (num == null) {
        return 'Digite um número válido';
      }

      if (num < min || num > max) {
        return '$fieldName deve estar entre $min e $max';
      }
    }

    return null;
  }

  void _loadCoordinatesFromDecimal(double lat, double lng) {
    // Latitude
    bool latNegative = lat < 0;
    double absLat = lat.abs();
    int latGraus = absLat.floor();
    double latMinutosDecimal = (absLat - latGraus) * 60;
    int latMinutos = latMinutosDecimal.floor();
    double latSegundos = (latMinutosDecimal - latMinutos) * 60;

    _latGrausController.text = latGraus.toString();
    _latMinutosController.text = latMinutos.toString();
    _latSegundosController.text = latSegundos.toStringAsFixed(1);
    _latHemisferio = latNegative ? 'S' : 'N';

    // Longitude
    bool lngNegative = lng < 0;
    double absLng = lng.abs();
    int lngGraus = absLng.floor();
    double lngMinutosDecimal = (absLng - lngGraus) * 60;
    int lngMinutos = lngMinutosDecimal.floor();
    double lngSegundos = (lngMinutosDecimal - lngMinutos) * 60;

    _lngGrausController.text = lngGraus.toString();
    _lngMinutosController.text = lngMinutos.toString();
    _lngSegundosController.text = lngSegundos.toStringAsFixed(1);
    _lngHemisferio = lngNegative ? 'W' : 'E';
  }

  double? _convertToDecimal(String graus, String minutos, String segundos, String hemisferio) {
    try {
      int g = int.parse(graus.isEmpty ? '0' : graus);
      int m = int.parse(minutos.isEmpty ? '0' : minutos);
      double s = double.parse(segundos.isEmpty ? '0' : segundos);

      double decimal = g + (m / 60.0) + (s / 3600.0);

      if (hemisferio == 'S' || hemisferio == 'W') {
        decimal = -decimal;
      }

      return decimal;
    } catch (e) {
      return null;
    }
  }

  String _formatTraditionalCoordinate(String graus, String minutos, String segundos, String hemisferio) {
    if (graus.isEmpty) return 'Não informado';
    String min = minutos.isEmpty ? '00' : minutos;
    String sec = segundos.isEmpty ? '00.0' : segundos;
    return '${graus}°${min}\'${sec}\"$hemisferio';
  }

  bool _hasCoordinates() {
    return _latGrausController.text.isNotEmpty && _lngGrausController.text.isNotEmpty;
  }

  void _clearCoordinates() {
    _latGrausController.clear();
    _latMinutosController.clear();
    _latSegundosController.clear();
    _lngGrausController.clear();
    _lngMinutosController.clear();
    _lngSegundosController.clear();
    _currentLatitude = 0.0;
    _currentLongitude = 0.0;
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
            SnackBar(
              content: Text('GPS desativado. Ative nas configurações.'),
              backgroundColor: Colors.orange,
            ),
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
          _currentLatitude = position.latitude;
          _currentLongitude = position.longitude;
          _isLoadingLocation = false;
          _useManualCoordinates = false;
        });

        _loadCoordinatesFromDecimal(position.latitude, position.longitude);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coordenadas obtidas com GPS!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissão de localização negada.'),
            backgroundColor: Colors.red,
          ),
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
        SnackBar(
          content: Text('Erro ao obter localização: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _criarPonto() async {
    if (_formKey.currentState!.validate()) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

      double latitude = 0.0;
      double longitude = 0.0;

      // Converter coordenadas tradicionais para decimal se informadas
      if (_latGrausController.text.isNotEmpty && _lngGrausController.text.isNotEmpty) {
        latitude = _convertToDecimal(
          _latGrausController.text,
          _latMinutosController.text,
          _latSegundosController.text,
          _latHemisferio,
        ) ?? 0.0;

        longitude = _convertToDecimal(
          _lngGrausController.text,
          _lngMinutosController.text,
          _lngSegundosController.text,
          _lngHemisferio,
        ) ?? 0.0;
      }

      final id = await projectProvider.createPontoColeta(
        nome: _nomeController.text,
        projetoId: widget.projeto.id!,
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
    _latGrausController.dispose();
    _latMinutosController.dispose();
    _latSegundosController.dispose();
    _lngGrausController.dispose();
    _lngMinutosController.dispose();
    _lngSegundosController.dispose();
    super.dispose();
  }
}