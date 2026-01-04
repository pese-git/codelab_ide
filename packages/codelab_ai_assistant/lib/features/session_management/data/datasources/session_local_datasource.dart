// Local data source для кеширования сессий
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:convert';
import '../../../../core/error/exceptions.dart';
import '../models/session_model.dart';

/// Интерфейс для локального источника данных сессий
abstract class SessionLocalDataSource {
  /// Кеширует сессию локально
  Future<Unit> cacheSession(SessionModel session);
  
  /// Получает последнюю кешированную сессию
  Future<Option<SessionModel>> getLastSession();
  
  /// Очищает кеш сессий
  Future<Unit> clearCache();
  
  /// Кеширует список сессий
  Future<Unit> cacheSessionList(List<SessionModel> sessions);
  
  /// Получает кешированный список сессий
  Future<Option<List<SessionModel>>> getCachedSessionList();
  
  /// Проверяет, устарел ли кеш (старше 1 часа)
  Future<bool> isCacheStale();
}

/// Реализация локального источника данных через SharedPreferences
class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  final SharedPreferences _prefs;
  
  static const String _lastSessionKey = 'last_session';
  static const String _sessionListKey = 'session_list';
  static const String _lastSyncKey = 'last_sync_timestamp';
  
  SessionLocalDataSourceImpl(this._prefs);
  
  @override
  Future<Unit> cacheSession(SessionModel session) async {
    try {
      final jsonString = jsonEncode(session.toJson());
      await _prefs.setString(_lastSessionKey, jsonString);
      await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      return unit;
    } catch (e) {
      throw CacheException('Failed to cache session: $e', e);
    }
  }
  
  @override
  Future<Option<SessionModel>> getLastSession() async {
    try {
      final jsonString = _prefs.getString(_lastSessionKey);
      return Option.fromNullable(jsonString).flatMap((str) {
        try {
          final json = jsonDecode(str) as Map<String, dynamic>;
          return some(SessionModel.fromJson(json));
        } catch (e) {
          throw CacheException('Invalid JSON in cache', e);
        }
      });
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to get cached session: $e', e);
    }
  }
  
  @override
  Future<Unit> clearCache() async {
    try {
      await Future.wait([
        _prefs.remove(_lastSessionKey),
        _prefs.remove(_sessionListKey),
        _prefs.remove(_lastSyncKey),
      ]);
      return unit;
    } catch (e) {
      throw CacheException('Failed to clear cache: $e', e);
    }
  }
  
  @override
  Future<Unit> cacheSessionList(List<SessionModel> sessions) async {
    try {
      final jsonList = sessions.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_sessionListKey, jsonString);
      await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      return unit;
    } catch (e) {
      throw CacheException('Failed to cache session list: $e', e);
    }
  }
  
  @override
  Future<Option<List<SessionModel>>> getCachedSessionList() async {
    try {
      final jsonString = _prefs.getString(_sessionListKey);
      return Option.fromNullable(jsonString).flatMap((str) {
        try {
          final jsonList = jsonDecode(str) as List<dynamic>;
          final sessions = jsonList
              .map((json) => SessionModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return some(sessions);
        } catch (e) {
          throw CacheException('Invalid JSON in cache', e);
        }
      });
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to get cached session list: $e', e);
    }
  }
  
  @override
  Future<bool> isCacheStale() async {
    try {
      final timestamp = _prefs.getInt(_lastSyncKey);
      if (timestamp == null) return true;
      
      final lastSync = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(lastSync);
      
      return difference.inHours >= 1;
    } catch (e) {
      return true;
    }
  }
}
