import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../../agent_chat/data/datasources/agent_remote_datasource.dart';
import '../../../agent_chat/data/datasources/gateway_api.dart';
import '../../../agent_chat/data/models/message_model.dart';
import '../../../tool_execution/domain/entities/tool_call.dart';
import '../../../tool_execution/domain/entities/tool_approval.dart'
    as tool_approval;
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_response.dart';
import '../../domain/entities/approval_type.dart';
import '../../domain/entities/approval_decision.dart';
import 'approval_api_datasource.dart';

/// Реализация ApprovalApiDataSource через HTTP API и WebSocket
///
/// Использует:
/// - GatewayApi для HTTP запросов (getPendingApprovals)
/// - AgentRemoteDataSource для WebSocket коммуникации (sendDecision)
///
/// Переиспользует существующую инфраструктуру для совместимости.
class ApprovalApiDataSourceImpl implements ApprovalApiDataSource {
  final GatewayApi _gatewayApi;
  final AgentRemoteDataSource _remoteDataSource;
  final Logger _logger;

  ApprovalApiDataSourceImpl({
    required GatewayApi gatewayApi,
    required AgentRemoteDataSource remoteDataSource,
    required Logger logger,
  }) : _gatewayApi = gatewayApi,
       _remoteDataSource = remoteDataSource,
       _logger = logger;

  @override
  Future<List<ApprovalRequest>> getPendingApprovals(String sessionId) async {
    _logger.i('Fetching pending approvals for session: $sessionId');

    try {
      // Используем существующий API endpoint
      final response = await _gatewayApi.getPendingApprovals(sessionId);

      _logger.i(
        'Received ${response.pendingApprovals.length} pending approvals from server',
      );

      // Конвертируем существующую модель в unified ApprovalRequest
      return response.pendingApprovals.map((approvalData) {
        return ApprovalRequest(
          approvalRequestId: approvalData.callId,
          type: ApprovalType
              .tool, // Пока только tool approvals поддерживаются backend
          requestedAt: DateTime.parse(approvalData.createdAt),
          timeoutSeconds: 300, // Default timeout
          data: {
            'tool_name': approvalData.toolName,
            'tool_arguments': approvalData.arguments,
            'tool_id': approvalData.callId,
            'requires_approval': true,
            'created_at': approvalData.createdAt,
          },
        );
      }).toList();
    } on DioException catch (e, stackTrace) {
      // 404 - нормальная ситуация для новых сессий
      if (e.response?.statusCode == 404) {
        _logger.d('No pending approvals found for session: $sessionId (404)');
        return [];
      }

      _logger.e(
        'Failed to fetch pending approvals: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
      // Не блокируем подключение к сессии
      return [];
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error fetching pending approvals: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<void> sendApprovalDecision(ApprovalResponse response) async {
    _logger.i(
      'Sending approval decision: ${response.approvalRequestId} -> ${response.decision.toDecisionString()}',
    );

    try {
      // Конвертируем в WebSocket сообщение
      final message = _convertResponseToMessage(response);

      await _remoteDataSource.sendMessage(message);

      _logger.d('Approval decision sent successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to send approval decision: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Конвертирует ApprovalResponse в MessageModel для WebSocket
  MessageModel _convertResponseToMessage(ApprovalResponse response) {
    // Тип сообщения зависит от типа approval
    final messageType = response.type == ApprovalType.tool
        ? 'tool_result'
        : 'plan_decision';

    // Базовые метаданные
    final metadata = <String, dynamic>{
      'approval_request_id': response.approvalRequestId,
      'decision': response.decision.toDecisionString(),
      'responded_at': response.respondedAt.toIso8601String(),
      'decision_time_ms': response.decisionTimeMs,
    };

    // Добавляем специфичные данные для каждого типа решения
    response.decision.when(
      approved: () {
        metadata['approved'] = true;
      },
      rejected: (feedback) {
        metadata['approved'] = false;
        if (feedback != null) {
          feedback.fold(() => null, (f) => metadata['feedback'] = f);
        }
      },
      modified: (modifiedData, feedback) {
        metadata['approved'] = true;
        metadata['modified'] = true;
        metadata['modified_data'] = modifiedData;
        if (feedback.isNotEmpty) {
          metadata['feedback'] = feedback;
        }
      },
      cancelled: () {
        metadata['approved'] = false;
        metadata['cancelled'] = true;
      },
    );

    return MessageModel(
      type: messageType,
      content: _getDecisionContent(response.decision),
      metadata: metadata,
    );
  }

  /// Получает текстовое содержимое для решения
  String _getDecisionContent(ApprovalDecision decision) {
    return decision.when(
      approved: () => 'Approved',
      rejected: (feedback) =>
          feedback?.fold(() => 'Rejected', (f) => 'Rejected: $f') ?? 'Rejected',
      modified: (_, feedback) =>
          feedback.isNotEmpty ? 'Modified: $feedback' : 'Modified',
      cancelled: () => 'Cancelled',
    );
  }
}
