import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:codelab_core/assets/settings_default.dart';

/// GlobalConfigService watches a directory with config files (e.g., ~/.codelab_ide/) and reloads configs on any change.
class GlobalConfigService {
  final String configDirPath;
  Directory? _configDir;
  final Map<String, dynamic> _configs = {};
  final StreamController<String> _onChanged = StreamController.broadcast();

  Stream<String> get onChanged => _onChanged.stream;
  Map<String, dynamic> get configs => Map.unmodifiable(_configs);
  dynamic getConfig(String filename) => _configs[filename];

  GlobalConfigService({required this.configDirPath});

  Future<void> init() async {
    _configDir = Directory(configDirPath);
    if (!(await _configDir!.exists())) {
      await _configDir!.create(recursive: true);
    }
    // Проверяем наличие settings.json и создаём, если его нет
    final settingsFile = File('${_configDir!.path}/settings.json');
    if (!(await settingsFile.exists())) {
      await settingsFile.writeAsString(jsonEncode(defaultSettings));
    }
    await _loadAllConfigs();
    _watch();
  }

  Future<void> _loadAllConfigs() async {
    _configs.clear();
    final dir = _configDir!;
    await for (var entity in dir.list(recursive: false)) {
      if (entity is File && entity.path.endsWith('.json')) {
        final filename = entity.uri.pathSegments.last;
        try {
          final content = await entity.readAsString();
          _configs[filename] = jsonDecode(content);
        } catch (_) {
          // log/skip bad file
        }
      }
    }
  }

  void _watch() {
    _configDir!
        .watch(
          events:
              FileSystemEvent.create |
              FileSystemEvent.modify |
              FileSystemEvent.delete,
        )
        .listen((event) async {
          final file = File(event.path);
          if (!file.path.endsWith('.json')) return;
          final filename = file.uri.pathSegments.last;

          if (event.type == FileSystemEvent.delete) {
            _configs.remove(filename);
          } else {
            try {
              final content = await file.readAsString();
              _configs[filename] = jsonDecode(content);
            } catch (_) {
              // skip if unreadable
            }
          }
          _onChanged.add(filename);
        });
  }

  Future<void> setConfig(String filename, Map<String, dynamic> data) async {
    final file = File('${_configDir!.path}/$filename');
    await file.writeAsString(jsonEncode(data));
    _configs[filename] = data;
    _onChanged.add(filename);
  }
}
