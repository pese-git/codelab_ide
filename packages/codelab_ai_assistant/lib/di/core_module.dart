// Core Module - базовые зависимости (Logger, BlocObserver)
import 'package:cherrypick/cherrypick.dart';
import 'package:logger/logger.dart';

import '../core/bloc/app_bloc_observer.dart';

/// Модуль для регистрации базовых зависимостей
///
/// Включает:
/// - Logger для логирования
/// - AppBlocObserver для трейсинга BLoC событий
class CoreModule extends Module {
  @override
  void builder(Scope currentScope) {
    // ========================================================================
    // Logger
    // ========================================================================

    bind<Logger>()
        .toProvide(
          () => Logger(
            printer: PrettyPrinter(
              methodCount: 0,
              errorMethodCount: 5,
              lineLength: 80,
              colors: true,
              printEmojis: true,
            ),
          ),
        )
        .singleton();

    // ========================================================================
    // BlocObserver
    // ========================================================================

    bind<AppBlocObserver>()
        .toProvide(
          () => AppBlocObserver(logger: currentScope.resolve<Logger>()),
        )
        .singleton();
  }
}
