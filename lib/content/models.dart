/// Modelo de conteúdo. Cada tópico é um arquivo JSON em `assets/content/`
/// composto por seções, e cada seção por blocos tipados (`type`).
library;

typedef Json = Map<String, dynamic>;

class Topic {
  Topic({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.level,
    required this.minutes,
    required this.updated,
    required this.tags,
    required this.sections,
    this.series,
    this.part,
  });

  final String id;
  final String title;
  final String summary;
  final String category;
  final String level;
  final int minutes;
  final String updated;
  final List<String> tags;
  final List<Section> sections;

  /// Guias longos são quebrados em partes: tópicos com o mesmo `series`
  /// formam uma trilha ordenada por `part` (1, 2, 3…).
  final String? series;
  final int? part;

  factory Topic.fromJson(Json json) => Topic(
    id: json['id'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    category: json['category'] as String,
    level: json['level'] as String? ?? 'Intermediário',
    minutes: json['minutes'] as int,
    updated: json['updated'] as String,
    tags: _strings(json['tags']),
    series: json['series'] as String?,
    part: json['part'] as int?,
    sections: [
      for (final s in json['sections'] as List) Section.fromJson(s as Json),
    ],
  );

  /// Texto indexável para a busca.
  late final String searchText = normalize(
    [
      title,
      summary,
      category,
      ?series,
      ...tags,
      for (final s in sections) s.title,
    ].join(' '),
  );
}

class Section {
  Section({required this.id, required this.title, required this.blocks});

  final String id;
  final String title;
  final List<Block> blocks;

  factory Section.fromJson(Json json) => Section(
    id: json['id'] as String,
    title: json['title'] as String,
    blocks: [for (final b in json['blocks'] as List) Block.fromJson(b as Json)],
  );
}

sealed class Block {
  const Block();

  factory Block.fromJson(Json json) => switch (json['type']) {
    'p' => ParagraphBlock(json['text'] as String),
    'h' => SubheadingBlock(json['text'] as String),
    'list' => ListBlock(
      _strings(json['items']),
      ordered: json['ordered'] as bool? ?? false,
    ),
    'code' => CodeBlock(
      code: (json['code'] as String).trimRight(),
      lang: json['lang'] as String? ?? 'text',
      file: json['file'] as String?,
    ),
    'callout' => CalloutBlock(
      variant: CalloutVariant.values.byName(json['variant'] as String? ?? 'note'),
      title: json['title'] as String?,
      text: json['text'] as String,
    ),
    'table' => TableBlock(
      headers: _strings(json['headers']),
      rows: [for (final r in json['rows'] as List) _strings(r)],
    ),
    'steps' => StepsBlock([
      for (final s in json['items'] as List)
        TitledText((s as Json)['title'] as String, s['text'] as String),
    ]),
    'terms' => TermsBlock([
      for (final s in json['items'] as List)
        TitledText((s as Json)['term'] as String, s['def'] as String),
    ]),
    'diagram' => DiagramBlock.fromJson(json),
    'chart' => ChartBlock.fromJson(json),
    final type => throw FormatException('Tipo de bloco desconhecido: $type'),
  };
}

class ParagraphBlock extends Block {
  const ParagraphBlock(this.text);
  final String text;
}

class SubheadingBlock extends Block {
  const SubheadingBlock(this.text);
  final String text;
}

class ListBlock extends Block {
  const ListBlock(this.items, {required this.ordered});
  final List<String> items;
  final bool ordered;
}

class CodeBlock extends Block {
  const CodeBlock({required this.code, required this.lang, this.file});
  final String code;
  final String lang;
  final String? file;
}

enum CalloutVariant { note, tip, warning, danger }

class CalloutBlock extends Block {
  const CalloutBlock({required this.variant, this.title, required this.text});
  final CalloutVariant variant;
  final String? title;
  final String text;
}

class TableBlock extends Block {
  const TableBlock({required this.headers, required this.rows});
  final List<String> headers;
  final List<List<String>> rows;
}

class TitledText {
  const TitledText(this.title, this.text);
  final String title;
  final String text;
}

class StepsBlock extends Block {
  const StepsBlock(this.items);
  final List<TitledText> items;
}

class TermsBlock extends Block {
  const TermsBlock(this.items);
  final List<TitledText> items;
}

// ---------------------------------------------------------------------------
// Diagramas: grade de `cols` x `rows` unidades; nós e grupos são retângulos
// posicionados na grade, arestas ligam nós pelo id.

enum NodeVariant { normal, accent, muted, dashed }

class DiagramNode {
  const DiagramNode({
    required this.id,
    required this.label,
    this.sub,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.variant,
  });

  final String id;
  final String label;
  final String? sub;
  final double x, y, w, h;
  final NodeVariant variant;

  factory DiagramNode.fromJson(Json json) => DiagramNode(
    id: json['id'] as String,
    label: json['label'] as String,
    sub: json['sub'] as String?,
    x: _num(json['x']),
    y: _num(json['y']),
    w: _num(json['w']),
    h: _num(json['h'] ?? 2),
    variant: NodeVariant.values.byName(json['variant'] as String? ?? 'normal'),
  );
}

class DiagramEdge {
  const DiagramEdge({
    required this.from,
    required this.to,
    this.label,
    required this.dashed,
    required this.both,
    required this.offset,
    required this.accent,
  });

  final String from;
  final String to;
  final String? label;
  final bool dashed;
  final bool both;

  /// Deslocamento perpendicular (em unidades da grade) para separar arestas
  /// paralelas entre o mesmo par de nós.
  final double offset;
  final bool accent;

  factory DiagramEdge.fromJson(Json json) => DiagramEdge(
    from: json['from'] as String,
    to: json['to'] as String,
    label: json['label'] as String?,
    dashed: json['dashed'] as bool? ?? false,
    both: json['both'] as bool? ?? false,
    offset: _num(json['offset'] ?? 0),
    accent: json['accent'] as bool? ?? false,
  );
}

class DiagramGroup {
  const DiagramGroup({
    required this.label,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.labelBottom,
  });

  final String label;
  final double x, y, w, h;

  /// Rótulo no rodapé do grupo, para não colidir com arestas que entram pelo topo.
  final bool labelBottom;

  factory DiagramGroup.fromJson(Json json) => DiagramGroup(
    label: json['label'] as String,
    labelBottom: json['labelAt'] == 'bottom',
    x: _num(json['x']),
    y: _num(json['y']),
    w: _num(json['w']),
    h: _num(json['h']),
  );
}

class DiagramBlock extends Block {
  DiagramBlock({
    required this.title,
    required this.caption,
    required this.cols,
    required this.rows,
    required this.nodes,
    required this.edges,
    required this.groups,
  }) {
    final ids = {for (final n in nodes) n.id};
    for (final e in edges) {
      if (!ids.contains(e.from) || !ids.contains(e.to)) {
        throw FormatException('Aresta aponta para nó inexistente: ${e.from} → ${e.to}');
      }
    }
  }

  final String? title;
  final String? caption;
  final double cols;
  final double rows;
  final List<DiagramNode> nodes;
  final List<DiagramEdge> edges;
  final List<DiagramGroup> groups;

  factory DiagramBlock.fromJson(Json json) => DiagramBlock(
    title: json['title'] as String?,
    caption: json['caption'] as String?,
    cols: _num(json['cols']),
    rows: _num(json['rows']),
    nodes: [for (final n in json['nodes'] as List) DiagramNode.fromJson(n as Json)],
    edges: [for (final e in json['edges'] as List? ?? []) DiagramEdge.fromJson(e as Json)],
    groups: [for (final g in json['groups'] as List? ?? []) DiagramGroup.fromJson(g as Json)],
  );
}

// ---------------------------------------------------------------------------
// Gráficos: `line` (séries de pontos x/y) ou `bar` (barras horizontais).

enum SeriesTone { primary, accent, muted }

class ChartSeries {
  const ChartSeries({
    required this.name,
    required this.tone,
    required this.dashed,
    required this.points,
  });

  final String name;
  final SeriesTone tone;
  final bool dashed;
  final List<(double, double)> points;

  factory ChartSeries.fromJson(Json json) => ChartSeries(
    name: json['name'] as String,
    tone: SeriesTone.values.byName(json['tone'] as String? ?? 'primary'),
    dashed: json['dashed'] as bool? ?? false,
    points: [
      for (final p in json['points'] as List)
        (_num((p as List)[0]), _num(p[1])),
    ],
  );
}

class ChartBar {
  const ChartBar(this.label, this.value, {this.display});
  final String label;
  final double value;

  /// Rótulo de valor customizado (ex.: "~5 s"); senão usa `value` + unidade.
  final String? display;
}

enum ChartKind { line, bar }

class ChartBlock extends Block {
  const ChartBlock({
    required this.kind,
    required this.title,
    this.caption,
    this.unit = '',
    this.xLabel,
    this.yLabel,
    this.yMax,
    this.series = const [],
    this.bars = const [],
  });

  final ChartKind kind;
  final String title;
  final String? caption;
  final String unit;
  final String? xLabel;
  final String? yLabel;
  final double? yMax;
  final List<ChartSeries> series;
  final List<ChartBar> bars;

  factory ChartBlock.fromJson(Json json) => ChartBlock(
    kind: ChartKind.values.byName(json['kind'] as String),
    title: json['title'] as String,
    caption: json['caption'] as String?,
    unit: json['unit'] as String? ?? '',
    xLabel: json['xLabel'] as String?,
    yLabel: json['yLabel'] as String?,
    yMax: json['yMax'] == null ? null : _num(json['yMax']),
    series: [for (final s in json['series'] as List? ?? []) ChartSeries.fromJson(s as Json)],
    bars: [
      for (final b in json['bars'] as List? ?? [])
        ChartBar(
          (b as Json)['label'] as String,
          _num(b['value']),
          display: b['display'] as String?,
        ),
    ],
  );
}

// ---------------------------------------------------------------------------

double _num(Object? v) => (v as num).toDouble();

List<String> _strings(Object? v) => [for (final s in v as List? ?? []) s as String];

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'ê': 'e', 'è': 'e',
  'í': 'i', 'ì': 'i',
  'ó': 'o', 'ô': 'o', 'õ': 'o', 'ò': 'o',
  'ú': 'u', 'ü': 'u',
  'ç': 'c',
};

/// Minúsculas sem acentos, para busca tolerante.
String normalize(String s) {
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(_accents[ch] ?? ch);
  }
  return buf.toString();
}
