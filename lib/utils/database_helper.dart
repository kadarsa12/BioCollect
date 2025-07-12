import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../models/metodologia.dart';
import '../models/excel_template.dart'; // <- NOVA IMPORTAÇÃO
import 'string_extensions.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('biocollect.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        data_criacao TEXT NOT NULL
      )
    ''');

    // Tabela de projetos
     await db.execute('''
       CREATE TABLE projetos (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         nome TEXT NOT NULL,
         grupo_biologico TEXT NOT NULL,
         campanha TEXT NOT NULL,
         periodo TEXT NOT NULL,
         municipio TEXT NOT NULL,
         usuario_id INTEGER NOT NULL,
         data_inicio TEXT NOT NULL,
         status TEXT DEFAULT 'ABERTO',
         data_fechamento TEXT,
         FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
       )
     ''');

    // Tabela de pontos de coleta
    await db.execute('''
        CREATE TABLE projetos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    grupo_biologico TEXT NOT NULL,
    campanha TEXT NOT NULL,
    periodo TEXT NOT NULL,
    municipio TEXT NOT NULL,
    usuario_id INTEGER NOT NULL,
    data_inicio TEXT NOT NULL,
    status TEXT DEFAULT 'ABERTO',
    data_fechamento TEXT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
  )
    ''');

    // Tabela de coletas
    await db.execute('''
      CREATE TABLE coletas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ponto_coleta_id INTEGER NOT NULL,
        metodologia TEXT NOT NULL,
        especie TEXT NOT NULL,
        nome_popular TEXT,
        quantidade INTEGER NOT NULL,
        caminho_foto TEXT,
        data_hora TEXT NOT NULL,
        observacoes TEXT,
        FOREIGN KEY (ponto_coleta_id) REFERENCES pontos_coleta (id)
      )
    ''');

    // Tabela de metodologias personalizadas
    await db.execute('''
      CREATE TABLE metodologias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        grupo_biologico TEXT NOT NULL,
        usuario_id INTEGER NOT NULL,
        data_criacao TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
      )
    ''');

    // ===== NOVAS TABELAS PARA TEMPLATES EXCEL =====
    await db.execute(_createExcelTemplatesTable);
    await db.execute(_createExcelColumnsTable);
    // ================================================
  }

  // ===== MÉTODO PARA UPGRADE DO BANCO =====
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adicionar tabelas de templates para usuários que já têm o app
      await db.execute(_createExcelTemplatesTable);
      await db.execute(_createExcelColumnsTable);
    }

    // NOVA PARTE - Adicionar status aos projetos existentes
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE projetos ADD COLUMN status TEXT DEFAULT "ABERTO"');
      await db.execute('ALTER TABLE projetos ADD COLUMN data_fechamento TEXT');
    }
  }


  // ===== DEFINIÇÕES DAS NOVAS TABELAS =====
  static const String _createExcelTemplatesTable = '''
    CREATE TABLE excel_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      grupoBiologico TEXT NOT NULL,
      isDefault INTEGER DEFAULT 0,
      criadoEm INTEGER NOT NULL,
      atualizadoEm INTEGER
    )
  ''';

  static const String _createExcelColumnsTable = '''
    CREATE TABLE excel_columns (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      templateId INTEGER NOT NULL,
      campoOriginal TEXT NOT NULL,
      nomeExibicao TEXT NOT NULL,
      ativo INTEGER DEFAULT 1,
      ordem INTEGER NOT NULL,
      formato TEXT,
      FOREIGN KEY (templateId) REFERENCES excel_templates (id) ON DELETE CASCADE
    )
  ''';

  // Métodos para usuários
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('usuarios', user.toMap());
  }

  Future<User?> getUser() async {
    final db = await database;
    final maps = await db.query('usuarios', limit: 1);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Métodos para projetos
  Future<int> insertProjeto(Projeto projeto) async {
    final db = await database;
    return await db.insert('projetos', projeto.toMap());
  }

  Future<List<Projeto>> getProjetos() async {
    final db = await database;
    final maps = await db.query('projetos', orderBy: 'data_inicio DESC');

    return List.generate(maps.length, (i) {
      return Projeto.fromMap(maps[i]);
    });
  }

  // Métodos para pontos de coleta
  Future<int> insertPontoColeta(PontoColeta ponto) async {
    final db = await database;
    return await db.insert('pontos_coleta', ponto.toMap());
  }

  Future<List<PontoColeta>> getPontosByProjeto(int projetoId) async {
    final db = await database;
    final maps = await db.query(
      'pontos_coleta',
      where: 'projeto_id = ?',
      whereArgs: [projetoId],
      orderBy: 'data_hora DESC',
    );

    return List.generate(maps.length, (i) {
      return PontoColeta.fromMap(maps[i]);
    });
  }

  // Métodos para metodologias
  Future<int> insertMetodologia(Metodologia metodologia) async {
    final db = await database;
    return await db.insert('metodologias', metodologia.toMap());
  }

  Future<List<Metodologia>> getMetodologiasByGrupo(String grupoBiologico, int usuarioId) async {
    final db = await database;
    final maps = await db.query(
      'metodologias',
      where: 'grupo_biologico = ? AND usuario_id = ?',
      whereArgs: [grupoBiologico, usuarioId],
      orderBy: 'nome ASC',
    );

    return List.generate(maps.length, (i) {
      return Metodologia.fromMap(maps[i]);
    });
  }

  Future<List<Metodologia>> getAllMetodologias(int usuarioId) async {
    final db = await database;
    final maps = await db.query(
      'metodologias',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'grupo_biologico ASC, nome ASC',
    );

    return List.generate(maps.length, (i) {
      return Metodologia.fromMap(maps[i]);
    });
  }

  Future<void> deleteMetodologia(int id) async {
    final db = await database;
    await db.delete('metodologias', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para coletas
  Future<int> insertColeta(Coleta coleta) async {
    final db = await database;
    return await db.insert('coletas', coleta.toMap());
  }

  Future<List<Coleta>> getColetasByPonto(int pontoId) async {
    final db = await database;
    final maps = await db.query(
      'coletas',
      where: 'ponto_coleta_id = ?',
      whereArgs: [pontoId],
      orderBy: 'data_hora DESC',
    );

    return List.generate(maps.length, (i) {
      return Coleta.fromMap(maps[i]);
    });
  }

  // ===== NOVOS MÉTODOS PARA TEMPLATES EXCEL =====

  // Inserir template
  Future<int> insertTemplate(ExcelTemplate template) async {
    final db = await database;

    // Inserir template
    final templateId = await db.insert('excel_templates', {
      'nome': template.nome,
      'grupoBiologico': template.grupoBiologico,
      'isDefault': template.isDefault ? 1 : 0,
      'criadoEm': template.criadoEm.millisecondsSinceEpoch,
      'atualizadoEm': template.atualizadoEm?.millisecondsSinceEpoch,
    });

    // Inserir colunas
    for (final coluna in template.colunas) {
      await db.insert('excel_columns', {
        'templateId': templateId,
        'campoOriginal': coluna.campoOriginal,
        'nomeExibicao': coluna.nomeExibicao,
        'ativo': coluna.ativo ? 1 : 0,
        'ordem': coluna.ordem,
        'formato': coluna.formato,
      });
    }

    return templateId;
  }

  // Buscar templates por grupo
  Future<List<ExcelTemplate>> getTemplatesByGrupo(String grupoBiologico) async {
    final db = await database;

    final templates = await db.query(
      'excel_templates',
      where: 'grupoBiologico = ?',
      whereArgs: [grupoBiologico],
      orderBy: 'isDefault DESC, nome ASC',
    );

    List<ExcelTemplate> result = [];

    for (final templateMap in templates) {
      final colunas = await db.query(
        'excel_columns',
        where: 'templateId = ?',
        whereArgs: [templateMap['id']],
        orderBy: 'ordem ASC',
      );

      final template = ExcelTemplate(
        id: templateMap['id'] as int,
        nome: templateMap['nome'] as String,
        grupoBiologico: templateMap['grupoBiologico'] as String,
        isDefault: templateMap['isDefault'] == 1,
        criadoEm: DateTime.fromMillisecondsSinceEpoch(templateMap['criadoEm'] as int),
        atualizadoEm: templateMap['atualizadoEm'] != null
            ? DateTime.fromMillisecondsSinceEpoch(templateMap['atualizadoEm'] as int)
            : null,
        colunas: colunas.map((c) => ExcelColumn(
          campoOriginal: c['campoOriginal'] as String,
          nomeExibicao: c['nomeExibicao'] as String,
          ativo: c['ativo'] == 1,
          ordem: c['ordem'] as int,
          formato: c['formato'] as String?,
        )).toList(),
      );

      result.add(template);
    }

    return result;
  }

  // Buscar template por ID
  Future<ExcelTemplate?> getTemplateById(int id) async {
    final db = await database;

    final templateMaps = await db.query(
      'excel_templates',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (templateMaps.isEmpty) return null;

    final templateMap = templateMaps.first;
    final colunas = await db.query(
      'excel_columns',
      where: 'templateId = ?',
      whereArgs: [id],
      orderBy: 'ordem ASC',
    );

    return ExcelTemplate(
      id: templateMap['id'] as int,
      nome: templateMap['nome'] as String,
      grupoBiologico: templateMap['grupoBiologico'] as String,
      isDefault: templateMap['isDefault'] == 1,
      criadoEm: DateTime.fromMillisecondsSinceEpoch(templateMap['criadoEm'] as int),
      atualizadoEm: templateMap['atualizadoEm'] != null
          ? DateTime.fromMillisecondsSinceEpoch(templateMap['atualizadoEm'] as int)
          : null,
      colunas: colunas.map((c) => ExcelColumn(
        campoOriginal: c['campoOriginal'] as String,
        nomeExibicao: c['nomeExibicao'] as String,
        ativo: c['ativo'] == 1,
        ordem: c['ordem'] as int,
        formato: c['formato'] as String?,
      )).toList(),
    );
  }

  // Atualizar template
  Future<int> updateTemplate(ExcelTemplate template) async {
    final db = await database;

    // Atualizar template
    await db.update(
      'excel_templates',
      {
        'nome': template.nome,
        'grupoBiologico': template.grupoBiologico,
        'isDefault': template.isDefault ? 1 : 0,
        'atualizadoEm': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [template.id],
    );

    // Deletar colunas antigas
    await db.delete(
      'excel_columns',
      where: 'templateId = ?',
      whereArgs: [template.id],
    );

    // Inserir colunas novas
    for (final coluna in template.colunas) {
      await db.insert('excel_columns', {
        'templateId': template.id,
        'campoOriginal': coluna.campoOriginal,
        'nomeExibicao': coluna.nomeExibicao,
        'ativo': coluna.ativo ? 1 : 0,
        'ordem': coluna.ordem,
        'formato': coluna.formato,
      });
    }

    return template.id!;
  }

  // Deletar template
  Future<int> deleteTemplate(int id) async {
    final db = await database;

    // O CASCADE vai deletar as colunas automaticamente
    return await db.delete(
      'excel_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Criar templates padrão para cada grupo biológico
  Future<void> createDefaultTemplates() async {
    final grupos = [
      'ICTIOFAUNA',
      'HERPETOFAUNA',
      'AVIFAUNA',
      'MASTOFAUNA',
      'ENTOMOFAUNA',
      'MACROINVERTEBRADOS',
      'FLORA',
      'ZOOPLANCTON',
      'FITOPLANCTON'
    ];

    for (final grupo in grupos) {
      final existing = await getTemplatesByGrupo(grupo);
      if (existing.isEmpty) {
        await _createDefaultTemplate(grupo);
      }
    }
  }

  Future<void> _createDefaultTemplate(String grupoBiologico) async {
    final colunas = ColunasDisponiveis.getPorGrupo(grupoBiologico)
        .asMap()
        .entries
        .map((entry) => ExcelColumn(
      campoOriginal: entry.value['campo'],
      nomeExibicao: entry.value['nome'],
      ativo: entry.value['obrigatorio'] == true,
      ordem: entry.key,
      formato: entry.value['tipo'],
    ))
        .toList();

    final template = ExcelTemplate(
      nome: 'Padrão ${grupoBiologico.capitalize()}',
      grupoBiologico: grupoBiologico,
      colunas: colunas,
      isDefault: true,
    );

    await insertTemplate(template);
  }

  // Fechar banco
  Future close() async {
    final db = await database;
    db.close();
  }
}
