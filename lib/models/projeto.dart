import 'enums.dart';

class Projeto {
  final int? id;
  final String? uuid;          // ✅ adicionado
  final String? nome;
  final String? municipio;
  final int? usuarioId;
  final String? observacoes;   // ✅ adicionado
  final DateTime dataInicio;
  final StatusProjeto status;
  final DateTime? dataFechamento;

  Projeto({
    this.id,
    this.uuid,
    this.nome,
    this.municipio,
    this.usuarioId,
    this.observacoes,
    DateTime? dataInicio,
    this.status = StatusProjeto.aberto,
    this.dataFechamento,
  }) : dataInicio = dataInicio ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,                       // ✅ incluído
      'nome': nome,
      'municipio': municipio,
      'usuario_id': usuarioId,
      'observacoes': observacoes,         // ✅ incluído
      'data_inicio': dataInicio.toIso8601String(),
      'status': status.value,
      'data_fechamento': dataFechamento?.toIso8601String(),
    };
  }

  factory Projeto.fromMap(Map<String, dynamic> map) {
    return Projeto(
      id: map['id'],
      uuid: map['uuid'],                          // ✅ incluído
      nome: map['nome'],
      municipio: map['municipio'],
      usuarioId: map['usuario_id'],
      observacoes: map['observacoes'],            // ✅ incluído
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

  Projeto copyWith({
    int? id,
    String? uuid,
    String? nome,
    String? municipio,
    int? usuarioId,
    String? observacoes,
    DateTime? dataInicio,
    StatusProjeto? status,
    DateTime? dataFechamento,
  }) {
    return Projeto(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,                    // ✅ incluído
      nome: nome ?? this.nome,
      municipio: municipio ?? this.municipio,
      usuarioId: usuarioId ?? this.usuarioId,
      observacoes: observacoes ?? this.observacoes, // ✅ incluído
      dataInicio: dataInicio ?? this.dataInicio,
      status: status ?? this.status,
      dataFechamento: dataFechamento ?? this.dataFechamento,
    );
  }
}
