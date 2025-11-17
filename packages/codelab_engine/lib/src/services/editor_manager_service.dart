import 'package:flutter/material.dart';
import 'package:codelab_uikit/codelab_uikit.dart' as uikit;

/// Сервис для управления EditorPanel через GlobalKey
class EditorManagerService {
  GlobalKey<uikit.EditorPanelState>? _editorPanelKey;

  /// Устанавливает GlobalKey для управления редактором
  void setEditorPanelKey(GlobalKey<uikit.EditorPanelState> key) {
    _editorPanelKey = key;
  }

  /// Открывает файл в редакторе
  void openFile({
    required String filePath,
    required String title,
    required String content,
  }) {
    _editorPanelKey?.currentState?.openFile(
      filePath: filePath,
      title: title,
      content: content,
    );
  }

  /// Закрывает файл по пути
  void closeFile(String filePath) {
    _editorPanelKey?.currentState?.closeFile(filePath);
  }

  /// Закрывает все открытые файлы
  void closeAllFiles() {
    _editorPanelKey?.currentState?.closeAllFiles();
  }

  /// Сохраняет все файлы
  void saveAllFiles() {
    _editorPanelKey?.currentState?.saveAllFiles();
  }

  /// Обновляет содержимое файла
  void updateFileContent(String filePath, String content) {
    _editorPanelKey?.currentState?.updateFileContent(filePath, content);
  }

  /// Возвращает список всех открытых вкладок
  List<uikit.EditorTab> get tabs {
    return _editorPanelKey?.currentState?.tabs ?? [];
  }

  /// Возвращает активную вкладку
  uikit.EditorTab? get activeTab {
    return _editorPanelKey?.currentState?.activeTab;
  }

  /// Проверяет, открыт ли файл
  bool isFileOpen(String filePath) {
    return _editorPanelKey?.currentState?.tabs.any(
          (tab) => tab.filePath == filePath,
        ) ??
        false;
  }

  /// Переключается на вкладку с указанным файлом
  void switchToFile(String filePath) {
    final tabs = _editorPanelKey?.currentState?.tabs ?? [];
    for (final tab in tabs) {
      if (tab.filePath == filePath) {
        _editorPanelKey?.currentState?.openFile(
          filePath: filePath,
          title: tab.title,
          content: tab.content,
        );
        return;
      }
    }
  }
}
