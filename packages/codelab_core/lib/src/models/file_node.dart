import 'dart:io';
import 'package:codelab_core/codelab_core.dart';

class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;

  FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const [],
  });

  factory FileNode.fromDirectory(Directory directory) {
    final children = <FileNode>[];

    try {
      final entities = directory.listSync();
      for (var entity in entities) {
        final name = entity.path.split(Platform.pathSeparator).last;
        // Skip hidden files and build directories
        if (name.startsWith('.') || name == 'build' || name == '.dart_tool') {
          continue;
        }

        if (entity is Directory) {
          children.add(FileNode.fromDirectory(entity));
        } else {
          children.add(
            FileNode(name: name, path: entity.path, isDirectory: false),
          );
        }
      }
    } catch (e) {
      codelabLogger.e('Error reading directory ${directory.path}: $e', tag: 'file_node');
    }

    // Sort: directories first, then files
    children.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.compareTo(b.name);
    });

    return FileNode(
      name: directory.path.split(Platform.pathSeparator).last,
      path: directory.path,
      isDirectory: true,
      children: children,
    );
  }
}
