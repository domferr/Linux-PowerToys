import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

class RunModel extends ChangeNotifier {
  RunModel._() {
    _visible = kDebugMode;
  }

  static Future<RunModel> init() async {
    RunModel model = RunModel._();

    Size windowSize = const Size(700, 500);
    setWindowMinSize(windowSize);
    setWindowMaxSize(windowSize);

    // force window resize
    model._visible = !model._visible;
    await model.setVisibility(!model.visible);

    return model;
  }

  late bool _visible;
  bool get visible => _visible;

  Future<void> setVisibility(bool visible) async {
    if (visible == _visible) return;

    if (visible) {
      await Future.delayed(const Duration(milliseconds: 10));

      PlatformWindow window = await getWindowInfo();

      Offset center = Offset(window.screen?.frame.width ?? 0, window.screen?.frame.height ?? 0) / 2;
      Offset cornerPos = center - Offset(window.frame.width / 2, window.frame.height / 2);

      setWindowVisibility(visible: true);
      setWindowFrame(Rect.fromLTWH(cornerPos.dx, cornerPos.dy, window.frame.width, window.frame.height));
    } else {
      setWindowVisibility(visible: false);
    }

    _visible = visible;
    notifyListeners();
  }

  void summon() {
    setVisibility(!_visible);
  }
}
