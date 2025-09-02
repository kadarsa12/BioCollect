import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';

class ApiService {
  // ALTERE para seu IP local (encontre com ipconfig)
  static const String baseUrl = 'http://192.168.18.5:8000';

  // Headers padrão
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  // SYNC PROJETO
  static Future<Map<String, dynamic>> syncProjeto(Projeto projeto) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/projeto'),
        headers: headers,
        body: jsonEncode({
          'nome': projeto.nome,
          'descricao': '${projeto.grupoBiologico.name} - ${projeto.campanha} - ${projeto.periodo}',
          'data_inicio': projeto.dataInicio.toIso8601String(),
          'data_fim': projeto.dataFechamento?.toIso8601String(),
          'status': projeto.status.value,
          'observacoes': 'Município: ${projeto.municipio}',
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

  // SYNC PONTOS DE COLETA
  static Future<Map<String, dynamic>> syncPontosColeta(
      List<PontoColeta> pontos,
      int projetoIdServidor
      ) async {
    try {
      final pontosJson = pontos.map((ponto) => {
        'nome': ponto.nome,
        'projeto_id': projetoIdServidor,
        'latitude': ponto.latitude,
        'longitude': ponto.longitude,
        'data_hora': ponto.dataHora.toIso8601String(),
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

  // SYNC COLETAS
  static Future<Map<String, dynamic>> syncColetas(
      List<Coleta> coletas,
      Map<int, int> mapeamentoPontos // ID local → ID servidor
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

  // PROCESSAR DADOS (calcular índices e gerar gráficos)
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

  // LISTAR PROJETOS DO SERVIDOR
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

  // TESTAR CONEXÃO
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

  // OBTER URL DO GRÁFICO
  static String getGraficoUrl(String nomeArquivo) {
    return '$baseUrl/grafico/$nomeArquivo';
  }
}