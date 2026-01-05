// Local data source для хранения токенов
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_token_model.dart';

/// Интерфейс для локального источника данных авторизации
abstract class AuthLocalDataSource {
  /// Сохранить токен
  Future<void> saveToken(AuthTokenModel token);

  /// Получить сохраненный токен
  Future<AuthTokenModel?> getToken();

  /// Удалить токен
  Future<void> clearToken();

  /// Проверить наличие токена
  Future<bool> hasToken();
}

/// Реализация локального источника данных авторизации
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _tokenKey = 'auth_token';

  final SharedPreferences _prefs;

  AuthLocalDataSourceImpl(this._prefs);

  @override
  Future<void> saveToken(AuthTokenModel token) async {
    final jsonString = jsonEncode(token.toJson());
    await _prefs.setString(_tokenKey, jsonString);
  }

  @override
  Future<AuthTokenModel?> getToken() async {
    final jsonString = _prefs.getString(_tokenKey);
    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AuthTokenModel.fromJson(json);
    } catch (e) {
      // Если не удалось распарсить, удаляем поврежденные данные
      await clearToken();
      return null;
    }
  }

  @override
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  @override
  Future<bool> hasToken() async {
    return _prefs.containsKey(_tokenKey);
  }
}
