// DTO модель для настроек сервера (Data слой)
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/server_settings.dart';

part 'server_settings_model.freezed.dart';
part 'server_settings_model.g.dart';

/// DTO модель для сериализации/десериализации настроек сервера
///
/// Используется в data слое для работы с JSON и локальным хранилищем.
/// Конвертируется в domain entity через метод toEntity().
@freezed
abstract class ServerSettingsModel with _$ServerSettingsModel {
  const factory ServerSettingsModel({
    /// Базовый URL сервера
    // ignore: invalid_annotation_target
    @JsonKey(name: 'base_url') required String baseUrl,
  }) = _ServerSettingsModel;

  const ServerSettingsModel._();

  /// Создает модель из JSON
  factory ServerSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$ServerSettingsModelFromJson(json);

  /// Конвертирует DTO модель в domain entity
  ServerSettings toEntity() {
    return ServerSettings(baseUrl: baseUrl);
  }

  /// Создает DTO модель из domain entity
  factory ServerSettingsModel.fromEntity(ServerSettings settings) {
    return ServerSettingsModel(baseUrl: settings.baseUrl);
  }
}
