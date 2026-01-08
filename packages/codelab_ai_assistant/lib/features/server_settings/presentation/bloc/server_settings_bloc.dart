// BLoC для управления состоянием настроек сервера
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/server_settings.dart';
import '../../domain/usecases/load_settings.dart';
import '../../domain/usecases/save_settings.dart';
import '../../domain/usecases/test_connection.dart';
import '../../domain/usecases/clear_settings.dart';

part 'server_settings_bloc.freezed.dart';

/// События настроек сервера
@freezed
class ServerSettingsEvent with _$ServerSettingsEvent {
  /// Загрузить настройки
  const factory ServerSettingsEvent.loadSettings() = LoadSettings;

  /// Сохранить настройки
  const factory ServerSettingsEvent.saveSettings({required String baseUrl}) =
      SaveSettings;

  /// Тестировать соединение
  const factory ServerSettingsEvent.testConnection({required String baseUrl}) =
      TestConnection;

  /// Очистить настройки
  const factory ServerSettingsEvent.clearSettings() = ClearSettings;
}

/// Состояния настроек сервера
@freezed
class ServerSettingsState with _$ServerSettingsState {
  /// Начальное состояние
  const factory ServerSettingsState.initial() = Initial;

  /// Загрузка настроек
  const factory ServerSettingsState.loading() = Loading;

  /// Настройки загружены
  const factory ServerSettingsState.loaded({required ServerSettings settings}) =
      Loaded;

  /// Настройки не найдены (первый запуск)
  const factory ServerSettingsState.notConfigured() = NotConfigured;

  /// Сохранение настроек
  const factory ServerSettingsState.saving() = Saving;

  /// Настройки сохранены
  const factory ServerSettingsState.saved({required ServerSettings settings}) =
      Saved;

  /// Тестирование соединения
  const factory ServerSettingsState.testing() = Testing;

  /// Соединение успешно
  const factory ServerSettingsState.testSuccess() = TestSuccess;

  /// Соединение не удалось
  const factory ServerSettingsState.testFailure({required String message}) =
      TestFailure;

  /// Ошибка
  const factory ServerSettingsState.error({required String message}) =
      ServerSettingsError;
}

/// BLoC для управления настройками сервера
class ServerSettingsBloc
    extends Bloc<ServerSettingsEvent, ServerSettingsState> {
  final LoadSettingsUseCase _loadSettings;
  final SaveSettingsUseCase _saveSettings;
  final TestConnectionUseCase _testConnection;
  final ClearSettingsUseCase _clearSettings;
  final Logger _logger;

  ServerSettingsBloc({
    required LoadSettingsUseCase loadSettings,
    required SaveSettingsUseCase saveSettings,
    required TestConnectionUseCase testConnection,
    required ClearSettingsUseCase clearSettings,
    required Logger logger,
  }) : _loadSettings = loadSettings,
       _saveSettings = saveSettings,
       _testConnection = testConnection,
       _clearSettings = clearSettings,
       _logger = logger,
       super(const ServerSettingsState.initial()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveSettings>(_onSaveSettings);
    on<TestConnection>(_onTestConnection);
    on<ClearSettings>(_onClearSettings);

    // Автоматически загружаем настройки при создании блока
    _logger.d('[ServerSettingsBloc] 🔄 Auto-loading settings on bloc creation');
    add(const ServerSettingsEvent.loadSettings());
  }

  /// Загрузить настройки
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<ServerSettingsState> emit,
  ) async {
    _logger.d('[ServerSettingsBloc] 📥 Loading settings...');
    emit(const ServerSettingsState.loading());

    final result = await _loadSettings();

    result.fold(
      (failure) {
        _logger.e(
          '[ServerSettingsBloc] ❌ Failed to load settings: ${failure.message}',
        );
        emit(ServerSettingsState.error(message: failure.message));
      },
      (settingsOption) {
        settingsOption.fold(
          () {
            _logger.d('[ServerSettingsBloc] 🔓 No settings found');
            emit(const ServerSettingsState.notConfigured());
          },
          (settings) {
            _logger.i(
              '[ServerSettingsBloc] ✅ Settings loaded: ${settings.baseUrl}',
            );
            emit(ServerSettingsState.loaded(settings: settings));
          },
        );
      },
    );
  }

  /// Сохранить настройки
  Future<void> _onSaveSettings(
    SaveSettings event,
    Emitter<ServerSettingsState> emit,
  ) async {
    _logger.d('[ServerSettingsBloc] 💾 Saving settings: ${event.baseUrl}');
    emit(const ServerSettingsState.saving());

    // Сначала тестируем соединение
    final testResult = await _testConnection(
      TestConnectionParams(baseUrl: event.baseUrl),
    );

    await testResult.fold(
      (failure) async {
        _logger.e(
          '[ServerSettingsBloc] ❌ Connection test failed: ${failure.message}',
        );
        emit(ServerSettingsState.testFailure(message: failure.message));
      },
      (isConnected) async {
        if (!isConnected) {
          _logger.w('[ServerSettingsBloc] ⚠️ Server is not reachable');
          emit(
            const ServerSettingsState.testFailure(
              message: 'Сервер недоступен. Проверьте URL и попробуйте снова.',
            ),
          );
          return;
        }

        // Если соединение успешно, сохраняем настройки
        final settings = ServerSettings(baseUrl: event.baseUrl);
        final saveResult = await _saveSettings(
          SaveSettingsParams(settings: settings),
        );

        saveResult.fold(
          (failure) {
            _logger.e(
              '[ServerSettingsBloc] ❌ Failed to save settings: ${failure.message}',
            );
            emit(ServerSettingsState.error(message: failure.message));
          },
          (_) {
            _logger.i('[ServerSettingsBloc] ✅ Settings saved successfully');
            emit(ServerSettingsState.saved(settings: settings));
          },
        );
      },
    );
  }

  /// Тестировать соединение
  Future<void> _onTestConnection(
    TestConnection event,
    Emitter<ServerSettingsState> emit,
  ) async {
    _logger.d(
      '[ServerSettingsBloc] 🔍 Testing connection to: ${event.baseUrl}',
    );
    emit(const ServerSettingsState.testing());

    final result = await _testConnection(
      TestConnectionParams(baseUrl: event.baseUrl),
    );

    result.fold(
      (failure) {
        _logger.e(
          '[ServerSettingsBloc] ❌ Connection test failed: ${failure.message}',
        );
        emit(ServerSettingsState.testFailure(message: failure.message));
      },
      (isConnected) {
        if (isConnected) {
          _logger.i('[ServerSettingsBloc] ✅ Connection test successful');
          emit(const ServerSettingsState.testSuccess());
        } else {
          _logger.w('[ServerSettingsBloc] ⚠️ Connection test failed');
          emit(
            const ServerSettingsState.testFailure(message: 'Сервер недоступен'),
          );
        }
      },
    );
  }

  /// Очистить настройки
  Future<void> _onClearSettings(
    ClearSettings event,
    Emitter<ServerSettingsState> emit,
  ) async {
    _logger.d('[ServerSettingsBloc] 🗑️ Clearing settings...');
    
    final result = await _clearSettings();
    
    result.fold(
      (failure) {
        _logger.e('[ServerSettingsBloc] ❌ Failed to clear settings: ${failure.message}');
        emit(ServerSettingsState.error(message: failure.message));
      },
      (_) {
        _logger.i('[ServerSettingsBloc] ✅ Settings cleared successfully');
        emit(const ServerSettingsState.notConfigured());
      },
    );
  }
}
