import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/projeto.dart';
import '../models/grupo_fauna.dart';
import '../models/campanha.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';


class ApiService {
  // ===== CONFIGURAÇÃO BASE =====
  static const String baseUrl = 'http://192.168.18.5:8000'; // ajuste conforme IP local
  static String? _token;

  // ===== TOKEN =====
  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  // ===== HEADERS =====
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ===== LOGIN =====
  static Future<String?> login(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {'email': email, 'senha': senha},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== TESTAR CONEXÃO =====
  static Future<bool> testarConexao() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'), headers: headers)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===== SYNC PROJETO =====
  static Future<Map<String, dynamic>> syncProjeto(Projeto projeto) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/projeto'),
        headers: headers,
        body: jsonEncode({
          'uuid': projeto.uuid,
          'nome': projeto.nome,
          'municipio': projeto.municipio,
          'data_inicio': projeto.dataInicio.toIso8601String(),
          'data_fim': projeto.dataFechamento?.toIso8601String(),
          'status': projeto.status.value, // ✅ usa value
          'observacoes': projeto.observacoes,
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

  // ===== SYNC GRUPOS DE FAUNA =====
  static Future<Map<String, dynamic>> syncGruposFauna(
      int projetoIdServidor, List<GrupoFauna> grupos) async {
    try {
      final gruposJson = grupos
          .map((g) => {
        'uuid': g.uuid,
        'tipo': g.tipo?.code, // ✅ usa code
        'nome_customizado': g.nomeCustomizado,
        'descricao': g.descricao,
        'data_criacao': g.dataCriacao.toIso8601String(),
        'data_atualizacao': g.dataAtualizacao.toIso8601String(),
      })
          .toList();

      final payload = {
        'projeto_id': projetoIdServidor,
        'grupos': gruposJson,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/sync/grupos-fauna'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao sincronizar grupos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== SYNC CAMPANHAS =====
  static Future<Map<String, dynamic>> syncCampanhas(
      int grupoFaunaIdServidor, List<Campanha> campanhas) async {
    try {
      final campanhasJson = campanhas
          .map((c) => {
        'uuid': c.uuid,
        'nome': c.nome,
        'periodo': c.periodo,
        'data_inicio': c.dataInicio.toIso8601String(),
        'data_fim': c.dataFim?.toIso8601String(),
        'status': c.status.value, // ✅ usa value
        'observacoes': c.observacoes,
        'data_criacao': c.dataCriacao.toIso8601String(),
        'data_atualizacao': c.dataAtualizacao.toIso8601String(),
      })
          .toList();

      final payload = {
        'grupo_fauna_id': grupoFaunaIdServidor,
        'campanhas': campanhasJson,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/sync/campanhas'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao sincronizar campanhas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== SYNC PONTOS DE COLETA =====
  static Future<Map<String, dynamic>> syncPontosColeta(
      int campanhaIdServidor, List<PontoColeta> pontos) async {
    try {
      final pontosJson = pontos
          .map((p) => {
        'uuid': p.uuid,
        'nome': p.nome,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'data_hora': p.dataHora?.toIso8601String(),
        'observacoes': p.observacoes,
        'data_criacao': p.dataCriacao.toIso8601String(),
        'data_atualizacao': p.dataAtualizacao.toIso8601String(),
      })
          .toList();

      final payload = {
        'campanha_id': campanhaIdServidor,
        'pontos': pontosJson,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/sync/pontos-coleta'),
        headers: headers,
        body: jsonEncode(payload),
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
      int pontoIdServidor, List<Coleta> coletas) async {
    try {
      final coletasJson = coletas.map((c) {
        String? fotoBase64;
        if (c.caminhoFoto != null && File(c.caminhoFoto!).existsSync()) {
          final bytes = File(c.caminhoFoto!).readAsBytesSync();
          fotoBase64 = base64Encode(bytes);
        }

        return {
          'uuid': c.uuid,
          'metodologia': c.metodologia,
          'especie': c.especie,
          'nome_popular': c.nomePopular,
          'quantidade': c.quantidade,
          'foto': fotoBase64, // ✅ imagem convertida
          'observacoes': c.observacoes,
          'data_criacao': c.dataCriacao.toIso8601String(),
          'data_atualizacao': c.dataAtualizacao.toIso8601String(),
        };
      }).toList();

      final payload = {
        'ponto_coleta_id': pontoIdServidor,
        'coletas': coletasJson,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/sync/coletas'),
        headers: headers,
        body: jsonEncode(payload),
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

  // ===== PROCESSAR DADOS =====
  static Future<Map<String, dynamic>> processarDados(int projetoIdServidor) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/processar-dados/$projetoIdServidor'),
        headers: headers,
      );

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
        Uri.parse('$baseUrl/projetos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['dados'] ?? [];
      } else {
        throw Exception('Erro ao listar projetos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ===== URL DE GRÁFICOS =====
  static String getGraficoUrl(String nomeArquivo) {
    return '$baseUrl/grafico/$nomeArquivo';
  }
}
