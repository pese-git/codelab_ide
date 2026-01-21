# Changelog

Все значимые изменения в проекте CodeLab IDE будут документированы в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/),
и этот проект придерживается [Semantic Versioning](https://semver.org/lang/ru/).

## [1.0.0] - 2026-01-21

### Добавлено

**Основной функционал:**
- Модульная монорепозиторная архитектура с 6 packages
- Навигация по дереву файлов с фильтрацией системных файлов
- Редактор кода с подсветкой синтаксиса для 10+ языков
- Встроенный терминал с PTY поддержкой
- Кроссплатформенная поддержка (Windows, Linux, macOS)

**AI Ассистент (codelab_ai_assistant):**
- WebSocket интеграция с AI Service через Gateway
- Мультиагентная система с 5 специализированными агентами:
  - Orchestrator - координация задач
  - Coder - написание кода
  - Architect - проектирование архитектуры
  - Debug - отладка и исправление ошибок
  - Ask - ответы на вопросы
- Human-in-the-Loop (HITL) для контроля опасных операций
- Session persistence с сохранением истории
- Восстановление pending approvals после перезапуска
- Локальное выполнение 9+ инструментов (read_file, write_file, execute_command и др.)
- Streaming responses с token-by-token отображением

**Архитектурные паттерны:**
- Clean Architecture с разделением на Presentation, Domain, Data слои
- BLoC Pattern для управления состоянием
- Dependency Injection через CherryPick
- Functional Programming с FPDart (Either, Option, TaskEither)
- Freezed для неизменяемых классов данных

**Packages:**
- `codelab_core` - Основные сервисы (FileService, ProjectService, RunService)
- `codelab_engine` - Движок редактора и синхронизация файлов
- `codelab_ai_assistant` - Интеграция AI с мультиагентной системой
- `codelab_terminal` - Эмулятор терминала с xterm
- `codelab_uikit` - UI компоненты на основе Fluent UI
- `codelab_version_control` - Базовая Git интеграция

**Документация:**
- Полная документация проекта в директории `doc/`
- README.md для каждого пакета
- Руководства по интеграции HITL и мультиагентной системы
- Описание расширенного WebSocket протокола

### Изменено

- Обновлена структура проекта на монорепозиторий с Melos
- Переход на Clean Architecture во всех пакетах
- Улучшена обработка ошибок с использованием Either
- Оптимизирована производительность редактора

### Исправлено

- Исправлены проблемы с бесконечным loader в чате
- Исправлена обработка кликов по карточкам сессий
- Исправлены утечки памяти в WebSocket соединениях
- Исправлена синхронизация состояния при переключении агентов

## [Unreleased]

### Планируется

**v1.1 (Q1 2026):**
- LSP интеграция для автодополнения
- Multi-tab редактор
- Продвинутая Git интеграция
- Code navigation (Go to definition, Find references)

**v1.2 (Q2 2026):**
- Visual Debugger с breakpoints
- Performance profiling
- Code refactoring tools
- Улучшенная интеграция с AI

**v2.0 (Q3-Q4 2026):**
- Plugin system
- Custom themes
- Collaborative editing
- Package manager UI
- Project templates
- Integrated testing

---

[1.0.0]: https://github.com/your-org/codelab_ide/releases/tag/v1.0.0
