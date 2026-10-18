import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../content/models.dart';
import '../content/repository.dart';
import '../theme/theme.dart';
import 'topic_page.dart';
import 'widgets/common.dart';
import 'widgets/icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  String? _category;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final repo = ContentScope.of(context);
    final results = repo.search(_query.text, category: _category);
    final pad = MediaQuery.paddingOf(context);

    return ColoredBox(
      color: c.background,
      child: Column(
        children: [
          SizedBox(height: pad.top),
          const _TopBar(),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _focus.unfocus(),
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(20, 36, 20, pad.bottom + 40),
                children: [
                  Text('DOCUMENTAÇÃO DE BOLSO', style: AppText.eyebrow.copyWith(color: c.textMuted)),
                  const SizedBox(height: 12),
                  Text('Entenda a fundo,\nem poucos minutos.', style: AppText.display.copyWith(color: c.text)),
                  const SizedBox(height: 12),
                  Text(
                    'Guias técnicos com diagramas, gráficos e exemplos reais. Sem login, sem rede — só conteúdo.',
                    style: AppText.body.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  _SearchField(controller: _query, focusNode: _focus),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        _Chip(label: 'Todos', selected: _category == null, onTap: () => setState(() => _category = null)),
                        for (final cat in repo.categories)
                          _Chip(
                            label: cat,
                            selected: _category == cat,
                            onTap: () => setState(() => _category = _category == cat ? null : cat),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text('TÓPICOS', style: AppText.eyebrow.copyWith(color: c.textMuted)),
                      const Spacer(),
                      Text('${results.length}', style: AppText.eyebrow.copyWith(color: c.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (results.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        'Nada encontrado para “${_query.text}”.',
                        textAlign: TextAlign.center,
                        style: AppText.small.copyWith(color: c.textMuted),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (final (i, t) in results.indexed) ...[
                            if (i > 0) const Hairline(),
                            _TopicTile(topic: t),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                  Text(
                    '${repo.topics.length} tópicos · offline · conteúdo versionado no app',
                    textAlign: TextAlign.center,
                    style: AppText.eyebrow.copyWith(color: c.textMuted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = AppTheme.of(context);
    final (icon, next, label) = switch (theme.preference) {
      ThemePreference.system => (AppIconKind.monitor, ThemePreference.light, 'Tema: sistema'),
      ThemePreference.light => (AppIconKind.sun, ThemePreference.dark, 'Tema: claro'),
      ThemePreference.dark => (AppIconKind.moon, ThemePreference.system, 'Tema: escuro'),
    };
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.text, borderRadius: BorderRadius.circular(6)),
            child: Text('L', style: AppText.label.copyWith(color: c.background, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Text('learnapp', style: AppText.label.copyWith(color: c.text, fontSize: 15, letterSpacing: -.3)),
          const SizedBox(width: 8),
          const Badge('beta'),
          const Spacer(),
          IconButtonBox(icon: icon, label: label, onTap: () => theme.onPreferenceChanged(next)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: focused ? c.textMuted : c.border),
        boxShadow: focused ? [BoxShadow(color: c.border, spreadRadius: 3)] : const [],
      ),
      child: Row(
        children: [
          AppIcon(AppIconKind.search, size: 16, color: c.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (controller.text.isEmpty)
                  IgnorePointer(
                    child: Text('Buscar tópicos, conceitos, ferramentas…', style: AppText.small.copyWith(color: c.textMuted, fontSize: 14.5)),
                  ),
                EditableText(
                  controller: controller,
                  focusNode: focusNode,
                  style: AppText.small.copyWith(color: c.text, fontSize: 14.5),
                  cursorColor: c.text,
                  backgroundCursorColor: c.textMuted,
                  selectionColor: c.accent.withValues(alpha: .25),
                  textInputAction: TextInputAction.search,
                  autocorrect: false,
                ),
              ],
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: controller.clear,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AppIcon(AppIconKind.close, size: 14, color: c.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? c.text : c.background,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? c.text : c.border),
          ),
          child: Text(label, style: AppText.label.copyWith(color: selected ? c.background : c.textSecondary, fontSize: 12.5)),
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      borderRadius: BorderRadius.zero,
      onTap: () => Navigator.of(context).push(FadeRoute<void>(builder: (_) => TopicPage(topic: topic))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      topic.category.toUpperCase(),
                      if (topic.part != null) 'PARTE ${topic.part}',
                    ].join(' · '),
                    style: AppText.eyebrow.copyWith(color: c.textMuted, fontSize: 10.5),
                  ),
                  const SizedBox(height: 6),
                  Text(topic.title, style: AppText.h3.copyWith(color: c.text, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(
                    topic.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(AppIconKind.clock, size: 13, color: c.textMuted),
                          const SizedBox(width: 5),
                          Text('${topic.minutes} min', style: AppText.eyebrow.copyWith(color: c.textMuted, fontSize: 10.5)),
                        ],
                      ),
                      Text('${topic.sections.length} seções', style: AppText.eyebrow.copyWith(color: c.textMuted, fontSize: 10.5)),
                      Text(topic.level, style: AppText.eyebrow.copyWith(color: c.textMuted, fontSize: 10.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: AppIcon(AppIconKind.arrowRight, size: 16, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
