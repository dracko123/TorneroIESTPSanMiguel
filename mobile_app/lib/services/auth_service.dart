import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  bool get isMesaControl => _currentUser?.isMesaControl ?? false;
  bool get isLoading => _isLoading;
  String? getToken() => _currentUser?.token;

  static const String keyUserSession = 'user_session_json';

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(keyUserSession);
    if (jsonStr != null) {
      try {
        final map = json.decode(jsonStr);
        _currentUser = UserModel.fromJson(map, map['token'] ?? '');
        notifyListeners();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<bool> login(String usuario, String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService().login(usuario, pin);

      if (res['success'] == true) {
        final token = res['token']?.toString() ?? '';
        _currentUser = UserModel(
          idUsuario: res['id_usuario']?.toString() ?? '',
          nombre: res['nombre']?.toString() ?? '',
          usuario: res['usuario']?.toString() ?? '',
          rol: res['rol']?.toString().toUpperCase() ?? 'MESA_CONTROL',
          token: token,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyUserSession, json.encode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        throw Exception(res['error'] ?? 'Credenciales inválidas');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUserSession);
    notifyListeners();
  }
}
