import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/user_provider.dart';
import '../models/enums.dart';

class CreateProjectScreen extends StatefulWidget {
  @override
  _CreateProjectScreenState createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _campanhaController = TextEditingController();
  final _municipioController = TextEditingController();

  GrupoBiologico? _grupoBiologico;
  String? _periodo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Novo Projeto'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Projeto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o nome do projeto';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<GrupoBiologico>(
                decoration: InputDecoration(
                  labelText: 'Grupo Biológico',
                  border: OutlineInputBorder(),
                ),
                value: _grupoBiologico,
                items: GrupoBiologico.values.map((grupo) {
                  return DropdownMenuItem(
                    value: grupo,
                    child: Text(grupo.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _grupoBiologico = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecione o grupo biológico';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _campanhaController,
                decoration: InputDecoration(
                  labelText: 'Campanha',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite a campanha';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Período',
                  border: OutlineInputBorder(),
                ),
                value: _periodo,
                items: ['Seca', 'Cheia'].map((periodo) {
                  return DropdownMenuItem(
                    value: periodo,
                    child: Text(periodo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _periodo = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecione o período';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _municipioController,
                decoration: InputDecoration(
                  labelText: 'Município',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o município';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _criarProjeto,
                  child: Text('Criar Projeto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _criarProjeto() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

      final userId = userProvider.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: usuário não encontrado')),
        );
        return;
      }

      final id = await projectProvider.createProjeto(
        nome: _nomeController.text,
        grupoBiologico: _grupoBiologico!,
        campanha: _campanhaController.text,
        periodo: _periodo!,
        municipio: _municipioController.text,
        usuarioId: userId,
      );

      if (id != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Projeto criado com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar projeto')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _campanhaController.dispose();
    _municipioController.dispose();
    super.dispose();
  }
}