// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_token_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthTokenModel _$AuthTokenModelFromJson(Map<String, dynamic> json) =>
    _AuthTokenModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      scope: json['scope'] as String?,
      issuedAt: json['issued_at'] == null
          ? null
          : DateTime.parse(json['issued_at'] as String),
    );

Map<String, dynamic> _$AuthTokenModelToJson(_AuthTokenModel instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
      'scope': instance.scope,
      'issued_at': instance.issuedAt?.toIso8601String(),
    };

_PasswordGrantRequest _$PasswordGrantRequestFromJson(
  Map<String, dynamic> json,
) => _PasswordGrantRequest(
  grantType: json['grant_type'] as String? ?? 'password',
  username: json['username'] as String,
  password: json['password'] as String,
  clientId: json['client_id'] as String,
  scope: json['scope'] as String?,
);

Map<String, dynamic> _$PasswordGrantRequestToJson(
  _PasswordGrantRequest instance,
) => <String, dynamic>{
  'grant_type': instance.grantType,
  'username': instance.username,
  'password': instance.password,
  'client_id': instance.clientId,
  'scope': instance.scope,
};

_RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    _RefreshTokenRequest(
      grantType: json['grant_type'] as String? ?? 'refresh_token',
      refreshToken: json['refresh_token'] as String,
      clientId: json['client_id'] as String,
    );

Map<String, dynamic> _$RefreshTokenRequestToJson(
  _RefreshTokenRequest instance,
) => <String, dynamic>{
  'grant_type': instance.grantType,
  'refresh_token': instance.refreshToken,
  'client_id': instance.clientId,
};
