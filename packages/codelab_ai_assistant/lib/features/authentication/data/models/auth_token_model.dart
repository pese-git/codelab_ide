// DTO модель для токена авторизации (Data слой)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/entities/auth_token.dart';

part 'auth_token_model.freezed.dart';
part 'auth_token_model.g.dart';

/// DTO модель для сериализации/десериализации токена авторизации
///
/// Используется в data слое для работы с JSON API и локальным хранилищем.
/// Конвертируется в domain entity через метод toEntity().
@freezed
abstract class AuthTokenModel with _$AuthTokenModel {
  const factory AuthTokenModel({
    /// Access токен
    // ignore: invalid_annotation_target
    @JsonKey(name: 'access_token') required String accessToken,

    /// Refresh токен
    // ignore: invalid_annotation_target
    @JsonKey(name: 'refresh_token') required String refreshToken,

    /// Тип токена
    // ignore: invalid_annotation_target
    @JsonKey(name: 'token_type') required String tokenType,

    /// Время жизни в секундах
    // ignore: invalid_annotation_target
    @JsonKey(name: 'expires_in') required int expiresIn,

    /// Опциональные scope
    String? scope,

    /// Время выдачи токена (ISO 8601)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'issued_at') DateTime? issuedAt,
  }) = _AuthTokenModel;

  const AuthTokenModel._();

  /// Создает модель из JSON
  factory AuthTokenModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenModelFromJson(json);

  /// Конвертирует DTO модель в domain entity
  ///
  /// Преобразует nullable поля в Option<T> для функционального стиля
  AuthToken toEntity() {
    return AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      scope: scope != null ? some(scope!) : none(),
      issuedAt: issuedAt ?? DateTime.now(),
    );
  }

  /// Создает DTO модель из domain entity
  ///
  /// Преобразует Option<T> в nullable поля для JSON сериализации
  factory AuthTokenModel.fromEntity(AuthToken token) {
    return AuthTokenModel(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      tokenType: token.tokenType,
      expiresIn: token.expiresIn,
      scope: token.scope.toNullable(),
      issuedAt: token.issuedAt,
    );
  }
}

/// DTO модель для запроса токена с паролем
@freezed
abstract class PasswordGrantRequest with _$PasswordGrantRequest {
  const factory PasswordGrantRequest({
    /// Тип grant (всегда "password")
    // ignore: invalid_annotation_target
    @JsonKey(name: 'grant_type') @Default('password') String grantType,

    /// Имя пользователя
    required String username,

    /// Пароль
    required String password,

    /// ID клиента
    // ignore: invalid_annotation_target
    @JsonKey(name: 'client_id') required String clientId,

    /// Опциональные scope
    String? scope,
  }) = _PasswordGrantRequest;

  const PasswordGrantRequest._();

  /// Создает модель из JSON
  factory PasswordGrantRequest.fromJson(Map<String, dynamic> json) =>
      _$PasswordGrantRequestFromJson(json);

  /// Создает запрос из domain параметров
  factory PasswordGrantRequest.fromParams(PasswordGrantParams params) {
    return PasswordGrantRequest(
      username: params.username,
      password: params.password,
      clientId: params.clientId,
      scope: params.scope?.toNullable(),
    );
  }

  /// Конвертирует в form data для отправки
  Map<String, String> toFormData() {
    final data = <String, String>{
      'grant_type': grantType,
      'username': username,
      'password': password,
      'client_id': clientId,
    };
    if (scope != null) {
      data['scope'] = scope!;
    }
    return data;
  }
}

/// DTO модель для запроса обновления токена
@freezed
abstract class RefreshTokenRequest with _$RefreshTokenRequest {
  const factory RefreshTokenRequest({
    /// Тип grant (всегда "refresh_token")
    // ignore: invalid_annotation_target
    @JsonKey(name: 'grant_type') @Default('refresh_token') String grantType,

    /// Refresh токен
    // ignore: invalid_annotation_target
    @JsonKey(name: 'refresh_token') required String refreshToken,

    /// ID клиента
    // ignore: invalid_annotation_target
    @JsonKey(name: 'client_id') required String clientId,
  }) = _RefreshTokenRequest;

  const RefreshTokenRequest._();

  /// Создает модель из JSON
  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);

  /// Создает запрос из domain параметров
  factory RefreshTokenRequest.fromParams(RefreshTokenParams params) {
    return RefreshTokenRequest(
      refreshToken: params.refreshToken,
      clientId: params.clientId,
    );
  }

  /// Конвертирует в form data для отправки
  Map<String, String> toFormData() {
    return {
      'grant_type': grantType,
      'refresh_token': refreshToken,
      'client_id': clientId,
    };
  }
}
