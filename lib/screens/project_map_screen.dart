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
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showPontoInfo(ponto, coletas.length),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getMarkerColor(coletas.length),
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
                  child: Center(
                    child: Text(
                      ponto.nome,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
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
      return Colors.blue;
    } else if (numColetas <= 3) {
      return Colors.green;
    } else {
      return Colors.orange;
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
      appBar: AppBar(
        title: Text('Mapa - ${widget.projeto.nome}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPontosAndCreateMarkers,
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showMapLegend,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando pontos...'),
          ],
        ),
      )
          : _markers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum ponto com coordenadas',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Adicione coordenadas GPS aos pontos para visualizá-los no mapa',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      )
          : FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _markers.isNotEmpty
              ? _markers.first.point
              : _defaultCenter,
          initialZoom: 10.0,
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botão para centralizar
          if (_markers.isNotEmpty)
            FloatingActionButton(
              mini: true,
              onPressed: _fitMarkersInView,
              child: Icon(Icons.center_focus_strong),
              backgroundColor: Colors.blue,
              heroTag: "center",
            ),
          SizedBox(height: 8),
          // Botão para voltar à lista
          FloatingActionButton(
            onPressed: () => Navigator.pop(context),
            child: Icon(Icons.list),
            backgroundColor: Colors.green,
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
        title: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getMarkerColor(numColetas),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(ponto.nome),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Projeto: ${widget.projeto.nome}'),
            SizedBox(height: 8),
            Text('Coordenadas: ${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}'),
            SizedBox(height: 8),
            Text('Coletas registradas: $numColetas'),
            SizedBox(height: 8),
            Text('Status: ${ponto.status.value}'),
            if (ponto.observacoes != null && ponto.observacoes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Observações: ${ponto.observacoes}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fechar dialog
              Navigator.pop(context); // Voltar do mapa
            },
            child: Text('Ver Ponto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
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
        title: Text('Legenda do Mapa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Colors.blue, 'Ponto sem coletas'),
            _buildLegendItem(Colors.green, 'Ponto com 1-3 coletas'),
            _buildLegendItem(Colors.orange, 'Ponto com 4+ coletas'),
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

  Widget _buildLegendItem(Color color, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Text(description),
        ],
      ),
    );
  }
}