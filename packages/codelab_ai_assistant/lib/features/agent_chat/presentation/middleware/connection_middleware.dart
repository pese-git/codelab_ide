// Middleware для управления WebSocket подключением
import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/connect.dart';
import '../../domain/usecases/receive_messages.dart';

/// Middleware для управления WebSocket подключением
///
/// Ответственности:
/// - Подключение к WebSocket
/// - Отключение от WebSocket
/// - Подписка на поток сообщений
/// - Обработка ошибок подключения
class ConnectionMiddleware {
  final ConnectUseCase _connect;
  final ReceiveMessagesUseCase _receiveMessages;
  final Logger _logger;

  StreamSubscription<Either<Failure, Message>>? _messageSubscription;
  bool _isConnected = false;

  ConnectionMiddleware({
    required ConnectUseCase connect,
    required ReceiveMessagesUseCase receiveMessages,
    required Logger logger,
  })  : _connect = connect,
        _receiveMessages = receiveMessages,
        _logger = logger;

  /// Текущий статус подключения
  bool get isConnected => _isConnected;

  /// Подключиться к WebSocket и подписаться на сообщения
  ///
  /// Возвращает Either<Failure, Unit> для обработки ошибок
  /// Callback onMessage вызывается для каждого полученного сообщения
  /// Callback onError вызывается при ошибках в потоке сообщений
  Future<Either<Failure, Unit>> connect({
    required String sessionId,
    required void Function(Message message) onMessage,
    required void Function(Failure failure) onError,
  }) async {
    _logger.d('[ConnectionMiddleware] 🔌 Connecting to session: $sessionId');

    // Подключаемся к WebSocket через use case
    final connectResult = await _connect(
      ConnectParams(sessionId: sessionId),
    );

    return connectResult.fold(
      (failure) {
        _logger.e('[ConnectionMiddleware] ❌ Failed to connect: ${failure.message}');
        _isConnected = false;
        return left(failure);
      },
      (_) {
        _logger.i('[ConnectionMiddleware] ✅ Connected to WebSocket: $sessionId');
        _isConnected = true;

        // Подписываемся на поток сообщений
        _messageSubscription?.cancel();
        _messageSubscription = _receiveMessages(const NoParams()).listen(
          (either) {
            either.fold(
              (failure) {
                _logger.e('[ConnectionMiddleware] ❌ Message stream error: ${failure.message}');
                onError(failure);
              },
              (message) {
                _logger.d('[ConnectionMiddleware] 📨 Message received: ${message.role}');
                onMessage(message);
              },
            );
          },
          onError: (error) {
            _logger.e('[ConnectionMiddleware] ❌ Stream error: $error');
            onError(Failure.unknown(error.toString()));
          },
        );

        return right(unit);
      },
    );
  }

  /// Отключиться от WebSocket
  ///
  /// Отменяет подписку на сообщения и сбрасывает состояние
  Future<void> disconnect() async {
    _logger.d('[ConnectionMiddleware] 🔌 Disconnecting from chat');
    
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    _isConnected = false;

    _logger.i('[ConnectionMiddleware] ✅ Disconnected from chat');
  }

  /// Очистить ресурсы при закрытии
  Future<void> dispose() async {
    _logger.d('[ConnectionMiddleware] 🔒 Disposing connection middleware');
    await disconnect();
  }
}
