import 'dart:io';
import 'package:flutter/foundation.dart';

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
          children.add(FileNode(
            name: name,
            path: entity.path,
            isDirectory: false,
          ));
        }
      }
    } catch (e) {
      print('Error reading directory ${directory.path}: $e');
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

class ProjectState extends ChangeNotifier {
  String? _projectPath;
  FileNode? _fileTree;
  String? _currentFile;
  String _fileContent = '';

  String? get projectPath => _projectPath;
  FileNode? get fileTree => _fileTree;
  String? get currentFile => _currentFile;
  String get fileContent => _fileContent;

  void copyWith({
    String? projectPath,
    FileNode? fileTree,
    String? currentFile,
    String? fileContent,
  }) {
    _projectPath = projectPath ?? _projectPath;
    _fileTree = fileTree ?? _fileTree;
    _currentFile = currentFile ?? _currentFile;
    _fileContent = fileContent ?? _fileContent;
    notifyListeners();
  }
}
