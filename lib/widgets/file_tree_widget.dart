import 'package:flutter/material.dart';
import '../models/project_model.dart';

class FileTreeWidget extends StatefulWidget {
  final FileNode? fileTree;
  final Function(String) onFileSelected;
  final String? selectedFile;

  const FileTreeWidget({
    Key? key,
    required this.fileTree,
    required this.onFileSelected,
    this.selectedFile,
  }) : super(key: key);

  @override
  _FileTreeWidgetState createState() => _FileTreeWidgetState();
}

class _FileTreeWidgetState extends State<FileTreeWidget> {
  final Set<String> _expandedNodes = {};

  void _toggleExpanded(String path) {
    setState(() {
      if (_expandedNodes.contains(path)) {
        _expandedNodes.remove(path);
      } else {
        _expandedNodes.add(path);
      }
    });
  }

  Widget _buildFileNode(FileNode node) {
    final isExpanded = _expandedNodes.contains(node.path);
    final isSelected = widget.selectedFile == node.path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(
            node.isDirectory
                ? (isExpanded ? Icons.folder_open : Icons.folder)
                : _getFileIcon(node.name),
            color: node.isDirectory ? Colors.blue : Colors.grey,
          ),
          title: Text(
            node.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : null,
            ),
          ),
          trailing: node.isDirectory
              ? Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                )
              : null,
          onTap: () {
            if (node.isDirectory) {
              _toggleExpanded(node.path);
            } else {
              widget.onFileSelected(node.path);
            }
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
          minLeadingWidth: 0,
        ),
        if (node.isDirectory && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: node.children.map(_buildFileNode).toList(),
            ),
          ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'dart':
        return Icons.code;
      case 'py':
        return Icons.code;
      case 'js':
        return Icons.code;
      case 'java':
        return Icons.code;
      case 'cpp':
      case 'c':
        return Icons.code;
      case 'html':
        return Icons.html;
      case 'css':
        return Icons.css;
      case 'json':
        return Icons.data_object;
      case 'md':
        return Icons.text_snippet;
      case 'txt':
        return Icons.text_fields;
      case 'yaml':
      case 'yml':
        return Icons.settings;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fileTree == null) {
      return const Center(
        child: Text('No project loaded'),
      );
    }

    return SingleChildScrollView(
      child: _buildFileNode(widget.fileTree!),
    );
  }
}
