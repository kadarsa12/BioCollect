import 'enums.dart';

class Campanha {
  final int? id;
  final int grupoFaunaId;
  final String? nome;
  final String? periodo; // Seca, Cheia, Transição
  final DateTime dataInicio;
  final DateTime? dataFim;
  final StatusCampanha status;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Campanha({
    this.id,
    required this.grupoFaunaId,
    this.nome,
    this.periodo,
    required this.dataInicio,
    this.dataFim,
    this.status = StatusCampanha.ativa,
    this.observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Nome para exibir na tela
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
      'grupo_fauna_id': grupoFaunaId,
      'nome': nome,
      'periodo': periodo,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'status': status.value,
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Campanha.fromMap(Map<String, dynamic> map) {
    return Campanha(
      id: map['id'],
      grupoFaunaId: map['grupo_fauna_id'],
      nome: map['nome'],
      periodo: map['periodo'],
      dataInicio: DateTime.parse(map['data_inicio']),
      dataFim: map['data_fim'] != null
          ? DateTime.parse(map['data_fim'])
          : null,
      status: StatusCampanha.values.firstWhere(
            (e) => e.value == (map['status'] ?? 'ATIVA'),
        orElse: () => StatusCampanha.ativa,
      ),
      observacoes: map['observacoes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Método para copiar com alterações
  Campanha copyWith({
    int? id,
    int? grupoFaunaId,
    String? nome,
    String? periodo,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusCampanha? status,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Campanha(
      id: id ?? this.id,
      grupoFaunaId: grupoFaunaId ?? this.grupoFaunaId,
      nome: nome ?? this.nome,
      periodo: periodo ?? this.periodo,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      status: status ?? this.status,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}