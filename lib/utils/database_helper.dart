import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../models/metodologia.dart';

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
      version: 1,
      onCreate: _createDB,
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
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
      )
    ''');

    // Tabela de pontos de coleta
    await db.execute('''
      CREATE TABLE pontos_coleta (
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
  }

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

  // Fechar banco
  Future close() async {
    final db = await database;
    db.close();
  }
}