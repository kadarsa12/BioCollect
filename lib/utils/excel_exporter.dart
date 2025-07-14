import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../models/user.dart';
import '../models/excel_template.dart';
import '../utils/database_helper.dart';

class ExcelExporter {
  static Future<String?> exportProject(
      Projeto projeto,
      User usuario,
      {ExcelTemplate? template}
      ) async {
    try {
      print('=== INICIANDO EXPORT COM TEMPLATE ===');
      print('Projeto: ${projeto.nome}');
      print('Template: ${template?.nome ?? "Padrão"}');

      // Se não tem template, usar padrão
      if (template == null) {
        print('Criando template padrão...');
        template = await _getDefaultTemplate(projeto.grupoBiologico.code);
      }

      // Criar workbook
      print('Criando workbook...');
      final Workbook workbook = Workbook();
      final Worksheet worksheet = workbook.worksheets[0];
      worksheet.name = 'Coletas_${projeto.campanha}';
      print('Workbook criado com sucesso');

      // Configurar cabeçalhos baseado no template
      print('Configurando cabeçalhos...');
      _setupHeadersFromTemplate(worksheet, template);
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
          _addRowDataFromTemplate(worksheet, currentRow, projeto, ponto, null, usuario, template);
          currentRow++;
        } else {
          for (int j = 0; j < coletas.length; j++) {
            final coleta = coletas[j];
            print('Adicionando coleta ${j + 1} do ponto ${ponto.nome}');
            _addRowDataFromTemplate(worksheet, currentRow, projeto, ponto, coleta, usuario, template);
            currentRow++;
          }
        }
      }

      print('Dados adicionados, ajustando colunas...');
      // Auto-fit colunas apenas para as colunas ativas
      final activeCols = template.colunas.where((c) => c.ativo).length;
      for (int i = 1; i <= activeCols; i++) {
        worksheet.autoFitColumn(i);
      }

      print('Salvando workbook...');
      // Salvar arquivo
      final List<int> bytes = workbook.saveAsStream();
      print('Workbook salvo em memória');

      // Obter diretório para salvar
      print('Obtendo diretório...');
      final Directory directory = await getApplicationDocumentsDirectory();
      final String fileName = _generateFileName(projeto, template);
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

  static Future<ExcelTemplate> _getDefaultTemplate(String grupoBiologico) async {
    // Tentar buscar template padrão do banco
    try {
      final templates = await DatabaseHelper.instance.getTemplatesByGrupo(grupoBiologico);
      final defaultTemplate = templates.firstWhere(
            (t) => t.isDefault,
        orElse: () => templates.isNotEmpty ? templates.first : _createFallbackTemplate(grupoBiologico),
      );
      return defaultTemplate;
    } catch (e) {
      print('Erro ao buscar template padrão: $e');
      return _createFallbackTemplate(grupoBiologico);
    }
  }

  static ExcelTemplate _createFallbackTemplate(String grupoBiologico) {
    // Template básico caso não exista nenhum no banco
    return ExcelTemplate(
      nome: 'Template Padrão',
      grupoBiologico: grupoBiologico,
      colunas: [
        ExcelColumn(campoOriginal: 'campanha', nomeExibicao: 'Campanha', ordem: 0),
        ExcelColumn(campoOriginal: 'data', nomeExibicao: 'Data', ordem: 1),
        ExcelColumn(campoOriginal: 'municipio', nomeExibicao: 'Município', ordem: 2),
        ExcelColumn(campoOriginal: 'ponto', nomeExibicao: 'Ponto', ordem: 3),
        ExcelColumn(campoOriginal: 'especie', nomeExibicao: 'Espécie', ordem: 4),
        ExcelColumn(campoOriginal: 'quantidade', nomeExibicao: 'Quantidade', ordem: 5),
        ExcelColumn(campoOriginal: 'tecnicoResponsavel', nomeExibicao: 'Técnico', ordem: 6),
      ],
    );
  }

  static void _setupHeadersFromTemplate(Worksheet worksheet, ExcelTemplate template) {
    // Filtrar apenas colunas ativas e ordenar
    final activeCols = template.colunas
        .where((c) => c.ativo)
        .toList()
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    // Aplicar cabeçalhos
    for (int i = 0; i < activeCols.length; i++) {
      final cell = worksheet.getRangeByIndex(1, i + 1);
      cell.setText(activeCols[i].nomeExibicao);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#E0E0E0';
    }
  }

  static void _addRowDataFromTemplate(
      Worksheet worksheet,
      int row,
      Projeto projeto,
      PontoColeta ponto,
      Coleta? coleta,
      User usuario,
      ExcelTemplate template,
      ) {
    // Filtrar apenas colunas ativas e ordenar
    final activeCols = template.colunas
        .where((c) => c.ativo)
        .toList()
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

    // Preencher dados baseado no template
    for (int i = 0; i < activeCols.length; i++) {
      final coluna = activeCols[i];
      final cell = worksheet.getRangeByIndex(row, i + 1);

      // Obter valor baseado no campo
      final valor = _getFieldValue(coluna.campoOriginal, projeto, ponto, coleta, usuario, dateFormat);

      // Aplicar formatação baseada no tipo
      if (coluna.formato == 'numero' && valor is num) {
        cell.setNumber(valor.toDouble());
      } else {
        cell.setText(valor?.toString() ?? '');
      }
    }
  }

  static dynamic _getFieldValue(
      String campo,
      Projeto projeto,
      PontoColeta ponto,
      Coleta? coleta,
      User usuario,
      DateFormat dateFormat,
      ) {
    switch (campo) {
      case 'campanha':
        return projeto.campanha;
      case 'data':
        final data = coleta?.dataHora ?? ponto.dataHora;
        return dateFormat.format(data);
      case 'periodo':
        return projeto.periodo;
      case 'municipio':
        return projeto.municipio;
      case 'latitude':
        return ponto.latitude != 0.0 ? "${ponto.latitude.toStringAsFixed(6)}°S" : '';
      case 'longitude':
        return ponto.longitude != 0.0 ? "${ponto.longitude.toStringAsFixed(6)}°W" : '';
      case 'ponto':
        return ponto.nome;
      case 'ordem':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'familia':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'especie':
        return coleta?.especie ?? '';
      case 'nomePopular':
        return coleta?.nomePopular ?? '';
      case 'quantidade':
        return coleta?.quantidade ?? 0;
      case 'metodologia':
        return coleta?.metodologia ?? '';
      case 'habitat':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'endemismo':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'iucn':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'mma2022':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'mma2014':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'cites':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'importanciaEcologica':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'especiesCinegeticas':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'outroInteresse':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'guilda':
      case 'guildaTrofica':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'migracao':
        return ''; // Campo científico opcional - implementar quando necessário
      case 'observacoes':
        String observacoes = '';
        if (ponto.observacoes != null && ponto.observacoes!.isNotEmpty) {
          observacoes += 'Ponto: ${ponto.observacoes}';
        }
        if (coleta?.observacoes != null && coleta!.observacoes!.isNotEmpty) {
          if (observacoes.isNotEmpty) observacoes += ' | ';
          observacoes += 'Coleta: ${coleta.observacoes}';
        }
        return observacoes;
      case 'tecnicoResponsavel':
        return usuario.nome;
      default:
        print('Campo não mapeado: $campo');
        return '';
    }
  }

  static String _generateFileName(Projeto projeto, ExcelTemplate template) {
    final DateFormat fileFormat = DateFormat('yyyy.MM.dd');
    final data = fileFormat.format(DateTime.now());
    final grupo = projeto.grupoBiologico.code.toLowerCase();
    final templateName = template.nome.replaceAll(' ', '_').toLowerCase();
    return '${grupo}_${projeto.municipio.replaceAll(' ', '_')}_${projeto.campanha}_${templateName}_$data.xlsx';
  }

  static Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      print('Erro ao compartilhar arquivo: $e');
    }
  }
}