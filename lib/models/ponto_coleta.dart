import 'enums.dart';

class PontoColeta {
  final int? id;
  final String nome;
  final int projetoId;
  final double latitude;
  final double longitude;
  final DateTime dataHora;
  final String? observacoes;
  final StatusPonto status;

  PontoColeta({
    this.id,
    required this.nome,
    required this.projetoId,
    required this.latitude,
    required this.longitude,
    required this.dataHora,
    this.observacoes,
    this.status = StatusPonto.aberto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'projeto_id': projetoId,
      'latitude': latitude,
      'longitude': longitude,
      'data_hora': dataHora.toIso8601String(),
      'observacoes': observacoes,
      'status': status.value,
    };
  }

  factory PontoColeta.fromMap(Map<String, dynamic> map) {
    return PontoColeta(
      id: map['id'],
      nome: map['nome'],
      projetoId: map['projeto_id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      dataHora: DateTime.parse(map['data_hora']),
      observacoes: map['observacoes'],
      status: StatusPonto.values.firstWhere(
            (e) => e.value == map['status'],
      ),
    );
  }
}