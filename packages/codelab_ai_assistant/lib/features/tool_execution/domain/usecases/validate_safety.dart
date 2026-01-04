// Use case для валидации безопасности инструмента
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/tool_call.dart';
import '../repositories/tool_repository.dart';

/// Use case для валидации безопасности tool call
/// 
/// Проверяет, является ли операция безопасной для выполнения.
/// Используется перед выполнением инструмента.
class ValidateSafetyUseCase implements SyncUseCase<Unit, ValidateSafetyParams> {
  final ToolRepository _repository;

  ValidateSafetyUseCase(this._repository);

  @override
  SyncEither<Unit> call(ValidateSafetyParams params) {
    return _repository.validateSafety(params);
  }
}
