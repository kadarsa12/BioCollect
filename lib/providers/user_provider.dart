import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Carregar usuário existente
  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await DatabaseHelper.instance.getUser();
    } catch (e) {
      print('Erro ao carregar usuário: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Criar novo usuário
  Future<void> createUser(String nome) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = User(
        nome: nome,
        dataCriacao: DateTime.now(),
      );

      final id = await DatabaseHelper.instance.insertUser(user);
      _currentUser = User(
        id: id,
        nome: nome,
        dataCriacao: user.dataCriacao,
      );
    } catch (e) {
      print('Erro ao criar usuário: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Limpar usuário (para logout futuro)
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}