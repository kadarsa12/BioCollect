import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../models/campanha.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';

class ApiService {
  // ALTERE para seu IP local (encontre com ipconfig)
  static const String baseUrl = 'http://192.168.18.5:8000';

  // Headers padrão
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  // ===== SYNC PROJETO =====
  static Future<Map<String, dynamic>> syncProjeto(Projeto projeto) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/projeto'),
        headers: headers,
        body: jsonEncode({
          'nome': projeto.nome,
          'municipio': projeto.municipio,
          'data_inicio': projeto.dataInicio.toIso8601String(),
          'data_fechamento': projeto.dataFechamento?.toIso8601String(),
          'status': projeto.status.value,
          'usuario_id': projeto.usuarioId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao sincronizar projeto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== SYNC GRUPO DE FAUNA =====
  static Future<Map<String, dynamic>> syncGrupoFauna(
      GrupoFauna grupo,
      int projetoIdServidor,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/grupo-fauna'),
        headers: headers,
        body: jsonEncode({
          'projeto_id': projetoIdServidor,
          'tipo': grupo.tipo?.code,
          'nome_customizado': grupo.nomeCustomizado,
          'descricao': grupo.descricao,
          'created_at': grupo.createdAt.toIso8601String(),
          'updated_at': grupo.updatedAt.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao sincronizar grupo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== SYNC CAMPANHA =====
  static Future<Map<String, dynamic>> syncCampanha(
      Campanha campanha,
      int grupoFaunaIdServidor,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/campanha'),
        headers: headers,
        body: jsonEncode({
          'grupo_fauna_id': grupoFaunaIdServidor,
          'nome': campanha.nome,
          'periodo': campanha.periodo,
          'data_inicio': campanha.dataInicio.toIso8601String(),
          'data_fim': campanha.dataFim?.toIso8601String(),
          'status': campanha.status.value,
          'observacoes': campanha.observacoes,
          'created_at': campanha.createdAt.toIso8601String(),
          'updated_at': campanha.updatedAt.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao sincronizar campanha: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== SYNC PONTOS DE COLETA =====
  static Future<Map<String, dynamic>> syncPontosColeta(
      List<PontoColeta> pontos,
      int campanhaIdServidor,
      ) async {
    try {
      final pontosJson = pontos.map((ponto) => {
        'nome': ponto.nome,
        'campanha_id': campanhaIdServidor,
        'latitude': ponto.latitude,
        'longitude': ponto.longitude,
        'data_hora': (ponto.dataHora ?? DateTime.now()).toIso8601String(),
        'observacoes': ponto.observacoes,
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/sync/pontos-coleta'),
        headers: headers,
        body: jsonEncode(pontosJson),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao sincronizar pontos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== SYNC COLETAS =====
  static Future<Map<String, dynamic>> syncColetas(
      List<Coleta> coletas,
      Map<int, int> mapeamentoPontos, // ID local → ID servidor
      ) async {
    try {
      final coletasJson = coletas.map((coleta) => {
        'ponto_coleta_id': mapeamentoPontos[coleta.pontoColetaId],
        'metodologia': coleta.metodologia,
        'especie': coleta.especie,
        'nome_popular': coleta.nomePopular,
        'quantidade': coleta.quantidade,
        'caminho_foto': coleta.caminhoFoto,
        'data_hora': coleta.dataHora.toIso8601String(),
        'observacoes': coleta.observacoes,
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/sync/coletas'),
        headers: headers,
        body: jsonEncode(coletasJson),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao sincronizar coletas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== SYNC COMPLETO (HIERÁRQUICO) =====
  static Future<Map<String, dynamic>> syncCompleto({
    required Projeto projeto,
    required List<GrupoFauna> grupos,
    required Map<int, List<Campanha>> campanhasPorGrupo, // grupoId → campanhas
    required Map<int, List<PontoColeta>> pontosPorCampanha, // campanhaId → pontos
    required Map<int, List<Coleta>> coletasPorPonto, // pontoId → coletas
  }) async {
    try {
      // 1. Sync Projeto
      final projetoResponse = await syncProjeto(projeto);
      final projetoIdServidor = projetoResponse['id'];

      Map<int, int> mapaGrupos = {}; // ID local → ID servidor
      Map<int, int> mapaCampanhas = {};
      Map<int, int> mapaPontos = {};

      // 2. Sync Grupos
      for (final grupo in grupos) {
        final grupoResponse = await syncGrupoFauna(grupo, projetoIdServidor);
        mapaGrupos[grupo.id!] = grupoResponse['id'];

        // 3. Sync Campanhas do grupo
        final campanhas = campanhasPorGrupo[grupo.id] ?? [];
        for (final campanha in campanhas) {
          final campanhaResponse = await syncCampanha(
            campanha,
            grupoResponse['id'],
          );
          mapaCampanhas[campanha.id!] = campanhaResponse['id'];

          // 4. Sync Pontos da campanha
          final pontos = pontosPorCampanha[campanha.id] ?? [];
          if (pontos.isNotEmpty) {
            final pontosResponse = await syncPontosColeta(
              pontos,
              campanhaResponse['id'],
            );

            // Mapear IDs dos pontos
            final pontosServidor = pontosResponse['pontos'] as List;
            for (int i = 0; i < pontos.length; i++) {
              mapaPontos[pontos[i].id!] = pontosServidor[i]['id'];
            }

            // 5. Sync Coletas dos pontos
            for (final ponto in pontos) {
              final coletas = coletasPorPonto[ponto.id] ?? [];
              if (coletas.isNotEmpty) {
                await syncColetas(coletas, mapaPontos);
              }
            }
          }
        }
      }

      return {
        'success': true,
        'projeto_id': projetoIdServidor,
        'grupos_sincronizados': mapaGrupos.length,
        'campanhas_sincronizadas': mapaCampanhas.length,
        'pontos_sincronizados': mapaPontos.length,
      };
    } catch (e) {
      throw Exception('Erro na sincronização completa: $e');
    }
  }

  // ===== PROCESSAR DADOS (calcular índices) =====
  static Future<Map<String, dynamic>> processarDados({
    required int projetoIdServidor,
    int? grupoFaunaId,
    int? campanhaId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (grupoFaunaId != null) queryParams['grupo_fauna_id'] = grupoFaunaId.toString();
      if (campanhaId != null) queryParams['campanha_id'] = campanhaId.toString();

      final uri = Uri.parse('$baseUrl/processar-dados/$projetoIdServidor')
          .replace(queryParameters: queryParams);

      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao processar dados: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== LISTAR PROJETOS =====
  static Future<List<dynamic>> listarProjetos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/flutter/projetos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['projetos'] ?? [];
      } else {
        throw Exception('Erro ao listar projetos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== TESTAR CONEXÃO =====
  static Future<bool> testarConexao() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: headers,
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===== OBTER URL DO GRÁFICO =====
  static String getGraficoUrl(String nomeArquivo) {
    return '$baseUrl/grafico/$nomeArquivo';
  }
}