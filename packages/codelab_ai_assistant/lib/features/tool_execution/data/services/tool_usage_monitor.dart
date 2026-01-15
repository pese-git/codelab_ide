/// Сервис мониторинга и логирования использования tools
/// 
/// Собирает метрики использования tools для анализа паттернов и оптимизации
library;

import 'dart:async';
import 'package:logger/logger.dart';

/// Запись об использовании tool
class ToolUsageRecord {
  final String toolName;
  final DateTime timestamp;
  final int durationMs;
  final bool success;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const ToolUsageRecord({
    required this.toolName,
    required this.timestamp,
    required this.durationMs,
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'tool_name': toolName,
        'timestamp': timestamp.toIso8601String(),
        'duration_ms': durationMs,
        'success': success,
        if (errorCode != null) 'error_code': errorCode,
        if (errorMessage != null) 'error_message': errorMessage,
        if (metadata != null) 'metadata': metadata,
      };

  @override
  String toString() =>
      'ToolUsageRecord(tool=$toolName, duration=${durationMs}ms, success=$success)';
}

/// Статистика использования tool
class ToolUsageStats {
  final String toolName;
  final int totalCalls;
  final int successfulCalls;
  final int failedCalls;
  final double successRate;
  final int totalDurationMs;
  final double averageDurationMs;
  final int minDurationMs;
  final int maxDurationMs;
  final DateTime firstUsed;
  final DateTime lastUsed;
  final Map<String, int> errorCounts;

  const ToolUsageStats({
    required this.toolName,
    required this.totalCalls,
    required this.successfulCalls,
    required this.failedCalls,
    required this.successRate,
    required this.totalDurationMs,
    required this.averageDurationMs,
    required this.minDurationMs,
    required this.maxDurationMs,
    required this.firstUsed,
    required this.lastUsed,
    required this.errorCounts,
  });

  Map<String, dynamic> toJson() => {
        'tool_name': toolName,
        'total_calls': totalCalls,
        'successful_calls': successfulCalls,
        'failed_calls': failedCalls,
        'success_rate': successRate,
        'total_duration_ms': totalDurationMs,
        'average_duration_ms': averageDurationMs,
        'min_duration_ms': minDurationMs,
        'max_duration_ms': maxDurationMs,
        'first_used': firstUsed.toIso8601String(),
        'last_used': lastUsed.toIso8601String(),
        'error_counts': errorCounts,
      };
}

/// Сервис мониторинга использования tools
class ToolUsageMonitor {
  final Logger _logger;
  final List<ToolUsageRecord> _records = [];
  final StreamController<ToolUsageRecord> _recordsController =
      StreamController<ToolUsageRecord>.broadcast();

  /// Максимальное количество записей в памяти
  final int maxRecords;

  /// Включить детальное логирование
  final bool verboseLogging;

  ToolUsageMonitor({
    Logger? logger,
    this.maxRecords = 1000,
    this.verboseLogging = false,
  }) : _logger = logger ?? Logger();

  /// Stream записей использования
  Stream<ToolUsageRecord> get recordsStream => _recordsController.stream;

  /// Записать использование tool
  void recordUsage({
    required String toolName,
    required int durationMs,
    required bool success,
    String? errorCode,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    final record = ToolUsageRecord(
      toolName: toolName,
      timestamp: DateTime.now(),
      durationMs: durationMs,
      success: success,
      errorCode: errorCode,
      errorMessage: errorMessage,
      metadata: metadata,
    );

    _records.add(record);
    _recordsController.add(record);

    // Ограничиваем размер списка
    if (_records.length > maxRecords) {
      _records.removeAt(0);
    }

    // Логирование
    if (success) {
      if (verboseLogging) {
        _logger.d(
          '✅ Tool executed: $toolName (${durationMs}ms)${metadata != null ? ' | metadata: $metadata' : ''}',
        );
      } else {
        _logger.i('✅ Tool executed: $toolName (${durationMs}ms)');
      }
    } else {
      _logger.w(
        '❌ Tool failed: $toolName (${durationMs}ms) - $errorCode: $errorMessage${metadata != null ? ' | metadata: $metadata' : ''}',
      );
    }
  }

  /// Получить все записи
  List<ToolUsageRecord> getAllRecords() => List.unmodifiable(_records);

  /// Получить записи за период
  List<ToolUsageRecord> getRecordsSince(DateTime since) {
    return _records.where((r) => r.timestamp.isAfter(since)).toList();
  }

  /// Получить записи для конкретного tool
  List<ToolUsageRecord> getRecordsForTool(String toolName) {
    return _records.where((r) => r.toolName == toolName).toList();
  }

  /// Получить статистику для tool
  ToolUsageStats? getStatsForTool(String toolName) {
    final toolRecords = getRecordsForTool(toolName);
    if (toolRecords.isEmpty) return null;

    final successfulCalls = toolRecords.where((r) => r.success).length;
    final failedCalls = toolRecords.length - successfulCalls;
    final durations = toolRecords.map((r) => r.durationMs).toList();
    final totalDuration = durations.reduce((a, b) => a + b);

    // Подсчет ошибок
    final errorCounts = <String, int>{};
    for (final record in toolRecords.where((r) => !r.success)) {
      final errorCode = record.errorCode ?? 'unknown';
      errorCounts[errorCode] = (errorCounts[errorCode] ?? 0) + 1;
    }

    return ToolUsageStats(
      toolName: toolName,
      totalCalls: toolRecords.length,
      successfulCalls: successfulCalls,
      failedCalls: failedCalls,
      successRate: successfulCalls / toolRecords.length,
      totalDurationMs: totalDuration,
      averageDurationMs: totalDuration / toolRecords.length,
      minDurationMs: durations.reduce((a, b) => a < b ? a : b),
      maxDurationMs: durations.reduce((a, b) => a > b ? a : b),
      firstUsed: toolRecords.first.timestamp,
      lastUsed: toolRecords.last.timestamp,
      errorCounts: errorCounts,
    );
  }

  /// Получить статистику для всех tools
  Map<String, ToolUsageStats> getAllStats() {
    final toolNames = _records.map((r) => r.toolName).toSet();
    final stats = <String, ToolUsageStats>{};

    for (final toolName in toolNames) {
      final toolStats = getStatsForTool(toolName);
      if (toolStats != null) {
        stats[toolName] = toolStats;
      }
    }

    return stats;
  }

  /// Получить топ N самых используемых tools
  List<MapEntry<String, int>> getTopUsedTools(int n) {
    final toolCounts = <String, int>{};

    for (final record in _records) {
      toolCounts[record.toolName] = (toolCounts[record.toolName] ?? 0) + 1;
    }

    final sorted = toolCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(n).toList();
  }

  /// Получить топ N самых медленных tools
  List<MapEntry<String, double>> getSlowestTools(int n) {
    final stats = getAllStats();
    final sorted = stats.entries
        .map((e) => MapEntry(e.key, e.value.averageDurationMs))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(n).toList();
  }

  /// Получить tools с наибольшим количеством ошибок
  List<MapEntry<String, int>> getToolsWithMostErrors(int n) {
    final stats = getAllStats();
    final sorted = stats.entries
        .map((e) => MapEntry(e.key, e.value.failedCalls))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(n).toList();
  }

  /// Получить общую статистику
  Map<String, dynamic> getOverallStats() {
    if (_records.isEmpty) {
      return {
        'total_calls': 0,
        'unique_tools': 0,
        'success_rate': 0.0,
        'average_duration_ms': 0.0,
      };
    }

    final successfulCalls = _records.where((r) => r.success).length;
    final totalDuration = _records.map((r) => r.durationMs).reduce((a, b) => a + b);
    final uniqueTools = _records.map((r) => r.toolName).toSet().length;

    return {
      'total_calls': _records.length,
      'successful_calls': successfulCalls,
      'failed_calls': _records.length - successfulCalls,
      'success_rate': successfulCalls / _records.length,
      'unique_tools': uniqueTools,
      'total_duration_ms': totalDuration,
      'average_duration_ms': totalDuration / _records.length,
      'first_call': _records.first.timestamp.toIso8601String(),
      'last_call': _records.last.timestamp.toIso8601String(),
    };
  }

  /// Экспортировать статистику в JSON
  Map<String, dynamic> exportStats() {
    return {
      'overall': getOverallStats(),
      'by_tool': getAllStats().map((k, v) => MapEntry(k, v.toJson())),
      'top_used': getTopUsedTools(10)
          .map((e) => {'tool': e.key, 'count': e.value})
          .toList(),
      'slowest': getSlowestTools(10)
          .map((e) => {'tool': e.key, 'avg_duration_ms': e.value})
          .toList(),
      'most_errors': getToolsWithMostErrors(10)
          .map((e) => {'tool': e.key, 'error_count': e.value})
          .toList(),
    };
  }

  /// Вывести отчет в лог
  void logReport() {
    final overall = getOverallStats();
    final topUsed = getTopUsedTools(5);
    final slowest = getSlowestTools(5);
    final mostErrors = getToolsWithMostErrors(5);

    _logger.i('═══════════════════════════════════════════════════');
    _logger.i('📊 Tool Usage Report');
    _logger.i('═══════════════════════════════════════════════════');
    _logger.i('Total calls: ${overall['total_calls']}');
    _logger.i('Success rate: ${(overall['success_rate'] * 100).toStringAsFixed(1)}%');
    _logger.i('Unique tools: ${overall['unique_tools']}');
    _logger.i(
        'Average duration: ${overall['average_duration_ms'].toStringAsFixed(0)}ms');
    _logger.i('');

    if (topUsed.isNotEmpty) {
      _logger.i('🔥 Top Used Tools:');
      for (var i = 0; i < topUsed.length; i++) {
        _logger.i('  ${i + 1}. ${topUsed[i].key}: ${topUsed[i].value} calls');
      }
      _logger.i('');
    }

    if (slowest.isNotEmpty) {
      _logger.i('🐌 Slowest Tools:');
      for (var i = 0; i < slowest.length; i++) {
        _logger.i(
            '  ${i + 1}. ${slowest[i].key}: ${slowest[i].value.toStringAsFixed(0)}ms avg');
      }
      _logger.i('');
    }

    if (mostErrors.isNotEmpty) {
      _logger.i('⚠️  Tools with Most Errors:');
      for (var i = 0; i < mostErrors.length; i++) {
        _logger.i('  ${i + 1}. ${mostErrors[i].key}: ${mostErrors[i].value} errors');
      }
      _logger.i('');
    }

    _logger.i('═══════════════════════════════════════════════════');
  }

  /// Очистить все записи
  void clear() {
    _records.clear();
    _logger.i('🗑️  Tool usage records cleared');
  }

  /// Закрыть монитор
  void dispose() {
    _recordsController.close();
  }
}
