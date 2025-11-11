import 'package:fluent_ui/fluent_ui.dart';
import 'file_node.dart';

class ExplorerPanel extends StatelessWidget {
  final List<FileNode> files;
  final void Function(FileNode) onFileOpen;
  const ExplorerPanel({super.key, required this.files, required this.onFileOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey[20],
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'EXPLORER',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TreeView(
              items: _buildTree(files),
            ),
          ),
        ],
      ),
    );
  }

  List<TreeViewItem> _buildTree(List<FileNode> nodes) {
    return nodes.map((node) {
      if (node.isDirectory) {
        return TreeViewItem(
          leading: const Icon(FluentIcons.folder_horizontal),
          content: Text(node.name),
          children: _buildTree(node.children),
        );
      } else {
        return TreeViewItem(
          leading: const Icon(FluentIcons.page),
          content: GestureDetector(
            onTap: () => onFileOpen(node),
            child: Text(node.name),
          ),
        );
      }
    }).toList();
  }
}
