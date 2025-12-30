import 'package:code_forge/code_forge.dart';

class EditorTab {
  final String id;
  final String title;
  final String filePath;
  final String workspacePath;
  final String content;
  final bool isDirty;
  final LspConfig? lspConfig;

  EditorTab({
    required this.id,
    required this.title,
    required this.filePath,
    required this.content,
    this.isDirty = false,
    required this.workspacePath,
    this.lspConfig,
  });

  EditorTab copyWith({
    String? id,
    String? title,
    String? filePath,
    String? content,
    bool? isDirty,
    String? workspacePath,
    LspConfig? lspConfig,
  }) {
    return EditorTab(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      isDirty: isDirty ?? this.isDirty,
      workspacePath: workspacePath ?? this.workspacePath,
      lspConfig: lspConfig ?? this.lspConfig,
    );
  }
}
