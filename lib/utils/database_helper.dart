import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/projeto.dart';
import '../models/grupo_fauna.dart'; // ← NOVO IMPORT
import '../models/campanha.dart'; // ← NOVO IMPORT (vamos criar depois)
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../models/metodologia.dart';
import '../models/excel_template.dart';
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
      version: 5, // ← AUMENTEI PARA 5
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        data_criacao TEXT NOT NULL
      )
    ''');

    // Tabela de projetos (SIMPLIFICADA)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projetos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        municipio TEXT,
        usuario_id INTEGER,
        data_inicio TEXT NOT NULL,
        status TEXT DEFAULT 'ABERTO',
        data_fechamento TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
      )
    ''');

    // ===== NOVA TABELA: grupos_fauna =====
    await db.execute('''
      CREATE TABLE IF NOT EXISTS grupos_fauna (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projeto_id INTEGER NOT NULL,
        tipo TEXT,
        nome_customizado TEXT,
        descricao TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (projeto_id) REFERENCES projetos (id)
      )
    ''');

    // ===== NOVA TABELA: campanhas =====
    await db.execute('''
      CREATE TABLE IF NOT EXISTS campanhas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grupo_fauna_id INTEGER NOT NULL,
        nome TEXT,
        periodo TEXT,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        status TEXT DEFAULT 'ATIVA',
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (grupo_fauna_id) REFERENCES grupos_fauna (id)
      )
    ''');

    // Tabela de pontos de coleta (MODIFICADA)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pontos_coleta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        campanha_id INTEGER NOT NULL,
        latitude REAL,
        longitude REAL,
        data_hora TEXT NOT NULL,
        observacoes TEXT,
        FOREIGN KEY (campanha_id) REFERENCES campanhas (id)
      )
    ''');

    // Tabela de coletas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS coletas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ponto_coleta_id INTEGER NOT NULL,
        metodologia TEXT,
        especie TEXT,
        nome_popular TEXT,
        quantidade INTEGER,
        caminho_foto TEXT,
        data_hora TEXT NOT NULL,
        observacoes TEXT,
        FOREIGN KEY (ponto_coleta_id) REFERENCES pontos_coleta (id)
      )
    ''');

    // Tabela de metodologias personalizadas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS metodologias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        descricao TEXT,
        grupo_biologico TEXT,
        usuario_id INTEGER,
        data_criacao TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
      )
    ''');

    // Tabelas de templates Excel
    await db.execute(_createExcelTemplatesTable);
    await db.execute(_createExcelColumnsTable);
  }

  // ===== MÉTODO PARA UPGRADE DO BANCO =====
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(_createExcelTemplatesTable);
      await db.execute(_createExcelColumnsTable);
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE projetos ADD COLUMN status TEXT DEFAULT "ABERTO"');
      await db.execute('ALTER TABLE projetos ADD COLUMN data_fechamento TEXT');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pontos_coleta (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          projeto_id INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          data_hora TEXT NOT NULL,
          observacoes TEXT,
          status TEXT NOT NULL,
          FOREIGN KEY (projeto_id) REFERENCES projetos (id)
        )
      ''');
    }

    // ===== NOVA MIGRATION - VERSÃO 5 =====
    if (oldVersion < 5) {
      // Criar novas tabelas
      await db.execute('''
        CREATE TABLE IF NOT EXISTS grupos_fauna (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          projeto_id INTEGER NOT NULL,
          tipo TEXT,
          nome_customizado TEXT,
          descricao TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (projeto_id) REFERENCES projetos (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS campanhas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          grupo_fauna_id INTEGER NOT NULL,
          nome TEXT,
          periodo TEXT,
          data_inicio TEXT NOT NULL,
          data_fim TEXT,
          status TEXT DEFAULT 'ATIVA',
          observacoes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (grupo_fauna_id) REFERENCES grupos_fauna (id)
        )
      ''');

      // Migrar dados antigos (se houver projetos)
      final projetos = await db.query('projetos');

      for (final projeto in projetos) {
        // Criar grupo_fauna para cada projeto antigo
        final grupoId = await db.insert('grupos_fauna', {
          'projeto_id': projeto['id'],
          'tipo': projeto['grupo_biologico'], // Dados antigos
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Criar campanha para cada projeto antigo
        final campanhaId = await db.insert('campanhas', {
          'grupo_fauna_id': grupoId,
          'nome': projeto['campanha'], // Dados antigos
          'periodo': projeto['periodo'], // Dados antigos
          'data_inicio': projeto['data_inicio'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Atualizar pontos_coleta para apontar para campanha
        await db.execute('''
          UPDATE pontos_coleta 
          SET campanha_id = ? 
          WHERE projeto_id = ?
        ''', [campanhaId, projeto['id']]);
      }

      // Remover colunas antigas da tabela projetos
      // (SQLite não suporta DROP COLUMN, então vamos recriar)
      await db.execute('ALTER TABLE projetos RENAME TO projetos_old');

      await db.execute('''
        CREATE TABLE projetos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT,
          municipio TEXT,
          usuario_id INTEGER,
          data_inicio TEXT NOT NULL,
          status TEXT DEFAULT 'ABERTO',
          data_fechamento TEXT,
          FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
        )
      ''');

      await db.execute('''
        INSERT INTO projetos (id, nome, municipio, usuario_id, data_inicio, status, data_fechamento)
        SELECT id, nome, municipio, usuario_id, data_inicio, status, data_fechamento
        FROM projetos_old
      ''');

      await db.execute('DROP TABLE projetos_old');

      // Atualizar pontos_coleta para remover projeto_id
      await db.execute('ALTER TABLE pontos_coleta RENAME TO pontos_coleta_old');

      await db.execute('''
        CREATE TABLE pontos_coleta (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT,
          campanha_id INTEGER NOT NULL,
          latitude REAL,
          longitude REAL,
          data_hora TEXT NOT NULL,
          observacoes TEXT,
          FOREIGN KEY (campanha_id) REFERENCES campanhas (id)
        )
      ''');

      await db.execute('''
        INSERT INTO pontos_coleta (id, nome, campanha_id, latitude, longitude, data_hora, observacoes)
        SELECT id, nome, campanha_id, latitude, longitude, data_hora, observacoes
        FROM pontos_coleta_old
      ''');

      await db.execute('DROP TABLE pontos_coleta_old');
    }
  }

  // ===== DEFINIÇÕES DAS TABELAS EXCEL =====
  static const String _createExcelTemplatesTable = '''
    CREATE TABLE IF NOT EXISTS excel_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      grupoBiologico TEXT NOT NULL,
      isDefault INTEGER DEFAULT 0,
      criadoEm INTEGER NOT NULL,
      atualizadoEm INTEGER
    )
  ''';

  static const String _createExcelColumnsTable = '''
    CREATE TABLE IF NOT EXISTS excel_columns (
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

  // ===== MÉTODOS PARA PROJETOS =====
  Future<int> insertProjeto(Projeto projeto) async {
    final db = await database;
    return await db.insert('projetos', projeto.toMap());
  }

  Future<List<Projeto>> getProjetos() async {
    final db = await database;
    final maps = await db.query('projetos', orderBy: 'data_inicio DESC');
    return List.generate(maps.length, (i) => Projeto.fromMap(maps[i]));
  }

  // ===== NOVOS MÉTODOS PARA GRUPOS_FAUNA =====
  Future<int> insertGrupoFauna(GrupoFauna grupo) async {
    final db = await database;
    return await db.insert('grupos_fauna', grupo.toMap());
  }

  Future<List<GrupoFauna>> getGruposByProjeto(int projetoId) async {
    final db = await database;
    final maps = await db.query(
      'grupos_fauna',
      where: 'projeto_id = ?',
      whereArgs: [projetoId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => GrupoFauna.fromMap(maps[i]));
  }

  Future<int> updateGrupoFauna(GrupoFauna grupo) async {
    final db = await database;
    return await db.update(
      'grupos_fauna',
      grupo.toMap(),
      where: 'id = ?',
      whereArgs: [grupo.id],
    );
  }

  Future<int> deleteGrupoFauna(int id) async {
    final db = await database;
    return await db.delete('grupos_fauna', where: 'id = ?', whereArgs: [id]);
  }

  // ===== MÉTODOS PARA USUÁRIOS =====
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('usuarios', user.toMap());
  }

  Future<User?> getUser() async {
    final db = await database;
    final maps = await db.query('usuarios', limit: 1);
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  // ===== MÉTODOS PARA PONTOS DE COLETA =====
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
    return List.generate(maps.length, (i) => PontoColeta.fromMap(maps[i]));
  }

  // ===== MÉTODOS PARA METODOLOGIAS =====
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
    return List.generate(maps.length, (i) => Metodologia.fromMap(maps[i]));
  }

  Future<List<Metodologia>> getAllMetodologias(int usuarioId) async {
    final db = await database;
    final maps = await db.query(
      'metodologias',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'grupo_biologico ASC, nome ASC',
    );
    return List.generate(maps.length, (i) => Metodologia.fromMap(maps[i]));
  }

  Future<void> deleteMetodologia(int id) async {
    final db = await database;
    await db.delete('metodologias', where: 'id = ?', whereArgs: [id]);
  }

  // ===== MÉTODOS PARA COLETAS =====
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
    return List.generate(maps.length, (i) => Coleta.fromMap(maps[i]));
  }

  // ===== MÉTODOS PARA TEMPLATES EXCEL =====
  Future<int> insertTemplate(ExcelTemplate template) async {
    final db = await database;
    final templateId = await db.insert('excel_templates', {
      'nome': template.nome,
      'grupoBiologico': template.grupoBiologico,
      'isDefault': template.isDefault ? 1 : 0,
      'criadoEm': template.criadoEm.millisecondsSinceEpoch,
      'atualizadoEm': template.atualizadoEm?.millisecondsSinceEpoch,
    });

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

  Future<ExcelTemplate?> getTemplateById(int id) async {
    final db = await database;
    final templateMaps = await db.query('excel_templates', where: 'id = ?', whereArgs: [id]);
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

  Future<int> updateTemplate(ExcelTemplate template) async {
    final db = await database;
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

    await db.delete('excel_columns', where: 'templateId = ?', whereArgs: [template.id]);

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

  Future<int> deleteTemplate(int id) async {
    final db = await database;
    return await db.delete('excel_templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> createDefaultTemplates() async {
    final grupos = [
      'ICTIOFAUNA', 'HERPETOFAUNA', 'AVIFAUNA', 'MASTOFAUNA', 'ENTOMOFAUNA',
      'MACROINVERTEBRADOS', 'FLORA', 'ZOOPLANCTON', 'FITOPLANCTON'
    ];

    for (final grupo in grupos) {
      final existing = await getTemplatesByGrupo(grupo);
      if (existing.isEmpty) await _createDefaultTemplate(grupo);
    }
  }
  // ===== NOVOS MÉTODOS PARA CAMPANHAS =====
  Future<int> insertCampanha(Campanha campanha) async {
    final db = await database;
    return await db.insert('campanhas', campanha.toMap());
  }

  Future<List<Campanha>> getCampanhasByGrupo(int grupoFaunaId) async {
    final db = await database;
    final maps = await db.query(
      'campanhas',
      where: 'grupo_fauna_id = ?',
      whereArgs: [grupoFaunaId],
      orderBy: 'data_inicio DESC',
    );
    return List.generate(maps.length, (i) => Campanha.fromMap(maps[i]));
  }

  Future<int> updateCampanha(Campanha campanha) async {
    final db = await database;
    return await db.update(
      'campanhas',
      campanha.toMap(),
      where: 'id = ?',
      whereArgs: [campanha.id],
    );
  }

  Future<int> deleteCampanha(int id) async {
    final db = await database;
    return await db.delete('campanhas', where: 'id = ?', whereArgs: [id]);
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

  Future close() async {
    final db = await database;
    db.close();
  }
}