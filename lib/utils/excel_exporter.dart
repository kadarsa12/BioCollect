import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

class ExcelExporter {
  static Future<String?> exportProject(Projeto projeto, User usuario) async {
    try {
      print('=== INICIANDO EXPORT ===');
      print('Projeto: ${projeto.nome}');
      print('Usuário: ${usuario.nome}');

      // Criar workbook
      print('Criando workbook...');
      final Workbook workbook = Workbook();
      final Worksheet worksheet = workbook.worksheets[0];
      worksheet.name = 'Coletas_${projeto.campanha}';
      print('Workbook criado com sucesso');

      // Configurar cabeçalhos
      print('Configurando cabeçalhos...');
      _setupHeaders(worksheet, projeto);
      print('Cabeçalhos configurados');

      // Buscar dados do projeto
      print('Buscando pontos do projeto...');
      final pontos = await DatabaseHelper.instance.getPontosByProjeto(projeto.id!);
      print('Encontrados ${pontos.length} pontos');

      int currentRow = 2; // Linha 1 é o cabeçalho

      for (int i = 0; i < pontos.length; i++) {
        final ponto = pontos[i];
        print('Processando ponto ${i + 1}: ${ponto.nome}');

        final coletas = await DatabaseHelper.instance.getColetasByPonto(ponto.id!);
        print('Encontradas ${coletas.length} coletas no ponto ${ponto.nome}');

        if (coletas.isEmpty) {
          print('Adicionando linha sem coleta para ponto ${ponto.nome}');
          _addRowData(worksheet, currentRow, projeto, ponto, null, usuario);
          currentRow++;
        } else {
          for (int j = 0; j < coletas.length; j++) {
            final coleta = coletas[j];
            print('Adicionando coleta ${j + 1} do ponto ${ponto.nome}');
            _addRowData(worksheet, currentRow, projeto, ponto, coleta, usuario);
            currentRow++;
          }
        }
      }

      print('Dados adicionados, ajustando colunas...');
      // Auto-fit colunas
      for (int i = 1; i <= 26; i++) {
        worksheet.autoFitColumn(i);
      }

      print('Salvando workbook...');
      // Salvar arquivo
      final List<int> bytes = workbook.saveAsStream();
      print('Workbook salvo em memória');

      // Obter diretório para salvar
      print('Obtendo diretório...');
      final Directory directory = await getApplicationDocumentsDirectory();
      final String fileName = _generateFileName(projeto);
      final String filePath = '${directory.path}/$fileName';

      print('Salvando arquivo: $filePath');
      final File file = File(filePath);
      await file.writeAsBytes(bytes);
      print('Arquivo salvo com sucesso!');

      return filePath;
    } catch (e, stackTrace) {
      print('=== ERRO NO EXPORT ===');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static void _setupHeaders(Worksheet worksheet, Projeto projeto) {
    // Cabeçalhos padrão para todos os grupos (baseado no seu exemplo de peixes)
    final List<String> headers = <String>[
      'Campanha',           // A
      'Data',               // B
      'Período (Seca ou Cheia)', // C
      'Município',          // D
      'Latitude (S)',       // E
      'Longitude (W)',      // F
      'Ponto (P1,P2...)',   // G
      'Ordem',              // H
      'Família',            // I
      'Espécie',            // J
      'Nome popular',       // K
      'Quantidade (N)',     // L
      'Metodologia',        // M
      'Habitat (relativo à espécie)', // N
      'Endemismo',          // O
      'IUCN',               // P
      'MMA 2022',           // Q
      'MMA 2014',           // R
      'CITES',              // S
      'Importância ecológica', // T
      'Espécies cinegéticas',  // U
      'Outro interesse humano', // V
      'Guilda',             // W
      'Migração',           // X
      'Observações',        // Y
      'Técnico responsável', // Z
    ];

    // Aplicar cabeçalhos
    for (int i = 0; i < headers.length; i++) {
      final cell = worksheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#E0E0E0';
    }
  }

  static void _addRowData(
      Worksheet worksheet,
      int row,
      Projeto projeto,
      PontoColeta ponto,
      Coleta? coleta,
      User usuario,
      ) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

    // Coluna A - Campanha
    worksheet.getRangeByIndex(row, 1).setText(projeto.campanha);

    // Coluna B - Data (da coleta ou do ponto se não houver coleta)
    final data = coleta?.dataHora ?? ponto.dataHora;
    worksheet.getRangeByIndex(row, 2).setText(dateFormat.format(data));

    // Coluna C - Período
    worksheet.getRangeByIndex(row, 3).setText(projeto.periodo);

    // Coluna D - Município
    worksheet.getRangeByIndex(row, 4).setText(projeto.municipio);

    // Coluna E - Latitude
    if (ponto.latitude != 0.0) {
      worksheet.getRangeByIndex(row, 5).setText("${ponto.latitude.toStringAsFixed(6)}°S");
    } else {
      worksheet.getRangeByIndex(row, 5).setText('');
    }

    // Coluna F - Longitude
    if (ponto.longitude != 0.0) {
      worksheet.getRangeByIndex(row, 6).setText("${ponto.longitude.toStringAsFixed(6)}°W");
    } else {
      worksheet.getRangeByIndex(row, 6).setText('');
    }

    // Coluna G - Ponto
    worksheet.getRangeByIndex(row, 7).setText(ponto.nome);

    // Se tem coleta, preencher dados da coleta
    if (coleta != null) {
      // Coluna H - Ordem (vazio por enquanto - campo científico opcional)
      worksheet.getRangeByIndex(row, 8).setText('');

      // Coluna I - Família (vazio por enquanto - campo científico opcional)
      worksheet.getRangeByIndex(row, 9).setText('');

      // Coluna J - Espécie
      worksheet.getRangeByIndex(row, 10).setText(coleta.especie);

      // Coluna K - Nome popular
      worksheet.getRangeByIndex(row, 11).setText(coleta.nomePopular ?? '');

      // Coluna L - Quantidade
      worksheet.getRangeByIndex(row, 12).setNumber(coleta.quantidade.toDouble());

      // Coluna M - Metodologia
      worksheet.getRangeByIndex(row, 13).setText(coleta.metodologia);

      // Colunas N a X - Campos científicos (vazios por enquanto)
      for (int i = 14; i <= 24; i++) {
        worksheet.getRangeByIndex(row, i).setText('');
      }

      // Coluna Y - Observações (do ponto + da coleta)
      String observacoes = '';
      if (ponto.observacoes != null && ponto.observacoes!.isNotEmpty) {
        observacoes += 'Ponto: ${ponto.observacoes}';
      }
      if (coleta.observacoes != null && coleta.observacoes!.isNotEmpty) {
        if (observacoes.isNotEmpty) observacoes += ' | ';
        observacoes += 'Coleta: ${coleta.observacoes}';
      }
      worksheet.getRangeByIndex(row, 25).setText(observacoes);
    } else {
      // Sem coleta - preencher apenas campos básicos
      for (int i = 8; i <= 24; i++) {
        worksheet.getRangeByIndex(row, i).setText('');
      }
      // Observações só do ponto
      worksheet.getRangeByIndex(row, 25).setText(ponto.observacoes ?? '');
    }

    // Coluna Z - Técnico responsável
    worksheet.getRangeByIndex(row, 26).setText(usuario.nome);
  }

  static String _generateFileName(Projeto projeto) {
    final DateFormat fileFormat = DateFormat('yyyy.MM.dd');
    final data = fileFormat.format(DateTime.now());
    final grupo = projeto.grupoBiologico.code.toLowerCase();
    return '${grupo}_${projeto.municipio.replaceAll(' ', '_')}_${projeto.campanha}_$data.xlsx';
  }

  static Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      print('Erro ao compartilhar arquivo: $e');
    }
  }
}