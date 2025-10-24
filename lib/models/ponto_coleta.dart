import 'enums.dart';

class PontoColeta {
  final int? id;
  final String? uuid; // ✅ novo campo
  final String? nome;
  final int campanhaId;
  final double? latitude;
  final double? longitude;
  final DateTime? dataHora;
  final String? observacoes;
  final DateTime dataCriacao;      // ✅ novo campo
  final DateTime dataAtualizacao;  // ✅ novo campo

  PontoColeta({
    this.id,
    this.uuid,
    this.nome,
    required this.campanhaId,
    this.latitude,
    this.longitude,
    this.dataHora,
    this.observacoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  })  : dataCriacao = dataCriacao ?? DateTime.now(),
        dataAtualizacao = dataAtualizacao ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid, // ✅ incluído
      'nome': nome,
      'campanha_id': campanhaId,
      'latitude': latitude,
      'longitude': longitude,
      'data_hora': dataHora?.toIso8601String(),
      'observacoes': observacoes,
      'data_criacao': dataCriacao.toIso8601String(),         // ✅ incluído
      'data_atualizacao': dataAtualizacao.toIso8601String(), // ✅ incluído
    };
  }

  factory PontoColeta.fromMap(Map<String, dynamic> map) {
    return PontoColeta(
      id: map['id'],
      uuid: map['uuid'], // ✅ incluído
      nome: map['nome'],
      campanhaId: map['campanha_id'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      dataHora: map['data_hora'] != null ? DateTime.parse(map['data_hora']) : null,
      observacoes: map['observacoes'],
      dataCriacao: map['data_criacao'] != null
          ? DateTime.parse(map['data_criacao'])
          : DateTime.now(),
      dataAtualizacao: map['data_atualizacao'] != null
          ? DateTime.parse(map['data_atualizacao'])
          : DateTime.now(),
    );
  }
}
