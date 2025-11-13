import 'package:fluent_ui/fluent_ui.dart';

class HeaderSection extends StatelessWidget {
  final VoidCallback? onPlay;
  final VoidCallback? onStop;
  final String title;

  const HeaderSection({
    this.onPlay,
    this.onStop,
    this.title = 'RUN AND DEBUG',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(icon: const Icon(FluentIcons.play), onPressed: onPlay),
              IconButton(icon: const Icon(FluentIcons.stop), onPressed: onStop),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ComboBox<String>(
              placeholder: const Text('Select configuration'),
              items: const [
                ComboBoxItem(child: Text('Launch main.dart'), value: 'main'),
              ],
              onChanged: (val) {},
            ),
          ),
        ],
      ),
    );
  }
}
