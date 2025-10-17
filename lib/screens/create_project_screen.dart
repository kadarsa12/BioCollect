import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/user_provider.dart';

class CreateProjectScreen extends StatefulWidget {
  @override
  _CreateProjectScreenState createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _municipioController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4),
      appBar: AppBar(
        title: Text('Novo Projeto'),
        backgroundColor: Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Card de informações
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF8D6E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF8D6E63).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF8D6E63),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Após criar o projeto, você poderá adicionar grupos de fauna e campanhas',
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Nome do Projeto
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Nome do Projeto',
                hintText: 'Ex: UHE Rio Verde',
                prefixIcon: Icon(Icons.folder, color: Color(0xFF8D6E63)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF8D6E63), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.words,
            ),

            SizedBox(height: 16),

            // Município
            TextFormField(
              controller: _municipioController,
              decoration: InputDecoration(
                labelText: 'Município',
                hintText: 'Ex: São Paulo',
                prefixIcon: Icon(Icons.location_city, color: Color(0xFF8D6E63)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF8D6E63), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.words,
            ),

            SizedBox(height: 32),

            // Botão Criar
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _criarProjeto,
                icon: _isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(Icons.check, size: 24),
                label: Text(
                  _isLoading ? 'Criando...' : 'Criar Projeto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8D6E63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            SizedBox(height: 16),

            // Texto de ajuda
            Center(
              child: Text(
                'Nenhum campo é obrigatório',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _criarProjeto() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);

      final userId = userProvider.currentUser?.id;

      final id = await projectProvider.createProjeto(
        nome: _nomeController.text.isEmpty ? null : _nomeController.text,
        municipio: _municipioController.text.isEmpty ? null : _municipioController.text,
        usuarioId: userId,
      );

      if (id != null && mounted) {
        Navigator.of(context).pop(true); // Retorna true indicando sucesso

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Projeto criado! Adicione grupos de fauna agora.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Erro ao criar projeto'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Erro ao criar projeto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _municipioController.dispose();
    super.dispose();
  }
}