import 'dart:math' as math;

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'custom_card.dart';

const verticalPadding = 20.0;

class SettingWrapper extends StatelessWidget {
  const SettingWrapper({
    super.key,
    required this.child,
    required this.enabled,
    this.title,
  });

  final Widget child;
  final bool enabled;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title != null ? SettingHeader(title: title!) : const SizedBox.shrink(),
        const SizedBox(height: 8.0),
        CustomCard(
          child: child,
        ),
      ],
    );
  }
}

extension _SettingTextStyleExtension on TextStyle {
  TextStyle enabled(bool enabled) {
    if (enabled) return copyWith();

    return copyWith(color: color?.withAlpha(90));
  }
}

/// Theme for settings elements automatically grays out disabled section
class SettingsTheme extends ThemeExtension<SettingsTheme> {
  SettingsTheme({
    this.textBodyMedium,
    this.textTitleMedium,
    this.textLabelMedium,
    this.textTitleLarge,
    this.intend = 0,
    this.enabled = true,
    Color? disabledColor,
  }) : disabledColor = disabledColor ?? Colors.grey;

  /// automatically generates the settings theme from a given [context] and [enable] state
  factory SettingsTheme.fromContext(
    BuildContext context, {
    bool enabled = true,
    Color? disabledColor,
    double intend = 0,
  }) {
    enabled &= SettingsTheme.of(context)?.enabled != false;

    TextTheme baseTheme = Theme.of(context).textTheme;

    return SettingsTheme(
      enabled: enabled,
      intend: (SettingsTheme.of(context)?.intend ?? 0) + intend,
      disabledColor: disabledColor ?? SettingsTheme.of(context)?.disabledColor,
      textBodyMedium: baseTheme.bodyMedium?.enabled(enabled),
      textTitleMedium: baseTheme.titleMedium?.enabled(enabled),
      textLabelMedium: baseTheme.labelMedium?.enabled(enabled),
      textTitleLarge: baseTheme.titleLarge?.enabled(enabled),
    );
  }

  final TextStyle? textBodyMedium;
  final TextStyle? textLabelMedium;
  final TextStyle? textTitleMedium;
  final TextStyle? textTitleLarge;

  final Color disabledColor;

  final bool enabled;
  final double intend;

  @override
  SettingsTheme copyWith() {
    return SettingsTheme();
  }

  @override
  ThemeExtension<SettingsTheme> lerp(SettingsTheme other, double t) {
    return SettingsTheme(
      textBodyMedium: TextStyleTween(
        begin: textBodyMedium,
        end: other.textBodyMedium,
      ).lerp(t),
      textTitleMedium: TextStyleTween(
        begin: textTitleMedium,
        end: other.textTitleMedium,
      ).lerp(t),
      textLabelMedium: TextStyleTween(
        begin: textLabelMedium,
        end: other.textLabelMedium,
      ).lerp(t),
      textTitleLarge: TextStyleTween(
        begin: textTitleLarge,
        end: other.textTitleLarge,
      ).lerp(t),
    );
  }

  static SettingsTheme? of(BuildContext context) => Theme.of(context).extension<SettingsTheme>();
}

/// A setting widget that separates setting groups
class SettingHeader extends StatefulWidget {
  const SettingHeader({
    super.key,
    required this.title,
  });

  /// title of the setting header
  final String title;

  @override
  State<SettingHeader> createState() => _SettingHeaderState();
}

class _SettingHeaderState extends State<SettingHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: verticalPadding, bottom: 8.0),
      child: Text(
        widget.title,
        textAlign: TextAlign.start,
        style: SettingsTheme.of(context)?.textTitleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// A widget that combines multiple setting elements into one expandable card with an optional global enable
class SettingCardExpandable extends StatefulWidget {
  const SettingCardExpandable({
    required this.title,
    required this.children,
    this.description,
    this.leading,
    this.error,
    this.onGroupEnableChange,
    this.groupEnabled,
    this.alwaysExpanded = false,
    super.key,
  });

  /// The name of the setting group
  final String title;

  /// The name of the description group
  final String? description;

  /// A widget to display before the title.
  ///
  /// Typically an [Icon] or a [CircleAvatar] widget.
  final Widget? leading;

  /// children of the settings group
  ///
  /// if the group is disabled the [SettingsTheme] is modified for the children
  final List<Widget> children;

  /// Text that appears below the [description].
  final String? error;

  /// wether the group should be always expanded
  final bool alwaysExpanded;

  /// gets called if the user disables/enables the settings group
  ///
  /// if null the group is always enabled
  final ValueChanged<bool>? onGroupEnableChange;

  /// wether the group is enabled (true), disabled(false) or loading(null)
  ///
  /// if [onGroupEnableChange] is `null` the [groupEnabled] has no effect
  final bool? groupEnabled;

  @override
  State<SettingCardExpandable> createState() => _SettingCardExpandableState();
}

class _SettingCardExpandableState extends State<SettingCardExpandable> with TickerProviderStateMixin {
  final ExpandableController expandableController = ExpandableController();

  late AnimationController _expandAnimationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    _expandAnimationController = AnimationController(vsync: this, duration: Durations.medium1);

    _expandAnimation = Tween<double>(begin: math.pi / 2, end: -math.pi / 2).animate(_expandAnimationController);

    super.initState();
  }

  bool get _intractable => widget.error == null && SettingsTheme.of(context)?.enabled == true;

  bool get _expandable => _intractable && widget.children.isNotEmpty && !widget.alwaysExpanded;

  bool get _displayThumb => widget.children.isNotEmpty && !widget.alwaysExpanded;

  void Function()? get _toggleExpand => _expandable ? _setExpanded : null;

  void _setExpanded({bool? expanded}) {
    expanded ??= !expandableController.expanded;

    expandableController.expanded = expanded;
    if (expanded) {
      _expandAnimationController.forward();
    } else {
      _expandAnimationController.reverse();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      const Divider(),
      ...widget.children,
    ];

    if (SettingsTheme.of(context)?.enabled != true && expandableController.expanded) {
      _setExpanded(expanded: false);
    }

    return CustomCard(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _toggleExpand,
            child: Row(
              children: [
                if (widget.leading != null)
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 20),
                    height: 32,
                    width: 32,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        SettingsTheme.of(context)?.enabled == true
                            ? Colors.transparent
                            : SettingsTheme.of(context)?.disabledColor ?? Colors.grey,
                        BlendMode.srcATop,
                      ),
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: widget.leading,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.title,
                        style: SettingsTheme.of(context)?.textTitleMedium,
                      ),
                      if (widget.description != null)
                        Text(
                          widget.description!,
                          style: SettingsTheme.of(context)?.textBodyMedium,
                        ),
                      if (widget.error != null)
                        Text(
                          widget.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                    ],
                  ),
                ),
                if (widget.onGroupEnableChange != null)
                  widget.groupEnabled == null
                      ? const CircularProgressIndicator()
                      : Switch(
                          value: widget.groupEnabled!,
                          onChanged: _intractable ? widget.onGroupEnableChange : null,
                        ),
                if (_displayThumb)
                  IconButton(
                    onPressed: _toggleExpand,
                    icon: AnimatedBuilder(
                      animation: _expandAnimation,
                      builder: (_, child) => Transform.rotate(
                        angle: _expandAnimation.value,
                        child: child,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
              ],
            ),
          ),
          if (_expandable || _expandAnimationController.isAnimating)
            Expandable(
              controller: expandableController,
              collapsed: Container(),
              theme: const ExpandableThemeData(
                alignment: Alignment.topCenter,
              ),
              expanded: Theme(
                data: Theme.of(context).copyWith(
                  extensions: [
                    SettingsTheme.fromContext(
                      context,
                      enabled: widget.groupEnabled == true,
                      intend: 62,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          if (widget.alwaysExpanded)
            Theme(
              data: Theme.of(context).copyWith(
                extensions: [
                  SettingsTheme.fromContext(
                    context,
                    enabled: widget.groupEnabled == true,
                    intend: 62,
                  ),
                ],
              ),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }
}

/// A controller for a [SettingListEdit]
///
/// if you modify the [elements] property, the setting list edit will be notified and will update itself appropriately.
class SettingListEditController<T extends Object> extends ChangeNotifier {
  SettingListEditController({
    required List<T> elements,
  }) : _elements = elements {
    _entries = _elements.map((value) => _FileListSettingEntry<T>(value: value)).toList();
  }

  final List<T> _elements;
  set elements(List<T> elements) {
    _elements.clear();
    _entries.clear();

    _elements.addAll(elements);
    _entries.addAll(_elements.map((value) => _FileListSettingEntry<T>(value: value)));
  }

  late final List<_FileListSettingEntry<T>> _entries;
}

class _FileListSettingEntry<T extends Object> {
  _FileListSettingEntry({required T value}) : textController = TextEditingController(text: value.toString()) {
    focusNode = FocusNode();
  }

  late FocusNode focusNode;
  final TextEditingController textController;
}

/// Widget for modifying a given list
class SettingListEdit<T extends Object> extends StatefulWidget {
  const SettingListEdit({
    required this.title,
    required this.controller,
    this.onAdd,
    this.onChange,
    this.onDelete,
    this.validator,
    this.addToolTip,
    this.emptyMessage,
    super.key,
  });

  /// title of the list
  final String title;

  /// controls the setting list
  final SettingListEditController<T> controller;

  /// function which gets called when the user adds a element
  ///
  /// if a [validator] is provided only valid adds are submitted
  final void Function(String)? onAdd;

  /// function which gets called when the user changes a element
  ///
  /// if a [validator] is provided only valid changes are submitted
  final void Function(int, String)? onChange;

  /// function for validate the user input
  ///
  /// if `null` gets returned the input is treaded as valid else the return value gets displayed
  final String? Function(String)? validator;

  /// function which gets called if a user deletes a list entry
  final void Function(int)? onDelete;

  /// tool tip for the add button
  final String? addToolTip;

  /// text which should be displayed if the list is empty
  final String? emptyMessage;

  @override
  State<SettingListEdit> createState() => _SettingListEditState();
}

class _SettingListEditState extends State<SettingListEdit> {
  final FocusNode _pendingAddFocusNode = FocusNode();
  final TextEditingController _pendingAddTextController = TextEditingController();

  bool _pendingAdd = false;

  @override
  void initState() {
    super.initState();
  }

  void _pendingAddFinish() async {
    if (widget.validator?.call(_pendingAddTextController.text) != null) {
      if (_pendingAddTextController.text.isNotEmpty) return;

      _pendingAddCancel();
      return;
    }

    // wait for possible delete button to click
    await Future.delayed(const Duration(milliseconds: 250));

    if (!_pendingAdd) return;

    _pendingAdd = false;
    widget.onAdd?.call(_pendingAddTextController.text);
    _pendingAddTextController.clear();
  }

  void _pendingAddCancel() {
    _pendingAdd = false;
    setState(() {
      _pendingAddTextController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: SettingsTheme.of(context)?.intend,
            ),
            Text(
              widget.title,
              style: SettingsTheme.of(context)?.textTitleMedium,
            ),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: widget.addToolTip,
              onPressed: widget.onAdd != null && SettingsTheme.of(context)?.enabled == true
                  ? () {
                      setState(() {
                        _pendingAdd = true;
                      });
                      _pendingAddFocusNode.requestFocus();
                    }
                  : null,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => Column(
            children: [
              for (int i = 0; i < widget.controller._entries.length; i++)
                _SettingListEditElement(
                  controller: widget.controller._entries[i].textController,
                  focusNode: widget.controller._entries[i].focusNode,
                  validator: widget.validator,
                  onSubmitted: (value) => widget.onChange?.call(i, value),
                  onDelete: () => widget.onDelete?.call(i),
                ),
              if (_pendingAdd)
                Focus(
                  child: _SettingListEditElement(
                    focusNode: _pendingAddFocusNode,
                    controller: _pendingAddTextController,
                    onSubmitted: (value) => _pendingAddFinish(),
                    onDelete: _pendingAddCancel,
                    validator: widget.validator,
                  ),
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) _pendingAddFinish();
                  },
                ),
              if (widget.controller._entries.isEmpty && !_pendingAdd && widget.emptyMessage != null)
                Text(
                  widget.emptyMessage!,
                  style: SettingsTheme.of(context)?.textLabelMedium,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// element for the [SettingListEdit]
class _SettingListEditElement extends StatefulWidget {
  const _SettingListEditElement({
    required this.onDelete,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final void Function() onDelete;
  final void Function(String)? onSubmitted;
  final String? Function(String)? validator;

  @override
  State<_SettingListEditElement> createState() => _SettingListEditElementState();
}

class _SettingListEditElementState extends State<_SettingListEditElement> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.only(
        left: (SettingsTheme.of(context)?.intend ?? 0) + 8,
        top: 4,
        bottom: 4,
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 12,
          top: 2,
          bottom: 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                focusNode: widget.focusNode,
                controller: widget.controller,
                onSubmitted: _error == null ? widget.onSubmitted : null,
                onChanged: (value) {
                  setState(() {
                    _error = widget.validator?.call(value);
                  });
                },
                decoration: InputDecoration(
                  enabled: SettingsTheme.of(context)?.enabled == true,
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(2),
                  errorText: _error,
                ),
              ),
            ),
            IconButton(
              onPressed: SettingsTheme.of(context)?.enabled == true ? widget.onDelete : null,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingContainer extends StatelessWidget {
  const SettingContainer({super.key, required this.title, this.padding, required this.child});

  /// title of the setting
  final String title;

  /// The amount of space by which to inset the content
  final EdgeInsets? padding;

  /// child of the setting container displayed right of the title
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: SettingsTheme.of(context)?.intend,
          ),
          Text(
            title,
            style: SettingsTheme.of(context)?.textTitleMedium,
          ),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

/// Creates a setting text field
class SettingTextField extends StatelessWidget {
  SettingTextField({
    required this.title,
    TextEditingController? controller,
    this.onSubmitted,
    this.onChanged,
    this.padding,
    this.error,
    super.key,
  }) : controller = controller ?? TextEditingController();

  /// title of the setting
  final String title;

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own [TextEditingController].
  final TextEditingController controller;

  /// Text that appears below the [InputDecorator.child] and the border.
  ///
  /// If non-null, the border's color animates to red
  final String? error;

  /// Called when the user initiates a change to the TextField's value: when they have inserted or deleted text.
  final ValueChanged<String>? onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  ///
  /// Note: this includes also leaving the textfield
  final ValueChanged<String>? onSubmitted;

  /// The amount of space by which to inset the content
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return SettingContainer(
      title: title,
      child: SizedBox(
        width: 200,
        child: Focus(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              enabled: SettingsTheme.of(context)?.enabled == true,
              errorText: error,
              filled: true,
              isDense: true,
            ),
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
          ),
          onFocusChange: (hasFocus) {
            if (hasFocus) return;
            if (error != null) return;

            onSubmitted?.call(controller.text);
          },
        ),
      ),
    );
  }
}

extension _SettingKeyExtension on LogicalKeyboardKey {
  bool get isControlKey {
    if (LogicalKeyboardKey.controlLeft.keyId <= keyId && keyId <= LogicalKeyboardKey.metaRight.keyId) return true;
    if (keyId == LogicalKeyboardKey.control.keyId) return true;
    if (keyId == LogicalKeyboardKey.alt.keyId) return true;
    if (keyId == LogicalKeyboardKey.shift.keyId) return true;
    if (keyId == LogicalKeyboardKey.meta.keyId) return true;

    return false;
  }

  String get userFriendlyKeyName => switch (LogicalKeyboardKey(keyId)) {
        LogicalKeyboardKey.control => "ctrl",
        LogicalKeyboardKey.controlLeft => "ctrl",
        LogicalKeyboardKey.controlRight => "ctrl",
        LogicalKeyboardKey.alt => "alt",
        LogicalKeyboardKey.altLeft => "alt",
        LogicalKeyboardKey.altRight => "alt",
        LogicalKeyboardKey.shift => "shift",
        LogicalKeyboardKey.shiftLeft => "shift",
        LogicalKeyboardKey.shiftRight => "shift",
        LogicalKeyboardKey.meta => "meta",
        LogicalKeyboardKey.metaLeft => "meta",
        LogicalKeyboardKey.metaRight => "meta",
        LogicalKeyboardKey.space => "space",
        _ => keyLabel,
      };

  static int bindingKeyOrder(LogicalKeyboardKey a, LogicalKeyboardKey b) {
    if (a.isControlKey == b.isControlKey) return a.keyId.compareTo(b.keyId);
    if (a.isControlKey && !b.isControlKey) return -1;
    return 1;
  }
}

class _SettingKeyDisplay extends StatelessWidget {
  const _SettingKeyDisplay({
    required this.logicalKey,
    required this.enabled,
    this.height,
  });

  final LogicalKeyboardKey logicalKey;

  final double? height;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? Theme.of(context).colorScheme.inversePrimary
            : Theme.of(context).colorScheme.inversePrimary.withAlpha(90),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(
        fit: BoxFit.fitHeight,
        child: Text(logicalKey.userFriendlyKeyName),
      ),
    );
  }
}

class _SettingKeyBindingDisplay extends StatelessWidget {
  _SettingKeyBindingDisplay({
    List<LogicalKeyboardKey>? logicalKeys,
    this.height,
    this.enabled = true,
  }) : _logicalKeys = List.from(logicalKeys ?? []);

  final List<LogicalKeyboardKey> _logicalKeys;

  final double? height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    List<Widget> keyWidgets = [];

    _logicalKeys.sort(_SettingKeyExtension.bindingKeyOrder);

    for (int i = 0; i < _logicalKeys.length; i++) {
      keyWidgets.add(_SettingKeyDisplay(
        logicalKey: _logicalKeys[i],
        height: height,
        enabled: enabled,
      ));
      if (i < _logicalKeys.length - 1) {
        keyWidgets.add(Text(
          "+",
          style: SettingsTheme.of(context)?.textTitleMedium,
        ));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keyWidgets,
    );
  }
}

class _SettingsKeyBindingDialog extends StatefulWidget {
  const _SettingsKeyBindingDialog({required this.keyBinding});

  final List<LogicalKeyboardKey> keyBinding;

  @override
  State<_SettingsKeyBindingDialog> createState() => __SettingsKeyBindingDialogState();
}

class __SettingsKeyBindingDialogState extends State<_SettingsKeyBindingDialog> {
  final FocusNode _node = FocusNode();
  final List<LogicalKeyboardKey> _keys = [];

  List<LogicalKeyboardKey> _lastValidBinding = [];
  bool _validKeybinding = false;

  @override
  void initState() {
    super.initState();

    _node.requestFocus();

    _lastValidBinding = widget.keyBinding;
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is KeyUpEvent) {
      _keys.remove(event.logicalKey);
    }

    if (event is KeyDownEvent && _keys.where((key) => !key.isControlKey).isEmpty) {
      _keys.add(event.logicalKey);
    }

    int controlKeys = _keys.where((key) => key.isControlKey).length;
    int normalKeys = _keys.length - controlKeys;

    _validKeybinding = normalKeys == 1 && controlKeys > 0;

    if (_validKeybinding) {
      _lastValidBinding = List.from(_keys);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 400,
          height: 250,
          child: KeyboardListener(
            focusNode: _node,
            onKeyEvent: _onKeyEvent,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "New Accelerator",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _SettingKeyBindingDisplay(
                    logicalKeys: _keys.isEmpty ? _lastValidBinding : _keys,
                    height: 50,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _validKeybinding || (_lastValidBinding.isNotEmpty && _keys.isEmpty)
                              ? () {
                                  Navigator.pop(context, _lastValidBinding);
                                }
                              : null,
                          child: const Text("ok"),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("cancel"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A controller for a [SettingKeyBinding]
///
/// if you modify the [keys] property, the setting of the keybinding will be
/// notified and will update itself appropriately.
class SettingKeyBindingController extends ChangeNotifier {
  SettingKeyBindingController({List<LogicalKeyboardKey>? keys}) : _keys = keys ?? [];

  List<LogicalKeyboardKey> _keys;
  List<LogicalKeyboardKey> get keys => List.unmodifiable(_keys);
  set keys(List<LogicalKeyboardKey> keys) {
    _keys = keys;
    notifyListeners();
  }
}

// setting for keybindings
class SettingKeyBinding extends StatefulWidget {
  SettingKeyBinding({
    super.key,
    this.onChange,
    required this.title,
    SettingKeyBindingController? controller,
  }) : controller = controller ?? SettingKeyBindingController();

  /// title of the keybinding
  final String title;

  /// function gets called when the user changes the keybinding
  final ValueChanged<List<LogicalKeyboardKey>>? onChange;

  /// Controls the keybinding being edited.
  ///
  /// If null, this widget will create its own [SettingKeyBindingController].
  final SettingKeyBindingController controller;

  @override
  State<SettingKeyBinding> createState() => _SettingKeyBindingState();
}

class _SettingKeyBindingState extends State<SettingKeyBinding> {
  void _onUserKeyChangeRequest() async {
    List<LogicalKeyboardKey>? binding = await showDialog(
      context: context,
      builder: (BuildContext context) => _SettingsKeyBindingDialog(
        keyBinding: widget.controller.keys,
      ),
    );

    if (binding == null) return;

    widget.onChange?.call(binding);
    widget.controller.keys = binding;
  }

  bool get enabled => widget.onChange != null && SettingsTheme.of(context)?.enabled != false;

  @override
  Widget build(BuildContext context) {
    return SettingContainer(
      title: widget.title,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => InkWell(
          onTap: enabled ? _onUserKeyChangeRequest : null,
          child: _SettingKeyBindingDisplay(
            logicalKeys: widget.controller.keys,
            height: 32,
            enabled: enabled,
          ),
        ),
      ),
    );
  }
}
