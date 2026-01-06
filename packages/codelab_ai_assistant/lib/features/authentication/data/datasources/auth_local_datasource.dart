// Local data source для хранения токенов
import 'dart:async';
import 'dart:convert';
import 'package:cherrypick/cherrypick.dart';
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

  /// Stream для уведомлений об истечении токена
  Stream<void> get tokenExpiredStream;

  /// Уведомить об истечении токена
  void notifyTokenExpired();

  /// Освободить ресурсы
  void dispose();
}

/// Реализация локального источника данных авторизации
class AuthLocalDataSourceImpl implements AuthLocalDataSource, Disposable {
  static const String _tokenKey = 'auth_token';

  final SharedPreferences _prefs;
  final _tokenExpiredController = StreamController<void>.broadcast();

  AuthLocalDataSourceImpl(this._prefs);

  @override
  Stream<void> get tokenExpiredStream => _tokenExpiredController.stream;

  @override
  void notifyTokenExpired() {
    if (!_tokenExpiredController.isClosed) {
      _tokenExpiredController.add(null);
    }
  }

  @override
  void dispose() {
    _tokenExpiredController.close();
  }

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
    // Уведомляем об истечении токена при его удалении
    notifyTokenExpired();
  }

  @override
  Future<bool> hasToken() async {
    return _prefs.containsKey(_tokenKey);
  }
}
