import 'dart:io';
import '../models/project_model.dart';

class FileService {
  static Future<String?> pickProjectDirectory() async {
    // For MVP, we'll use a mock directory picker
    // In a real implementation, you'd use file_picker
    try {
      // Return current directory as mock
      return Directory.current.path;
    } catch (e) {
      print('Error picking directory: $e');
      return null;
    }
  }

  static FileNode? loadProjectTree(String projectPath) {
    try {
      final directory = Directory(projectPath);
      if (directory.existsSync()) {
        return FileNode.fromDirectory(directory);
      }
    } catch (e) {
      print('Error loading project tree: $e');
    }
    return null;
  }

  static Future<String> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('Error reading file: $e');
    }
    return '';
  }

  static Future<bool> writeFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('Error writing file: $e');
      return false;
    }
  }

  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
