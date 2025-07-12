import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../utils/database_helper.dart';

class ProjectMapScreen extends StatefulWidget {
  final Projeto projeto;

  ProjectMapScreen({required this.projeto});

  @override
  _ProjectMapScreenState createState() => _ProjectMapScreenState();
}

class _ProjectMapScreenState extends State<ProjectMapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<PontoColeta> _pontos = [];
  bool _isLoading = true;

  // Coordenadas padrão (centro do Brasil)
  static const LatLng _defaultCenter = LatLng(-15.7942, -47.8822);

  @override
  void initState() {
    super.initState();
    _loadPontosAndCreateMarkers();
  }

  Future<void> _loadPontosAndCreateMarkers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar pontos do projeto
      _pontos = await DatabaseHelper.instance.getPontosByProjeto(widget.projeto.id!);

      // Criar marcadores
      List<Marker> markers = [];

      for (int i = 0; i < _pontos.length; i++) {
        final ponto = _pontos[i];

        // Só adicionar se tem coordenadas válidas
        if (ponto.latitude != 0.0 && ponto.longitude != 0.0) {
          // Contar coletas do ponto
          final coletas = await DatabaseHelper.instance.getColetasByPonto(ponto.id!);

          markers.add(
            Marker(
              point: LatLng(ponto.latitude, ponto.longitude),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showPontoInfo(ponto, coletas.length),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getMarkerColor(coletas.length),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 18,
                        ),
                        if (coletas.length > 0)
                          Text(
                            '${coletas.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }

      setState(() {
        _markers = markers;
        _isLoading = false;
      });

      // Ajustar câmera para mostrar todos os pontos
      if (_markers.isNotEmpty) {
        _fitMarkersInView();
      }
    } catch (e) {
      print('Erro ao carregar pontos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getMarkerColor(int numColetas) {
    if (numColetas == 0) {
      return Color(0xFF8D6E63); // Marrom padrão - sem coletas
    } else if (numColetas <= 5) {
      return Colors.green; // Verde - poucas coletas
    } else if (numColetas <= 15) {
      return Colors.orange; // Laranja - média coletas
    } else {
      return Colors.red; // Vermelho - muitas coletas
    }
  }

  void _fitMarkersInView() {
    if (_markers.isEmpty) return;

    double minLat = _markers.first.point.latitude;
    double maxLat = _markers.first.point.latitude;
    double minLng = _markers.first.point.longitude;
    double maxLng = _markers.first.point.longitude;

    for (Marker marker in _markers) {
      minLat = minLat < marker.point.latitude ? minLat : marker.point.latitude;
      maxLat = maxLat > marker.point.latitude ? maxLat : marker.point.latitude;
      minLng = minLng < marker.point.longitude ? minLng : marker.point.longitude;
      maxLng = maxLng > marker.point.longitude ? maxLng : marker.point.longitude;
    }

    // Adicionar padding
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat - latPadding, minLng - lngPadding),
          LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      appBar: AppBar(
        title: Text('Mapa - ${widget.projeto.nome}'),
        backgroundColor: Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPontosAndCreateMarkers,
            tooltip: 'Atualizar mapa',
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showMapLegend,
            tooltip: 'Legenda',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF8D6E63),
            ),
            SizedBox(height: 16),
            Text(
              'Carregando pontos...',
              style: TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : _markers.isEmpty
          ? Center(
        child: Container(
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
                'Nenhum ponto com coordenadas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Adicione coordenadas GPS aos pontos\npara visualizá-los no mapa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back),
                label: Text('Voltar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8D6E63),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      )
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _markers.isNotEmpty
                  ? _markers.first.point
                  : _defaultCenter,
              initialZoom: 12.0,
              minZoom: 1.0,
              maxZoom: 18.0,
            ),
            children: [
              // Camada do mapa (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.biocollectapp',
              ),
              // Camada dos marcadores
              MarkerLayer(markers: _markers),
            ],
          ),

          // Card de informações do projeto
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: Color(0xFF8D6E63),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.projeto.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${_markers.length} pontos mapeados',
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
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botão para mostrar legenda
          FloatingActionButton(
            mini: true,
            onPressed: _showMapLegend,
            child: Icon(Icons.help_outline),
            backgroundColor: Color(0xFF8D6E63),
            foregroundColor: Colors.white,
            heroTag: "legend",
          ),
          SizedBox(height: 8),
          // Botão para centralizar
          if (_markers.isNotEmpty)
            FloatingActionButton(
              mini: true,
              onPressed: _fitMarkersInView,
              child: Icon(Icons.center_focus_strong),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              heroTag: "center",
            ),
          if (_markers.isNotEmpty) SizedBox(height: 8),
          // Botão para voltar à lista
          FloatingActionButton(
            onPressed: () => Navigator.pop(context),
            child: Icon(Icons.list),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            heroTag: "list",
          ),
        ],
      ),
    );
  }

  void _showPontoInfo(PontoColeta ponto, int numColetas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getMarkerColor(numColetas),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.white,
                size: 14,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                ponto.nome,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Projeto', widget.projeto.nome),
            _buildInfoRow('Grupo', widget.projeto.grupoBiologico.displayName),
            _buildInfoRow(
              'Coordenadas',
              '${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}',
            ),
            _buildInfoRow('Coletas registradas', '$numColetas'),
            _buildInfoRow(
              'Data de criação',
              '${ponto.dataHora.day}/${ponto.dataHora.month}/${ponto.dataHora.year}',
            ),
            if (ponto.observacoes != null && ponto.observacoes!.isNotEmpty)
              _buildInfoRow('Observações', ponto.observacoes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Fechar dialog
              Navigator.pop(context); // Voltar do mapa
            },
            icon: Icon(Icons.visibility, size: 16),
            label: Text('Ver Detalhes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8D6E63),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
                color: Color(0xFF5D4037),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMapLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF8D6E63)),
            SizedBox(width: 8),
            Text('Legenda do Mapa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cores dos marcadores baseadas no número de coletas:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            _buildLegendItem(Color(0xFF8D6E63), 'Nenhuma coleta', '0'),
            _buildLegendItem(Colors.green, 'Poucas coletas', '1-5'),
            _buildLegendItem(Colors.orange, 'Médias coletas', '6-15'),
            _buildLegendItem(Colors.red, 'Muitas coletas', '16+'),
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

  Widget _buildLegendItem(Color color, String description, String range) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: 14,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              range,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}