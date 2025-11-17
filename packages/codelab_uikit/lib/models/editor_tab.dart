class EditorTab {
  final String id;
  final String title;
  final String filePath;
  final String content;
  final bool isDirty;

  EditorTab({
    required this.id,
    required this.title,
    required this.filePath,
    required this.content,
    this.isDirty = false,
  });

  EditorTab copyWith({
    String? id,
    String? title,
    String? filePath,
    String? content,
    bool? isDirty,
  }) {
    return EditorTab(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
