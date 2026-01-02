// Base use case interfaces
import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';
import '../utils/type_defs.dart';

/// Базовый интерфейс для всех Use Cases
/// 
/// Use Case инкапсулирует бизнес-логику приложения.
/// Каждый use case должен делать одну конкретную вещь.
/// 
/// [Type] - тип возвращаемого значения
/// [Params] - тип параметров
/// 
/// Пример:
/// ```dart
/// class SendMessageUseCase implements UseCase<Unit, SendMessageParams> {
///   final AgentRepository repository;
///   
///   SendMessageUseCase(this.repository);
///   
///   @override
///   FutureEither<Unit> call(SendMessageParams params) {
///     return repository.sendMessage(params.message);
///   }
/// }
/// ```
abstract class UseCase<Type, Params> {
  /// Выполняет use case с заданными параметрами
  /// 
  /// Возвращает [FutureEither] с [Failure] слева или результатом справа
  FutureEither<Type> call(Params params);
}

/// Use Case без параметров
/// 
/// Используется когда use case не требует входных данных
/// 
/// Пример:
/// ```dart
/// class GetCurrentUserUseCase implements NoParamsUseCase<User> {
///   final UserRepository repository;
///   
///   GetCurrentUserUseCase(this.repository);
///   
///   @override
///   FutureEither<User> call() {
///     return repository.getCurrentUser();
///   }
/// }
/// ```
abstract class NoParamsUseCase<Type> {
  /// Выполняет use case без параметров
  FutureEither<Type> call();
}

/// Use Case возвращающий Stream
/// 
/// Используется для операций, которые возвращают поток данных
/// 
/// Пример:
/// ```dart
/// class ReceiveMessagesUseCase implements StreamUseCase<Message, NoParams> {
///   final AgentRepository repository;
///   
///   ReceiveMessagesUseCase(this.repository);
///   
///   @override
///   StreamEither<Message> call(NoParams params) {
///     return repository.receiveMessages();
///   }
/// }
/// ```
abstract class StreamUseCase<Type, Params> {
  /// Выполняет use case и возвращает поток результатов
  StreamEither<Type> call(Params params);
}

/// Use Case возвращающий синхронный результат
/// 
/// Используется для операций, которые не требуют асинхронности
/// 
/// Пример:
/// ```dart
/// class ValidateEmailUseCase implements SyncUseCase<bool, String> {
///   @override
///   SyncEither<bool> call(String email) {
///     if (email.contains('@')) {
///       return right(true);
///     }
///     return left(Failure.validation('Invalid email format'));
///   }
/// }
/// ```
abstract class SyncUseCase<Type, Params> {
  /// Выполняет use case синхронно
  SyncEither<Type> call(Params params);
}

/// Класс для use cases без параметров
/// 
/// Используется как placeholder когда use case не требует параметров
/// 
/// Пример:
/// ```dart
/// final result = await useCase(NoParams());
/// ```
class NoParams {
  const NoParams();
  
  @override
  bool operator ==(Object other) => other is NoParams;
  
  @override
  int get hashCode => 0;
}
