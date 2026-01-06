// Настройка и инициализация Bloc Observer
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'app_bloc_observer.dart';

/// Инициализирует глобальный BlocObserver для трейсинга всех Bloc'ов
/// 
/// Должна быть вызвана один раз при запуске приложения, до создания любых Bloc'ов
/// 
/// Пример использования:
/// ```dart
/// void main() {
///   final logger = Logger();
///   initializeBlocObserver(logger);
///   runApp(MyApp());
/// }
/// ```
void initializeBlocObserver(Logger logger) {
  Bloc.observer = AppBlocObserver(logger: logger);
  logger.i('🔷 [BlocSetup] BlocObserver initialized successfully');
}
