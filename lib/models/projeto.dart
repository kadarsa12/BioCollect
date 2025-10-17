import 'enums.dart';

class Projeto {
  final int? id;
  final String? nome;
  final String? municipio;
  final int? usuarioId;
  final DateTime dataInicio;
  final StatusProjeto status;
  final DateTime? dataFechamento;

  Projeto({
    this.id,
    this.nome,
    this.municipio,
    this.usuarioId,
    DateTime? dataInicio,
    this.status = StatusProjeto.aberto,
    this.dataFechamento,
  }) : dataInicio = dataInicio ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'municipio': municipio,
      'usuario_id': usuarioId,
      'data_inicio': dataInicio.toIso8601String(),
      'status': status.value,
      'data_fechamento': dataFechamento?.toIso8601String(),
    };
  }

  factory Projeto.fromMap(Map<String, dynamic> map) {
    return Projeto(
      id: map['id'],
      nome: map['nome'],
      municipio: map['municipio'],
      usuarioId: map['usuario_id'],
      dataInicio: DateTime.parse(map['data_inicio']),
      status: StatusProjeto.values.firstWhere(
            (e) => e.value == (map['status'] ?? 'ABERTO'),
        orElse: () => StatusProjeto.aberto,
      ),
      dataFechamento: map['data_fechamento'] != null
          ? DateTime.parse(map['data_fechamento'])
          : null,
    );
  }

  // Método copyWith para facilitar edições
  Projeto copyWith({
    int? id,
    String? nome,
    String? municipio,
    int? usuarioId,
    DateTime? dataInicio,
    StatusProjeto? status,
    DateTime? dataFechamento,
  }) {
    return Projeto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      municipio: municipio ?? this.municipio,
      usuarioId: usuarioId ?? this.usuarioId,
      dataInicio: dataInicio ?? this.dataInicio,
      status: status ?? this.status,
      dataFechamento: dataFechamento ?? this.dataFechamento,
    );
  }
}