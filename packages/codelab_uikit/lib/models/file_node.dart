class FileNode {
  final String path;
  final String workspacePath;
  final String name;
  final bool isDirectory;
  final List<FileNode> children;

  FileNode({
    required this.path,
    required this.name,
    this.isDirectory = false,
    this.children = const [],
    required this.workspacePath,
  });
}
