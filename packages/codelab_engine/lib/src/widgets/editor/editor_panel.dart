import 'dart:async';
import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_engine/codelab_engine.dart';
import 'package:codelab_uikit/codelab_uikit.dart' as uikit;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'editor_bloc.dart';

class EditorPanel extends StatefulWidget {
  const EditorPanel({super.key});

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  late final FileSyncService _fileSyncService;
  StreamSubscription<String>? _fileOpenedSubscription;
  StreamSubscription<String>? _fileSavedSubscription;
  StreamSubscription<String>? _fileChangedSubscription;
  StreamSubscription<String>? _fileDeletedSubscription;

  @override
  void initState() {
    super.initState();
    _fileSyncService = CherryPick.openRootScope().resolve<FileSyncService>();
    _setupFileSyncListeners();
  }

  @override
  void dispose() {
    _fileOpenedSubscription?.cancel();
    _fileSavedSubscription?.cancel();
    _fileChangedSubscription?.cancel();
    _fileDeletedSubscription?.cancel();
    super.dispose();
  }

  void _setupFileSyncListeners() {
    print('EditorPanel: Setting up file sync listeners');

    // Слушаем открытие файлов из ExplorerPanel
    _fileOpenedSubscription = _fileSyncService.fileOpenedStream.listen((
      filePath,
    ) {
      print('EditorPanel: Received file opened event: $filePath');
      // Открыть файл в редакторе через EditorBloc
      final bloc = context.read<EditorBloc>();
      bloc.add(EditorEvent.openFile(filePath));
    });

    // Слушаем сохранение файлов
    _fileSavedSubscription = _fileSyncService.fileSavedStream.listen((
      filePath,
    ) {
      print('EditorPanel: File saved: $filePath');
      // TODO: Обновить статус файла в редакторе
    });

    // Слушаем изменения файлов извне
    _fileChangedSubscription = _fileSyncService.fileChangedStream.listen((
      filePath,
    ) {
      print('EditorPanel: File changed externally: $filePath');
      // TODO: Показать диалог о внешних изменениях
    });

    // Слушаем удаление файлов
    _fileDeletedSubscription = _fileSyncService.fileDeletedStream.listen((
      filePath,
    ) {
      print('EditorPanel: File deleted: $filePath');
      // Закрыть вкладку если файл был удален
      final bloc = context.read<EditorBloc>();
      bloc.add(EditorEvent.fileDeleted(filePath));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EditorBloc>(
      create: (context) => EditorBloc(
        fileService: CherryPick.openRootScope().resolve<FileService>(),
      ),
      child: BlocBuilder<EditorBloc, EditorState>(
        builder: (context, state) {
          print('EditorPanel: Building with ${state.openTabs.length} tabs');
          return uikit.EditorPanel(
            label: 'Editor',
            initialTabs: state.openTabs,
          );
        },
      ),
    );
  }
}
