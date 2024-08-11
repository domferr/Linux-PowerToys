import 'package:flutter/material.dart';

import '../../backend_api/utilities/run/run_plugin_backend.dart';
import '../../common_widgets/setting_wrapper.dart';

/// Provides the settings for the activation prefix and enabled state for each run plugin
class RunPluginSettingsWrapper extends StatefulWidget {
  const RunPluginSettingsWrapper({
    super.key,
    required this.title,
    required this.description,
    required this.leading,
    required this.children,
    this.error,
    this.onEnableChange,
    required this.settings,
  });

  /// title of the run plugin
  final String title;

  /// description of the run plugin
  final String description;

  /// icon of the run plugin
  final Widget leading;

  /// children containing the run plugin specific settings
  final List<Widget> children;

  /// run plugin error is displayed if not null
  final String? error;

  /// gets called when the user changes the enabled-state of the run-plugin
  final void Function(bool)? onEnableChange;

  /// settings of the run plugin
  final RunPluginSettings settings;

  @override
  State<RunPluginSettingsWrapper> createState() => _RunPluginSettingsWrapperState();
}

class _RunPluginSettingsWrapperState extends State<RunPluginSettingsWrapper> with TickerProviderStateMixin {
  final TextEditingController _activationPrefixController = TextEditingController();

  String? _activationPrefixError;

  @override
  void initState() {
    widget.settings.addListener(_textSynchronization);

    super.initState();
  }

  void _textSynchronization() {
    _activationPrefixController.text = widget.settings.activationPrefix;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) => SettingCardExpandable(
        title: widget.title,
        description: widget.description,
        leading: widget.leading,
        error: widget.settings.error,
        onGroupEnableChange: (enable) => widget.settings.enable = enable,
        groupEnabled: widget.settings.enable,
        children: [
          SettingTextField(
            title: "Activation Prefix",
            controller: _activationPrefixController,
            error: _activationPrefixError,
            onSubmitted: (value) {
              if (_activationPrefixError == null) widget.settings.activationPrefix = value;
            },
            onChanged: (value) {
              String? error;

              if (value.isEmpty) error = "activation prefix can not be empty";

              setState(() {
                _activationPrefixError = error;
              });
            },
          ),
          if (widget.children.isNotEmpty) const Divider(),
          if (widget.error == null) ...widget.children,
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.settings.removeListener(_textSynchronization);
    super.dispose();
  }
}
