class Coleta {
  final int? id;
  final String? uuid; // ✅ novo campo
  final int? pontoColetaId;
  final String? metodologia;
  final String? especie;
  final String? nomePopular;
  final int? quantidade;
  final String? caminhoFoto;
  final DateTime dataHora;
  final String? observacoes;
  final DateTime dataCriacao;      // ✅ novo campo
  final DateTime dataAtualizacao;  // ✅ novo campo

  Coleta({
    this.id,
    this.uuid,
    this.pontoColetaId,
    this.metodologia,
    this.especie,
    this.nomePopular,
    this.quantidade,
    this.caminhoFoto,
    DateTime? dataHora,
    this.observacoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  })  : dataHora = dataHora ?? DateTime.now(),
        dataCriacao = dataCriacao ?? DateTime.now(),
        dataAtualizacao = dataAtualizacao ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid, // ✅ incluído
      'ponto_coleta_id': pontoColetaId,
      'metodologia': metodologia,
      'especie': especie,
      'nome_popular': nomePopular,
      'quantidade': quantidade,
      'caminho_foto': caminhoFoto,
      'data_hora': dataHora.toIso8601String(),
      'observacoes': observacoes,
      'data_criacao': dataCriacao.toIso8601String(),         // ✅ incluído
      'data_atualizacao': dataAtualizacao.toIso8601String(), // ✅ incluído
    };
  }

  factory Coleta.fromMap(Map<String, dynamic> map) {
    return Coleta(
      id: map['id'],
      uuid: map['uuid'], // ✅ incluído
      pontoColetaId: map['ponto_coleta_id'],
      metodologia: map['metodologia'],
      especie: map['especie'],
      nomePopular: map['nome_popular'],
      quantidade: map['quantidade'],
      caminhoFoto: map['caminho_foto'],
      dataHora: DateTime.parse(map['data_hora']),
      observacoes: map['observacoes'],
      dataCriacao: map['data_criacao'] != null
          ? DateTime.parse(map['data_criacao'])
          : DateTime.now(),
      dataAtualizacao: map['data_atualizacao'] != null
          ? DateTime.parse(map['data_atualizacao'])
          : DateTime.now(),
    );
  }

  Coleta copyWith({
    int? id,
    String? uuid,
    int? pontoColetaId,
    String? metodologia,
    String? especie,
    String? nomePopular,
    int? quantidade,
    String? caminhoFoto,
    DateTime? dataHora,
    String? observacoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return Coleta(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid, // ✅ incluído
      pontoColetaId: pontoColetaId ?? this.pontoColetaId,
      metodologia: metodologia ?? this.metodologia,
      especie: especie ?? this.especie,
      nomePopular: nomePopular ?? this.nomePopular,
      quantidade: quantidade ?? this.quantidade,
      caminhoFoto: caminhoFoto ?? this.caminhoFoto,
      dataHora: dataHora ?? this.dataHora,
      observacoes: observacoes ?? this.observacoes,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}
