import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnapp/content/models.dart';
import 'package:learnapp/content/repository.dart';
import 'package:learnapp/main.dart';
import 'package:learnapp/ui/topic_page.dart';

ContentRepository loadFromDisk() {
  final index = jsonDecode(File('assets/content/index.json').readAsStringSync()) as Json;
  return ContentRepository([
    for (final f in index['topics'] as List)
      Topic.fromJson(jsonDecode(File('assets/content/$f').readAsStringSync()) as Json),
  ]);
}

void main() {
  test('todo o conteúdo é válido', () {
    final repo = loadFromDisk();
    expect(repo.topics, isNotEmpty);
    final ids = <String>{};
    for (final t in repo.topics) {
      expect(ids.add(t.id), isTrue, reason: 'id duplicado: ${t.id}');
      final sectionIds = {for (final s in t.sections) s.id};
      expect(sectionIds.length, t.sections.length, reason: 'seção duplicada em ${t.id}');
      for (final s in t.sections) {
        expect(s.blocks, isNotEmpty, reason: '${t.id}/${s.id} vazia');
        for (final b in s.blocks) {
          if (b is DiagramBlock) {
            for (final n in b.nodes) {
              expect(n.x + n.w <= b.cols && n.y + n.h <= b.rows, isTrue,
                  reason: '${t.id}: nó ${n.id} fora da grade');
            }
          }
          if (b is TableBlock) {
            for (final r in b.rows) {
              expect(r.length, b.headers.length, reason: '${t.id}: linha de tabela com colunas erradas');
            }
          }
        }
      }
    }
  });

  test('séries têm partes 1..N sem buracos, em sequência no índice', () {
    final repo = loadFromDisk();
    for (final t in repo.topics.where((t) => t.series != null)) {
      final parts = repo.seriesOf(t);
      expect([for (final p in parts) p.part], [for (var i = 1; i <= parts.length; i++) i],
          reason: 'série ${t.series}');
      final first = repo.topics.indexOf(parts.first);
      expect([for (final p in parts) repo.topics.indexOf(p) - first], [for (var i = 0; i < parts.length; i++) i],
          reason: 'partes de ${t.series} fora de sequência no index.json');
    }
  });

  test('busca ignora acentos e combina termos', () {
    final repo = loadFromDisk();
    expect(repo.search('reconciliacao').map((t) => t.id), contains('gitops'));
    expect(repo.search('rebase git').map((t) => t.id), ['git-internals']);
    expect(repo.search('xyzzy'), isEmpty);
  });

  testWidgets('cada tópico renderiza sem erros', (tester) async {
    final repo = loadFromDisk();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(LearnApp(repository: repo));
    expect(find.text('GitOps'), findsOneWidget);

    for (final t in repo.topics) {
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.push(PageRouteBuilder<void>(pageBuilder: (_, _, _) => TopicPage(topic: t)));
      await tester.pumpAndSettle();
      // Rola até o fim para construir e pintar todos os blocos.
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -100000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: t.id);
      nav.pop();
      await tester.pumpAndSettle();
    }
  });
}
