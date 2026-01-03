// BLoC для подтверждения выполнения инструментов (Presentation слой)
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/tool_call.dart';
import '../../domain/entities/tool_approval.dart';
import '../../domain/usecases/request_approval.dart';

part 'tool_approval_bloc.freezed.dart';

/// События для ToolApprovalBloc
@freezed
class ToolApprovalEvent with _$ToolApprovalEvent {
  const factory ToolApprovalEvent.requestApproval(ToolCall toolCall) = RequestApprovalEvent;
  const factory ToolApprovalEvent.approve() = ApproveEvent;
  const factory ToolApprovalEvent.reject(String reason) = RejectEvent;
  const factory ToolApprovalEvent.modify(Map<String, dynamic> modifiedArguments) = ModifyEvent;
  const factory ToolApprovalEvent.cancel() = CancelEvent;
}

/// Состояния для ToolApprovalBloc
@freezed
class ToolApprovalState with _$ToolApprovalState {
  const factory ToolApprovalState.initial() = InitialState;
  const factory ToolApprovalState.requesting({
    required ToolApprovalRequest request,
  }) = RequestingState;
  const factory ToolApprovalState.approved() = ApprovedState;
  const factory ToolApprovalState.rejected(String reason) = RejectedState;
  const factory ToolApprovalState.modified(Map<String, dynamic> arguments) = ModifiedState;
  const factory ToolApprovalState.cancelled() = CancelledState;
  const factory ToolApprovalState.error(String message) = ErrorState;
}

/// BLoC для управления подтверждением выполнения инструментов
/// 
/// Использует Clean Architecture подход с Use Cases
class ToolApprovalBloc extends Bloc<ToolApprovalEvent, ToolApprovalState> {
  final RequestApprovalUseCase _requestApproval;
  final Logger _logger;
  
  ToolApprovalBloc({
    required RequestApprovalUseCase requestApproval,
    required Logger logger,
  })  : _requestApproval = requestApproval,
        _logger = logger,
        super(const ToolApprovalState.initial()) {
    on<RequestApprovalEvent>(_onRequestApproval);
    on<ApproveEvent>(_onApprove);
    on<RejectEvent>(_onReject);
    on<ModifyEvent>(_onModify);
    on<CancelEvent>(_onCancel);
  }
  
  Future<void> _onRequestApproval(
    RequestApprovalEvent event,
    Emitter<ToolApprovalState> emit,
  ) async {
    final request = ToolApprovalRequest(
      requestId: DateTime.now().millisecondsSinceEpoch.toString(),
      toolCall: event.toolCall,
      requestedAt: DateTime.now(),
      timeoutSeconds: 300,
      context: none(),
    );
    
    emit(ToolApprovalState.requesting(request: request));
    
    _logger.i('Requesting approval for tool: ${event.toolCall.toolName}');
  }
  
  Future<void> _onApprove(
    ApproveEvent event,
    Emitter<ToolApprovalState> emit,
  ) async {
    _logger.i('Tool execution approved');
    emit(const ToolApprovalState.approved());
  }
  
  Future<void> _onReject(
    RejectEvent event,
    Emitter<ToolApprovalState> emit,
  ) async {
    _logger.w('Tool execution rejected: ${event.reason}');
    emit(ToolApprovalState.rejected(event.reason));
  }
  
  Future<void> _onModify(
    ModifyEvent event,
    Emitter<ToolApprovalState> emit,
  ) async {
    _logger.i('Tool arguments modified');
    emit(ToolApprovalState.modified(event.modifiedArguments));
  }
  
  Future<void> _onCancel(
    CancelEvent event,
    Emitter<ToolApprovalState> emit,
  ) async {
    _logger.i('Tool approval cancelled');
    emit(const ToolApprovalState.cancelled());
  }
}
