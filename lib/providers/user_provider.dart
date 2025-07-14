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
  Future<void> createUser(User user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await DatabaseHelper.instance.insertUser(user);
      _currentUser = User(
        id: id,
        name: user.name,
        userType: user.userType,
        organization: user.organization,
        title: user.title,
        specialization: user.specialization,
        email: user.email,
        avatar: user.avatar,
        createdAt: user.createdAt,
      );
    } catch (e) {
      print('Erro ao criar usuário: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    if (user.id == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await DatabaseHelper.instance.updateUser(user);
      _currentUser = user;
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
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