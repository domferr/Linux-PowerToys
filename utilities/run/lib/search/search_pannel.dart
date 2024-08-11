import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../plugins/plugins.dart';
import '../search/search.dart';
import '../search/search_plugin.dart';
import '../run.dart';

class RunSearch extends StatefulWidget {
  const RunSearch({super.key, required this.plugins});

  final List<RunPlugin> plugins;

  @override
  State<RunSearch> createState() => _RunSearchState();
}

class _RunSearchState extends State<RunSearch> {
  final TextEditingController _searchController = TextEditingController(text: "");

  final ScrollController _resultScrollcontroller = ScrollController();

  final FocusNode _searchFocus = FocusNode();
  final FocusNode _searchExit = FocusNode();
  final FocusNode _firstResult = FocusNode();
  final FocusNode _resultExit = FocusNode();

  List<SearchResult> results = [];

  String? _last;

  bool _searchesFinished = false;

  late final SearchEngine _engine;

  StreamSubscription? _searchSubscription;

  @override
  void initState() {
    _engine = SearchEngine(plugins: widget.plugins);

    super.initState();
    search();

    Provider.of<RunModel>(context, listen: false).addListener(runListener);
  }

  void runListener() {
    if (context.read<RunModel>().visible) {
      _searchFocus.requestFocus();
    }
  }

  void search() {
    _searchSubscription?.cancel();
    setState(() {
      results.clear();
      _searchesFinished = false;
    });

    _searchSubscription = _engine.search(_searchController.text).listen((result) {
      setState(() {
        results.add(result);
        results.sort();
      });
    })
      ..onDone(() {
        setState(() {
          _searchesFinished = true;
        });
      });
  }

  @override
  void dispose() {
    _searchSubscription?.cancel();
    Provider.of<RunModel>(context).removeListener(runListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
          color: Theme.of(context).colorScheme.background,
        ),
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: KeyboardListener(
                focusNode: _searchExit,
                onKeyEvent: (value) {
                  if (value.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _firstResult.requestFocus();
                    _resultScrollcontroller.jumpTo(0);
                  }
                },
                child: TextField(
                  focusNode: _searchFocus,
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _last,
                    icon: const Icon(Icons.search_rounded),
                    border: InputBorder.none,
                  ),
                  onChanged: (s) {
                    _last = null;
                    search();
                  },
                  onSubmitted: (s) {
                    if (s != "") {
                      setState(() {
                        _last = s;
                        _searchController.clear();
                        _searchFocus.requestFocus();
                      });
                    }
                    _firstResult.nextFocus();
                  },
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _searchesFinished ? 0 : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text("${results.length}"),
                    ),
                  ],
                )),
            Expanded(
              child: KeyboardListener(
                onKeyEvent: (event) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) return;
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) return;

                  _searchFocus.requestFocus();
                },
                focusNode: _resultExit,
                child: Scrollbar(
                  controller: _resultScrollcontroller,
                  thumbVisibility: true,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 19),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: FocusTraversalGroup(
                        policy: OrderedTraversalPolicy(),
                        child: ListView.builder(
                          itemCount: results.length,
                          controller: _resultScrollcontroller,
                          itemBuilder: (context, index) => SearchResultElement(
                            result: results[index],
                            order: index.toDouble(),
                            focusNode: index == 0 ? _firstResult : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResultElement extends StatelessWidget {
  const SearchResultElement({
    required this.result,
    required this.order,
    this.focusNode,
    super.key,
  });

  final SearchResult result;
  final FocusNode? focusNode;
  final double order;

  Widget buildHighlightedText(
    String text,
    List<(int, int)> highlightSections, {
    TextStyle? textStyle,
    Color highlightColor = Colors.purple,
  }) {
    TextStyle? highlightStyle = textStyle?.copyWith(
      color: highlightColor,
      fontWeight: FontWeight.bold,
    );

    int pos = 0;
    List<TextSpan> textSections = [];
    for ((int, int) section in highlightSections) {
      textSections.add(TextSpan(
        text: text.substring(pos, section.$1),
        style: textStyle,
      ));
      textSections.add(TextSpan(
        text: text.substring(section.$1, section.$2),
        style: highlightStyle,
      ));

      pos = section.$2;
    }

    textSections.add(TextSpan(
      text: text.substring(pos),
      style: textStyle,
    ));

    return RichText(
      text: TextSpan(children: textSections),
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: Material(
        type: MaterialType.button,
        color: Theme.of(context).colorScheme.background,
        child: InkWell(
          canRequestFocus: true,
          focusNode: focusNode,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.4),
          onTap: () {
            if (result.actions.isEmpty) return;

            result.actions[0].callAction(context);
          },
          child: Container(
            height: 50,
            padding: const EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: result.icon,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildHighlightedText(
                        result.title,
                        result.titleHighlightSections,
                        textStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        highlightColor: Theme.of(context).colorScheme.primary,
                      ),
                      buildHighlightedText(
                        result.subTitle,
                        result.subTitleHighlightSections,
                        textStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        highlightColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: result.actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
