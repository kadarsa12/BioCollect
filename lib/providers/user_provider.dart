import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _token; // 🔐 token JWT

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get token => _token;
  bool get isLoggedIn => _token != null;

  // ========= Carregar usuário local =========
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

  // ========= Criar usuário local (modo offline) =========
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

  // ========= Login remoto (API) =========
  Future<bool> login(String email, String senha) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await ApiService.login(email, senha);

      if (token != null) {
        _token = token;
        ApiService.setToken(token); // ✅ aplica o token globalmente

        // opcional: salvar usuário local (pode vir do servidor futuramente)
        _currentUser = User(
          nome: email.split('@').first,
          dataCriacao: DateTime.now(),
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Erro no login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========= Logout =========
  void logout() {
    _token = null;
    ApiService.clearToken(); // 🔒 remove token global
    _currentUser = null;
    notifyListeners();
  }

  // ========= Utilitário para definir token direto =========
  void setToken(String token) {
    _token = token;
    ApiService.setToken(token);
    notifyListeners();
  }
}
