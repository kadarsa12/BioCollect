import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/projeto.dart';
import '../models/ponto_coleta.dart';
import '../models/enums.dart';
import '../providers/project_provider.dart';

class CreateColetaScreen extends StatefulWidget {
  final PontoColeta ponto;
  final Projeto projeto;

  CreateColetaScreen({
    required this.ponto,
    required this.projeto,
  });

  @override
  _CreateColetaScreenState createState() => _CreateColetaScreenState();
}

class _CreateColetaScreenState extends State<CreateColetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _especieController = TextEditingController();
  final _nomePopularController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _observacoesController = TextEditingController();

  String? _metodologia;
  File? _imagemCapturada;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nova Coleta'),
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
                      Icon(Icons.location_on, color: Colors.green),
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
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Metodologia',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.science),
                ),
                value: _metodologia,
                items: widget.projeto.grupoBiologico.getMetodologias().map((metodologia) {
                  return DropdownMenuItem(
                    value: metodologia,
                    child: Text(metodologia),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _metodologia = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecione a metodologia';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Espécie
              TextFormField(
                controller: _especieController,
                decoration: InputDecoration(
                  labelText: 'Espécie (nome científico)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                  hintText: 'Ex: Astyanax lacustris',
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
                  hintText: 'Ex: lambari-do-rabo-amarelo',
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
                          Icon(Icons.camera_alt, color: Colors.green),
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

              // Botão salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _salvarColeta,
                  child: Text('Registrar Coleta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      print('Erro ao capturar foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar foto: $e')),
      );
    }
  }

  Future<void> _salvarColeta() async {
    if (_formKey.currentState!.validate()) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

      // Salvar foto se foi capturada (simplificado para MVP)
      String? caminhoFoto;
      if (_imagemCapturada != null) {
        caminhoFoto = _imagemCapturada!.path;
      }

      final id = await projectProvider.createColeta(
        pontoColetaId: widget.ponto.id!,
        metodologia: _metodologia!,
        especie: _especieController.text,
        nomePopular: _nomePopularController.text.isEmpty ? null : _nomePopularController.text,
        quantidade: int.parse(_quantidadeController.text),
        caminhoFoto: caminhoFoto,
        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
      );

      if (id != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coleta registrada com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar coleta')),
        );
      }
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