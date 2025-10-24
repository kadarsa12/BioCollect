import 'enums.dart';

class Campanha {
  final int? id;
  final String? uuid; // ✅ novo campo
  final int grupoFaunaId;
  final String? nome;
  final String? periodo; // Seca, Cheia, Transição
  final DateTime dataInicio;
  final DateTime? dataFim;
  final StatusCampanha status;
  final String? observacoes;
  final DateTime dataCriacao;      // 🔄 renomeado
  final DateTime dataAtualizacao;  // 🔄 renomeado

  Campanha({
    this.id,
    this.uuid,
    required this.grupoFaunaId,
    this.nome,
    this.periodo,
    required this.dataInicio,
    this.dataFim,
    this.status = StatusCampanha.ativa,
    this.observacoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  })  : dataCriacao = dataCriacao ?? DateTime.now(),
        dataAtualizacao = dataAtualizacao ?? DateTime.now();

  String get nomeExibicao {
    if (nome != null && nome!.isNotEmpty) {
      return nome!;
    }
    if (periodo != null && periodo!.isNotEmpty) {
      return '$periodo ${dataInicio.year}';
    }
    return 'Campanha ${dataInicio.day}/${dataInicio.month}/${dataInicio.year}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid, // ✅ incluído
      'grupo_fauna_id': grupoFaunaId,
      'nome': nome,
      'periodo': periodo,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'status': status.value,
      'observacoes': observacoes,
      'data_criacao': dataCriacao.toIso8601String(),         // 🔄 nome ajustado
      'data_atualizacao': dataAtualizacao.toIso8601String(), // 🔄 nome ajustado
    };
  }

  factory Campanha.fromMap(Map<String, dynamic> map) {
    return Campanha(
      id: map['id'],
      uuid: map['uuid'], // ✅ incluído
      grupoFaunaId: map['grupo_fauna_id'],
      nome: map['nome'],
      periodo: map['periodo'],
      dataInicio: DateTime.parse(map['data_inicio']),
      dataFim: map['data_fim'] != null ? DateTime.parse(map['data_fim']) : null,
      status: StatusCampanha.values.firstWhere(
            (e) => e.value == (map['status'] ?? 'ATIVA'),
        orElse: () => StatusCampanha.ativa,
      ),
      observacoes: map['observacoes'],
      dataCriacao: DateTime.parse(map['data_criacao']),
      dataAtualizacao: DateTime.parse(map['data_atualizacao']),
    );
  }

  Campanha copyWith({
    int? id,
    String? uuid,
    int? grupoFaunaId,
    String? nome,
    String? periodo,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusCampanha? status,
    String? observacoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return Campanha(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid, // ✅ incluído
      grupoFaunaId: grupoFaunaId ?? this.grupoFaunaId,
      nome: nome ?? this.nome,
      periodo: periodo ?? this.periodo,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      status: status ?? this.status,
      observacoes: observacoes ?? this.observacoes,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}
