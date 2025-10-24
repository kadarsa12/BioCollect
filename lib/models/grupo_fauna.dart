import 'enums.dart';

class GrupoFauna {
  final int? id;
  final String? uuid; // ✅ novo campo
  final int projetoId;
  final GrupoBiologico? tipo;
  final String? nomeCustomizado;
  final String? descricao;
  final DateTime dataCriacao;      // 🔄 renomeado
  final DateTime dataAtualizacao;  // 🔄 renomeado

  GrupoFauna({
    this.id,
    this.uuid,
    required this.projetoId,
    this.tipo,
    this.nomeCustomizado,
    this.descricao,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  })  : dataCriacao = dataCriacao ?? DateTime.now(),
        dataAtualizacao = dataAtualizacao ?? DateTime.now();

  // Nome exibido na tela
  String get nomeExibicao {
    if (nomeCustomizado != null && nomeCustomizado!.isNotEmpty) {
      return nomeCustomizado!;
    }
    if (tipo != null) {
      return tipo!.displayName;
    }
    return 'Sem nome';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid, // ✅ incluído
      'projeto_id': projetoId,
      'tipo': tipo?.code,
      'nome_customizado': nomeCustomizado,
      'descricao': descricao,
      'data_criacao': dataCriacao.toIso8601String(),        // 🔄 nome ajustado
      'data_atualizacao': dataAtualizacao.toIso8601String(), // 🔄 nome ajustado
    };
  }

  factory GrupoFauna.fromMap(Map<String, dynamic> map) {
    return GrupoFauna(
      id: map['id'],
      uuid: map['uuid'], // ✅ incluído
      projetoId: map['projeto_id'],
      tipo: map['tipo'] != null
          ? GrupoBiologico.values.firstWhere(
            (e) => e.code == map['tipo'],
        orElse: () => GrupoBiologico.values.first,
      )
          : null,
      nomeCustomizado: map['nome_customizado'],
      descricao: map['descricao'],
      dataCriacao: DateTime.parse(map['data_criacao']),
      dataAtualizacao: DateTime.parse(map['data_atualizacao']),
    );
  }
}
