class Coleta {
  final int? id;
  final int pontoColetaId;
  final int? usuarioId;
  final String metodologia;
  final String? especie;
  final String? nomePopular;
  final int quantidade;
  final String? caminhoFoto;
  final DateTime dataHora;
  final String? observacoes;

  Coleta({
    this.id,
    required this.pontoColetaId,
    this.usuarioId,
    required this.metodologia,
    required this.especie,
    this.nomePopular,
    required this.quantidade,
    this.caminhoFoto,
    required this.dataHora,
    this.observacoes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ponto_coleta_id': pontoColetaId,
      'usuario_id': usuarioId,
      'metodologia': metodologia,
      'especie': especie,
      'nome_popular': nomePopular,
      'quantidade': quantidade,
      'caminho_foto': caminhoFoto,
      'data_hora': dataHora.toIso8601String(),
      'observacoes': observacoes,
    };
  }

  factory Coleta.fromMap(Map<String, dynamic> map) {
    return Coleta(
      id: map['id'],
      pontoColetaId: map['ponto_coleta_id'],
      usuarioId: map['usuario_id'],
      metodologia: map['metodologia'],
      especie: map['especie'],
      nomePopular: map['nome_popular'],
      quantidade: map['quantidade'],
      caminhoFoto: map['caminho_foto'],
      dataHora: DateTime.parse(map['data_hora']),
      observacoes: map['observacoes'],
    );
  }
}