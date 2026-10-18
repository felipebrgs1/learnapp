import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'models.dart';

/// Carrega todos os tópicos listados em `assets/content/index.json`.
/// O conteúdo é pequeno e local, então é lido uma vez na inicialização.
class ContentRepository {
  ContentRepository(this.topics);

  final List<Topic> topics;

  static Future<ContentRepository> load(AssetBundle bundle) async {
    final index = jsonDecode(await bundle.loadString('assets/content/index.json')) as Json;
    final topics = await Future.wait([
      for (final file in index['topics'] as List)
        bundle
            .loadString('assets/content/$file')
            .then((raw) => Topic.fromJson(jsonDecode(raw) as Json)),
    ]);
    return ContentRepository(topics);
  }

  List<String> get categories => {for (final t in topics) t.category}.toList();

  List<Topic> search(String query, {String? category}) {
    final terms = normalize(query).split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return [
      for (final t in topics)
        if ((category == null || t.category == category) &&
            terms.every(t.searchText.contains))
          t,
    ];
  }

  Topic? neighbor(Topic topic, int delta) {
    final i = topics.indexOf(topic) + delta;
    return i >= 0 && i < topics.length ? topics[i] : null;
  }
}

class ContentScope extends InheritedWidget {
  const ContentScope({super.key, required this.repository, required super.child});

  final ContentRepository repository;

  static ContentRepository of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContentScope>()!.repository;

  @override
  bool updateShouldNotify(ContentScope oldWidget) => repository != oldWidget.repository;
}
