# Набор инструментов (tools) для flow "Разработка" в интеграции AI-агента и IDE

## Обязательные инструменты для сценариев разработки

### 1. file_read
- Чтение содержимого файла по пути.
- `{ "path": "src/main.dart" }`

### 2. file_write
- Запись/перезапись содержимого файла.
- `{ "path": "src/main.dart", "content": "..." }`

### 3. file_append / file_insert / file_replace_fragment
- Добавление текста, вставка блока, замена региона в файле (например, патчем/диффом).
- `{ "path": "src/main.dart", "region": [10, 15], "content": "..." }`

### 4. file_list / file_glob
- Получить структуру директорий/файлов или список файлов по маске.
- `{ "path": "src/", "pattern": "*.dart" }`

### 5. file_remove
- Удаление файла.

### 6. run_script / run_command
- Запуск консольной команды или скрипта в проекте.
- `{ "command": "dart test", "args": [] }`

### 7. test_run
- Запуск тестов, с фильтрацией по паттерну (файлам, тегам).
- `{ "pattern": "*user_test.dart" }`

### 8. git_diff / git_commit / git_status / git_apply_patch
- Получение диффа, создание коммита, просмотр git-статуса, применение patch/diff.
- `{ "message": "refactor: update foo.dart" }`

### 9. search_in_code / grep
- Поиск выражения/регулярки по коду (например, TODO/название функции).
- `{ "pattern": "TODO", "path": "src/" }`

### 10. code_format
- Автоформатирование файла или проекта.
- `{ "path": "src/", "language": "dart" }`

### 11. code_analyze / linter
- Запуск статического анализа (линтер, подсказки, типизация).
- `{ "path": "src/", "language": "dart" }`

### 12. editor_actions
- Открытие файла во вкладке, выделение строки, скролл, показ подсказки/нотификации.

### Дополнительно:
- create_file / create_folder
- rename_file
- run_shell / terminal_input (ограниченно!)
- send_notification (ошибка, инфо и т.д.)
- diagnostics_info (CPU, память, OS и т.п.)
- install_dependency (подключить пакет, обновить зависимости)

---

## Назначение минимального набора

- создание/чтение/изменение файлов (file_read, file_write, file_remove, file_list)
- работа с кодом: запуск, тестирование, анализ, форматирование (run_script, test_run, code_format, code_analyze)
- версии: git_diff/commit/status
- работа с проектом и IDE: навигация, search_in_code, editor_action

---

## Рекомендация
Запускать разработку удобно с:
- file_read, file_write, run_script, test_run, git_diff/git_commit, editor_action
- Затем постепенно расширять список инструментов (поисковые, linter, patch/replace, notification) под расширенный workflow агента.
