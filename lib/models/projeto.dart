import 'enums.dart';

class Projeto {
  final int? id;
  final String nome;
  final GrupoBiologico grupoBiologico;
  final String campanha;
  final String periodo; // Seca ou Cheia
  final String municipio;
  final int usuarioId;
  final DateTime dataInicio;
  final StatusProjeto status;        // ← NOVA LINHA
  final DateTime? dataFechamento;

  Projeto({
    this.id,
    required this.nome,
    required this.grupoBiologico,
    required this.campanha,
    required this.periodo,
    required this.municipio,
    required this.usuarioId,
    required this.dataInicio,
    this.status = StatusProjeto.aberto,  // ← NOVA LINHA (padrão = aberto)
    this.dataFechamento,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'grupo_biologico': grupoBiologico.code,
      'campanha': campanha,
      'periodo': periodo,
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
      grupoBiologico: GrupoBiologico.values.firstWhere(
            (e) => e.code == map['grupo_biologico'],
      ),
      campanha: map['campanha'],
      periodo: map['periodo'],
      municipio: map['municipio'],
      usuarioId: map['usuario_id'],
      dataInicio: DateTime.parse(map['data_inicio']),
    status: StatusProjeto.values.firstWhere(
    (e) => e.value == (map['status'] ?? 'ABERTO'),
    ),
      dataFechamento: map['data_fechamento'] != null         // ← NOVA LINHA
          ? DateTime.parse(map['data_fechamento'])
          : null,
    );
  }
}