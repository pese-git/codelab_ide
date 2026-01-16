// Unit тесты для use cases планирования
import 'package:codelab_ai_assistant/core/error/failures.dart';
import 'package:codelab_ai_assistant/core/usecases/usecase.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/execution_plan.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/repositories/agent_repository.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/approve_plan.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/reject_plan.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/get_active_plan.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Mock для AgentRepository
class MockAgentRepository extends Mock implements AgentRepository {}

void main() {
  late MockAgentRepository mockRepository;

  setUpAll(() {
    // Регистрируем fallback значения для mocktail
    registerFallbackValue(none<String>());
  });

  setUp(() {
    mockRepository = MockAgentRepository();
  });

  group('ApprovePlanUseCase', () {
    late ApprovePlanUseCase useCase;

    setUp(() {
      useCase = ApprovePlanUseCase(mockRepository);
    });

    test('должен вызвать repository.approvePlan с правильными параметрами', () async {
      // Arrange
      const planId = 'plan-123';
      const feedback = 'Looks good';
      when(() => mockRepository.approvePlan(
        planId: planId,
        feedback: any(named: 'feedback'),
      )).thenAnswer((_) async => right(unit));

      // Act
      await useCase(ApprovePlanParams(
        planId: planId,
        feedback: some(feedback),
      ));

      // Assert
      verify(() => mockRepository.approvePlan(
        planId: planId,
        feedback: some(feedback),
      )).called(1);
    });

    test('должен вернуть Right(unit) при успешном подтверждении', () async {
      // Arrange
      const planId = 'plan-123';
      when(() => mockRepository.approvePlan(
        planId: planId,
        feedback: any(named: 'feedback'),
      )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(ApprovePlanParams(
        planId: planId,
        feedback: none(),
      ));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (value) => value,
      );
    });

    test('должен вернуть Left(Failure) при ошибке', () async {
      // Arrange
      const planId = 'plan-123';
      final failure = Failure.network('Connection failed');
      when(() => mockRepository.approvePlan(
        planId: planId,
        feedback: any(named: 'feedback'),
      )).thenAnswer((_) async => left(failure));

      // Act
      final result = await useCase(ApprovePlanParams(
        planId: planId,
        feedback: none(),
      ));

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.message, contains('Connection failed')),
        (_) => fail('Should not return success'),
      );
    });

    test('должен работать без feedback', () async {
      // Arrange
      const planId = 'plan-123';
      when(() => mockRepository.approvePlan(
        planId: planId,
        feedback: const None(),
      )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(ApprovePlanParams(
        planId: planId,
      ));

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.approvePlan(
        planId: planId,
        feedback: const None(),
      )).called(1);
    });
  });

  group('RejectPlanUseCase', () {
    late RejectPlanUseCase useCase;

    setUp(() {
      useCase = RejectPlanUseCase(mockRepository);
    });

    test('должен вызвать repository.rejectPlan с правильными параметрами', () async {
      // Arrange
      const planId = 'plan-123';
      const reason = 'Too complex';
      when(() => mockRepository.rejectPlan(
        planId: planId,
        reason: reason,
      )).thenAnswer((_) async => right(unit));

      // Act
      await useCase(RejectPlanParams(
        planId: planId,
        reason: reason,
      ));

      // Assert
      verify(() => mockRepository.rejectPlan(
        planId: planId,
        reason: reason,
      )).called(1);
    });

    test('должен вернуть Right(unit) при успешном отклонении', () async {
      // Arrange
      const planId = 'plan-123';
      const reason = 'Too complex';
      when(() => mockRepository.rejectPlan(
        planId: planId,
        reason: reason,
      )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(RejectPlanParams(
        planId: planId,
        reason: reason,
      ));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (value) => value,
      );
    });

    test('должен вернуть Left(Failure) при ошибке', () async {
      // Arrange
      const planId = 'plan-123';
      const reason = 'Too complex';
      final failure = Failure.server('Server error');
      when(() => mockRepository.rejectPlan(
        planId: planId,
        reason: reason,
      )).thenAnswer((_) async => left(failure));

      // Act
      final result = await useCase(RejectPlanParams(
        planId: planId,
        reason: reason,
      ));

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.message, contains('Server error')),
        (_) => fail('Should not return success'),
      );
    });

    test('должен требовать reason', () {
      // Arrange & Act & Assert
      expect(
        () => RejectPlanParams(
          planId: 'plan-123',
          reason: '',
        ),
        returnsNormally,
      );
    });
  });

  group('GetActivePlanUseCase', () {
    late GetActivePlanUseCase useCase;

    setUp(() {
      useCase = GetActivePlanUseCase(mockRepository);
    });

    test('должен вызвать repository.getActivePlan', () async {
      // Arrange
      when(() => mockRepository.getActivePlan())
          .thenAnswer((_) async => right(none()));

      // Act
      await useCase(const NoParams());

      // Assert
      verify(() => mockRepository.getActivePlan()).called(1);
    });

    test('должен вернуть Right(None) если нет активного плана', () async {
      // Arrange
      when(() => mockRepository.getActivePlan())
          .thenAnswer((_) async => right(none()));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (option) => expect(option.isNone(), true),
      );
    });

    test('должен вернуть Right(Some(plan)) если есть активный план', () async {
      // Arrange
      final plan = ExecutionPlan.create(
        planId: 'plan-123',
        sessionId: 'session-1',
        originalTask: 'Build feature',
        subtasks: [
          Subtask.pending(
            id: 'task-1',
            description: 'First task',
            agent: 'coder',
          ),
        ],
      );

      when(() => mockRepository.getActivePlan())
          .thenAnswer((_) async => right(some(plan)));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (option) {
          expect(option.isSome(), true);
          option.fold(
            () => fail('Should have plan'),
            (p) {
              expect(p.planId, 'plan-123');
              expect(p.sessionId, 'session-1');
              expect(p.originalTask, 'Build feature');
              expect(p.subtasks.length, 1);
            },
          );
        },
      );
    });

    test('должен вернуть Left(Failure) при ошибке', () async {
      // Arrange
      final failure = Failure.unknown('Unknown error');
      when(() => mockRepository.getActivePlan())
          .thenAnswer((_) async => left(failure));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.message, contains('Unknown error')),
        (_) => fail('Should not return success'),
      );
    });

    test('должен работать с NoParams', () async {
      // Arrange
      when(() => mockRepository.getActivePlan())
          .thenAnswer((_) async => right(none()));

      // Act
      final result1 = await useCase(const NoParams());
      final result2 = await useCase(const NoParams());

      // Assert
      expect(result1.isRight(), true);
      expect(result2.isRight(), true);
      verify(() => mockRepository.getActivePlan()).called(2);
    });
  });

  group('ApprovePlanParams', () {
    test('должен создаваться с обязательным planId', () {
      const params = ApprovePlanParams(planId: 'plan-123');
      
      expect(params.planId, 'plan-123');
      expect(params.feedback.isNone(), true);
    });

    test('должен создаваться с feedback', () {
      const params = ApprovePlanParams(
        planId: 'plan-123',
        feedback: Some('Good plan'),
      );
      
      expect(params.planId, 'plan-123');
      expect(params.feedback.isSome(), true);
      expect(params.feedback.getOrElse(() => ''), 'Good plan');
    });
  });

  group('RejectPlanParams', () {
    test('должен создаваться с обязательными полями', () {
      const params = RejectPlanParams(
        planId: 'plan-123',
        reason: 'Too complex',
      );
      
      expect(params.planId, 'plan-123');
      expect(params.reason, 'Too complex');
    });
  });
}
