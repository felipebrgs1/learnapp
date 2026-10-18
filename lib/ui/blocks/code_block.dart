import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../content/models.dart';
import '../../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';

class CodeBlockView extends StatefulWidget {
  const CodeBlockView(this.block, {super.key});

  final CodeBlock block;

  @override
  State<CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<CodeBlockView> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.block.code));
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final b = widget.block;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.only(left: 14, right: 4),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    b.file ?? b.lang,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.eyebrow.copyWith(color: c.textSecondary),
                  ),
                ),
                Pressable(
                  onTap: _copy,
                  semanticLabel: 'Copiar código',
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: AppIcon(
                        _copied ? AppIconKind.check : AppIconKind.copy,
                        key: ValueKey(_copied),
                        size: 15,
                        color: _copied ? c.success : c.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Text.rich(
              highlight(b.code, b.lang, c),
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Tok { comment, string, number, key, keyword, punct, prompt }

typedef _Rule = (RegExp, _Tok);

final _yaml = <_Rule>[
  (RegExp(r'#.*'), _Tok.comment),
  (RegExp(r'"[^"]*"' r"|'[^']*'"), _Tok.string),
  (RegExp(r'^(\s*-?\s*)?[\w./-]+(?=:(\s|$))', multiLine: true), _Tok.key),
  (RegExp(r'\b(true|false|null)\b'), _Tok.keyword),
  (RegExp(r'\b\d+(\.\d+)?\b'), _Tok.number),
  (RegExp(r'^\s*-(?=\s)|[|>{}\[\]]', multiLine: true), _Tok.punct),
];

final _bash = <_Rule>[
  (RegExp(r'#.*'), _Tok.comment),
  (RegExp(r'^\$ ', multiLine: true), _Tok.prompt),
  (RegExp(r'"[^"]*"' r"|'[^']*'"), _Tok.string),
  (RegExp(r'(?<=\s)--?[\w-]+'), _Tok.keyword),
  (RegExp(r'[|&;>]'), _Tok.punct),
];

final _json = <_Rule>[
  (RegExp(r'"[^"]*"(?=\s*:)'), _Tok.key),
  (RegExp(r'"[^"]*"'), _Tok.string),
  (RegExp(r'\b(true|false|null)\b'), _Tok.keyword),
  (RegExp(r'-?\b\d+(\.\d+)?\b'), _Tok.number),
];

final _go = <_Rule>[
  (RegExp(r'//.*|/\*[\s\S]*?\*/'), _Tok.comment),
  (RegExp(r'"(\\.|[^"\\])*"' r"|`[^`]*`|'(\\.|[^'\\])+'"), _Tok.string),
  (
    RegExp(
      r'\b(break|case|chan|const|continue|default|defer|else|fallthrough|for|func|go|goto|if|import|'
      r'interface|map|package|range|return|select|struct|switch|type|var|nil|true|false|iota)\b',
    ),
    _Tok.keyword,
  ),
  (RegExp(r'\b\d+(\.\d+)?\b'), _Tok.number),
  (RegExp(r'\b[A-Z]\w*(?=\s*[({])'), _Tok.key),
  (RegExp(r':=|<-|[{}()\[\]]'), _Tok.punct),
];

final _tree = <_Rule>[
  (RegExp(r'#.*'), _Tok.comment),
  (RegExp(r'[│├└─]+'), _Tok.punct),
  (RegExp(r'[\w.-]+/'), _Tok.key),
];

/// Realce léxico simples por regex: suficiente para YAML, shell, JSON e Go
/// curtos de documentação, sem dependências.
TextSpan highlight(String code, String lang, AppColors c) {
  final rules = switch (lang) {
    'yaml' || 'yml' => _yaml,
    'bash' || 'sh' || 'shell' => _bash,
    'json' => _json,
    'go' || 'golang' => _go,
    'tree' => _tree,
    _ => const <_Rule>[],
  };
  final styles = {
    _Tok.comment: TextStyle(color: c.textMuted),
    _Tok.string: TextStyle(color: c.codeString),
    _Tok.number: TextStyle(color: c.codeNumber),
    _Tok.key: TextStyle(color: c.text, fontWeight: FontWeight.w500),
    _Tok.keyword: TextStyle(color: c.accent),
    _Tok.punct: TextStyle(color: c.textMuted),
    _Tok.prompt: TextStyle(color: c.textMuted),
  };

  // Coleta todos os matches, resolve sobreposições pela ordem das regras
  // (regras anteriores vencem) e depois pela posição.
  final claimed = List<_Tok?>.filled(code.length, null);
  for (final (re, tok) in rules) {
    for (final m in re.allMatches(code)) {
      var start = m.start;
      // Para chaves YAML com recuo/"- ", só a palavra recebe destaque.
      if (tok == _Tok.key && lang.startsWith('y')) {
        final word = RegExp(r'[\w./-]+$').firstMatch(m[0]!);
        if (word != null) start = m.start + word.start;
      }
      if (start == m.end) continue;
      final free = Iterable.generate(m.end - start, (i) => claimed[start + i]).every((t) => t == null);
      if (free) {
        for (var i = start; i < m.end; i++) {
          claimed[i] = tok;
        }
      }
    }
  }

  final spans = <TextSpan>[];
  var i = 0;
  while (i < code.length) {
    final tok = claimed[i];
    var j = i + 1;
    while (j < code.length && claimed[j] == tok) {
      j++;
    }
    spans.add(TextSpan(text: code.substring(i, j), style: tok == null ? null : styles[tok]));
    i = j;
  }
  return TextSpan(style: AppText.code.copyWith(color: c.textSecondary), children: spans);
}
