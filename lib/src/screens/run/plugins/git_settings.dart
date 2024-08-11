import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../backend_api/utilities/run/plugins/run_plugin_git_bakcned.dart';
import '../../../common_widgets/setting_wrapper.dart';
import '../run_plugin_settings.dart';

class RunGitSettings extends StatefulWidget {
  const RunGitSettings({super.key});

  @override
  State<RunGitSettings> createState() => _RunGitSettingsState();
}

class _RunGitSettingsState extends State<RunGitSettings> {
  late SettingListEditController<String> _searchFolderController;
  late SettingListEditController<String> _excludeSearchFolderController;

  @override
  void initState() {
    RunGitSettingsBackend backend = Provider.of(context, listen: false);

    _searchFolderController = SettingListEditController(elements: backend.basePaths);
    _excludeSearchFolderController = SettingListEditController(elements: backend.ignorePaths);

    backend.addListener(_onChange);

    super.initState();
  }

  void _onChange() {
    RunGitSettingsBackend backend = Provider.of<RunGitSettingsBackend>(context, listen: false);
    _searchFolderController.elements = backend.basePaths;
    _excludeSearchFolderController.elements = backend.ignorePaths;
  }

  @override
  Widget build(BuildContext context) {
    return RunPluginSettingsWrapper(
      settings: Provider.of<RunGitSettingsBackend>(context),
      error: Provider.of<RunGitSettingsBackend>(context).error,
      title: "git",
      description: "finds git repositories",
      leading: const Icon(Icons.folder_outlined),
      children: [
        Consumer<RunGitSettingsBackend>(
          builder: (context, settings, _) => SettingListEdit<String>(
            title: "Search folders",
            controller: _searchFolderController,
            addToolTip: "add search folder",
            emptyMessage: "Press + to add a new glob",
            onAdd: (value) {
              settings.addSearchPaths(value);
            },
            onChange: (index, value) {
              settings.modifySearchPaths(index, value);
            },
            onDelete: (index) {
              settings.removeSearchPaths(settings.basePaths[index]);
            },
            validator: (value) {
              if (value.isEmpty) return "ignore path can not be empty";
              return null;
            },
          ),
        ),
        Consumer<RunGitSettingsBackend>(
          builder: (context, settings, _) => SettingListEdit<String>(
            title: "Exclude search folders",
            controller: _excludeSearchFolderController,
            addToolTip: "add new glob to exclude search folders",
            emptyMessage: "Press + to add a new glob",
            onAdd: (value) {
              settings.addIgnorePaths(value);
            },
            onChange: (index, value) {
              settings.modifyIgnorePaths(index, value);
            },
            onDelete: (index) {
              settings.removeIgnorePaths(settings.ignorePaths[index]);
            },
            validator: (value) {
              if (value.isEmpty) return "ignore path can not be empty";
              return null;
            },
          ),
        ),
      ],
    );
  }
}
