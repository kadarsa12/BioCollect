import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nomeController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  // Verificar se já existe usuário salvo
  Future<void> _checkExistingUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser();

    setState(() {
      _isLoading = false;
    });

    // Se já tem usuário, vai direto para home
    if (userProvider.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    }
  }

  // Salvar nome do usuário
  Future<void> _salvarNome() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, digite seu nome')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.createUser(_nomeController.text.trim());

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text('Carregando...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Ícone
            Icon(
              Icons.nature,
              size: 100,
              color: Colors.green,
            ),
            SizedBox(height: 20),

            // Título
            Text(
              'BioCollect',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 10),

            // Subtítulo
            Text(
              'Coleta biológica em campo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 50),

            // Campo de nome
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Qual seu nome?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 20),

            // Botão continuar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _salvarNome,
                child: Text('Continuar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }
}