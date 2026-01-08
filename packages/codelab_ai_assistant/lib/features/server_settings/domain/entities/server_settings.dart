// Domain entity для настроек сервера
import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_settings.freezed.dart';

/// Domain entity представляющая настройки сервера AI Assistant
///
/// Это чистая бизнес-модель, не зависящая от источника данных
@freezed
abstract class ServerSettings with _$ServerSettings {
  const factory ServerSettings({
    /// Базовый URL сервера (например, http://localhost:8000)
    required String baseUrl,
  }) = _ServerSettings;

  const ServerSettings._();

  /// Проверяет, настроен ли сервер
  bool get isConfigured => baseUrl.isNotEmpty;

  /// Возвращает URL для API запросов
  String get apiUrl => '$baseUrl/api/v1';

  /// Возвращает URL для health check
  String get healthUrl => '$baseUrl/health';
}
