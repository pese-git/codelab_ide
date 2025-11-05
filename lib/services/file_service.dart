import 'dart:io';
import 'package:file_picker/file_picker.dart';

import '../models/project_model.dart';
import '../utils/logger.dart';

class FileService {
  static Future<String?> pickProjectDirectory() async {
    // Use file_picker to let user select a directory
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      return selectedDirectory;
    } catch (e) {
      logger.e('Error picking directory: $e');
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
      logger.e('Error loading project tree: $e');
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
      logger.e('Error reading file: $e');
    }
    return '';
  }

  static Future<bool> writeFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      logger.e('Error writing file: $e');
      return false;
    }
  }

  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
