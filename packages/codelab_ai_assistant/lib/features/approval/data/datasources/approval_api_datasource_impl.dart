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
    // Для tool approval отправляем hitl_decision, для plan - plan_decision
    if (response.type == ApprovalType.tool) {
      // Для tool approval используем hitl_decision с правильной структурой
      final decisionString = response.decision.when(
        approved: () => 'approve',
        rejected: (_) => 'reject',
        modified: (_, __) => 'edit',
        cancelled: () => 'reject',
      );
      
      // Извлекаем modified_arguments если есть
      Map<String, dynamic>? modifiedArguments;
      String? feedback;
      
      response.decision.maybeWhen(
        modified: (modifiedData, feedbackText) {
          modifiedArguments = modifiedData;
          feedback = feedbackText.isNotEmpty ? feedbackText : null;
        },
        rejected: (feedbackOpt) {
          feedbackOpt?.fold(() => null, (f) => feedback = f);
        },
        orElse: () {},
      );
      
      return MessageModel(
        type: 'hitl_decision',
        callId: response.approvalRequestId, // ✅ call_id на верхнем уровне
        decision: decisionString,
        feedback: feedback,
        metadata: modifiedArguments != null
            ? {'modified_arguments': modifiedArguments}
            : null,
      );
    } else {
      // Для plan approval используем plan_decision
      final decisionString = response.decision.when(
        approved: () => 'approve',
        rejected: (_) => 'reject',
        modified: (_, __) => 'modify',
        cancelled: () => 'reject',
      );
      
      String? feedback;
      response.decision.maybeWhen(
        rejected: (feedbackOpt) {
          feedbackOpt?.fold(() => null, (f) => feedback = f);
        },
        modified: (_, feedbackText) {
          feedback = feedbackText.isNotEmpty ? feedbackText : null;
        },
        orElse: () {},
      );
      
      return MessageModel(
        type: 'plan_decision',
        approvalRequestId: response.approvalRequestId,
        planId: response.approvalRequestId, // используем approval_request_id как plan_id
        decision: decisionString,
        feedback: feedback,
      );
    }
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
