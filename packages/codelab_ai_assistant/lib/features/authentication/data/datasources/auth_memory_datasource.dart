// Memory data source для хранения токенов в памяти (без персистентности)
import 'dart:async';
import 'package:cherrypick/cherrypick.dart';
import '../models/auth_token_model.dart';
import 'auth_local_datasource.dart';

/// Реализация источника данных авторизации с хранением в памяти
/// 
/// Используется когда SharedPreferences недоступен.
/// Токены хранятся только в памяти и теряются при перезапуске приложения.
class AuthMemoryDataSourceImpl implements AuthLocalDataSource, Disposable {
  AuthTokenModel? _token;
  final _tokenExpiredController = StreamController<void>.broadcast();

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
    _token = token;
  }

  @override
  Future<AuthTokenModel?> getToken() async {
    return _token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
    // Уведомляем об истечении токена при его удалении
    notifyTokenExpired();
  }

  @override
  Future<bool> hasToken() async {
    return _token != null;
  }
}
