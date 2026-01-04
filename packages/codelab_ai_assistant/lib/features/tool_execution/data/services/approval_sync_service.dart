// Сервис синхронизации запросов на подтверждение с сервером
import 'package:logger/logger.dart';
import '../../../agent_chat/data/datasources/gateway_api.dart';
import '../../domain/entities/tool_approval.dart';
import '../../domain/entities/tool_call.dart';
import '../models/pending_approvals_response.dart';

/// Сервис для синхронизации запросов на подтверждение с сервером
///
/// Используется для восстановления ожидающих подтверждений после
/// перезапуска или переустановки IDE.
class ApprovalSyncService {
  final GatewayApi _api;
  final Logger _logger;

  ApprovalSyncService({required GatewayApi api, required Logger logger})
    : _api = api,
      _logger = logger;

  /// Получить все ожидающие подтверждения с сервера
  ///
  /// Загружает список ожидающих подтверждений из базы данных на сервере.
  /// Используется при восстановлении сессии после перезапуска IDE.
  ///
  /// Args:
  ///   sessionId: Идентификатор сессии
  ///
  /// Returns:
  ///   Список запросов на подтверждение
  Future<List<ToolApprovalRequest>> fetchPendingApprovals(
    String sessionId,
  ) async {
    try {
      _logger.i('Fetching pending approvals for session: $sessionId');

      final response = await _api.getPendingApprovals(sessionId);

      _logger.i(
        'Received ${response.pendingApprovals.length} pending approvals from server',
      );

      return response.pendingApprovals.map((approvalData) {
        return ToolApprovalRequest(
          requestId: approvalData.callId,
          toolCall: ToolCall(
            id: approvalData.callId,
            toolName: approvalData.toolName,
            arguments: approvalData.arguments,
            requiresApproval: true,
            createdAt: DateTime.parse(approvalData.createdAt),
          ),
          requestedAt: DateTime.parse(approvalData.createdAt),
        );
      }).toList();
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to fetch pending approvals: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Возвращаем пустой список вместо выброса исключения
      // чтобы не блокировать подключение к сессии
      return [];
    }
  }
}
