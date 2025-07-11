import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/coleta.dart';
import '../models/metodologia.dart';
import '../models/enums.dart';
import '../providers/project_provider.dart';
import '../providers/user_provider.dart';
import '../utils/database_helper.dart';
import 'manage_metodologias_screen.dart';

class EditColetaScreen extends StatefulWidget {
  final Coleta coleta;
  final PontoColeta ponto;
  final Projeto projeto;

  EditColetaScreen({
    required this.coleta,
    required this.ponto,
    required this.projeto,
  });

  @override
  _EditColetaScreenState createState() => _EditColetaScreenState();
}

class _EditColetaScreenState extends State<EditColetaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _especieController;
  late TextEditingController _nomePopularController;
  late TextEditingController _quantidadeController;
  late TextEditingController _observacoesController;

  String? _metodologia;
  File? _imagemCapturada;
  final ImagePicker _picker = ImagePicker();

  // Metodologias cadastradas
  List<Metodologia> _metodologiasCadastradas = [];
  bool _isLoadingMetodologias = false;
  bool _metodologiaOriginalExiste = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controllers com dados atuais
    _especieController = TextEditingController(text: widget.coleta.especie);
    _nomePopularController = TextEditingController(text: widget.coleta.nomePopular ?? '');
    _quantidadeController = TextEditingController(text: widget.coleta.quantidade.toString());
    _observacoesController = TextEditingController(text: widget.coleta.observacoes ?? '');

    _metodologia = widget.coleta.metodologia;

    // Verificar se tem foto
    if (widget.coleta.caminhoFoto != null && widget.coleta.caminhoFoto!.isNotEmpty) {
      _imagemCapturada = File(widget.coleta.caminhoFoto!);
    }

    _loadMetodologias();
  }

  Future<void> _loadMetodologias() async {
    setState(() {
      _isLoadingMetodologias = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;

      if (userId != null) {
        final metodologias = await DatabaseHelper.instance.getMetodologiasByGrupo(
          widget.projeto.grupoBiologico.code,
          userId,
        );

        setState(() {
          _metodologiasCadastradas = metodologias;
        });

        // Verificar se a metodologia original existe nas cadastradas
        _metodologiaOriginalExiste = metodologias.any((m) => m.nome == widget.coleta.metodologia);

        // Se não existe, criar automaticamente
        if (!_metodologiaOriginalExiste && widget.coleta.metodologia.isNotEmpty) {
          await _criarMetodologiaAutomatica(widget.coleta.metodologia);
        }
      }
    } catch (e) {
      print('Erro ao carregar metodologias: $e');
    }

    setState(() {
      _isLoadingMetodologias = false;
    });
  }

  Future<void> _criarMetodologiaAutomatica(String nomeMetodologia) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;

      if (userId != null) {
        final metodologia = Metodologia(
          nome: nomeMetodologia,
          descricao: 'Criada automaticamente durante edição',
          grupoBiologico: widget.projeto.grupoBiologico.code,
          usuarioId: userId,
          dataCriacao: DateTime.now(),
        );

        await DatabaseHelper.instance.insertMetodologia(metodologia);

        // Recarregar metodologias
        final metodologias = await DatabaseHelper.instance.getMetodologiasByGrupo(
          widget.projeto.grupoBiologico.code,
          userId,
        );

        setState(() {
          _metodologiasCadastradas = metodologias;
          _metodologiaOriginalExiste = true;
        });
      }
    } catch (e) {
      print('Erro ao criar metodologia automática: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Coleta'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmarDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info do ponto
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xFF8D6E63)),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ponto: ${widget.ponto.nome}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Grupo: ${widget.projeto.grupoBiologico.displayName}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Metodologia
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingMetodologias)
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Carregando metodologias...'),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Metodologia',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.science),
                      ),
                      value: _metodologia,
                      items: [
                        // Métodos cadastrados pelo usuário
                        ..._metodologiasCadastradas.map((metodologia) {
                          return DropdownMenuItem(
                            value: metodologia.nome,
                            child: Text(metodologia.nome),
                          );
                        }).toList(),

                        // Opção para criar novo método
                        DropdownMenuItem(
                          value: "CRIAR_NOVO",
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 16, color: Color(0xFF8D6E63)),
                              SizedBox(width: 8),
                              Text(
                                'Criar novo método...',
                                style: TextStyle(
                                  color: Color(0xFF8D6E63),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == "CRIAR_NOVO") {
                          _showCreateMetodologiaDialog();
                        } else {
                          setState(() {
                            _metodologia = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value == "CRIAR_NOVO") {
                          return 'Selecione uma metodologia';
                        }
                        return null;
                      },
                    ),

                  // Aviso se metodologia foi criada automaticamente
                  if (!_metodologiaOriginalExiste && !_isLoadingMetodologias && widget.coleta.metodologia.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, size: 16, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Metodologia "${widget.coleta.metodologia}" foi adicionada automaticamente',
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Botão para gerenciar métodos
                  if (_metodologiasCadastradas.isEmpty && !_isLoadingMetodologias)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ManageMetodologiasScreen(projeto: widget.projeto),
                            ),
                          ).then((_) => _loadMetodologias());
                        },
                        icon: Icon(Icons.science),
                        label: Text('Gerenciar Métodos'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF8D6E63),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),

              // Espécie
              TextFormField(
                controller: _especieController,
                decoration: InputDecoration(
                  labelText: 'Espécie (nome científico)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o nome da espécie';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Nome popular
              TextFormField(
                controller: _nomePopularController,
                decoration: InputDecoration(
                  labelText: 'Nome popular (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              SizedBox(height: 16),

              // Quantidade
              TextFormField(
                controller: _quantidadeController,
                decoration: InputDecoration(
                  labelText: 'Quantidade',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite a quantidade';
                  }
                  final quantidade = int.tryParse(value);
                  if (quantidade == null || quantidade <= 0) {
                    return 'Digite um número válido maior que 0';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Captura de foto
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.camera_alt, color: Color(0xFF8D6E63)),
                          SizedBox(width: 8),
                          Text(
                            'Foto do Exemplar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      if (_imagemCapturada != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imagemCapturada!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 50),
                                      Text('Erro ao carregar foto'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _capturarFoto(ImageSource.camera),
                              icon: Icon(Icons.camera),
                              label: Text('Câmera'),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _capturarFoto(ImageSource.gallery),
                              icon: Icon(Icons.photo_library),
                              label: Text('Galeria'),
                            ),
                          ),
                        ],
                      ),

                      if (_imagemCapturada != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _imagemCapturada = null;
                            });
                          },
                          icon: Icon(Icons.delete, color: Colors.red),
                          label: Text('Remover Foto', style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Observações
              TextFormField(
                controller: _observacoesController,
                decoration: InputDecoration(
                  labelText: 'Observações (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvarAlteracoes,
                      child: Text('Salvar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8D6E63),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateMetodologiaDialog() {
    final nomeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Metodologia'),
        content: TextField(
          controller: nomeController,
          decoration: InputDecoration(
            labelText: 'Nome da metodologia',
            border: OutlineInputBorder(),
            hintText: 'Ex: Puçá malha 5mm',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.trim().isNotEmpty) {
                await _createMetodologiaRapida(nomeController.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text('Criar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8D6E63),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createMetodologiaRapida(String nome) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;

      if (userId != null) {
        final metodologia = Metodologia(
          nome: nome,
          descricao: null,
          grupoBiologico: widget.projeto.grupoBiologico.code,
          usuarioId: userId,
          dataCriacao: DateTime.now(),
        );

        await DatabaseHelper.instance.insertMetodologia(metodologia);
        await _loadMetodologias();

        setState(() {
          _metodologia = nome;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Metodologia "$nome" criada e selecionada!'),
            backgroundColor: Color(0xFF8D6E63),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar metodologia: $e')),
      );
    }
  }

  Future<void> _capturarFoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagemCapturada = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar foto: $e')),
      );
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? caminhoFoto;
        if (_imagemCapturada != null) {
          caminhoFoto = _imagemCapturada!.path;
        }

        // Atualizar no banco
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'coletas',
          {
            'metodologia': _metodologia!,
            'especie': _especieController.text,
            'nome_popular': _nomePopularController.text.isEmpty ? null : _nomePopularController.text,
            'quantidade': int.parse(_quantidadeController.text),
            'caminho_foto': caminhoFoto,
            'observacoes': _observacoesController.text.isEmpty ? null : _observacoesController.text,
          },
          where: 'id = ?',
          whereArgs: [widget.coleta.id],
        );

        // Recarregar lista
        final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
        await projectProvider.loadColetasByPonto(widget.ponto.id!);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coleta atualizada com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  void _confirmarDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Coleta'),
        content: Text('Tem certeza que deseja excluir esta coleta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: _deleteColeta,
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteColeta() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('coletas', where: 'id = ?', whereArgs: [widget.coleta.id]);

      // Recarregar lista
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.loadColetasByPonto(widget.ponto.id!);

      Navigator.pop(context); // Fechar dialog
      Navigator.pop(context); // Voltar para lista de coletas
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coleta excluída com sucesso!')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }

  @override
  void dispose() {
    _especieController.dispose();
    _nomePopularController.dispose();
    _quantidadeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}