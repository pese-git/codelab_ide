// packages/codelab_engine/lib/widgets/editor_panel_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codelab_uikit/widgets/panels/editor_panel/editor_panel.dart';
import '../deprecate/widgets/editor/editor_bloc.dart';
import 'package:codelab_uikit/widgets/panels/editor_panel/pane_node.dart';
import 'package:codelab_uikit/models/editor_tab.dart';

class EditorPanelWrapper extends StatefulWidget {
  const EditorPanelWrapper({super.key});

  @override
  State<EditorPanelWrapper> createState() => _EditorPanelWrapperState();
}

class _EditorPanelWrapperState extends State<EditorPanelWrapper> {
  final _editorPanelKey = GlobalKey<EditorPanelState>();
  late final EditorBloc _bloc;
  late final void Function() _blocSubscriptionCancel;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<EditorBloc>();

    // Подписка на состояние блока для синхронизации в обе стороны
    final subscription = _bloc.stream.listen((state) {
      _syncWithBlocState(state);
    });
    _blocSubscriptionCancel = subscription.cancel;
    // Синхронизируем при запуске
    _syncWithBlocState(_bloc.state);
  }

  void _syncWithBlocState(EditorState state) {
    // Когда BLoC сообщает о новом открытом файле — открываем вкладку
    if (state.filePath.isNotEmpty) {
      _editorPanelKey.currentState?.openFile(
        filePath: state.filePath,
        title: state.filePath.split('/').last,
        content: state.content,
      );
    }
    // Можно добавить поддержку других операций (закрытие, сохранение и т.д.)
  }

  // Пример отправки событий из EditorPanel в Bloc через callback:
  void _onTabContentChanged(EditorTabsPane pane, EditorTab tab) {
    if (tab.filePath == _bloc.state.filePath &&
        tab.content != _bloc.state.content) {
      _bloc.add(EditorEvent.updateContent(tab.content));
    }
  }

  // Можно реализовать дополнительные callbacks для onTabClosed, onTabSelected и др.

  @override
  Widget build(BuildContext context) {
    return EditorPanel(
      key: _editorPanelKey,
      label: 'Editor',
      initialTabs: const [],
      // Кастомные callbacks для обновлений в Bloc:
      // onTabContentChanged: _onTabContentChanged,
      // onTabClosed: ...
    );
  }

  @override
  void dispose() {
    _blocSubscriptionCancel();
    super.dispose();
  }
}
