import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'main_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final _nomeController = TextEditingController();
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animações
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser();

    setState(() {
      _isLoading = false;
    });

    // Iniciar animações
    _animationController.forward();

    // Se já tem usuário, aguardar animação e ir para home
    if (userProvider.currentUser != null) {
      await Future.delayed(Duration(milliseconds: 1000));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    }
  }

  Future<void> _salvarNome() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, digite seu nome'),
          backgroundColor: Color(0xFF8D6E63),
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.createUser(_nomeController.text.trim());

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEFEBE9), // Brown 50
                Color(0xFFD7CCC8), // Brown 100
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF8D6E63),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF8D6E63).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Carregando...',
                  style: TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFEBE9), // Brown 50
              Color(0xFFD7CCC8), // Brown 100
              Color(0xFFF5F5F5), // Grey 100
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(flex: 2),

                // Logo animado
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Color(0xFF8D6E63),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF8D6E63).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 0,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.eco,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32),

                // Título
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'BioCollect',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sua lista de espécie mais acessível!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8D6E63),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 48),

                // Card do formulário
                SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF8D6E63).withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem-vindo!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Digite seu nome para começar',
                          style: TextStyle(
                            color: Color(0xFF8D6E63),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 20),

                        // Campo de nome
                        TextField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            labelText: 'Seu nome',
                            hintText: 'Ex: João Silva',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Color(0xFF8D6E63),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFF8D6E63),
                                width: 2,
                              ),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),

                        SizedBox(height: 24),

                        // Botão continuar
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _salvarNome,
                            child: Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF8D6E63),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Spacer(flex: 3),

                // Footer
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Versão 1.0.0',
                    style: TextStyle(
                      color: Color(0xFF8D6E63).withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nomeController.dispose();
    super.dispose();
  }
}