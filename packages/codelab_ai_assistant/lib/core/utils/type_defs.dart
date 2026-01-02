// Core type definitions using fpdart
import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';

/// Either для асинхронных операций с Failure слева и результатом справа
typedef FutureEither<T> = Future<Either<Failure, T>>;

/// Either для синхронных операций
typedef SyncEither<T> = Either<Failure, T>;

/// Stream с Either для обработки ошибок в потоках
typedef StreamEither<T> = Stream<Either<Failure, T>>;

/// Task для ленивых вычислений с Either
typedef FutureTask<T> = Task<Either<Failure, T>>;
