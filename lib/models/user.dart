class User {
  final int? id;
  final String nome;
  final DateTime dataCriacao;

  User({
    this.id,
    required this.nome,
    required this.dataCriacao,
  });

  // Converter objeto para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'data_criacao': dataCriacao.toIso8601String(),
    };
  }

  // Converter Map para objeto (quando ler do banco)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nome: map['nome'],
      dataCriacao: DateTime.parse(map['data_criacao']),
    );
  }
}