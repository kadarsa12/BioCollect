import 'enums.dart';

class PontoColeta {
  final int? id;
  final String? nome;
  final int campanhaId; // ✅ MUDOU de projetoId para campanhaId
  final double? latitude;
  final double? longitude;
  final DateTime? dataHora;
  final String? observacoes;

  PontoColeta({
    this.id,
    this.nome,
    required this.campanhaId, // ✅ MUDOU
    this.latitude,
    this.longitude,
    this.dataHora,
    this.observacoes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'campanha_id': campanhaId, // ✅ MUDOU
      'latitude': latitude,
      'longitude': longitude,
      'data_hora': dataHora?.toIso8601String(),
      'observacoes': observacoes,
    };
  }

  factory PontoColeta.fromMap(Map<String, dynamic> map) {
    return PontoColeta(
      id: map['id'],
      nome: map['nome'],
      campanhaId: map['campanha_id'], // ✅ MUDOU
      latitude: map['latitude'],
      longitude: map['longitude'],
      dataHora: map['data_hora'] != null ? DateTime.parse(map['data_hora']) : null,
      observacoes: map['observacoes'],
    );
  }
}