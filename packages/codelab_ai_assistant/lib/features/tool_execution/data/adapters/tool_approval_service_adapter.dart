// Адаптер для интеграции с существующим ToolApprovalService
import 'dart:async';
import 'package:fpdart/fpdart.dart';
import '../../domain/entities/tool_call.dart';
import '../../domain/entities/tool_approval.dart';
import '../models/tool_models.dart' as legacy_models;
import '../repositories/tool_repository_impl.dart';
import '../../../../src/services/tool_approval_service.dart' as legacy;

/// Адаптер для интеграции нового ToolApprovalService с существующим
/// 
/// Конвертирует между новыми domain entities и старыми моделями
class ToolApprovalServiceAdapter implements ToolApprovalService {
  final legacy.ToolApprovalService _legacyService;
  
  ToolApprovalServiceAdapter(this._legacyService);
  
  @override
  Future<ApprovalDecision> requestApproval(ToolCall toolCall) async {
    // Конвертируем новый ToolCall в старый формат
    final legacyToolCall = legacy_models.ToolCall(
      callId: toolCall.id,
      toolName: toolCall.toolName,
      arguments: toolCall.arguments,
      requiresConfirmation: toolCall.requiresApproval,
    );
    
    // Запрашиваем подтверждение через старый сервис
    final legacyResult = await _legacyService.requestApproval(legacyToolCall);
    
    // Конвертируем результат в новый формат
    switch (legacyResult) {
      case legacy.ToolApprovalResult.approved:
        return const ApprovalDecision.approved();
      
      case legacy.ToolApprovalResult.rejected:
        return ApprovalDecision.rejected(reason: none());
      
      case legacy.ToolApprovalResult.cancelled:
        return const ApprovalDecision.cancelled();
    }
  }
}

/// Factory для создания ToolApprovalService
class ToolApprovalServiceFactory {
  /// Создает адаптер к существующему сервису
  static ToolApprovalService createAdapter(legacy.ToolApprovalService legacyService) {
    return ToolApprovalServiceAdapter(legacyService);
  }
  
  /// Создает mock сервис для тестирования
  static ToolApprovalService createMock() {
    return _MockToolApprovalService();
  }
}

/// Mock реализация для тестирования
class _MockToolApprovalService implements ToolApprovalService {
  @override
  Future<ApprovalDecision> requestApproval(ToolCall toolCall) async {
    // Автоматически одобряем все операции в mock режиме
    return const ApprovalDecision.approved();
  }
}
