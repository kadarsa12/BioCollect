import 'package:flutter/foundation.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../models/enums.dart';
import '../utils/database_helper.dart';

class ProjectProvider with ChangeNotifier {
  List<Projeto> _projetos = [];
  List<PontoColeta> _pontosColeta = [];
  List<Coleta> _coletas = [];
  bool _isLoading = false;

  List<Projeto> get projetos => _projetos;
  List<PontoColeta> get pontosColeta => _pontosColeta;
  List<Coleta> get coletas => _coletas;
  bool get isLoading => _isLoading;

  // Carregar todos os projetos
  Future<void> loadProjetos() async {
    _isLoading = true;
    notifyListeners();

    try {
      _projetos = await DatabaseHelper.instance.getProjetos();
    } catch (e) {
      print('Erro ao carregar projetos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Criar novo projeto
  Future<int?> createProjeto({
    required String nome,
    required GrupoBiologico grupoBiologico,
    required String campanha,
    required String periodo,
    required String municipio,
    required int usuarioId,
  }) async {
    try {
      final projeto = Projeto(
        nome: nome,
        grupoBiologico: grupoBiologico,
        campanha: campanha,
        periodo: periodo,
        municipio: municipio,
        usuarioId: usuarioId,
        dataInicio: DateTime.now(),
      );

      final id = await DatabaseHelper.instance.insertProjeto(projeto);
      await loadProjetos(); // Recarregar lista
      return id;
    } catch (e) {
      print('Erro ao criar projeto: $e');
      return null;
    }
  }

  // Carregar pontos de um projeto
  Future<void> loadPontosByProjeto(int projetoId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _pontosColeta = await DatabaseHelper.instance.getPontosByProjeto(projetoId);
    } catch (e) {
      print('Erro ao carregar pontos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Criar novo ponto de coleta
  Future<int?> createPontoColeta({
    required String nome,
    required int projetoId,
    required int usuarioId,
    required double latitude,
    required double longitude,
    String? observacoes,
  }) async {
    try {
      final ponto = PontoColeta(
        nome: nome,
        projetoId: projetoId,
        usuarioId: usuarioId,
        latitude: latitude,
        longitude: longitude,
        dataHora: DateTime.now(),
        observacoes: observacoes,
      );

      final id = await DatabaseHelper.instance.insertPontoColeta(ponto);
      await loadPontosByProjeto(projetoId); // Recarregar lista
      return id;
    } catch (e) {
      print('Erro ao criar ponto: $e');
      return null;
    }
  }

  // Carregar coletas de um ponto
  Future<void> loadColetasByPonto(int pontoId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _coletas = await DatabaseHelper.instance.getColetasByPonto(pontoId);
    } catch (e) {
      print('Erro ao carregar coletas: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Criar nova coleta
  Future<int?> createColeta({
    required int pontoColetaId,
    required int usuarioId,
    required String metodologia,
    required String especie,
    String? nomePopular,
    required int quantidade,
    String? caminhoFoto,
    String? observacoes,
  }) async {
    try {
      final coleta = Coleta(
        pontoColetaId: pontoColetaId,
        usuarioId: usuarioId,
        metodologia: metodologia,
        especie: especie,
        nomePopular: nomePopular,
        quantidade: quantidade,
        caminhoFoto: caminhoFoto,
        dataHora: DateTime.now(),
        observacoes: observacoes,
      );

      final id = await DatabaseHelper.instance.insertColeta(coleta);
      await loadColetasByPonto(pontoColetaId); // Recarregar lista
      return id;
    } catch (e) {
      print('Erro ao criar coleta: $e');
      return null;
    }
  }
}