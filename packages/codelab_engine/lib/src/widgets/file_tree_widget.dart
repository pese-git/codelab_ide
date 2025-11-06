import 'package:codelab_engine/src/models/file_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'file_tree_bloc.dart';

class FileTreeWidget extends StatefulWidget {
  final FileNode? initialFileTree;
  final ValueChanged<String>? onFileSelected;

  const FileTreeWidget({
    super.key,
    required this.initialFileTree,
    this.onFileSelected,
  });

  @override
  State<FileTreeWidget> createState() => _FileTreeWidgetState();
}

class _FileTreeWidgetState extends State<FileTreeWidget> {
  late final FileTreeBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = FileTreeBloc();
    if (widget.initialFileTree != null) {
      _bloc.add(FileTreeEvent.setFileTree(widget.initialFileTree));
    }
  }

  @override
  void didUpdateWidget(covariant FileTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFileTree != oldWidget.initialFileTree) {
      _bloc.add(FileTreeEvent.setFileTree(widget.initialFileTree));
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FileTreeBloc>.value(
      value: _bloc,
      child: BlocBuilder<FileTreeBloc, FileTreeState>(
        builder: (context, state) {
          final fileTree = state.fileTree;
          if (fileTree == null) {
            return const Center(child: Text('No project loaded'));
          }
          return SingleChildScrollView(
            child: _buildFileNode(context, fileTree, state),
          );
        },
      ),
    );
  }

  Widget _buildFileNode(
    BuildContext context,
    FileNode node,
    FileTreeState state,
  ) {
    final isExpanded = state.expandedNodes.contains(node.path);
    final isSelected = state.selectedFile == node.path;
    final bloc = context.read<FileTreeBloc>();

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
              bloc.add(FileTreeEvent.toggleExpanded(node.path));
            } else {
              bloc.add(FileTreeEvent.selectFile(node.path));
              if (widget.onFileSelected != null) {
                widget.onFileSelected!(node.path);
              }
            }
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
          minLeadingWidth: 0,
        ),
        if (node.isDirectory && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: node.children
                  .map((child) => _buildFileNode(context, child, state))
                  .toList(),
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
}
