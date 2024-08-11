import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';

import '../plugins/plugins.dart';
import '../search/search_plugin.dart';

class SearchEngine {
  SearchEngine({required this.plugins}) {
    _init();
  }

  final List<RunPlugin> plugins;

  void _init() {
    for (var plugin in plugins) {
      plugin.fetch();
    }
  }

  Stream<SearchResult> search(String text) {
    String? activationPrefix;

    if (text.isNotEmpty &&
        plugins.where((plugin) => plugin.enable).map((plugin) => plugin.activationPrefix).contains(text[0])) {
      activationPrefix = text[0];
    }

    if (activationPrefix != null) {
      text = text.substring(1);
    }

    return plugins
        .where((plugin) => plugin.enable)
        .where((plugin) => activationPrefix == null || plugin.activationPrefix == activationPrefix)
        .map((plugin) => plugin.find(text))
        .reduce((results1, results2) => StreamGroup.merge([results1, results2]))
        .map((searchEntry) => searchEntry is SearchResult ? searchEntry : standardSearch(searchEntry, text))
        .where((searchResult) => searchResult.rating > 0.2);
  }

  static List<(int, int)> _findOccurrences(String haystack, String needle) {
    List<(int, int)> occurrences = [];
    int index = 0;

    while (index < haystack.length) {
      index = haystack.indexOf(needle, index);

      if (index == -1) break;

      occurrences.add((index, index + needle.length));
      index += needle.length;
    }

    return occurrences;
  }

  static int _sortOccurrences((int, int) occurrenceA, (int, int) occurrenceB) {
    int result = occurrenceA.$1.compareTo(occurrenceB.$1);
    if (result != 0) return result;
    return occurrenceA.$2.compareTo(occurrenceB.$2);
  }

  static List<(int, int)> _simplifyHighlightSections(List<(int, int)> highlightSections) {
    List<(int, int)> sections = [];
    int pos = -1;

    highlightSections.sort(_sortOccurrences);

    for ((int, int) section in highlightSections) {
      if (section.$2 <= pos) continue;

      if (section.$1 <= pos) {
        sections.last = (sections.last.$1, section.$2);
        pos = section.$2;
        continue;
      }

      pos = section.$2;
      sections.add(section);
    }

    return sections;
  }

  static double _lengthAdjustedRatingWeight(int length) {
    return pow(length / 3.0, 2).toDouble();
  }

  static SearchResult standardSearch(SearchEntry entry, String searchTest) {
    const double subtitleWight = 0.4;
    const double titleWight = 0.6;

    List<(int, int)> titleHighlightSections = [];
    List<(int, int)> subtitleHighlightSections = [];
    double subtitleRating = 0;
    double titleRating = 0;

    searchTest = searchTest.toLowerCase();

    List<String> searchParts = searchTest.split(" ").where((part) => part.isNotEmpty).toList();
    // ToDo: minimize rating of single occurrences
    for (String searchPart in searchParts) {
      List<(int, int)> titleOccurrences = _findOccurrences(entry.title.toLowerCase(), searchPart);
      List<(int, int)> subtitleOccurrences = _findOccurrences(entry.subTitle.toLowerCase(), searchPart);

      titleHighlightSections.addAll(titleOccurrences);
      titleRating += titleOccurrences.length / searchParts.length * _lengthAdjustedRatingWeight(searchPart.length);

      subtitleHighlightSections.addAll(subtitleOccurrences);
      subtitleRating +=
          subtitleOccurrences.length / searchParts.length * _lengthAdjustedRatingWeight(searchPart.length);
    }

    titleRating = titleRating.clamp(0, 1);
    subtitleRating = subtitleRating.clamp(0, 1);
    double rating = subtitleRating * subtitleWight + titleRating * titleWight;

    return SearchResult.fromSearchEntry(
      entry: entry,
      rating: rating,
      highlightSections: _simplifyHighlightSections(titleHighlightSections),
      subTitleHighlightSections: _simplifyHighlightSections(subtitleHighlightSections),
    );
  }
}
