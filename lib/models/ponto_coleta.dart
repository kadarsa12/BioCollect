import 'enums.dart';

class PontoColeta {
  final int? id;
  final String nome;
  final int projetoId;
  final int? usuarioId;
  final double latitude;
  final double longitude;
  final DateTime dataHora;
  final String? observacoes;

  PontoColeta({
    this.id,
    required this.nome,
    required this.projetoId,
    this.usuarioId,
    required this.latitude,
    required this.longitude,
    required this.dataHora,
    this.observacoes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'projeto_id': projetoId,
      'usuario_id': usuarioId,
      'latitude': latitude,
      'longitude': longitude,
      'data_hora': dataHora.toIso8601String(),
      'observacoes': observacoes,
    };
  }

  factory PontoColeta.fromMap(Map<String, dynamic> map) {
    return PontoColeta(
      id: map['id'],
      nome: map['nome'],
      projetoId: map['projeto_id'],
      usuarioId: map['usuario_id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      dataHora: DateTime.parse(map['data_hora']),
      observacoes: map['observacoes']
    );
  }
}