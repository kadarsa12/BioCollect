import 'package:flutter/foundation.dart';
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../models/campanha.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../models/enums.dart';
import '../utils/database_helper.dart';

class ProjectProvider with ChangeNotifier {
  List<Projeto> _projetos = [];
  List<GrupoFauna> _gruposFauna = [];
  List<Campanha> _campanhas = [];
  List<PontoColeta> _pontosColeta = [];
  List<Coleta> _coletas = [];
  bool _isLoading = false;

  List<Projeto> get projetos => _projetos;
  List<GrupoFauna> get gruposFauna => _gruposFauna;
  List<Campanha> get campanhas => _campanhas;
  List<PontoColeta> get pontosColeta => _pontosColeta;
  List<Coleta> get coletas => _coletas;
  bool get isLoading => _isLoading;

  // ===== MÉTODOS PARA PROJETOS =====

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

  Future<int?> createProjeto({
    String? nome,
    String? municipio,
    int? usuarioId,
  }) async {
    try {
      final projeto = Projeto(
        nome: nome,
        municipio: municipio,
        usuarioId: usuarioId,
        dataInicio: DateTime.now(),
      );

      final id = await DatabaseHelper.instance.insertProjeto(projeto);
      await loadProjetos();
      return id;
    } catch (e) {
      print('Erro ao criar projeto: $e');
      return null;
    }
  }

  // ===== MÉTODOS PARA GRUPOS DE FAUNA =====

  Future<void> loadGruposByProjeto(int projetoId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _gruposFauna = await DatabaseHelper.instance.getGruposByProjeto(projetoId);
    } catch (e) {
      print('Erro ao carregar grupos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<int?> createGrupoFauna({
    required int projetoId,
    GrupoBiologico? tipo,
    String? nomeCustomizado,
    String? descricao,
  }) async {
    try {
      final grupo = GrupoFauna(
        projetoId: projetoId,
        tipo: tipo,
        nomeCustomizado: nomeCustomizado,
        descricao: descricao,
      );

      final id = await DatabaseHelper.instance.insertGrupoFauna(grupo);
      await loadGruposByProjeto(projetoId);
      return id;
    } catch (e) {
      print('Erro ao criar grupo: $e');
      return null;
    }
  }

  Future<bool> updateGrupoFauna(GrupoFauna grupo) async {
    try {
      await DatabaseHelper.instance.updateGrupoFauna(grupo);
      await loadGruposByProjeto(grupo.projetoId);
      return true;
    } catch (e) {
      print('Erro ao atualizar grupo: $e');
      return false;
    }
  }

  Future<bool> deleteGrupoFauna(int id, int projetoId) async {
    try {
      await DatabaseHelper.instance.deleteGrupoFauna(id);
      await loadGruposByProjeto(projetoId);
      return true;
    } catch (e) {
      print('Erro ao deletar grupo: $e');
      return false;
    }
  }

  // ===== MÉTODOS PARA CAMPANHAS =====

  Future<void> loadCampanhasByGrupo(int grupoFaunaId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _campanhas = await DatabaseHelper.instance.getCampanhasByGrupo(grupoFaunaId);
    } catch (e) {
      print('Erro ao carregar campanhas: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<int?> createCampanha({
    required int grupoFaunaId,
    String? nome,
    String? periodo,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? observacoes,
  }) async {
    try {
      final campanha = Campanha(
        grupoFaunaId: grupoFaunaId,
        nome: nome,
        periodo: periodo,
        dataInicio: dataInicio ?? DateTime.now(),
        dataFim: dataFim,
        observacoes: observacoes,
      );

      final id = await DatabaseHelper.instance.insertCampanha(campanha);
      await loadCampanhasByGrupo(grupoFaunaId);
      return id;
    } catch (e) {
      print('Erro ao criar campanha: $e');
      return null;
    }
  }

  Future<bool> updateCampanha(Campanha campanha) async {
    try {
      await DatabaseHelper.instance.updateCampanha(campanha);
      await loadCampanhasByGrupo(campanha.grupoFaunaId);
      return true;
    } catch (e) {
      print('Erro ao atualizar campanha: $e');
      return false;
    }
  }

  Future<bool> deleteCampanha(int id, int grupoFaunaId) async {
    try {
      await DatabaseHelper.instance.deleteCampanha(id);
      await loadCampanhasByGrupo(grupoFaunaId);
      return true;
    } catch (e) {
      print('Erro ao deletar campanha: $e');
      return false;
    }
  }

  // ===== MÉTODOS PARA PONTOS DE COLETA =====

  // ✅ NOVO: Carregar pontos por campanha
  Future<void> loadPontosByCampanha(int campanhaId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _pontosColeta = await DatabaseHelper.instance.getPontosByCampanha(campanhaId);
    } catch (e) {
      print('Erro ao carregar pontos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ ATUALIZADO: Criar ponto com campanhaId
  Future<int?> createPontoColeta({
    required int campanhaId, // ✅ MUDOU de projetoId
    String? nome,
    double? latitude,
    double? longitude,
    String? observacoes,
  }) async {
    try {
      final ponto = PontoColeta(
        nome: nome,
        campanhaId: campanhaId, // ✅ MUDOU
        latitude: latitude,
        longitude: longitude,
        dataHora: DateTime.now(),
        observacoes: observacoes,
      );

      final id = await DatabaseHelper.instance.insertPontoColeta(ponto);
      await loadPontosByCampanha(campanhaId); // ✅ MUDOU
      return id;
    } catch (e) {
      print('Erro ao criar ponto: $e');
      return null;
    }
  }

  // ===== MÉTODOS PARA COLETAS =====

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

  Future<int?> createColeta({
    required int pontoColetaId,
    String? metodologia,
    String? especie,
    String? nomePopular,
    int? quantidade,
    String? caminhoFoto,
    String? observacoes,
  }) async {
    try {
      final coleta = Coleta(
        pontoColetaId: pontoColetaId,
        metodologia: metodologia ?? '',
        especie: especie ?? '',
        nomePopular: nomePopular,
        quantidade: quantidade ?? 0,
        caminhoFoto: caminhoFoto,
        dataHora: DateTime.now(),
        observacoes: observacoes,
      );

      final id = await DatabaseHelper.instance.insertColeta(coleta);
      await loadColetasByPonto(pontoColetaId);
      return id;
    } catch (e) {
      print('Erro ao criar coleta: $e');
      return null;
    }
  }
}