// models/excel_template.dart
class ExcelTemplate {
  int? id;
  String nome;
  String grupoBiologico; // 'peixes', 'aves', 'mamiferos', etc.
  List<ExcelColumn> colunas;
  bool isDefault;
  DateTime criadoEm;
  DateTime? atualizadoEm;

  ExcelTemplate({
    this.id,
    required this.nome,
    required this.grupoBiologico,
    required this.colunas,
    this.isDefault = false,
    DateTime? criadoEm,
    this.atualizadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'grupoBiologico': grupoBiologico,
      'colunas': colunas.map((c) => c.toMap()).toList(),
      'isDefault': isDefault ? 1 : 0,
      'criadoEm': criadoEm.millisecondsSinceEpoch,
      'atualizadoEm': atualizadoEm?.millisecondsSinceEpoch,
    };
  }

  factory ExcelTemplate.fromMap(Map<String, dynamic> map) {
    return ExcelTemplate(
      id: map['id'],
      nome: map['nome'],
      grupoBiologico: map['grupoBiologico'],
      colunas: (map['colunas'] as List)
          .map((c) => ExcelColumn.fromMap(c))
          .toList(),
      isDefault: map['isDefault'] == 1,
      criadoEm: DateTime.fromMillisecondsSinceEpoch(map['criadoEm']),
      atualizadoEm: map['atualizadoEm'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['atualizadoEm'])
          : null,
    );
  }
}

class ExcelColumn {
  String campoOriginal;    // 'campanha', 'data', 'latitude', etc.
  String nomeExibicao;     // Nome que aparece no Excel
  bool ativo;              // Se deve ser exportado
  int ordem;               // Ordem da coluna (0, 1, 2...)
  String? formato;         // 'data', 'numero', 'coordenada', 'texto'

  ExcelColumn({
    required this.campoOriginal,
    required this.nomeExibicao,
    this.ativo = true,
    required this.ordem,
    this.formato,
  });

  Map<String, dynamic> toMap() {
    return {
      'campoOriginal': campoOriginal,
      'nomeExibicao': nomeExibicao,
      'ativo': ativo ? 1 : 0,
      'ordem': ordem,
      'formato': formato,
    };
  }

  factory ExcelColumn.fromMap(Map<String, dynamic> map) {
    return ExcelColumn(
      campoOriginal: map['campoOriginal'],
      nomeExibicao: map['nomeExibicao'],
      ativo: map['ativo'] == 1,
      ordem: map['ordem'],
      formato: map['formato'],
    );
  }
}

// Colunas disponíveis no sistema - BASEADO NOS SEUS GRUPOS BIOLÓGICOS
class ColunasDisponiveis {
  // Colunas básicas (comuns a todos os grupos)
  static const List<Map<String, dynamic>> basicas = [
    {
      'campo': 'campanha',
      'nome': 'Campanha',
      'tipo': 'texto',
      'obrigatorio': true,
    },
    {
      'campo': 'data',
      'nome': 'Data',
      'tipo': 'data',
      'obrigatorio': true,
    },
    {
      'campo': 'periodo',
      'nome': 'Período (Seca ou Cheia)',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'municipio',
      'nome': 'Município',
      'tipo': 'texto',
      'obrigatorio': true,
    },
    {
      'campo': 'latitude',
      'nome': 'Latitude (S)',
      'tipo': 'coordenada',
      'obrigatorio': false,
    },
    {
      'campo': 'longitude',
      'nome': 'Longitude (W)',
      'tipo': 'coordenada',
      'obrigatorio': false,
    },
    {
      'campo': 'ponto',
      'nome': 'Ponto (P1,P2...)',
      'tipo': 'texto',
      'obrigatorio': true,
    },
    {
      'campo': 'metodologia',
      'nome': 'Metodologia',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'observacoes',
      'nome': 'Observações',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'tecnicoResponsavel',
      'nome': 'Técnico responsável',
      'tipo': 'texto',
      'obrigatorio': true,
    },
  ];

  // Colunas científicas comuns
  static const List<Map<String, dynamic>> cientificas = [
    {
      'campo': 'ordem',
      'nome': 'Ordem',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'familia',
      'nome': 'Família',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'especie',
      'nome': 'Espécie',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'nomePopular',
      'nome': 'Nome popular',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'quantidade',
      'nome': 'Quantidade (N)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
  ];

  // Colunas de conservação
  static const List<Map<String, dynamic>> conservacao = [
    {
      'campo': 'endemismo',
      'nome': 'Endemismo',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'iucn',
      'nome': 'IUCN',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'mma2022',
      'nome': 'MMA 2022',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'cites',
      'nome': 'CITES',
      'tipo': 'texto',
      'obrigatorio': false,
    },
  ];

  // ICTIOFAUNA - Peixes
  static const List<Map<String, dynamic>> ictiofauna = [
    {
      'campo': 'comprimento',
      'nome': 'Comprimento (cm)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
    {
      'campo': 'peso',
      'nome': 'Peso (g)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
    {
      'campo': 'habitat',
      'nome': 'Habitat aquático',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'guildaTrofica',
      'nome': 'Guilda trófica',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'migracao',
      'nome': 'Migração',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'importanciaEconomica',
      'nome': 'Importância econômica',
      'tipo': 'texto',
      'obrigatorio': false,
    },
  ];

  // AVIFAUNA - Aves
  static const List<Map<String, dynamic>> avifauna = [
    {
      'campo': 'comportamento',
      'nome': 'Comportamento',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'estrato',
      'nome': 'Estrato',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'habitat',
      'nome': 'Habitat',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'guildaTrofica',
      'nome': 'Guilda trófica',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'migracao',
      'nome': 'Migração',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'sensibilidade',
      'nome': 'Sensibilidade ambiental',
      'tipo': 'texto',
      'obrigatorio': false,
    },
  ];

  // HERPETOFAUNA - Anfíbios e Répteis
  static const List<Map<String, dynamic>> herpetofauna = [
    {
      'campo': 'tipo',
      'nome': 'Tipo (Anfíbio/Réptil)',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'habitat',
      'nome': 'Habitat',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'substrato',
      'nome': 'Substrato',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'atividade',
      'nome': 'Período de atividade',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'reproducao',
      'nome': 'Reprodução',
      'tipo': 'texto',
      'obrigatorio': false,
    },
  ];

  // MASTOFAUNA - Mamíferos
  static const List<Map<String, dynamic>> mastofauna = [
    {
      'campo': 'porte',
      'nome': 'Porte',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'habitat',
      'nome': 'Habitat',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'habito',
      'nome': 'Hábito',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'guildaTrofica',
      'nome': 'Guilda trófica',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'evidencia',
      'nome': 'Tipo de evidência',
      'tipo': 'texto',
      'obrigatorio': false,
    },
  ];

  // ENTOMOFAUNA - Insetos
  static const List<Map<String, dynamic>> entomofauna = [
    {
      'campo': 'classe',
      'nome': 'Classe',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'morfotipo',
      'nome': 'Morfotipo',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'habitat',
      'nome': 'Habitat',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'guildaTrofica',
      'nome': 'Guilda trófica',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'estagio',
      'nome': 'Estágio de desenvolvimento',
      'tipo': 'texto',
      'obrigatorio': false,
    },
  ];

  // MACROINVERTEBRADOS
  static const List<Map<String, dynamic>> macroinvertebrados = [
    {
      'campo': 'filo',
      'nome': 'Filo',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'classe',
      'nome': 'Classe',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'habitat',
      'nome': 'Habitat bentônico',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'substrato',
      'nome': 'Tipo de substrato',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'tolerancia',
      'nome': 'Tolerância à poluição',
      'tipo': 'texto',
      'obrigatorio': false,
    },
  ];

  // FLORA - Plantas
  static const List<Map<String, dynamic>> flora = [
    {
      'campo': 'formaVida',
      'nome': 'Forma de vida',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'altura',
      'nome': 'Altura (m)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
    {
      'campo': 'dap',
      'nome': 'DAP (cm)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
    {
      'campo': 'fenologia',
      'nome': 'Fenologia',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'sucessao',
      'nome': 'Sucessão ecológica',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'dispersao',
      'nome': 'Dispersão',
      'tipo': 'texto',
      'obrigatorio': false,
    },
  ];

  // ZOOPLÂNCTON
  static const List<Map<String, dynamic>> zooplancton = [
    {
      'campo': 'grupo',
      'nome': 'Grupo taxonômico',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'tamanho',
      'nome': 'Tamanho (μm)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
    {
      'campo': 'densidade',
      'nome': 'Densidade (ind/L)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
    {
      'campo': 'profundidade',
      'nome': 'Profundidade (m)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
  ];

  // FITOPLÂNCTON
  static const List<Map<String, dynamic>> fitoplancton = [
    {
      'campo': 'grupo',
      'nome': 'Grupo taxonômico',
      'tipo': 'texto',
      'obrigatorio': false,
    },
    {
      'campo': 'tamanho',
      'nome': 'Tamanho (μm)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
    {
      'campo': 'densidade',
      'nome': 'Densidade (cél/mL)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
    {
      'campo': 'biomassa',
      'nome': 'Biomassa (mg/L)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
    {
      'campo': 'profundidade',
      'nome': 'Profundidade (m)',
      'tipo': 'numero',
      'obrigatorio': false,
    },
  ];

  // Método para obter colunas por grupo (baseado no enum do usuário)
  static List<Map<String, dynamic>> getPorGrupo(String grupoBiologico) {
    final List<Map<String, dynamic>> colunas = [...basicas];

    switch (grupoBiologico.toUpperCase()) {
      case 'ICTIOFAUNA':
        colunas.addAll([...cientificas, ...ictiofauna, ...conservacao]);
        break;
      case 'AVIFAUNA':
        colunas.addAll([...cientificas, ...avifauna, ...conservacao]);
        break;
      case 'HERPETOFAUNA':
        colunas.addAll([...cientificas, ...herpetofauna, ...conservacao]);
        break;
      case 'MASTOFAUNA':
        colunas.addAll([...cientificas, ...mastofauna, ...conservacao]);
        break;
      case 'ENTOMOFAUNA':
        colunas.addAll([...cientificas, ...entomofauna, ...conservacao]);
        break;
      case 'MACROINVERTEBRADOS':
        colunas.addAll([...cientificas, ...macroinvertebrados, ...conservacao]);
        break;
      case 'FLORA':
        colunas.addAll([...cientificas, ...flora, ...conservacao]);
        break;
      case 'ZOOPLANCTON':
        colunas.addAll([...cientificas, ...zooplancton]);
        break;
      case 'FITOPLANCTON':
        colunas.addAll([...cientificas, ...fitoplancton]);
        break;
      default:
      // Fallback para grupos não reconhecidos
        colunas.addAll([...cientificas, ...conservacao]);
    }

    return colunas;
  }

  // Manter compatibilidade com código existente
  static List<Map<String, dynamic>> get todas => getPorGrupo('ICTIOFAUNA');
}