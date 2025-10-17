import 'enums.dart';

class GrupoFauna {
  final int? id;
  final int projetoId;
  final GrupoBiologico? tipo; // ← OPCIONAL agora
  final String? nomeCustomizado;
  final String? descricao;
  final DateTime createdAt;
  final DateTime updatedAt;

  GrupoFauna({
    this.id,
    required this.projetoId,
    this.tipo, // ← Não é mais required
    this.nomeCustomizado,
    this.descricao,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Nome que aparece na tela
  String get nomeExibicao {
    if (nomeCustomizado != null && nomeCustomizado!.isNotEmpty) {
      return nomeCustomizado!;
    }
    if (tipo != null) {
      return tipo!.displayName;
    }
    return 'Sem nome'; // Fallback
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projeto_id': projetoId,
      'tipo': tipo?.code, // ← Pode ser null
      'nome_customizado': nomeCustomizado,
      'descricao': descricao,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory GrupoFauna.fromMap(Map<String, dynamic> map) {
    return GrupoFauna(
      id: map['id'],
      projetoId: map['projeto_id'],
      tipo: map['tipo'] != null
          ? GrupoBiologico.values.firstWhere(
            (e) => e.code == map['tipo'],
        orElse: () => GrupoBiologico.values.first, // ← Segurança
      )
          : null,
      nomeCustomizado: map['nome_customizado'],
      descricao: map['descricao'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}