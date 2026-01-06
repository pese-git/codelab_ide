// BlocObserver для трейсинга состояний всех Bloc'ов
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

/// Глобальный наблюдатель за всеми Bloc'ами в приложении
/// 
/// Логирует все события, переходы состояний и ошибки для отладки
class AppBlocObserver extends BlocObserver {
  final Logger _logger;

  AppBlocObserver({required Logger logger}) : _logger = logger;

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _logger.d('🔷 [BlocObserver] onCreate: ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.d('📥 [BlocObserver] onEvent: ${bloc.runtimeType}\n  Event: $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _logger.i(
      '🔄 [BlocObserver] onChange: ${bloc.runtimeType}\n'
      '  Current: ${_formatState(change.currentState)}\n'
      '  Next: ${_formatState(change.nextState)}',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _logger.i(
      '🔀 [BlocObserver] onTransition: ${bloc.runtimeType}\n'
      '  Event: ${transition.event}\n'
      '  Current: ${_formatState(transition.currentState)}\n'
      '  Next: ${_formatState(transition.nextState)}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _logger.e(
      '❌ [BlocObserver] onError: ${bloc.runtimeType}\n'
      '  Error: $error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _logger.d('🔶 [BlocObserver] onClose: ${bloc.runtimeType}');
  }

  /// Форматирует состояние для более читаемого вывода
  String _formatState(Object? state) {
    if (state == null) return 'null';
    
    final stateStr = state.toString();
    // Ограничиваем длину для больших состояний
    if (stateStr.length > 200) {
      return '${stateStr.substring(0, 200)}...';
    }
    return stateStr;
  }
}
