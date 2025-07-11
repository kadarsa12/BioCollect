class Metodologia {
  final int? id;
  final String nome;
  final String? descricao;
  final String grupoBiologico;
  final int usuarioId;
  final DateTime dataCriacao;

  Metodologia({
    this.id,
    required this.nome,
    this.descricao,
    required this.grupoBiologico,
    required this.usuarioId,
    required this.dataCriacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'grupo_biologico': grupoBiologico,
      'usuario_id': usuarioId,
      'data_criacao': dataCriacao.toIso8601String(),
    };
  }

  factory Metodologia.fromMap(Map<String, dynamic> map) {
    return Metodologia(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      grupoBiologico: map['grupo_biologico'],
      usuarioId: map['usuario_id'],
      dataCriacao: DateTime.parse(map['data_criacao']),
    );
  }
}