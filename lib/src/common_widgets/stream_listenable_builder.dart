import 'dart:async';

import 'package:flutter/material.dart';

class StreamListenableBuilder<T> extends StatefulWidget {
  /// Creates a [StreamListenableBuilder].
  ///
  /// The [stream] and [builder] arguments must not be null.
  /// The [child] is optional but is good practice to use if part of the widget
  /// subtree does not depend on the value of the [stream].
  const StreamListenableBuilder({
    super.key,
    required this.stream,
    required this.builder,
    required this.initialValue,
    this.child,
  });

  /// The [stream] whose value you depend on in order to build.
  ///
  /// This widget does not ensure that the [stream]'s value is not
  /// null, therefore your [builder] may need to handle null values.
  ///
  /// This [stream] itself must not be null.
  final Stream<T> stream;

  final T initialValue;

  /// A [ValueWidgetBuilder] which builds a widget depending on the
  /// [stream]'s value.
  ///
  /// Can incorporate a [stream] value-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  ///
  /// Must not be null.
  final ValueWidgetBuilder<T> builder;

  /// A [stream]-independent widget which is passed back to the [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree the
  /// [builder] builds depends on the value of the [stream]. For
  /// example, in the case where the [stream] is a [String] and the
  /// [builder] returns a [Text] widget with the current [String] value, there
  /// would be no useful [child].
  final Widget? child;

  @override
  State<StatefulWidget> createState() => _StreamListenableBuilderState<T>();
}

class _StreamListenableBuilderState<T>
    extends State<StreamListenableBuilder<T>> {
  late T value;
  late StreamSubscription<T> streamSubscription;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
    streamSubscription = widget.stream.listen(_valueChanged);
  }

  @override
  void didUpdateWidget(StreamListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget != widget) {
      streamSubscription.cancel();
      value = widget.initialValue;
      widget.stream.listen(_valueChanged);
    }
  }

  @override
  void dispose() {
    streamSubscription.cancel();
    super.dispose();
  }

  void _valueChanged(T newValue) {
    setState(() {
      value = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }
}
