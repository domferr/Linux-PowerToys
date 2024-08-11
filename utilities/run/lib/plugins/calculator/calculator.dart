import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gsettings/gsettings.dart';
import 'package:math_expressions/math_expressions.dart';

import '../../plugins/plugins.dart';
import '../../search/search_plugin.dart';

class CalculatorPlugin extends RunPlugin {
  CalculatorPlugin()
      : super(
          name: "calculator",
          activationPrefix: "=",
          settings: GSettings("com.github.linux-powertoys.utilities.run.calc"),
        );

  @override
  Future<void> fetch() async {}

  @override
  Stream<SearchEntry> find(String needle) async* {
    Parser parser = Parser();
    ContextModel context = ContextModel();
    context.bindVariable(Variable("pi"), Number(pi));
    context.bindVariable(Variable("e"), Number(e));

    try {
      Expression expression = parser.parse(needle);
      double result = expression.evaluate(EvaluationType.REAL, context);
      yield SearchResult.fromSearchEntry(
        rating: 0.8,
        entry: SearchEntry(
          title: result.toString(),
          subTitle: needle,
          icon: const Icon(Icons.calculate_outlined),
          actions: [
            RunAction(
              action: () {
                Clipboard.setData(ClipboardData(text: result.toString()));
              },
              content: const Icon(Icons.open_in_new),
            )
          ],
        ),
      );
    } catch (_) {}
  }
}
