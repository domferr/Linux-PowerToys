import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../run.dart';

class SearchEntry implements Comparable<SearchEntry> {
  const SearchEntry({
    required this.title,
    required this.subTitle,
    required this.icon,
    this.actions = const [],
  });

  /// title of the search result
  final String title;

  /// subtitle of the search result
  final String subTitle;

  /// icon of the search results
  final Widget icon;

  /// actions of the search results this should be a list of Buttons
  final List<RunAction> actions;

  @override
  int compareTo(SearchEntry other) {
    int result = title.compareTo(other.title);
    if (result != 0) return result;

    return subTitle.compareTo(subTitle);
  }
}

class RunAction extends StatelessWidget {
  const RunAction({
    super.key,
    required void Function() action,
    required this.content,
  }) : _action = action;

  final Widget content;

  final void Function() _action;

  void callAction(BuildContext context) {
    context.read<RunModel>().setVisibility(false);
    _action();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => callAction(context),
      icon: content,
    );
  }
}

class SearchResult extends SearchEntry {
  SearchResult._({
    required super.title,
    required super.subTitle,
    required super.icon,
    super.actions,
    required this.rating,
    this.titleHighlightSections = const [],
    this.subTitleHighlightSections = const [],
  });

  factory SearchResult.fromSearchEntry({
    required SearchEntry entry,
    required double rating,
    List<(int, int)> highlightSections = const [],
    List<(int, int)> subTitleHighlightSections = const [],
  }) {
    return SearchResult._(
      title: entry.title,
      subTitle: entry.subTitle,
      icon: entry.icon,
      actions: entry.actions,
      rating: rating,
      titleHighlightSections: highlightSections,
      subTitleHighlightSections: subTitleHighlightSections,
    );
  }

  final double rating;
  final List<(int, int)> titleHighlightSections;
  final List<(int, int)> subTitleHighlightSections;

  @override
  int compareTo(covariant SearchResult other) {
    double diff = other.rating - rating;

    if (diff.abs() > 0.1) {
      if (diff > 0) return diff.ceil();
      return diff.floor();
    }

    return super.compareTo(other);
  }
}
